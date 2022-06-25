# Methods

## Check parameters for validity

Document all invariants for parameters of methods and check them.  For example, check that non-nullable parameters are, indeed, not null.  Or check that an integer that should be non-negative is indeed, not negative.  You do this at the top of the function.

For `public` and `protected` methods, use the Javadoc `@throws` tag to document the exception that will be thrown if a restriction on parameter values is violated.  Typically this will be an `IllegalArgumentException`, `IndexOutOfBoundsException`, or `NullPointerException`.

```java
// For example:

/**
 * Returns a BigInteger whose value is (this mod m).  This method differs....
 *
 * @param m  the modulus, which must be positive
 * @return this mod m
 * @throws ArithmeticException if m is less than or equal to 0
 */
public BigInteger mod(BigInteger m) {
    if (m.signum() <= 0) {
        throw new ArithmeticException("Modulus <= 0: " + m);
    }

    ...
}
```

Note that in the above example, we don't have to check for `NullPointerException`.  We get it for free since we're calling `m.signum()`.  If `m` is `null`, then the method invocation will throw the NPE.

The `Objects.requireNonNull` method replaces any need to perform null checks manually.

If you're working with list and array indices, you can use a number of range-checking methods: `Objects.checkFromIndexSize`, `Objects.checkFromToIndex`, and `Objects.checkIndex`.

For `private` methods, you control all the circumstances under which the method is called so you should ensure they are _never_ called with invalid parameters.  You should check their parameters using `assert`.
* Assertions assert that the check will _always_ be true, regardless of how the enclosing package is used by clients.
* Assertions have no effect and therefore no cost unless you pass `-enableassertions` flag to the `java` command.


**It is even more important to check for parameter invariants that are stored for later use**.  Without doing so, you delay exceptions until they are later invoked, which makes debugging harder.  This is especially true in constructors.

**When should you skip the parameter checks?**  Skip them when validity checks would be (expensive or impractical) AND the check is performed implicitly as part of doing the computation.

You should design methods to be as general as it is practical to make them.

## Make defensive copies when needed

You must program defensively, with the assumption that clients of your class will do their best to destroy its invariants.

Here's an example implementation of a `Period` class signifying a `start` and `end` date range that should be immutable.  Upon first inspection, it looks like there's nothing wrong with it.

```java
// This class is broken
public final class Period {
    private final Date start;
    private final Date end;

    /**
     * @param start the beginning of the period
     * @param end   the end of the period
     * @throws IllegalArgumentException if start is after end
     * @throws NullPointerException if start or end is null
     */
    public Period(Date start, Date end) {
        if (start.compareTo(end) > 0) {
            throw new IllegalArgumentException(...);
        }
        this.start = start;
        this.end = end;
    }

    public Date start() { return start; }
    public Date end() { return end; }
}
```

This is broken because `Period` accepts two `Date` references and stores them.  They are immutable from the class itself, but `Date` is not immutable, so it is possible for a client to call `period.end().setYear(78);`

Instead, the above code should have made a defensive copy **of each mutable parameter**.

```java
public Period(Date start, Date end) {
    this.start = new Date(start.getTime());
    this.end = new Date(end.getTime());
    
    // note that we make the copies before any invariant checks.
    // and the invariant checks operate on the newly-made copies.
    // this helps maintain invariants even in the presence of threaded code.
    //
    // note also we are not using Date.clone
    // since Date is nonfinal, the clone method is not guaranteed to return a Date,
    // it could return an untrusted subclass.
    if (this.start.compareTo(this.end) > 0) {
        throw new IllegalArgumentException(...);
    }
}
```

Read the notes in the comment of the constructor above. **Do not use the `clone` method to make a defensive copy of a parameter whose type is subclassable**.

Now we have to check the getters.  Since the accessors offer access to the internal `Date` objects, `Date` is still not immutable and can therefore be changed after-the-fact.  Accessors should also make defensive copies when returning mutable internal fields.

```java
public Date start() { return new Date(start.getTime()); }
public Date end() { return new Date(end.getTime()); }
```

Anytime you write a method that stores a reference to a client-provided object in an internal data structure:
* think about whether the client provided the object is potentially mutable.
* if yes, then think about whether your class could tolerate that mutability
* if you can't tolerate it, then you must make defensive copies.

The above is true when you are returning references.  You should think twice if you're returning an internal object that is mutable.

The more you use immutable objects, the less you have to worry about defensive copying.

## Design method signatures carefully

**Choose method names carefully.**  Names should always obey standard naming conventions.  Choose names that are understandable and consistent with other names in the same package.  Avoid long method names.

**Don't go overboard providing convenience methods.**  Every method should "pull its weight".  Too many methods makes a class difficult to learn, use, document, test, and maintain.  When in doubt, leave it out.

**Avoid long parameter lists**.  4 parameters or fewer.  Long sequences of parameters with the same type are especially harmful.
* You could break the method up into multiple methods.
* You could create _helper classes_ to hold groups of parameters, these are often static member classes.
* You could adapt a Builder pattern for the method, where a class builds up parameters, then is expected to have some `execute` method.  Remember to check invariants on the `execute` or `build` method.

**For parameters, favor interfaces over classes.** This keeps your methods flexible.

**Prefer two-element enum types to boolean parameters.**  Unless the meaning of the boolean is clear from the method name.

## Use overloading judiciously

Overloading uses static dispatch to decide what method is called, meaning it is determined at **compile-time**.

Java does have dynamic dispatch, but that is implemented using _overriding_.  Dynamic dispatch means that the function implementation is determined at **runtime**.  This is also called runtime polymorphism.

**Selection among overloaded methods is static, while selection among overridden methods is dynamic.**

```java
// example of static dispatch
public class CollectionClassifier {
    public static String classify(Set<?> s) { return "Set"; }
    public static String classify(List<?> lst) { return "List"; }
    public static String classify(Collection<?> c) { return "Unknown Collection"; }

    public static void main(String[] args) {
        Collection<?>[] collections = {
            new HashSet<String>(),
            new ArrayList<BigInteger>(),
            new HashMap<String, String>().values()
        };

        for (Collection<?> c : collections) {
            // At compile-time, the typechecker will decide to use the "Unknown Collection" one.
            System.out.println(classify(c));
        }
    }
}

// example of dynamic dispatch
class Animal {
    String cry() { return "unknown animal cries"; }
}

class Dog extends Animal {
    String cry() { return "woof"; }
}

class Cat extends Animal {
    String cry() { return "meow"; }
}

public class Main {
    public static void main(String[] args) {
        List<Animal> animals = List.of(new Animal(), new Dog(), new Cat());

        for (Animal animal : animals) {
            // this executes the "most specific" override, so you get all three
            System.out.println(animal.cry());
        }
    }
}
```

Overloading can be confusing.  A safe, conservative policy is to **never export two overloadings with the same number of parameters.**  If a method uses varargs, a conservative policy is to not use overloading at all.
* Just give methods different names instead of overloading.
* **Do not overlaod methods to take different functional interfaces in the same argument position**.

## Use varargs judiciously

Varargs are invaluable when you need to define methods with a variable number of arguments.  Precede the varargs parameter with any required parameters and be aware of performance consequences.

Every varargs call involves an array allocation and initialization.

```java
// basic implementation, supports zero or more args
public void example(int... args) { ... }

// suppose you need at least 1 arg but can accept more
public void example(int first, int... rest) { ... }

// suppose you need to support varargs but you also care about performance
// with these overloads, you get static dispatch for any vararg count below 5.
// After 5 you pay the cost.
// Assuming most of your calls have few args, this could avoid many array allocations.
public void example() { ... }
public void example(int a1) { ... }
public void example(int a1, int a2) { ... }
public void example(int a1, int a2, int a3) { ... }
public void example(int a1, int a2, int a3, int a4) { ... }
public void example(int a1, int a2, int a3, int a4, int... rest) { ... }
```

## Return empty collections or arrays, not nulls

Don't return `null` in place of an empty collection.  It forces clients to handle for `null`.

If you're wary of allocating empty collections:
* Stop worrying about it until you test it and realize it's actually a problem.
* You could use an immutable collection, for example `Collections.emptyList()` which returns the same empty list instance and avoids allocation entirely.

## Return optionals judiciously

If you write a method that may sometimes be unable to return a value under certain circumstances, you've got some options:
1. Throw an exception if it can't return a value.
2. Return `null`.
3. Return an `Optional<T>`.

Exceptions are useful for exceptional conditions.

Returning `null` passes the buck to clients to handle the null-case, otherwise NPEs abound.

**Rules for using `Optional<T>`**
* Never return `null` from an `Optional<T>`-returning method.  Defeats the entire purpose of using `Optional`.
* Never return `Optional<Collection<T>>` or any other container type wrapped in an `Optional`.  You should just return empty versions of those collections instead of wrapping them in an `Optional`.
* Be wary of the performance cost.  `Optional` does add another object that must be allocated.
* Never return an optional of a boxed primitive type.  The optional will have two levels of boxing instead of zero. Instead use one of `OptionalInt`, `OptionalLong`, or `OptionalDouble`.
* Never use optionals as map values. Otherwise you will then have two ways of expressing a key's logical absence from the map.
* Never use optionals as map keys.
* Never use optionals as elements in a collection or array.
* It is often a code smell to use optionals in an instance field.

## Write doc comments for all exposed API elements

If an API is to be usable, it must be documented.

_Javadoc_ generates API documentation automatically from source code with specially formatted _documentation comments_.

Documentation comments constitute a de facto API that every Java programmer should know.

Precede _every_ exported class, interface, constructor, method, and field declaration with a doc comment.
* If a class is serializable, document its serialized form.
* The doc comment should describe succinctly the contract between the method and its client.
* Doc comments should focus on _what_ the method does instead of _how_ the method does it, with the exception of methods in classes designed for inheritance.
* Doc comments should enumerate all of the method's preconditions, which must be true in order for a client to invoke it.
* Doc comments should enumerate all of the method's postconditions, which are things that must remain true after the invocation has completed successfully.
* Use `@throws` tags for unchecked exceptions.
* Document any and all _side effects_.
* Have a `@param` tag for every parameter and a `@return` tag unless it returns `void`.
* By convention, the text following a `@param` or `@return` tag should be a noun phrase describing the parameter represented or return value
* By convention, the phrase or clauses that follow these tags are not terminated by a period.
* Use `@implSpec` to define the relationship between a class and any subclass.  You use this tag when you are designing a class for inheritance.
