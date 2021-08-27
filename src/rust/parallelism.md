# Parallel Rust

Concurrency comes in three flavors:
1. Single-thread concurrency (`async`/`await`)
2. Single-core, multi-threaded concurrency.
3. Multicore concurrency

Concurrency is "interleaving" concurrent tasks to be executed in your program.

## Concurrency is hard

Concurrent code must coordinate write access to a resource shared among multiple threads.
- If you only need a read-only multi-thread access, then just stick the type in an `Arc` and send it over the thread boundary.
- If you need write access in a multi-threaded context, then you have to be extremely worried about data races.

A *data race* is when one thread updates shared state while a second thread is also accessing that state.  Without synchronization, the second thread's read might read partially overwritten state or clobber parts of what the first thread wrote.  Data races are undefined behavior (UB).

A *race condition* is a superset that includes data races, and occurs whenever multiple outcomes are possible from a sequence of instructions, depending on the relative timing of other events in the system.
- Race conditions are not always bad and are not UB.
- But they're often where bugs are found.

Just because you introduce concurrency doesn't mean that you'll experience perfect linear scalability (a linear relationship between # of cores and the program's performance metrics.)
- Sublinear relationships are way more common
- Negative scaling is possible, where more cores _reduce_ performance.  This often occurs when many threads are contending for some shared resource.
- In some cases it is common to implement mutual exclusion over some critical piece of code (like writes to shared resources).  By definition, mutual exclusion slows down and prevents achieving linear scalability since it forces serial execution of the relevant part of the program.
- Even if you've solved other problems, there are limits to how the shared resources, e.g., the kernel, the memory bus, the GPU, etc., can perform its duties.  At some point, you can't achieve higher scalability.

*False sharing* is when two operations that shouldn't contend with each other do so anyway, which precludes parallel execution.
- This can occur if the two operations use the same resource even though they use unrelated parts of that resource.
- An example of this is _lock oversharing_ where some resource is behind a lock and two threads need the lock to write to two different sub-resources (or subcomponents) held behind the lock.

*False sharing* can occur at the CPU level.
- CPUs operate on memory in cache lines, which are long sequences of consecutive bytes in memory, instead of individual bytes.  The idea is that by reading a longer line of bytes, you can save some time not having to read consecutive bytes in memory.  (The guiding assumption is that data clustered together are often accessed together, like a `Vec` (or array))
    - On most Intel processors, the cache line size is 64 bytes.
    - This means that every memory operation reads or writes bytes in multiples of 64.
- If two cores want to update the value of two different bytes that fall on teh same cache line, those updates must execute sequentially, even though the updates are logically disjoint.
- One way to avoid false cache line sharing is to pad values so that they are the size of a cache line.


## Concurrency Patterns

### Shared Memory

- Threads cooperate by operating on regions of memory shared between them.
- Such memory regions may be guarded by a mutex or using a data structure that supports concurrent access.
- Your choice of data structures are where you make key decisions on allowing for shared memory.
    - Mutexes are good for a few cores, might not scale well past a few.
    - A RwLock allows for many concurrent reads at the cost of slow writes.
    - A sharded reader/writer lock might allow for perfectly scalable reads but make writes costly and disruptive.
- Shared memory concurrency is a good fit when you want threads to jointly update shared state in a way that **does not commute**, AKA, `thread1 then thread2 !== thread2 then thread1`
- Lock-free concurrency algorithms provide concurrent shared memory operations without the use of locks.

### Worker Pools

- Many identical threads receive jobs from a shared queue of jobs, which are executed entirely independently.
- Worker pools often use shared memory to coordinate how they take jobs from the queue and how they return incomplete jobs back to the queue.
- The rust project `rayon` spins up a worker pool, splits a vector of elements into subranges, then hands the subranges to the threads in the pool.
- **Work stealing** is a key feature. If one thread finishes its work early and there is no more unassigned work available, that thread can steal jobs that have already been assigned to a different worker but hasn't started.
    - Even if every worker is given the same _number_ of jobs, some workers may end up finishing more quickly than others.
- Implementing work stealing is hard without incurring significant overhead (threads need to keep trying to steal work from each other)
    - Work stealing is very important to a good, high performance worker pool.
    - Usually most worker pools start out using a simple multi-producer, multi-consumer channel to send work to the worker pool threads, but this ends up becoming a bottleneck over time.
- Worker pools are a good fit when the work that each thread performs is the same but the data varies.  This includes asynchrony, since the "work" performed is calling `Future::poll()`.
- It is sometimes common to place a task back onto the queue when a task yields.

### Actors

- There are separate job queues, one for each job "topic".  Each job queue feeds into a particular actor which handles all jobs that pertain to a subset of that application's state.
- If some task wants to interact with a particular subset of the application's state, it must send a message to the owning actor.
- Actors have exclusive access to its inner resource, meaning no locks or other synchronization mechanisms are required.
- Actors may talk to each other, in fact it is quite common for it to do so.
- Actors don't necessarily have its own thread.  In general, there is often many actors, each of which map to a particular type of task instead of a thread.  This is usually safe because actors own their respective domain and don't care whether it's running on a particular thread or not.
- Actors is often used together with worker pools.  For example, you can spawn an async task for each actor, which is then handed to the worker pool.  Execution of a given actor may move from thread to thread, but every time the actor executes, it maintains exclusive access to its wrapped resource.
- Actors are a good fit when you have many resources that can operate independently (relatively speaking) and where there is little or no opportunity for concurrency _within_ a given resource.  If you only need a few actors, it's not so great.  If one actor's workload is skewed heavily, then that one actor becomes a bottleneck, and it is impossible to parallelize it (since it has exclusive access over its resource.)


## Async x Parallelism

- Strictly speaking, async does not require `Send` futures since they can theoretically operate on a single-threaded executor.
- In most cases though, applications want both concurrency and parallelism, such that it wants the async executor to take advantage of more than one core on the host computer.
    - The `Future`s handed to the executor must be `Send`.  If they aren't, the executor cannot send the future to other threads for execution.
    - The `Future`s must be able to be split into tasks that can operate independently.  If one giant `Future` contains a number of inner `Future`s that _could_ execute in parallel, the executor must still call `poll()` on the top-level root `Future`.
        - As a result you must explicitly `spawn` the futures you want to run in parallel.
- Most synchronization primitives have asynchronous counterparts.  We need these counterparts because blocking a future means blocking the thread executing the future, preventing the executor from doing its job.
    - There are use-cases for using the synchronized versions, for example Mutexes when you know that a particular Mutex is unlikely to block for a long period of time.
    - Never yield or perform long running operations while holding the `MutexGuard`.

### Low-level concurrency data structures
- The `std::sync::atomic` module provides atomic primitives backed by underlying CPU primitives:  `AtomicUsize`, `AtomicI32`, `AtomicBool`, `AtomicPtr`, `Ordering`, `fence`, `compiler_fence`, etc.
- These primitives share similar API: `load`, `store`, `fetch_*`, and `compare_exchange`.
- There are a limited number of atomic types because there are a limited number of values tha a CPU can access atomically.

How do concurrent memory accesses behave?
- The compiler emits CPU instructions when your program needs to read the value of a variable or write to it.
- Compilers can often perform all sorts of optimizations and transformations on the code, which can cause program statements to be reordered or removed.  Ultimately a subset of statements translates into memory instructions.
- At the CPU level, memory addresses come in only two forms:
    - `loads` pull bytes from a location in memory into a CPU register
    - `stores` move bytes from a CPU register into a location in memory.
- Loads and stores occur on small chunks of memory at a time (at most 8 bytes).  If a program needs to access memory larger than one of these chunks, then the compiler has to emit multiple load and/or store instructions.
- CPUs often execute instructions in parallel and even out of order when it deems that there are no dependencies on each other.
- CPUs have several layers of caches between a core and RAM, so a `load` may be out-of-date depending on if it's reading from a cache or not.
    - Writes aren't visible everywhere until all caches of the written memory location have been updated.
    - Meanwhile, other CPUs can execute instructions against the same me,ory location.

In general, CPU instruction optimizations are performed by the compiler under the assumption that the code will not be run concurrently.  If you do end up writing code to run concurrently, the compiler's optimizations could really get in the way.

Most methods on atomic types take an argument of type `Ordering`, which dictates ordering restrictions that the atomic operation is subject to.
- `Ordering` is a way to request precise behavior for what happens when multiple CPUs access a particular memory location for a particular operation.
- You can think of it from the perspective of the memory location.  Requests to access your location come from many threads all at once.  How do you order these requests?

```rust
enum Ordering {
    Relaxed,
    Release,
    Acquire,
    AcqRel,
    SeqCst,
}
```

#### Relaxed
- Guarantees nothing about concurrent access beyond the fact that access is atomic.
- Guarantees nothing about the relative ordering of memory accesses across different threads.

#### Release/Acquire (`Acquire`, `Release`, and `AcqRel`)
- Guarantees an execution dependency between a store in one thread and a load in another.
- Doesn't just establish the dependency for a single value, but also puts ordering constrains on other loads and stores in all threads involved.
    - If a `load` in thread B has a dependency on a `store` in thread A, then A must execute before B.
    - Furthermore, it also follows that any `load` or `store` in B after the first `load` must therefore happen after that store in `A`.
- `Acquire` affects `load`. `Release` affects `store`. `AcqRel` will apply to both `load` and `store`.

1. `load`s and `store`s cannot be moved forward past a `store` with `Ordering::Release`.
2. `load`s and `store`s cannot be moved back before a `load` with `Ordering::Acquire`.
3. A `load` with `Ordering::Acquire` must see all `store`s that happened before an `Ordering::Release` `store` that stored what the `load` had loaded.

#### Sequentially Consistent (`SeqCst`)
- Has the same guarantees as Release/Acquire, plus more.
- Instructs the compiler to take extra precautions to guarantee sequential consistency for `load`s and `store`s. Sequentially consistency ensures that if you looked at all related `SeqCst` operations, you could put teh thread executions in some order so that the values were loaded and stored would all match up.


### `compare_and_exchange`

An atomic operation where you have to provide an expected current value and the target value you want to update the atomic to.  If the current value matches the expected value, then the value will be updated.
- If some other thread modified the atomic variable's value, then modified it back, before your `compare_and_exchange` runs, then it will still succeed.
- Can become a scalability bottleneck since only one CPU can make progress at a time, since `compare_exchange` requires that a CPU has exclusive access to the underlying value.

### Fetch methods (`fetch_add`, `fetch_sub`, `fetch_and`, etc.)

- More efficient execution of atomic operations that commute.
- `compare_exchange` is powerful but if two threads want to update a single variable, one will succeed and the other will fail and will have to retry.
- For simple threads that commute, rather than fail and retry, the method will inform the CPU to just perform the operation eventually when it gets exclusive access again.
    - An example is if you have an `AtomicUsize` that counts th number of operations a pool of threads has completed.  In this case, no one really cares which updates the counter first, as long as they are both eventually counted.
- The power of doing this instead of a `load` followed by a `store` is that the CPU performs a load and store atomically without another thread getting in the way.
- The methods also never fail, since the CPU will just perform the operation eventually.



## Further Reading
* https://pages.cs.wisc.edu/~remzi/OSTEP/threads-bugs.pdf

