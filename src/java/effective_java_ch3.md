# Methods Common to All Objects

Each of `Object`'s nonfinal methods have a _general contract_ that should be upheld since they are meant to be overridden.  These nonfinal methods include::
* `equals`
* `hashCode`
* `toString`
* `clone`
* `finalize` (but you shouldn't even use this one. avoid finalizers and cleaners.)

## Obey the general contract when overriding `equals`

First, don't even override `equals` if any of the following apply:
1. Each instance of the class is inherently unique (like an enum)
1. There is no need for the class to provide a "logical equality" test.  For example, two differnet instances of a `Point` object that have the same `x` and `y` value would be "logically equal".
1. A superclass has already overriden equals and the superclass behavior is appropriate for your subclass.
1. The class is `private` or `package-private`, and you are certain that its `equals` method will never be invoked.

Override `equals` if the following applies:
1. The class _does_ have a notion of _logical equality_ that differs from object identity.  This is generally true for _value classes_.
1. The superclass doesn't already override `equals`.
1. The class (value class or not) does NOT use _instance control_ to ensure that at most one object exists with each value, e.g., enum types.  For these classes, logical identity is the same as object identity.

The `equals` method has a general contract:
* _Reflexive_.  `x.equals(x)` must be true.
* _Symmetric_.  if `x.equals(y)` if and only if `y.equals(x)` (if y and x are both non-null).
* _Transitive_.  if `x.equals(y)` and `y.equals(z)`, then `x.equals(z)` must be true.
* _Consistent_.  calling `x.equals(y)` multiple times will always return the same answer.
* _Non-nullity_.  if x is non-null, then `x.equals(null)` must be false.

**If you violate the `equals` contract, you simply don't know how other objects will behave when confronted with your object**.

A lot of trouble occurs across classes.  Take for example the `String` class, and another class we define, `CaseInsensitiveString` for which we implement `equals` and which isn't a subclass of `String`.

```java
// An example of breaking the Symmetry requirement

public final class CaseInsensitiveString {
    ...
    @Override
    public boolean equals(Object o) {
        if (o instanceof CaseInsensitiveString) {
            return s.equalsIgnoreCase(((CaseInsensitiveString) o).s);
        } else if (o instanceof String) {
            return s.equalsIgnoreCase((String) o);
        }
        return false;
    }
}

CaseInsensitiveString cis = new CaseInsensitiveString("Polish");
String s = "polish";

cis.equals(s) // true
s.equals(cis) // false -- not symmetric!
```

A lot of trouble occurs across inheritance.  **There is no way to extend an instantiable class and add a value component while preserving the `equals` contract**.  Take for example a `Point` class and a `ColorPoint` subclass.

```java
// An example of breaking the Transitivity requirement

public class Point {
    private final int x;
    private final int y;
    ...
    @Override
    public booelan equals(Object o) {
        if (!(o instanceof Point)) {
            return false;
        }
        Point p = (Point) o;
        return p.x == x && p.y == y;
    }
}

public class ColorPoint extends Point {
    private final Color color;

    @Override
    public boolean equals(Object o) {
        if (!(o instanceof Point)) {
            return false;
        }

        // If o is a normal Point do a color-blind comparison
        if (!(o instanceof ColorPoint)) {
            return o.equals(this);
        }

        // Assume o is a ColorPoint, do a fll comparison
        return super.equals(o) && ((ColorPoint) o).color == color;
    }
}

ColorPoint p1 = new ColorPoint(1, 2, Color.RED);
Point p2 = new Point(1, 2);
ColorPoint p3 = new ColorPoint(1, 2, Color.BLUE);

p1.equals(p2); // true
p2.equals(p3); // true
p1.equals(p3); // false  -- not transitive!
```

You could use `Object.getClass` in the `equals` evaluation to only allow a potential equality if the classes are _exactly_ the same, ignoring the inheritance structure, but this violates the `Liskov substitution principle`.

Any instance of a subclass of `Point` is also a `Point`!  This implementation breaks that behavior.

```java
// Example which violates the Liskov substitution principle

@Override
public boolean equals(Object o) {
    if (o == null || o.getClass() != getClass()) {
        return false;
    }
    Point p = (Point) o;
    return p.x == x && p.y == y;
}
```

Instead of inheritance, **favor composition over inheritance**.  Instead of having `ColorPoint` extend `Point`, give `ColorPoint` a private `Point` field and a public `view` method that returns the point at the same position as this color point.

```java
// Composition over Inheritance

public class ColorPoint {
    private final Point point;
    private final Color color;

    public Point asPoint() {
        return point;
    }

    @Override
    public boolean equals(Object o) {
        if (!(o instanceof ColorPoint)) {
            return false;
        }
        ColorPoint cp = (ColorPoint) o;
        return cp.point.equals(point) && cp.color.equals(color);
    }
}
```

**Do not write an `equals` method that relies on unreliable resources.**  `Equals` methods should only perform deterministic computations on memory-resident objects.

The last requirement, _Non-nullity_, imposes that objects should never equal `null`, which doesn't seem hard to miss, but what many people mistake is that `o.equals(null)` should also NOT throw a `NullPointerException`.

### The process for writing a high-quality `equals` implementation:

**Always override `hashCode` when you override `equals`.**
**Don't try to be too clever**
**Don't substitute another type for `Object` in the `equals` declaration.**
**Do consider using frameworks that automatically implement `equals` for you.  One example is Google's `AutoValue` framework**.

1. Use the `==` operator to check if the argument is a reference to `this` object.  Return true if it is.  This is a performance optimization.
1. Use the `instanceof` operator to check if the argument is the correct type.  This also handles the issue of if the argument is `null`, because the `instanceof` always returns false if its left-hand side is `null`.
1. Cast the argument to the correct type.
1. For each "significant" field in the class, check if that field of the argument matches the corresponding field of `this` object.
    * For primitive fields, use the `==` operator.
    * For object reference fields, call the `equals` method recursively.
    * For `float` and `double` fields, call `Float.compare` or `Double.compare` respective
    * For array fields, apply the above on an element-by-element basis.  You could also use `Arrays.equals`
    * For fields that may legitimately contain `null`, avoid NPEs by using `Object.equals`.
1. When finished, do a final check: is it symmetric, transitive, and consistent?


## Always override `hashCode` when you override `equals`

If you forget to do so, you will violate the general contract for `hashCode`, which will make your class not work for collections like `HashMap` and `HashSet`.

The `hashCode` contract:
* **Consistency**.  `hashCode` must consistently return the same value provided no information used in `equals` comparisons is modified.
* **Equivalence**.  If `x.equals(y)`, then `x.hashCode() == y.hashCode()`
* **Non-equivalence**.  If `!x.equals(y)`, it is not necessary for `x.hashCode() != y.hashCode()`, but if it were, it would improve the performance of hash tables.

Forgetting to override `hashCode` violates the equivalence part of the contract.  Two objects may be logically equal, but their hashcodes won't be equal.

A good hash function tends to produce unequal hash codes for unequal instances. Ideally, the function should distributre any reasonable collection of unequal instances uniformly across all `int` values.

### The process for writing a high-quality `hashCode` implementation

1. Declare an `int` variable named `result`, initialized to the hash code `c` for the first significant field in your object.
1. For every remaining significant field `f` in your object, excluding _derived fields_ and fields not used in the `equals` comparison:
    1. Compute an `int` hash code `c` for `f`:
        * If the field is primitive, compute `Type.hashCode(f)`, where `Type` is the boxed primitive of `f`.
        * If the field is an object reference, recursively invoke `hashCode` on the field.  If a more complex comparison is required, compute a "canonical representation" for the field and invoke `hashCode` on the canonical representation.  If the field is `null`, use `0`.
        * If the field is an array, treat it as if each significant element were a separate field.  Compute a hash code for each significant element by applying the above rules recursively, and combine using the following step. If the array has no significant elements, use a constant, preferably not 0.  If all elements are significant, use `Arrays.hashCode`.
    1. Combine the hash code `c` computed in the previous step into the result as follows: `result = 31 * result + c`
1. Return `result`
1. Confirm that equal objects have equal hash codes.

Multiplying by `31` above is chosen because it is an odd prime.  For objects like String anagrams, it avoids having identical hash codes.


It's possible to write a one-line hashCode method using `Objects.hash`, but the performance is mediocre.  Only use it if you're not in a performance-constrained environment.

```java
@Override public int hashCode() {
    return Objects.hash(lineNum, prefix, areaCode);
}
```

When a class is immutable, you may consider caching the hash code in the object instead of calculating it each time.  If calculating the hash code is expensive, you may want to _lazily initialize_ it.  Lazy initialization has some pitfalls surrounding thread-safety though.

**Do not be tempted to exclude significant fields from the hash code computation to improve performance.**

**Do not provide a detailed specification for the value returned by `hashCode` for your objects.  Clients may end up depending on the value.  Not providing this spec allows you the flexibility to change it in the future.**  Some Java classes like `String` and `Integer` specified the hash code which prevents language authors from changing it in the future.  This was deemed to be a mistake that should not be repeated.


## Always override `toString`

The exceptions to having to _always_ override `toString` are:
* static utility classes
* enum types

Abstract classes are _not_ an exception, i.e., you should override the `toString`.

The contract of `toString`:

> A concise but informative representation that is easy for a person to read.  It is recommended that all subclasses override this method.

By default it looks like the classname followed by its hash code, i.e., `PhoneNumer@163b91`.

Providing a good `toString` implemenation makes your class much more pleasant to use and makes systems using the class easier to debug.  Even if you never call `toString` on an object, others may.

**When practical, the `toString` method should return _all_ of the interesting information on the object**.  When impractical, i.e., it has a large amount of state not conducive to strin grepresentation, `toString` should return a summary, i.e., `Manhattan residential phone directory (1487536 listings)` or `Thread[main, 5, main]`.

For _value classes_, it is recommended that you document a specification for the format of your `toString` return value.  Otherwise, it's up to you.  Advantages are that clients can rely on the value and can translate it to/from the string representation.  Disadvantages are that you're stuck with it for life.
    * **Whether you decide to specify the format or not, you should clearly document your intentions.**

Any value/information contained in the string representation **should be programmatically accessible**.  For example, if the `toString` for a `PhoneNumber` class returns "XXX-YYY-ZZZZ", there should be getters for area code, prefix, and number.
* If you don't, the string format becomes a de facto API (it contains information not accessible otherwise).

## Override `clone` judiciously

Be careful when overriding `clone`.

### You are often better off providing an alternative means of copying (avoiding `clone` and `Cloneable`)

You can provide a _copy constructor_ or a _copy factory_.

```java
// A Copy constructor
public MyClass(MyClass foo) { ... }

// A Copy factory
public static MyClass newInstance(MyClass foo) { ... }
```

Given all the problems associated with `Cloneable`, new interfaces should not extend it and new classes should not implement it.

The exception to this rule are arrays.  They are best copied with the `clone` method.

### If you must implement `Cloneable` and `clone`...

`Cloneable` is an interface intended to be used as a mixin interface.
* It's an interface that doesn't define any methods.
* The `clone` method is actually already defined as a `protected` method on `Object`.
* Classes that override the `Object.clone` method but _don't_ implement `Cloneable` will throw a `CloneNotSupportedException`.
* Similarly, classes that override `Cloneable` but _don't_ override `Object.clone` will also throw a `CloneNotSupportedException`.
* This is a weird setup for Java and should not be emulated in user-defined interfaces.


`clone` methods are expected to follow a complex, unenforceable, thinly documented protocol, which results in a fragile, dangerous, and _extralinguistic_ mechanism, since it creates objects without calling a constructor.

The `clone` contract:
* Creates and returns a copy of the object.  "Copy" meaning depends on the class of the object, but _usually_ (but not always) means:
    * `x.clone() != x`
    * `x.clone().getClass() == x.getClass()`
    * `x.clone().equals(x)`
    * By convention, the object returned should be obtained by calling `super.clone`.
    * By convention, the object returned should be independent of the object being cloned.

If a class's `clone` method returns an instance that is _not_ obtained by calling `super.clone`, but by calling a constructor, the compiler won't complain.  But if a subclass of that class calls `super.clone`, then the resulting object will have the wrong class.

If a class that overrides `clone` is `final`, then this convention may be ignored.  But if it doesn't use `super.clone`, then it might as well not implement `Cloneable`, since it doesn't follow the contract.

**Immutable classes should never provide a clone method**, it encourages wasteful copying.

**The `clone` method functions as a constructor: you must ensure that it does no harm to the original object and that it properly establishes invariants on the clone.**

**A `clone` method should never invoke an overridable method on the clone under construction.**

Process for writing a well-functioning `clone` method.
1. Update the class to implement `Cloneable`.
1. Make the return type of `clone` something more specific than `Object` (a covariant return type)
1. Wrap the function body in a `try-catch` block, because `clone` has a checked exception for `CloneNotSupportedException`.  But don't declare your method to _also_ throw `CloneNotSupportedException`.
1. First, always call `super.clone` and cast it to the class you want.
1. If the class fields are entirely primitives, then you're done!
1. If the class contains some mutable object reference fields, you may need to clone those objects as well.
    * Arrays for example may need to clone each of its elements.
1. If the class contains some `final` object reference fields that need to be changed, you're kind of screwed.   **the `Cloneable` architecture is incompatible with normal use of final fields referring to object objects, except in cases where the objects may be safely shared between an object and its clone.**
    * It may be necessary to remove `final` modifiers from some fields to make the class cloneable.

## Consider implementing `Comparable`

Unlike `Cloneable`, `Comparable` does bring with it a method: `compareTo`, which is _not_ defined on `Object`.

`Comparable` implies that an object has a natural ordering.

Why implement `Comparable`?
* The object immediately becomes sortable.
* The object can interoperate with many generic algorithms that rely on the `Comparable` interface.

The general contract of `compareTo`:
* Throw a `ClassCastException` if the given object's type prevents it from being compared to this object.
* Return a negative integer, zero, or a positive integer if this object is less than, equal to, or greater than the given object.
* **Symmetric**. `signum(x.compareTo(y)) == -signum(y.compareto(x))`
* **Transitive**.  `x.compareTo(y) > 0 && y.compareTo(z) > 0` implies `x.compareTo(z) > 0`
* `x.compareTo(y) == 0` implies `x.compareTo(z) == 0` and `y.compareTo(z) == 0` for all `z`.
* It is strongly recommended that `x.compareTo(y) == 0` implies `x.equals(y) == true`

It is **not** possible to extend an instantiable class with a new value component while preserving the `compareTo` contract, unless you are willing to forgo the benefits of OOP.
* The solution is similar to the `equals` contract: use `composition` instead of `inheritance`.

When writing a `compareTo` method on a class that has object references, be sure to call `compareTo` recursively for those object references.

When writing a `compareTo` method on a class with primitive fields, used the boxed method `compare`, e.g., `Double.compare` to perform the comparison.

If a field does not implement `Comparable` or you need a nonstandard ordering, using a `Comparator` instead.

Java 8 comes with a set of _comparator construction methods_ that can be statically imported, i.e.:

```java
private static final Comparator<PhoneNumber> COMPARATOR =
    comparingInt((PhoneNumber pn) -> pn.areaCode)
        .thenComparingInt(pn -> pn.prefix)
        .thenComparingInt(pn -> pn.lineNum);

public int compareto(PhoneNumber pn) {
    return COMPARATOR.compare(this, pn);
}
```

DO NOT use the _difference_ between two values for the comparison.

```java
// DON'T DO THIS
static Comparator<Object> hashCodeOrder = new Comparator<>() {
    public int compare(Object o1, Object o2) {
        return o1.hashCode() - o2.hashCode();
    }
}
```

This has non-deterministic due to integer overflow and if the values are floating point, then IEEE 754 can mess things up.  Use a static `compare` method or a comparator construction method instead.

```java
// These are better than the above
static Comparator<Object> hashCodeOrder = new Comparator<>() {
    public int compare(Object o1, Object o2) {
        return Integer.compare(o1.hashCode(), o2.hashCode());
    }
}


static Comparator<Object> hashCodeOrder = Comparator.comparingInt(o -> o.hashCode());
```
