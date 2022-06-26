# General Programming

## Minimize the scope of local variables

**Declare local variables where it is first used**.

**Nearly every local variable declaration should contain an initializer**.  If you don't have enough information to initialize a variable sensibly, you should postpone the declaration until you do.
* A notable and common exception is when the initialization can throw exceptions and you want to wrap it in a `try-catch`.  If you want the variable to accessible outside of the `try` block, it must be declared before the block.

**Prefer `for` loops to `while` loops**.  `for` loops allow you to declare _loop variables_, which limits their scope to the region of code where they are needed.

```java
// just need to iterate over a collection?
for (Element e : collection) {
    ...
}

// Need to get a handle to an iterator? This is the idiom:
for (Iterator<Element> i = collection.iterator(); iterator.hasNext(); ) {
    Element e = i.next();
    ...
}

// Need to call a function for every iteration, but it's guaranteed to return the same value every time?
for (int i = 0, n = expensiveComputation(); i < n; i++) {
    // note that `n` is a loop variable, processed once, and only scoped to the loop.
    ...
}
```

## Prefer `for-each` loops to traditional `for` loops

A `for-each` loop is this:

```java
// Example for-each loop.  the ':' reads "in"

for (Element e : collection) {
    ...
}
```

This `for-each` pattern hides the iterator and index variable `i` that you might have used otherwise.  The only requirement is that the `collection` must implement the `Iterable` interface.  If you define it on your classes, you can use `for-each` on them too.

There are three areas where you _can't_ use a `for-each`:
1. Destructive filtering
    * When you need to traverse a collection removing selected elements.  You'll need an explicit iterator. As an alternative you can use `Collection.removeIf`.
2. Transforming
    * If you need to traverse a collection and replace some or all of the values with a new value, you'll need to set values by index.
3. Parallel iteration
    * You will need explicit control over the iterator or index so that they can be advanced in lockstep.

## Know and use the libraries

**By using a standard library, you take advantage of the knowledge of the experts who wrote it and the experience of those who used it before you.**

As of Java 7, never use `Random`. The random number generator of choice for most uses is now `ThreadLocalRandom`.  For fork join pools and parallel streams, use `SplittableRandom`.

Many programmers don't use library facilities.  Why?  Perhaps they don't know the library facilities exist.  It pays to keep abreast of these additions.
* Every release there is a page published describing the new features.

**Every programmer should be familiar with the basics of:**
* `java.lang`, `java.util`, and `java.io`, and their subpackages.
* `Collections` framework
* `Streams` libray
* `java.util.concurrent`

If a standard library doesn't fit your needs, your next step should be to find high-quality third-party libraries.

Don't reinvent the wheel.

## Avoid `float` and `double` if exact answers are required

Floats and Doubles use floating-point arithmetic which are accurate approximations but not exact.  In situations where exact answers are required, e.g., financial systems, don't use them.  An easy alternative is `BigDecimal`.  Or you could just use `int` or `long`, then keep track of the decimal yourself, i.e., you do all the computations in cents instead of dollars.

## Prefer primitive types to boxed primitives

Primitives only have their values.  Boxed primitives have identities distinct from their values, meaning two boxed primitive instances could have the same value but different identities.

Primitives cannot be `null`.  Boxed primitives can be `null`.

When boxed primitives are compared using the `==` operator, they are evaluated on an _identity comparison_, meaning that two `Integer`s of value 1000 could evaluate to `false` when compared.
* Boxed values between -128 to 127 are cached, so this may work sometimes.
* **Applying the `==` operator to boxed primitives is almost always wrong.**

```java
final Integer x = 5;
final Integer y = 5;
System.out.println(x == y); // true, but only because of the caching for values between -128 to 127

final Integer a = 1000;
final Integer b = 1000;
System.out.println(a == b); // false
```

**When you mix primitives and boxed primitives in an operation, the boxed primitive is auto-unboxed**.  If a `null` object reference is auto-unboxed, you get a `NullPointerException`.

## Avoid strings where other types are more appropriate

**Strings are poor substitutes for other value types**.  This is violated most often from inputs that come in as `String` and then programmers don't translate them into a better and more appropriate type.

**Strings are poor substitutes for enum types**.

**Strings are poor substitutes for aggregate types**.  If an entity has multiple components, it is bad to represent it as a single string.

```java
// Avoid doing this
String compoundKey = className + "#" + i.next();
```

1. In order to access individual fields, you have to parse the string, which is slow, tedious, and error-prone.
2. You can't provide `equals`, `toString`, or `compareTo` methods.  You're forced to whatever `String` provides.

## Beware the performance of string concatenation

Use `StringBuilder` in place of a `String` when concatenating many strings together.

It's still okay to use the string concatenation operator `+` to combine a small number of strings.

## Refer to objects by their interfaces

If appropriate interface types exist, then parameters, return values, variables and fields should all be declared using interface types.

```java
// Do this
Set<Son> sonSet = new LinkedHashSet<>();

// Don't do this
LinkedHashSet<Son> sonSet = new LinkedHashSet<>();
```

If you do this, your program will be more flexible.

If the original implementation offered special functionality not required by the general contract of the interface, and your code relies upon that special functionality, then it is critical that a specific implementation of the interface is used.
* In this case, you should use the more specific type.

If no appropriate interface exists, it's entirely appropriate to use the class name.

In _class-based frameworks_, it is preferable to refer to types using the relevant _base class_, which is often abstract, rather than by its implementation class.  Many `java.io` classes such as `OutputStream` fall into this category.

Err to wards using the least specific class in the class hierarchy that provides the required fnuctionality if there is no appropriate interface.

## Prefer interfaces to reflection

`java.lang.reflect` is the core reflection facility.  You can get programmatic access to arbirtary classes.  With a refernece to a `Class` object, you can obtain `Constructor`, `Method`, and `Field` instances.
* You can modify the underlying counterparts of these instances reflectively:  you can construct instances, invoke methods, access fields, etc.

Reflection comes with its disadvantages:
* You lose all the benefits of compile-time type checking
* Code required to perform reflective is clumsy and verbose.  It's tedious to write and hard to read.
* Performance suffers

In general, it's best to use reflection in a limited form:  create instances reflectively, but access them normally using their `interface` or `superclass`.

## Use native methods judiciously

The Java Native Interface (JNI) allows you to call _native methods_. Native methods give you access to platform-specific facilities, e.g., registries, existing native libraries and allows you to call performance-critical code that was written in native languages.

Nowadays it's seldom necessary to use JNI since Java has added so many features that previously were only native.  There is a process API added in Java 9 that provides access to OS processes, for example.

JVMs are also much faster than they used to be.  It's rarely advisable to use JNI to speed up performance.

Native methods have serious disadvantages:
1. They are not memory safe.
2. They are less portable, since the native code must be compiled for the platform they run on.
3. They are harder to debug.
4. It's possible to write native code that is less performant because if you don't know what you're doing you could be making tons of mistakes.  The garbage collector can't automate or track native memory usage.  And there is a cost for the JVM to dip in-and-out of native code.
5. Native code often requires "glue code" that is a pain to write.

## Optimize judiciously

> Many computing sins are committed in the name of efficiency (withut necessarily achieving it) than for any other single reason - including blind stupidity.
> - William A. Wulf

> We _should_ forget about small efficiencies, say about 97% of the time: premature optimization is the root of all evil.
> - Donald E. Knuth

> We follow two rules in the matter of optimization:
>     Rule 1. Don't do it.
>     Rule 2. (for experts only).  Don't do it yet - that is, not until you ahve a perfectly clear and unoptimized solution.
> - M. A. Jackson


**Strive to write good programs rather than fast ones**.  If a good program is not fast enough, its architecture will allow it to be optimized.  Strive to avoid design decisions that limit performance.

Consider the performance consequences of your API design decisions, but it is a very bad idea to warp an API to achieve good performance.  Measure performance before and after each attempted optimization.

## Adhere to generally accepted naming conventions

The _Java Language Specifiction_ has a set of well-established _naming conventions_.
* You should rarely violate these conventions and never without a very good reason.

Typographical Conventions
* Package and module names should be hierarchical with components separated by period
* Components should cosist of lowercase alphabetic characters and rarely digits.
* If your code will be used outside your organization, it should begin with your organization's Internet domain name with the components reversed, e.g., `com.google`
    * The `java.*` libraries are the exceptions to this rule.
    * Don't create any packages that begin with `java` or `javax`
* Components should be short, generally <= 8 characters.  Meaningful abbreviations are encouraged, e.g., `util`.  Acronyms are acceptable.
* Class and interface names, including enum and annotation type names, should consist of one or more words, `PascalCase`.
    * Avoid abbrevations in these class/interface names, with the exception of common abbreviations like `max` or `min`.
    * There is disagreement on whether acronyms should be capitalized or if only the first letter of the acronym should be capitalized.
* Method and field names follow the same conventions as classes and interfaces, except that they are `camelCase`
    * The exception to using `camelCase` are for "constant fields" whose names should be `ALL_CAPS_SNAKE_CASE`.  These fields are static, final, and immutable.
    * Local variable names follow the same naming conventions as member names, but allow abbreviations, e.g., `i`, `denom`, `houseNum`, but special care should be given to parameter names.
* Type parameters names are a single letter:  `T` for an arbitrary type.  `E` for an element type of a collection.  `K` and `V` for key and value of some map. `X` for an exception.  `R` for a return type.  Sequences of arbitrary types can be `T`, `U`, `V`, or `T1`, `T2`, `T3`.

Grammatical Conventions
* Instantiable classes, including enum types, are generally named with a singular noun or noun phrase.
* Non-instantiable classes are named with a plural noun, such as `Collectors` or `Collections`.
* Interfaces are named like classes or with an adjective ending, e.g., `*-able`, or `*-ible`:  `Runnable`, `Iterable`, `Accessible`.
* Methods that perform some action are named with a verb or verb phrase, e.g., `append` or `drawImage`.
* Methods that return a `boolean` have names that begin with `is` or `has`, e.g., `isDigit`, `hasSiblings`.
* Methods that return a non-boolean have names that are a noun, a noun phprase, or a verb phrase beginning with `get` or `set`, e.g., `size`, `hashCode`, `getTime`.
* Methods that convert the type of an object or returning an independent object of a different type are called `to[Type]`, e.g., `toString` or `toArray`.
* Methods that return a _view_ with a type that differs from the receiving object are called `as[Type]`, e.g., `asList`.
* Methods that return a primitive with the saem value as the object on which they're invoked are called `[type]Value`, e.g., `intValue`.
* Static factories follow a set of similar and common names, e.g., `from`, `of`, `valueOf`, `instance`, `getInstance`, `newInstance`, `get[Type]`, `new[Type]`.

Java Beans specification is largely obsolete. Some modern tools continue to rely on the Beans naming convention though.
