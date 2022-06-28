# Concurrency

## Synchronize access to shared mutable data

The `synchronized` ensures that only a single thread can execute a method or block at a time.  It provides a means of _mutual exclusion_.  Without synchronization, one thread's changes might be visible to other threads.  `synchronized` ensures that each thread entering a synchronized method or block sees the effect of all previous modifications that were guarded by the same lock.

Java language specification states that variable reads and writes are always _atomic_ (other than for `long` and `double`), even without synchronization.

Still, **synchronization is required for reliable communication between threads as well as for mutual exclusion. You must synchronize both reads AND writes.**

**Never** use `Thread.stop`.

Due to compiler optimizations, without `synchronized`, the compiler may re-order your source in a way that could cause your concurrent code to fail.  One such optimization is called _hoisting_, and in concurrent executions, it cojuld cause a _liveness failure_.
* Making the method `synchronized` avoids these optimizations

In some cases you may use the `volatile` modifier on shared state.  It does not perform any mutual exclusion, but it guarantees that any thread that reads the field will see the most recently written value.
* CPUs may otherwise cache values.  `volatile` tells the CPU to always read from memory the value of the state.

## Avoid excessive synchronization

Depending on the situation, excessive synchronization causes reduced performance, deadlock, or even nondeterministic behavior.

**Never cede control to the client within a synchronized method or block**.
* Do not invoke a method that is designed to be overridden.
* Do not invoke a method provided by a clilent in the form of a function object.

Move these calls to "alien" methods outside of the synchronized method or block.  An alien method invoked outside of a synchronized block is known as an _open call_.

**As a rule, you should do as little work as possible inside `synchronize`d regions**.

## Prefer executors, tasks, and streams to threads

The `java.util.concurrent` package has an _Executor Framework_.  Creating a work queue is extremely simple:

```java
// creating the executor service (a work queue)
ExecutorService exec = Executors.newSingleThreadExecutor();

// how to submit work to be done
exec.execute(runnable);

// how to terminate gracefully
exec.shutdown();
```

In general, `Executors.newCachedThreadPool` is what you want to use for simple workloads.  It creates a new thread for every new task if no threads are available.

Alternatively there is `Executors.newFixedThreadPool`, or you can use the `ThreadPoolExecutor` class directly for maximum control.

You should generally avoid working with `Thread`s.  The executor framework gives you an abstraction for the unit of work you want completed, called a _task_, of which there are two types: `Runnable` and `Callable`.  `Callable` is basically a `Runnable` but that returns values and can throw exceptions.

## Prefer concurrenchy utilities to `wait` and `notify`

Always use higher-level concurrency utilities instead of `wait` and `notify`, because these lower-level functions are old and are hard to do correctly.

There are three categories of these higher-level utilities:
1. Executor Framework
2. concurrent collections
3. synchronizers

The concurrent collections `ConcurrentList`, `ConcurrentQueue` and `ConcurrentHashMap` provide internal synchronization.  These collections are outfitted with _state-dependent modify operations_, e.g., `putIfAbsent`.
* Concurrent collections largely make synchronized collections obsolete.  Use `ConcurrentHashMap` instead of `Collections.synchronizedMap`

Synchronizers are objects that enable threads to wait for one another.
* `CountDownLatch`
* `Semaphore`
* `CyclicBarrier`
* `Exchanger`
* `Phaser`

Executors must be able to create enough threads to do what you want, otherwise you'll run into _thread starvation deadlock_.

**There is seldom, if ever, a reason to use `wait` and `notify` in new code**.

## Document thread safety

Javadoc does not include teh `synchronized` modifier in its output since this modifier is an implementation detail, not a part of the API.  It does not reliably indicate that a method is thread-safe.

There are multiple levels of thread safety.  A class msut clearly document what level of thread safety it supports.

Not exhaustive:
* **Immutable**.  No external synchronization is necessary.
* **Unconditionally thread-safe**.  Instances of this class are mutable but there is enough internal synchronization that instances can be used concurrently without any external synchronization.
* **Conditionally thread-safe**. Instances of this class are mutable.  To use them concurrently, clients must use external synchronization of the client's choosing.  You must indicate which invocations require synchronization and which lock must be acquired to execute these invocations.
* **Thread-hostile**.  Instances of this class is unsafe for concurrency even in the presence of external synchronization.  This usually happens if the class modifies static data without synchronization.

**Lock fields should always be declared `final`**.

## Use lazy initialization judiciously

Don't do lazy initialization unless you need to.  **Under most circumstances, normal initialization is preferable to lazy initialization.**

If you use lazy initialization, use a synchronized accessor:

```java
private FieldType field;

private synchronized FieldType getField() {
    if (field == null) {
        field = computeFieldValueExpensively();
    }
    return field;
}
```

If you use lazy initialization on a static field, use the lazy initialization holder class idiom:

```java
// The lazy initialization holder class idiom
private static class FieldHolder {
    static final FieldType field = computeFieldValueExpensively();
}

private static FieldType getField() {
    return FieldHolder.field;
}
```

If you use lazy initialization for an instance field, use the double-check idiom:

```java
// The double-check idiom
private volatile FieldType field;

private FieldType getField() {
    FieldType result = field;
    if (result == null) { // First check (no locking)
        synchronized(this) {
            if (field == null) { // Second check (with locking)
                field = result = computeFieldValueExpensively();
            }
        }
    }
    return result;
}
```

The double-check idiom looks convoluted, but what it does is ensure that `field` is read only once when it's already initialized.

## Don't depend on the thread scheduler

The thread scheduler determines which ones get to run and for how long.  Reasonable operating systems try to do this fairly, but the policy may vary.

**Any program that relies on the thread scheduler for correctness or performance is likely to be nonportable.**

**Ensure that the average number of _runnable_ threads is not significantly greater than the number of processors.**.  This leaves the thread scheduler with no choice: it simply runs the runnable threads until they're no longer runnable.

Make sure each thread does some useful work, and then wait for more.  Threads should not run if they aren't doing useful work.
* This means sizing thread pools appropriately and keeping tasks short, but not _too_ short such that the executor overhead ends up harming performance.
* Threads should not _busy-wait_, which is repeatedly checking a shared object waiting for its state to change.  Doing this increases the load on the CPU.
* Resist the urge to "fix" the program by adding calls to `Thread.yield`.  `Thread.yield` has no testable semantics.
* Thread priorities are among the least portable features of Java.
