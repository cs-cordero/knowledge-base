# Unsafe Rust

Unsafe code is the mechanism Rust gives developers for taking advantage of invariants that, for whatever reason, the compiler cannot check.

Unsafe code is not a way to get away with skirting the various rules of Rust like borrow checking.

Unsafe code is not a way to get around the borrow checker.

Unsafe code is not a way to get around the borrow checker. (one more time)

Unsafe code is not a way to get around the borrow checker. (last time)

`unsafe` (the keyword) marks a particular function as unsafe to call _and_ it enables you to invoke unsafe functionality in a given code block.

```rust
// foo is marked as unsafe, but inside
// there are no unsafe methods being used.
pub unsafe fn foo(&self) {
   self.some_usize -= 1;
}

// bar is not marked as unsafe, but inside
// an unsafe block is used
pub fn bar(&self) -> &T {
    unsafe { &*self.ptr }
}
```

## Unsafe Blocks

Unsafe blocks allow you to:
1. **Dereference raw pointers**
1. **Call unsafe functions**
1. Access mutable static variables
1. Access fields of unions

Might not sound like much, and you only really need to remember the first two.  But these two features allow you to:
- Turn one type into another using `mem::transmute`
- Dereference raw pointers
- Cast `&'a` to `&'static`
- Make types shareable across thread boundaries even when they're not thread-safe.

### Comparing References to Raw Pointers

| Pointer/Reference | Raw Pointer |
|:---:|:---:|
| `&T` | `*const T` and `std::ptr::NonNull<T>` |
| `&mut T` | `*mut T` |

Raw pointers do not have lifetimes.

Raw pointers are not subject to the same validity rules that regular references do.

You can safely go from reference to raw pointer, but you need `unsafe` to go from raw pointer to reference.

`*mut T` is invariant in `T`.

`*const T` and `NonNull<T>` are covariant in T.

`*const T` and `NonNull<T>` are the same except that `NonNull<T>` is not allowed to be a null pointer.

```rust
// It's common to see this in unsafe blocks:
unsafe { &*ptr }
unsafe { &mut *ptr}
```

### Raw pointers can express unrepresentable lifetimes
- In cases where you cannot express a reference with a lifetime that the compiler can use, i.e., self-referential structs, you can use raw pointers since they have no lifetime.
- Instead, you just have to make sure that when you _do_ dereference the pointer that it is still valid, which is what you're asserting when you write `unsafe { &*ptr }`.

### You can do pointer arithmetic with raw pointers
- This is done using `.offset()`, `.add()`, and `.sub()` to move the pointer to any byte, ideally within the same allocation.
- This is useful for space-optimized data structures like hash tables, where storing an extra pointer for each element is too much overhead.
    - See [hashbrown::RawTable](https://github.com/rust-lang/hashbrown/)
- Read the documentation carefully before using these methods!

### You can transmute from a type to a raw pointer then back again
- Some key stdlib types do this for you built-in.  For example, slices have `.as_ptr()` and `.len()`, then the slice can be recreated using `std::slice::from_raw_parts`.
    - `Vec`, `Arc`, and `String` have similar methods.
    - `Box` has `Box::into_raw` and `Box::from_raw`.
- Otherwise you can still go from `*const T` to `*const U` (and `*mut T` to `*mut U`) using pointer casting.  You don't even need `unsafe` to do it.  The `unsafe` comes later when you try to turn it into a reference.

## Unsafe functions

Unsafe functions are unsafe because they likely operate on raw pointers at some low level.

Calling an unsafe function is a way to have that unsafety abstracted from you, as long as you adhere to whatever contract that unsafe function requires from you.

In many unsafe function implementations, you'll see this pattern:

```rust
impl SomeType {
    pub fn calls_unsafe_with_checks() {
        // perform runtime safety checks
        unsafe {
            unchecked_unsafe_function()
        }
    }
    
    pub unsafe fn unchecked_unsafe_function() {
        // does some unsafe stuff, assuming invariants hold
    }
}
```

This allows users who have performance-sensitive applications that can't afford to do runtime checks to go directly to the `unchecked_*` version.  Otherwise, the safer method with an `unsafe` block provides some runtime checks that makes sure invariants hold first.

Most uses of `unsafe` rely on a custom invariant that cannot be provided or ensured by the compiler itself. Examples:
- `MaybeUninit::assume_init`
    - `MaybeUninit` allows you to store values that are not valid for their type in Rust temporarily.
    - When you call `::assume_init`, it requires that you are holding the invariant that it is _now_ holding the correct value for its type and can be used as that type.
- `ManuallyDrop::drop`
    - `ManuallyDrop` wraps some `T` that does not drop that `T` when the `ManuallyDrop` is dropped.
    - In addition, it provides an interface to drop the inner `T` even before `ManuallyDrop` is dropped.
    - You must hold the invariant that you won't ever access `T` again or try to `drop` a second time.
- `std::ptr::drop_in_place`
    - Allows you to call a value's destructor through a pointer to that value.  This is unsafe because the pointer will be left behind after the call.
    - You must hold the invariant that you won't ever try to dereference the pointer after calling `drop_in_place`.
- `Waker::from_raw`
    - The `Waker` type is made up of a data pointer and a `RawWaker` that holds a manually implemented vtable.
    - It holds raw function pointers in the vtable, such as `Waker::wake()` and `drop(waker)`, both of which can be called from safe code.
    - When calling `Waker::from_raw`, it asserts all pointers in its vtable are in fact valid function pointers that follow the invariant described in the docs of `RawWakerVTable`.
- `std::hint::unreachable_unchecked`
    - The `hint` module gives hints to the compiler about surrounding code but does not actually produce machine code.
    - The `unreachable_unchecked` method tells the compiler that it is impossible to reach a section of the code at runtime, which allows the compiler to make optimizations based on that.
    - You must hold the invariant that this is true (that the code is indeed unreachable).  If not, it's not easy to tell what the compiler will do.
- `std::ptr::read_unaligned`, `std::ptr::read_volatile`, `std::ptr::write_unaligned`, `std::ptr::write_volatile` 
    - These functions allow you to access data ignoring the alignment for the type `T` that a pointer points to.  This might happen if the `T` is contained in a packed byte array or packed in some other data structure without padding.
    - You must hold the invariant that the pointer is pointing at a valid `T`, since these methods ultimately dereference the pointer.
- `std::thread::Builder::spawn_unchecked`
    - Normally the safe `thread_spawn` function requires the provided closure is `'static`.  In some cases though, you might already know that some non-`'static` value in the caller will outlive the spawned thread.
    - `spawn_unchecked` removes the `'static` bound.
    - You must hold the invariant that the reference do not become invalidated while the spawn thread attempts to use it.
    - A panic in the caller might cause the caller's stack to unwind, dropping values, which will cause undefined behavior in the spawned threads, who will be trying to access the already-dropped reference.

## Unsafe Traits

A trait being unsafe doesn't mean that it is _necessarily_ unsafe to use, only that it was unsafe to _implement_.  Unsafe traits typically have custom invariatns that should be written in the documentation for the trait. 

Examples of unsafe traits:
- `Send` and `Sync`
    - Denotes a type is safe to send across thread boundaries or can be shared across thread boundaries.
    - Raw pointers are neither `Send` nor `Sync`.  They are prevented from automatically being so because types that store raw pointers are not expected to always work across thread boundaries.
- `GlobalAlloc`
    - This trait allows you to implement a custom memory allocator in Rust.
    - You're working directly with memory.  The trait itself is `unsafe`, and so is both of its required methods (`alloc` and `dealloc`).
    - It comes with a number of invariants that it must uphold, with regard to correct sizing, alignment, etc.
- Notable mention: `Unpin` is actually safe!
    - Implementing `Unpin` for a type does not grant you the ability to safely pin or unpin a `!Unpin` type.  You are still required to call` Pin::new_unchecked` or `Pin::get_unchecked_mut`.
    - There is already a safe way to unpin any type you control: the `Drop trait`

A trait should be made `unsafe` if safe code assumes that trait is implement correctly and can exhibit memory unsafety if the trait is _not_ implemented correctly.

Just because an incorrect implementation of a trait could cause havoc does not necessarily meet the bar for making it `unsafe.`  It should be used to highlight cases of memory unsafety, not just bad logic.

We rely on the _safety_ of safe code, NOT its correctness.

## When unsafe goes wrong

When unsafe code goes wrong, it causes *undefined behavior*, which manifests in one of three ways (shown in increasing severity):
1. Not at all
1. Through visible errors
1. Through invisible corruption

In #1, your code is not sound, but the compiler created sound code, likely by accident.  This could differ between compiler versions or even between platforms, so relying on this would be pretty stupid.

In #2, the compiler or runtime might crash, e.g., you tried to dereference a null pointer.  It may still be hard to debug the issue, but at least you're aware of the issue.  Other issues in this group could be deadlocks, garbled input/output, or panics that are triggered but don't cause the program to stop.

In #3, the program happily continues execution but the state is corrupted without any outward indication.  Transaction amounts could be slightly off.  Random bits of memory could be exposed to clients.  There could be infrequent, hard-to-explain outages.
- Since, by definition, the code's behavior is undefined, you have zero control or knowledge over what the compiler or bytecode will ultimately do.  This is a bad place to be in.
- ALL undefined behavior should be considered a serious bug.

## Validity is a concept that dictates the rules for what values inhabit a given type

- Reference types
    - Rust is very strict about what a valid reference type is.
    - References must never dangle.
    - References must always be aligned.
    - References always point to a valid value for their target type.
    - A shared and exclusive reference to a given location must never exist at the same time.
    - Multiple exclusive references to a given location must never exist at the same time.

- Shared reference types
    - In addition to the above, shared references require that the pointed-at value must not change during the reference's lifetime.
    - This applies transitively.  If you have an `&` to a type that contains a `*mut T`, you are not allowed to mutate the `T` through the `*mut` .
    - The only exception to this rule is if the value is wrapped by the `UnsafeCell` type.
        - `Cell`, `RefCell`, and `Mutex` internally use `UnsafeCell`.

- Primitive types
    - There are the common/expected validity rules for primitive types, e.g., `bool`s should be 1-byte large, but only hold `0x00` or `0x01`. Any other value is invalid.
    - Most of Rust's primitives cannot be constructed from uninitialized memory.
    - Many of these rules are enforced so that `rustc` _may_ perform optimizations with some given assumptions in mind.

- Owned pointer types
    - Owned pointer types like `Box` and `Vec` are subject to similar optimizations as if they were just an exclusive reference to its target.

- Storing invalid values (`MaybeUninit`)
    - Sometimes you need to store a value that isn't currently valid for its type. For example, you want to allocate a chunk of memory for some `T`, then read the bytes in over some IO into that chunk.
    - In general, you will call `MaybeUninit::uninit` to create something that can hold an invalid value temporarily.
    - Then you will use `MaybeUninit::as_mut_ptr` to write to its pointed at value.
    - Then you will use `MaybeUninit::assume_init` to take the inner `T` once it is valid.

## Unsafe code must be prepared to handle panics

When a thread panics, it begins _unwinding_ its stack, causing values in it and every value down the stack to be dropped.

You should comb through your code and identify statements that may panic, then consider whether your code is safe if they do panic.

Example from the book:

```rust
impl<T: Default> Vec<T> {
    pub fn fill_default(&mut self) {
        let fill = self.capacity() - self.len();
        if fill == 0 {
            return;
        }
        let start = self.len();
        unsafe {
            self.set_len(start + fill);  // We updated the length here before inserting new data.
            for i in 0..fill {
                *self.get_unchecked_mut(start + i) = T::default();
            }
        }
    }
}
```

In the above example, we call `Vec::set_len` _before_ filling the that new space with values.

If the call to `T::default()` panics for some reason, then the code would start unwinding before all of that extra space is initialized.

Eventually the `Vec` instance will be dropped, and the `Drop::drop` implementation will try to free the uninitialized memory since it will try to free the size of its length.

## Drop Checks can impact your code if you implement `Drop::drop`

Since `Drop::drop` requires a mutable borrow of the value, i.e., `&mut self`, there must be a valid exclusive flow to the drop.

```rust
let mut x = true;
let foo = Foo(&mut x);
x = false;
```

If `Foo` in the above does NOT implement `Drop::drop`, then this code would compile because the compiler knows that the exclusive borrow in `Foo` is not used again (there are no outward flows extending from it).

If `Foo` _did_ implement `Drop::drop`, there is an implicit call too `foo.drop`, which borrows `&mut self`.  As a result, there would be an exclusive flow drawn from the `foo` to its `drop`.

> However, **for a generic type to soundly implement drop, its generics arguments must strictly outlive it.**
> 
> https://doc.rust-lang.org/nomicon/dropck.html

> A generic Type<T> that manually implements Drop should consider whether a #[may_dangle] attribute is appropriate on T.
> 
> https://forge.rust-lang.org/libs/maintaining-std.html#is-there-a-manual-drop-implementation

## `repr(Rust)` structs have no guarantees on the layout of a struct in memory

Even if we're talking about a generic type `T<G>` - if you have a `T<A>` and a `T<B>`, they are not guaranteed to have the same representation in memory!

As a result, even if a type `T` and a type `U` have the same fields of the same type and the same order, they are not safe to cast a `T` to a `U` or vice versa.

- Even if `T` and `U` are guaranteed to have the same in-memory representation, i.e., you specified `repr(C)`, you will run into the same issue if these types are nested in another type.
    - `UnsafeCell<T>` and `MaybeUninit<T>` can be casted there and back again safely, but safety goes out the window once you have a `Option<MaybeUninit<T>>`.
    - Optimizations (like niche optimization) could affect the memory layout enough to no longer let this casting be safe.
    - Even regular ol' safe code without optimizations could cause different arrangements in memory even if a provided type is empty.

```rust
struct Wrapper<T: SneakyTrait> {
    item: T::Sneaky,
    iter: PhantomData<T>,
}

trait SneakyTrait {
    type Sneaky;
}
impl SneakyTrait for PhantomData<u8> {
    type Sneaky = ();
}
impl SneakyTrait for PhantomData<i8> {
    type Sneaky = [u8; 1024];
}
```

Although it is error-prone, you can still cast between types in Rust, just make sure you:
1. Guarantee the memory representation somehow,
2. Try to control all the types involved (if not, be cognizant of pitfalls)


## Tips for writing Unsafe code
- Make sure to handle `unsafe` code with care.  But don't be afraid - in a lot of circumstances, it's not too difficult to write sound code.
- Be sure that there isn't a safe implementation before resorting to `unsafe`.
- It's tempting to think that you only need to be vigilant in and around the `unsafe` keyword and `unsafe` blocks.  **THIS IS NOT TRUE**.  It is entirely possible for a safe implementation of code to cause previously written unsafe code to no longer be sound.
    - Look for safety only at the _privacy boundary_ of all code that relates to the unsafe block.
    - Where _privacy boundary_ means "any part of your code that can fiddle with the unsafe bits".

```rust
// module is bar/mod.rs
// this file is bar/foo.rs
pub struct Foo;

// If safety of unsafe code related to Foo depends on Foo not implementing
// particular traits or methods with particular signatures, recheck the
// safety of all unsafe blocks and keywords any time you implement a trait
// for Foo.
// Since users of your library may mess this up, the safety
// invariants should be strongly documented.
```

```rust
// module is bar/mod.rs
// this file is bar/foo.rs
pub(crate) struct Foo;

// If it was just pub(crate), then you'd only have to re-check for
// safety concerns within the same crate.
```

```rust
// module is bar/mod.rs
// this file is bar/foo.rs
struct Foo;

// Even better - if the Foo is private to this module, then you only
// need to re-check for safety within the same module (and any submodules).
```

- It is best to encapsulate `unsafe` code as much as possible.
    - Provide unsafety in the form of a single module and give that module an interface that is entirely safe.
    - Stick the unsafety in its own crate, so you don't accidentally leave any holes for `unsafe` code to lose its soundness.
    - Give them names that clearly communicate that care is needed, then document rigorously.
    - Don't sacrifice the `unsafe` keyword marker just to avoid the "noise" that it makes in your code.
    - Always document what conditions makes your `unsafe` function safe to call.
    - Always document the invariants that a given function expects to be upheld, even if they're already written elsewhere.  It's safe to assume documentation is read in an ad-hoc manner, not as prose.

- Additional `unsafe` code-writing tips:
    - Read the [Rustonomicon](https://doc.rust-lang.org/nomicon/) cover-to-cover.
    - Add a set of tools to your CI pipeline.
        - Use `miri` (Mid-level Intermediate Representation Interpreter).  This tool interprets the Rust code directly.
        - Use `AddressSanitizer` (written by Google), which detects a large number of memory errors, i.e., use-after-free, buffer overflows, memory leaks, etc.
    - Sprinkle assertions throughout your unsafe code.  A panic is better than UB.
        - If concerned about runtime cost, make use of `debug_assert*` macros and the `if cfg!(debug_assertions) || cfg!(test)` constructs for the debug and test contexts.






