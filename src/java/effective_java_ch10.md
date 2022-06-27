# Exceptions

## Use exceptions only for exceptional conditions

Exceptions should only be used in exceptional conditions, they should never be used for ordinary code flow.

As a corollary, a well-designed API must not force its clients to use exceptions for ordinary code flow.

```java
// Don't do this
try {
    Iterator<Foo> i = collection.iterator();
    while (true) {
        Foo foo = i.next();
        ...
    }
} catch (NoSuchElementException e) {
}

// Do this instead:
for (Iterator<Foo> i = collection.iterator(); i.hasNext(); ) {
    Foo foo = i.next();
    ...
}

// Or at worst, this. But this isn't better than the for loop idiom due to the the fact that the iterator is scoped too large:
Iterator<Foo> i = collection.iterator();
while (true) {
    if (!i.hasNext()) {
        break;
    }
    Foo foo = i.next();
    ...
}
```

## Use checked exceptions for recoverable conditions and runtime exceptions for programming errors

Java throws three kinds of throwables:
1. Checked exceptions
2. Runtime exceptions
3. Errors

**Use checked exceptions for conditions from which the caller can reasonably expected to recover.**  Throwing checked exceptions means the compiler will force the caller to handle the exception, either in a `catch` or to propagate it outward.

Runtime exceptions and errorsare not checked.  The API designer presents a mandate to recover from the condition, but users can disregard the mandate by catching the exception and ignoring it even though this would be a bad idea.
* They need not and generally should not be caught.
* If a program throws an unchecked exception ,it is generally the case that **recovery is impossible** and continued execution would do more harm than good.

**Use runtime exceptions to indicate programming errors.**  The majority of runtime exceptions are _precondition violations_.

There is a strong convention that _errors_ are reserved for use by the JVM to indicate resource deficiencies, invariant failures, or other conditions that make it impossible to continue execution.  As a result, **it is best not to implement any `Error` subclasses.**
* All unchecked throwables you implement should therefore subclass `RuntimeException`.
* Never implement `Throwable` that is not a subclass of `Exception`, `RuntimeException` or `Error`, even though the compiler will allow you to do this.
* If you implement a checked exception, you should provide methods that furnish information to help the caller recover from the condition.

## Avoid unnecessary use of checked exceptions

Checked exceptions force clients to deal with the problems, which enhances reliability.  But overuse of checked exceptions makes your API much less pleasant to use.

The checked exception litmus test:

When clients handle your checked exception, is this the best that can be done?

```java
} catch (TheCheckedException e) {
    throw new AssertionError(); // Can't happen!
}


// or

} catch (TheCheckedException e) {
    e.printStackTrace();
    System.exit(1);
}
```

If the answer to this litmus test is "yes", then an unchecked exception is a better option.

**The easiest way** to eliminate a checked exception is to return an `Optional<T>` of the desired result type.  The disadvantage is that the method can't return any additional information detailing its inability to perform the desired computation.  Exceptions are more descriptive with this regard.

**An alternative way** to eliminate a checked exception is to just turn it into an unchecked exception, but provide a helper method that checks whether the action is safe.  That way, clients can first call the helper method and if it returns `true`, then they can call the desired computation.
* You can't do this though if the method needs to be run concurrently.

## Favor the use of standard exceptions

Reusing standard exceptions:
1. Makes your API easier to learn and use because it matches established conventions.
2. Makes your API easier to read because they aren't cluttered with unfamiliar exceptions.
3. Fewer exception classes means a smaller memory footprint and less time spent loading classes.

Most common:  `IllegalArgumentException`.  Use this when callers pass arguments with inappropriate valeus.

Second most common: `IllegalStateException`.  Use this if an invocation is illegal because of the state of some receiving object.  For example if the caller attempted to use an object before it had been properly initialized.

The more specific exceptions can be useful too.
* It's convention to throw `NullPointerException` instead of `IllegalArgumentException` if the caller passes a null when they should not have.
* You should throw `IndexOutOfBoundsException` rather than `IllegalArgumentException` if the index given is out of bounds.
* `ConcurrentModificationException` should be used if an object that was designed for a single thread detects that it's being modified concurrently.
* `UnsupportedOperationException` can be rare but is notable because most objects support all of their methods.  But sometimes a class is extending a parent class with methods that your subclass doesn't want to support.

**Do not reuse `Exception`, `RuntimeException`, `Throwable`, or `Error` directly.  Treat these classes as if they were abstract.**

If an exception fits your needs, go ahead and use it, but only if the conditions where you would throw it match the semantics of the exception too (not just the name).

## Throw exceptions appropriate to the abstraction

It is confusing if a method throws an exception that has no apparent connection to the task it performs.

This can happen if a method propagates an exception thrown by a lower-level abstraction.  **Higher layers should catch lower-level exceptions and re-throw exceptions that can be explained in terms of the higher-level abstraction.**  This is called _exception translation_.

```java
try {
    ...
} catch (LowerLevelException e) {
    throw new HigherLevelException(...);
}

// an actual example from the AbstractSequentialList class
public E get(int index) {
    ListIterator<E> i = listIterator(index);
    try {
        return i.next();
    } catch (NoSuchElementException e) {
        throw new IndexOutOfBoundsException("Index: " + index);
    }
}
```

Exception _chaining_ is useful in cases where the lower-level exception might be helpful to someone debugging the problem that caused the higher-level exception.

This relies upon `Throwable`'s `getCause` method to retrieve the lower-level exception.

```java
// Exception chaining
try {
    ...
} catch (LowerLevelException cause) {
    throw new HigherLevelException(cause);
}

class HigherLevelException extends Exception {
    HigherLevelException(Throwable cause) {
        super(cause);
    }
}
```

Most standard exceptions have chaining-aware constructors.  For exceptions that don't, you can set the cause using `Throwable`'s `initCause` method.

## Document all exceptions thrown by each method

**Checked exceptions**.  Always declare checked exceptions individually, and document precisely the conditions under which each one is thrown using `@throws`.

If the method throws multiple checked exceptions, document each one, don't be tempted to just declare that it throws `Exception` or `Throwable`.
* The exception is the `main` method, this one _can_ be declared to throw `Exception`.


**Unchecked exceptions**.  It is wise to document all unchecked exceptions as carefully as the checked ones.  Interfaces especially should do this. Use the `@throws` tag, but do _not_ use the `throws` keyword on method signatures for unchecked exceptions.

## Include failure-capture information in detail messages

When the system prints an exception's stack trace, it does so using the exception's string representation, i.e., invoking its `toString` method.  Exception `toString` methods typically consists of the exception name followed by a _detail message_.  It's critically important that the detail message contains as much information needed to help engineers diagnose isues.

**To capture a failure, the detail message of an exception should contain the values of all parameters and fields that contributed to the exception**.
* For example, an `IndexOutOfBoundsException` should contain the lower bound, upper bound, and the index value that failed to lie between the bounds.
* But don't include passwords, encryption keys, or other security data points in detail messages.
* It is generally unimportant to include a lot of prose.  The stack trace and source code is usually enough "prose" for engineers to diagnose issues..
* Detail messages are not to be confused with user-level error messages, which should be intelligible to end users.  Detail messages should prioritize information content moreso than readability.
* One way to ensure it has all the information needed is to require these data points in their constructors.

## Strive for failure atomicity

In general, a failed method invocation should leave the object in the state that it was prior to the invocation.  A method with this property is said to be _failure-atomic_.

How to achieve failure atomicity:
1. If your object is immutable, then it's already failure atomic.
2. Check parameters for validity before performing the operation, throw exceptions before object modifications occur.
3. Order computations so that any part that may fail takes places before any part that modifies the object.
4. Perform the operation on a temporary copy of the object and then replace the contents of the object with the temporary copy once the operation is complete.
5. Write _recovery code_ that intercepts a failure and attempts to roll back to a previous state.


Failure atomicity is not always achievable, especially in the face of concurrency.

Sometimes it's achievable but not desirable, especially if it would significantly increase the cost or complexity.

## Don't ignore exceptions

When the designers of an API declare a method to throw an exception, don't ignore it!

**An empty `catch` block defeats the purpose of exceptions, which is to force you to handle exceptional conditions.**  So, handle those exceptional conditions.

In some situations it is appropriate to ignore an exception, but if you do, the `catch` block should contain a comment explaining why it is appropriate to do it, and the caught exception variable name should be `ignored`.
