# Memory Management

## Custom Memory Allocators

#### Why?
Custom memory allocators offer the following advantages:
1. Runs in `user` mode.  This avoids context switches to `kernel` mode to allocate memory on the heap by doing this one time for a large contiguous block of memory.  After the one-time kernel allocation, your custom allocator handles "allocating" memory to your program all in `user` mode.
2. Your implementation can be more efficient than the default global allocator by making assumptions about your most common use cases.

See: [http://www.swedishcoding.com/2008/08/31/are-we-out-of-memory/](http://www.swedishcoding.com/2008/08/31/are-we-out-of-memory/)

#### Stack-Based Allocator
* When the game needs to load a new game level, the allocator will allocate space for it.
* Once the level has been loaded, no more dynamic memory allocation takes place.
* Once the level has completed, its data is unloaded and all its memory is freed.
* Implementation
  1. First, allocate a large contiguous block of memory using `malloc()` or global `new` or by declaring a global array of bytes.
  1. Maintain a pointer to the top of the stack.
  1. Addresses below the pointer is in use.  Addresses above are considered free.
  1. Allocation requests move the pointer up by the requested number of bytes.
  1. Drops must occur in the opposite order they are allocated.
  1. You must maintain the invariant that the pointer points at memory locations _between_ two allocated blocks, or else you might overwrite some memory.
  
```rust
pub trait StackBasedAllocator {
    type Marker = u32;

    fn alloc(bytes: u32);
    fn get_marker(&self) -> Marker;
    fn free_to_marker(&mut self, marker: Marker);
    fn clear();
}
```

#### Double-Ended Stack Allocator
* Similar to the stack-based allocator, but has two pointers, one that allocates up from the bottom of the block and one that allocates down from the top of the block.
* Allows a trade-off between using the bottom allocator vs the top allocator.
* For example, the bottom allocator can be used to allocate and deallocate levels.  The top allocator can be used for memory blocks that are allocated and freed more frequently (as frequently as on every frame).

#### Pool Allocator
* Perfect for when we want to allocate and deallocate small blocks of memory, each of which are the same size, e.g., matrices, iterators, linked list nodes, mesh instances, etc.
* Pre-allocate a large block of memory with a size that is a multiple of the size of the elements that will be allocated.
* For example, a 4x4 Matrix has sixteen 32-bit floats. Each float is therefore 4 bytes. 4 * 16 = 64 bytes.  If we wanted our pool allocator to store matrices, the allocated size should be a multiple of 64.
* The pool is a linked list of elements.
* When we allocate, we pop from the linked list and place the data structure in the location where the element used to be.
* When we deallocate, the element is returned to the linked list.
* This makes allocations and frees O(1).

#### Allocators must provide addresses that are aligned
All memory allocators must be capable of returning aligned memory blocks.  We can do this by allocating a bit more memory than requested, shift the address of the memory block upward so that it is aligned correctly, then return the shifted address.

The worst case is having to pad with `alignment_size - 1` bytes.  An example of the worst case is starting with a pointer at an address ending 0x1 then being asked to allocate 16 bytes, which will require 15 bytes of padding to reach the next aligned memory address.

#### Single-Frame and Double-Buffered Allocators
On each iteration of the game loop, you'll need to allocate some temporary data and either release it or re-use it on the next frame.

*Single-Frame Allocator*
* Implemented using a simple stack allocator.
* At the beginning of each frame, the stack's top pointer is cleared to the bottom of the memory block.
* Within the frame, and through til the end, any allocations push the point upward.

```rust
fn main() {
    let stack_allocator = StackAllocator::default();

    loop {
        stack_allocator.clear();

        // This data need not ever be freed manually since the allcoator will clear
        // the stack at the beginning of the next frame.
        let pointer = stack_allocator.alloc(std::mem::<Something>());
    }
}
```

*Double-Buffered Allocator*
* Allows data allocated on frame _i_ to be used on frame _i_ and _i + 1_ only.
* To do this, we create two single-frame stack allocators of equal size, then ping-pong between them each frame.

```rust
struct DoubleBufferedAllocator {
    current_stack: u32,
    stacks: [StackAllocator; 2],
}

impl DoubleBufferedAllocator {
    fn swap_buffers(&mut self) {
        self.current_stack = !self.current_stack.clone();
    }
    
    fn clear_current_buffer(&mut self) {
        self.stacks[&self.current_stack].clear();
    }
    
    fn alloc(&mut self, bytes: u32) -> *const u32 {
        self.stacks[&self.current_stack].alloc(bytes)
    }
}
```

## Memory Fragmentation
As memory gets allocated and freed over the course of the game, the memory block starts to look like swiss cheese of holes where there is free memory.

As the count of free memory holes rises and when those holes are small, we say that the memory is heavily fragmented.

With high fragmentation, allocations may fail even when there are enough free bytes to satisfy the request.  This problem arises because allocations must occur over _contiguous_ blocks of memory.  A swiss cheese'd up free block makes it harder to find a large contiguous block even when the sum of all free space _should_ be enough.

### Avoiding fragmentation
Memory fragmentation can be completely sidestepped by using stack allocators or pool allocators.

Their designs completely remove the worry for memory fragmentations.  Stack allocators do so by clearing memory on each frame.  Pool allocators do so because they chunk up the memory block into equal sizes for the one kind of element that can be allocated.

### Dealing with fragmentation
If you cannot use a pool or stack allocator but you also need to arbitrarily allocate and free memory blocks, you may need to handle fragmentation with _defragmentation_.

The process of defragmentation involves shifting used memory blocks downward from higher addresses to lower addresses.  This bubbles up all free memory addresses to the top.
