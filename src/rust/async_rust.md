# Asynchronous Rust

An asynchronous interface is one that may not yield a result right away.  Its result is deferred to a later time.  This allows the caller to continue doing other work in the meantime rather than having to go to sleep.

An asynchronous interface is a method that returns a [Poll](https://doc.rust-lang.org/std/task/enum.Poll.html):  

```rust
// std::task::Poll
enum Poll<T> {
    Ready(T),
    Pending
}
```

This enum is often used with functions with names that begin with the word `poll`, and it signifies that the operation is non-blocking.
- If you have a handle to two or more different `Poll`s, you can loop over them and check for the first one that is `Poll::Ready`. 
- Be careful about doing this in a hot loop though, checking exactly 2 poll methods billions of times a second when its unlikely you'd get a `Ready` for minutes is a waste of CPU resources.

Polling in Rust is _standardized_ with a trait called `Future`.  A simplified version is below:

```rust
// Not the real std::future::Future
trait Future {
    type Output;
    fn poll(&mut self) -> Poll<Self::Output>;
}
```

Things that a future could be:
- The next time a network packet comes in
- The next time a mouse cursor moves
- The next time some amount of time has elapsed

### Futures nomenclature
- When a future eventually returns `Poll::Ready<T>`, we say that the future "resolved to" a T.
- Instead of `poll_recv` and `poll_keypress`, we can just have a method `recv` or `keypress` that each return `impl Future` with an appropriate `Output` type.
- In general, you cannot assume that you can call `poll` on a future _AFTER_ it has already returned a `Poll::ready`.  It is generally acceptable for it to panic if you do this.
    - But some futures explicitly allow you to poll it again and again even after it is ready.  These futures are referred to as a "fused future".

## Async/Await

`async` and its related keyword `await` are syntactic sugar for a function that returns an `impl Future`.  Under the hood, they are implemented with `generators`.

Example:
```rust
async fn forward<T>(receiver: Receiver<T>, sender: Sender<T>) {
    while let Some(t) = receiver.next().await {
        sender.send(t).await;
    }
}
```

### Generators

Generators are functions/chunks of code with the ability to allow it to `yield` execution midway, and resume execution from where it last yielded later on.

In the above example, Rust transforms `async` functions (like `forward`) into a generator.

The compiler transforms the function into a generator by creating some extra code that helps it do what it needs to do:
1. A custom data structure associated to the function which is capable of storing all the state in the generator at a given point in time (when it yields).
2. A `resume` method which allows the generator to resume from the snapshot state, executing from the last `yield`.

Generators (and therefore futures) have a potential of getting huge.

- The data structure responsible for holding state will have to be large enough to hold everything on the function stack.  If you've created a `[u8; 8192]`, then the data structure will need to hold that structure.
- In addition, any and all futures that your `async fn` awaits on will need to be stored in this data structure so that it can be polled later.
- If you perform `perf` profiles, you'll see an excess of time spent in `memcpy` functions since these data structures will be copied and moved repeatedly.
- When you discover this to be an issue, you have two options:
    1. Reduce the amount of local state that the `async` function needs.
    2. Move the future to the heap with `Box::pin`

### Pin

Copied for ease of comparison:

```rust
async fn forward<T>(receiver: Receiver<T>, sender: Sender<T>) {
    while let Some(t) = receiver.next().await {
        sender.send(t).await;
    }
}
```

What happens if the generator takes a reference to a local variable?

- The future returned by `receiver.next()` must hold a `&receiver` if a `next` message is not immediately available so it knows where to try again when the generator resumes.
- When `forward` yields, the future and the reference the future contains get stashed away inside the generator's associated data structure.

```rust
async fn try_forward<T>(receiver: Receiver<T>, sender: Sender<T>) -> Option<impl Future> {
    let mut f = forward(receiver, sender); // 1
    if f.poll().is_pending() { // 2
        Some(f)
    } else {
        None
    }
}
```

- On the line commented `1`, we call `forward(..)`, which is an async function that will return a `Future<Output = ()>`.
- On the line commented `2`, we call `f.poll()` on the future returned in line `1`.  This will return either a `Poll::Ready<()>` or a `Poll::Pending`.
    - When we call `f.poll()`, the `forward` generator resumes executing.
    - The `forward` generator continually calls `receiver.next().await` and `sender.send(t).await`.
    - As long as both `receiver.next()` and `sender.send(t)` both return a `Poll::Ready`, the `forward` generator will not yield back to our `f.poll()` call.
    - At some point, one of `receiver.next()` or `sender.send(t)` will return `Poll::Pending` OR `Poll::Ready<None>`.
    - If the value is `Poll::Pending`, it will yield back out to the `f.poll()` call.
    - If the value is `Poll::Ready<None>` then the function will kick out of the `while` loop and return a `Poll::Ready<()>`.

Here's where the issue is:
- `f.poll()` will return one of `Poll::Pending` or `Poll::Ready<()>`.
- If it's `Poll::Pending`, the `try_forward` function will move the future into a `Some` and return that.  Otherwise, it will return a `None`.
- When the future is moved into the `Some`, references stored in the generator data structure to `receiver` and `sender` will no longer be valid!

Futures are inherently self-referential. If the future is moved, then its data is also moved, which invalidates the references to `self`. See [additional reading here](https://rust-lang.github.io/async-book/04_pinning/01_chapter.html).
- The solution is an advanced Rust type called `Pin`, which adds a contract that the value pinned will never move again, allowing the references to remain valid.
- While `Future`s make use of `Pin`, `Pin` is general purpose and can be used for any self-referential data structure.

```rust
struct Pin<P> { pointer: P }
impl<P> Pin<P> where P: Deref {
    pub unsafe fn new_unchecked(pointer: P) -> Self { .. }
}
impl<'a, T> Pin<&'a mut T> {
    pub unsafe fn get_unchecked_mut(self) -> &'a mut T { .. }
}
impl<P> Deref for Pin<P> where P: Deref {
    type Target = P::Target;
    fn deref(&self) -> &Self::Target;
}
```

- `Pin` holds a pointer type, which is indicative of `P: Deref`, aka the type `P` can be dereferenced to some target `T`.
    - This means that instead of `Pin<MyType>` you can have a `Pin<Box<MyType>>`, a `Pin<Rc<MyType>>`, or a `Pin<&mut MyType>`.
- `Pin`'s constructor, `new_unchecked`, is `unsafe`.
    - It is unsafe because the compiler has no way to check that the pointer indeed promises that the target value won't move again.
    - Its safety depends on the implementation of traits that are themselves safe.
    - Specifically, `Deref`, `DerefMut` and `Drop` for the `P` pointer given to `Pin` cannot move their specific pointed-to values.
- `Pin` has a `get_unchecked_mut` method that gives you an exclusive reference to its target type, `&'a mut T`.
    - This method is also `unsafe`, because users must promise to not use the `&mut T` to move the `T` or otherwise invalidate its memory.
    - This invariant could be broken if a user wrote something like `std::mem::swap` on two difference `&'a mut T`s.
- `Pin::get_unchecked_mut` relies on its implementation of `DerefMut<Target = T>`.
- `Pin` has an implementation of `Deref<Target = T>` that is always safe (as opposed to `DerefMut<Target = T>`).
    - `Deref` is safe because you only get a `&T` and it does not let you move it without writing other unsafe code.

### Unpin

`Unpin` is an auto marker trait that asserts that the type is safe to move out of a `Pin` when used as the `Pin`'s target type `T`.
- This means that the type does not rely on any of `Pin`'s guarantees.
- This means that the type may be moved out of the `Pin` without causing memory unsafety.
- Only types that explicitly opt out of `Unpin` are `!Unpin`.  These types include generators and types that contain other `!Unpin`.

When the target type is `Unpin`, it allows us to provide a much simpler and safer interface to `Pin`.

```rust
impl<P> Pin<P> where P: Deref, P::Target: Unpin {
    pub fn new(pointer: P) -> Self;
}
impl<P> DerefMut for Pin<P> where P: DerefMut, P::Target: Unpin {
    type Target = P::Target;
    fn deref_mut(&mut self) -> &mut Self::Target;
}
```

When types are `Unpin`, it means that the type does not care if it is moved, even if it was previously pinned.
- For `Unpin` types, `Pin` is basically irrelevant.


## How to Pin

Suppose we're considering some type that implements `Future`.

If the type is `Unpin`, then just call `Pin::new(&mut future)`.

If the type is `!Unpin`, then we can pin the future to the heap or to the stack.

The primary contract of `Pin` is that once something has been pinned, it cannot move. And the API for `Pin` takes care of honoring that contract for all methods and traits on `Pin`.
- The role of any function/user that constructs a `Pin` is to **ensure that if the `Pin` _itself_ moves, that the underlying target does not move too.**
- We can do this by placing the value on the heap, then place a pointer to that value in the `Pin`.  This allows `Pin` to move, but the underlying data won't move with it.
    - This is done with `Box::pin`. 


## Awaiting Futures

```rust
pub trait Future {
    type Output;
    fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output>;
}
```

`await` syntax is syntactic sugar.

```rust
// In both examples, `expr` is a standin for `some_future.await`

// A heavily simplified version of the desugared await
loop {
    if let Poll::Ready(r) = expr.poll() {
        break r
    } else {
        yield
    }
}

// A less simplified (but still simplified) desugared await
match expr {
    mut pinned => loop {
        match unsafe { Pin::new_unchecked(&mut pinned) }.poll() {
            Poll::Ready(r) => break r,
            Poll::Pending => yield,
        }
    }
}
```

### Wakers

Both of the above aren't accurate because they each require a `loop` to call `.poll()` again.  Doing it this way would burn a lot of CPU cycles you could have probably used for other, more useful things.

We would rather have the executor poll the future once, then put it to sleep until another future can make progress.  It should then wake up long enough to call `.poll()` on those futures, then go back to sleep.

Waking up should therefore, be conditioned on some event, e.g.:
- When a network packet arrives on a given port.
- When the mouse cursor moves.
- When someone sends on this channel.
- When the CPU receives a particular interrupt.
- After a specific set of time has passed.
- Custom, user-defined, futures can also be created with not just one but multiple conditions.

A `Waker` provides a way to wake the executor.  By waking the executor, you are signaling to it that progress can be made.

Executors construct a `Waker`, then uses it when polling futures.  The `Waker` is part of the mechanisms that the executor uses to go to sleep and later awaken.  In the `poll()` method the second argument for `Context` contains the `Waker`.

`Waker` has the following interface:
```rust
impl Waker {
    pub fn wake(self);
    pub fn wake_by_ref(&self);
    pub unsafe fn from_raw(waker: RawWaker) -> Waker;
}
```

`wake` and/or `wake_by_ref` should be called when the future can again make progress.  Just in case it wasn't clear: the Future should be calling `wake`/`wake_by_ref` as part of its `poll()` method!.

The logic executed when `wake` or `wake_by_ref` is called is entirely up to the executor that constructed the `Waker`.  The executor decides the implementation for what happens when these functions are called, or when the `Waker` needs to be `clone`d, or when the `Waker` needs to be `drop`ped.
- This specification (by the executor) is performed using a manually implemented vtable which functions similarly to dynamic dispatch.

If `Future::poll` returns a `Poll::Pending`, it is the future's responsibility to ensure that _something_ calls `wake` on the provided `Waker` when the future is next able to make progress.
- When implementing your own `Future`, you are usually calling another method that _also_ returns a `Future`, and so your future should return `Poll::Pending` only if the inner future does.  You trust that the inner future handles waking the `Waker`.
- In other cases, you might have to handle a future that does not poll other futures.  These are called _leaf future_s.
    - Leaf futures are usually either (1) ones that wait for events that originate within the same process, or (2) ones that wait for events external to the process (like a TCP packet read).
    - For (1) above, the pattern is to store the `Waker` in a place that the code that needs to call it can find it.
    - For (2) above, it's more complicated since the code you're calling has no idea of futures and _they_ won't be waking the `Waker` for you.  Executors typically provide implementations of leaf futures that communicate behind the scenes with the operating system.
        - When a leaf future realizes it must wait for an external event, it updates that executor's state to include an external event source alongside the `Waker`.
        - When the executor can't make any progress, it gathers all event sources for pending leaf futures, then makes a blocking call to the operating system which should return if _any_ of the leaf futures can respond to an incoming event.
        - The blocking call to the operating system on Linux is typically `epoll`.
        - A `reactor` is the part of an executor that has leaf futures register event sources with and that the executor waits on when it has no more useful work to do.
        - Due to the tight integration between leaf futures and how the executor then interfaces with the OS, most leaf futures are incompatible with being executed on another executor.

### Futures in a tree

Futures in an async program form a tree: futures contain zero or more other futures, recursively.  The root future is given to whatever the executor's main "run" function is.

A root future is called a `task`.  The root future/task is the _only point of contact between the executor and the futures tree_.
- Executors call `poll()` on the root task. From that point on, the code of each contained future must figure out which inner future(s) to poll in response, all the way to the leaf.
- In general, executors construct a separate `Waker` for each task they poll so that they know which task was just made runnable.
    - The underlying `RawWaker` makes DRYs out the code that would otherwise be duplicated across all `Waker`s.

When the executor executes `poll()` on a future the second or subsequent time, it still begins running from the top of its implementation of `Future::poll` and must decide how to get to the future deeper down that can now make progress.
- If there is only one obvious future to return execution to, then it does that.
- But there are cases where it gets a little complex, for example a `join()` might be waiting for a collection of futures to all finish, or a `select()` might be waiting for the first of a collection of futures to finish.
    - When a future has to do a `join()` or `select()`, it becomes effectively a "subexecutor".
    - Subexecutors wrap the `Waker` with their own `Waker` type before they `poll` an inner future, which then allows it to store state on which futures are runnable, and they also get notified when `Waker::wake` is called.
    - Subexecutors can use its own internal state to figure out which inner futures needs to be polled.

It's worth mentioning: if there's only one root future and that root future holds hundreds of inner futures, the program is effectively single-threaded, due there being only one root future.
- To actually have multi-threaded async, you can `spawn` the futures. (aka pass a `Future` to the `spawn` method.)
- Spawned futures still depend on being polled by the executor.
- If the executor stops running/is dropped then the tasks also stop making progress (since nothing is around to call `poll()`).
    - There are some executors that are multi-threaded and which can continue to poll tasks even if they yield control.  You need to check the docs for your executor of choice.

