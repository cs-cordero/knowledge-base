# Enums and Annotations

An _enumerated type_ is a type whose legal values consist of a finite and fixed set of constants.

## Use `enum`s instead of `int` constnats

`int` constants were used commonly before `enum`s were added to the language.

```java
// The int enum pattern -- DON'T DO THIS
public static final int APPLE_FUJI = 0;
public static final int APPLE_PIPPIN = 1;
public static final int APPLE_GRANNY_SMITH = 2;

public static final int ORANGE_NAVEL = 0;
public static final int ORANGE_TEMPLE = 1;
public static final int ORANGE_BLOOD = 2;
```

Another variant of this is the _String_ enum pattern, where instead of `int`s, you give each "enum" a string value.  This is worse.

Shortcomings of this pattern:
1. No type safety
1. Can compare apples to oranges
1. No namespaces, so you have to manage them yourself, the above uses `APPLE_` and `ORANGE_`.
1. Brittle because since they use the primitive `int`, the values are compiled directly into the clients that use them.
1. No easy way to implement a `toString`, meaning the debugger experience will be terrible.
1. The "String enum pattern" variant is worse because it encourages users/clients of your code to hard-code string constants into their code instead of using field names.  It also relies on string comparisons which means it _may_ affect performance.


Java provides `enum`s which are much better:

```java
public enum Apple { FUJI, PIPPIN, GRANNY_SMITH }
public enum Orange { NAVEL, TEMPLE, BLOOD }
```

Java's enum types are full-fledged classes, which makes them pretty powerful compared to enums in other languages where they are essentially `int` values.
* They are classes which export one instance for each member via a `public static final` field.
* Enum types are effectively final since they have no accessible constructors.  They are therefore instance-controlled.
* Enums are a generalization of singletons, which are essentially single-element enums.
* Enums provide their own namespace, so you can have two members called `MERCURY` across an enum defined for `Planet` and another for `Element`.
* Constant values are not compiled into clients so you can reorder the members in source however you wish.
* Enums have a `toString` so you can print them.
* Since they're full-fledged classes, you may define methods and fields and implement arbitrary interfaces.
    * They come with implementations of the `Object` methods, `Comparable`, and `Serializable`.

```java
// Fat enums (enums with data and behavior)
public enum Planet {
    MERCURY(3.302e+23, 2.439e6),
    VENUS  (4.869e+24, 6.052e6),
    EARTH  (5.975e+24, 6.378e6),
    MARS   (6.419e+23, 3.393e6),
    JUPITER(1.899e+27, 7.149e7),
    SATURN (5.685e+26, 6.027e7),
    URANUS (8.683e+25, 2.556e7),
    NEPTUNE(1.024e+26, 2.477e7);

    private final double mass;           // kg
    private final double radius;         // m
    private final double surfaceGravity; // m / s^2

    // Universal gravitational constant in m^3 / kg s^2
    private staitc final double G = 6.67300E-11;

    Planet(double mass, double radius) {
        this.mass = mass;
        this.radius = radius;
        surfaceGravity  G * mass / (radius * radius);
    }

    public double mass() { return mass; }
    public double radius() { return radius; }
    public double surfaceGravity() { return surfaceGravity; }

    public double surfaceWeight(double mass) {
        return mass * surfaceGravity;  // F = ma
    }
}
```

When writing an enum like this:
* All fields should be `final`.
* Fields may be `public`, but it's better to make them `private` and expose them via getters.

**When you remove an enum member**, any client program that doesn't refer to the removed element will continue to work just fine.  If a client does reference the removed element, then it will need to be recompiled.  If it doesn't, then it'll get a helpful exception at runtime.
* Exceptions at runtime suck, but this is the best you can get, and better than `int` enums.

**If an enum is generally useful, it should be a top-level class**.

**If an enum's use is tied to another top-level class, it should be a member class of that top-level class**.

Enums with varying behavior per member:

```java
// This works but it isn't pretty
public enum Operation {
    PLUS,
    MINUS,
    TIMES,
    DIVIDE;

    public double apply(double x, double y) {
        switch(this) {
            case PLUS: return x + y;
            case MINUS: return x - y;
            case TIMES: return x * y;
            case DIVIDE: return x / y;
        }
    }
}
```

Do this instead:

```java
public enum Operation {
    PLUS {
        public double apply(double x, double y) { return x + y; }
    },
    MINUS {
        public double apply(double x, double y) { return x - y; }
    },
    TIMES {
        public double apply(double x, double y) { return x * y; }
    },
    DIVIDE {
        public double apply(double x, double y) { return x / y; }
    };

    public abstract double apply(double x, double y); // enforces its definition on every new member
}
```

Enum types come with a generated `valueOf(String)` method.  You should consider overriding `toString`, and if you do, provide a `fromString` (or similar static method) that helps you go from a string value to a enum member.


```java
private static final Map<String, Operation> stringToEnum = ...

public static Optional<Operation> fromString(String symbol) {
    return Optional.ofNullable(stringToEnum.get(symbol));
}
```

`switch` statements for `enum`s come in handy when you _don't_ control the enum.  As a result, wen you want to augment behavior for an `enum` without that control, it's best to use a `switch` statement there.  And only if the behavior you want is specific to each enum member.
* If you own the enum, it can also be acceptable to use `switch` if the method is not generally useful enough to warrant inclusion in the enum type.

**Use enums when you need a set of constants whose members are known at compile time**.  It is not necessary that the set of constants in an enum type stay fixed for all time.

## Use instance fields instead of ordinals

An ordinal is a call to `Enum.ordinal` which returns the numerical position of each enum emmeber in the type.  Don't use it.

```java
public enum Ensemble {
    SOLO, DUET, TRIO, QUARTET, QUINTET,
    SEXTET, SEPTET, OCTET, NONET, DECTET;

    public int numberOfMusicians() { return ordinal() + 1; }
}
```

If you need a value associated with an enum member's ordinal, store it in an instance field instead.

```java
public enum Ensemble {
    SOLO(1), DUET(2), TRIO(3), QUARTET(4), QUINTET(5),
    SEXTET(6), SEPTET(7), OCTET(8), NONET(9), DECTET(10);

    private final int numberOfMusicians;
    Ensemble(int size) { this.numberOfMusicians = size }
    public int numberOfMusicians() { return numberOfMusicians; }
}
```

It's best to avoid `Enum.ordinal` entirely.

## Use `EnumSet` instead of bit fields

If elements of an enumerated type are used to be combined with each other, there are some patterns where you use the `int` enum pattern to assign different powers of 2, then use bitwise methods to combine them.

```java
// DON'T DO THIS
public class Text {
    public static final int STYLE_BOLD      = 1 << 0;
    public static final int STYLE_ITALIC    = 1 << 1;
    public static final int STYLE_UNDERLINE = 1 << 2;

    public void applyStyles(int styles) { ... }
}

// usage
text.applyStyles(STYLE_BOLD | STYLE_ITALIC);
```

Never do this.  They created `java.util.EnumSet` specifically for this use case.  It implements the `Set` interface, so you get type safety, and as long as the enum type has less than 64 members, the entire `EnumSet`is represented with a single `long`, so its performance is comparable to the `int` enum above.
* It's still implemented under the hood with bit vectors but you are protected from having to deal with that directly.

```
// This is better
public class Text {
    public enum Style { BOLD, ITALIC, UNDERLINE, STRIKETHROUGH }
    public void applyStyles(Set<Style> styles) { ... }
}

// usage
text.applyStyles(EnumSet.of(Style.BOLD, Style.ITALIC));
```

## Use `EnumMap` instead of ordinal indexing

There is a very fast `Map` implementation designed for use with enum keys: `java.util.EnumMap`.

```java
class Plant {
    enum LifeCycle { ANNUAL, PERENNIAL, BIENNIAL }
    ...
}

Map<Plant.LifeCycle, Set<Plant>> plantsByLifeCycle = new EnumMap<>(Plant.LifeCycle.class);
for (Plant.LifeCycle lc : Plant.LifeCycle.values()) {
    plantsByLifeCycle.put(lc, new HashSet<>());
}
for (Plant p : garden) {
    plantsByLifeCycle.get(p.lifeCycle).add(p);
}
```

Using an `EnumMap` is clearer, safer and just as fast as a version that uses `ordinal` for indexing.  It also avoids unsafe casts.

Alternatively, you can use a `Stream`:

```java
// unlikely to produce an EnumMap
Arrays.stream(garden).collect(groupingBy(p -> p.lifeCycle));

// can make sure it produces an EnumMap
Arrays.stream(garden).collect(groupingBy(p -> p.lifeCycle, () -> new EnumMap<>(LifeCycle.class), toSet()));
```

It is never appropriate to use ordinals to index into arrays.  Always use `EnumMap` instead.

## Emulate extensible enums with interfaces

Sometimes you want your enum types to be _extensible_, meaning clients can `extend` it with new members.  For example, if you had an enum for `OpCode`s, but you want to allow clients to define their own operations, _that_ would count as being extensible.

But enum types need to be defined at compile time.  Luckily there's a trick, since enum types can implement arbitrary interfaces:

```java
public interface Operation {
    double apply(double x, double y);
}

public enum BasicOperation implements Operation {
    PLUS("+") {
        public double apply(double x, double y) { return x + y; }
    },
    MINUS("-") {
        public double apply(double x, double y) { return x - y; }
    },
    TIMES("*") {
        public double apply(double x, double y) { return x * y; }
    },
    DIVIDE("/") {
        public double apply(double x, double y) { return x / y; }
    };

    private final String symbol;

    BasicOperation(String symbol) {
        this.symbol = symbol;
    }

    @Override
    public String toString() {
        return symbol;
    }
}

// Clients can extend Operation themselves like this:
public enum ExtendedOperation implements Operation {
    EXP("^") {
        public double apply(double x, double y) { return Math.pow(x, y); }
    },
    REMAINDER("%") {
        public double apply(double x, double y) { return x % y; }
    };

    ...
}
```

While you cannot write an extensible enum type, you can emulate it by writing an interface to accompany a basic enum type that implements the interface.


## Prefer annotations to naming patterns

It was common to use naming patterns to indicate that something demanded special treatment by a tool or framework.
* For example, JUnit 3 and older used to require its clients to designate test methods by beginning their names with `test`.

Drawbacks:
1. Typographical errors result in silent failures
2. There is no way to have something that happens to follow the pattern but opt out of the framework behavior.  And no way to ensure it.
3. They don't provide you a way to associate parameter values with program elements.

Here's how to define your own annotation:

```java
import java.lang.annotation.*;

/**
 * Indicates that the annotated method is a test method.
 * Use only on parameterless static methods.
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Test {}
```

* The docstring indicates that the annotation should only be used on parameterless static methods.  If you want to enforce that, you'd have to write an annotation processor to do so.  Otherwise, misuse of it will still allow the program to compile.
* Annotations do not have a direct effect on the semantics of classes that use them.  They serve only to provide information for use by interested programs.
* Tools can use `isAnnotationPresent` to identify if a method has the annotation or not.


You can also have your annotation take arguments/parameters:

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface ExceptionTest {
    Class<? extends Exception>[] value();  // first, accepts an array argument

    Class<? extends Exception> value();    // alternatively, accepts a single argument
}

// example usage for the first one
@ExceptionTest({ FooException.class, BarException.class }) 
public static void ...

// example usage for the alternative one
@ExceptionTest(FooException.class) 
public static void ...
```

There is no reason to use aming patterns when you can use annotations instead.

**All programmers should use the predefined annotation types that Java provides**.  Most programmers will have no need to define annotation types.

## Consistently use the `Override` annotation

The `@Override` annotation is the most important annotation for the typical programmer.  It indicates that the annotated method overrides a declaration in a supertype.

Consistent usage of this annotation will save you from a class of bugs.

For example:

```java
class Foo {
    public boolean equals(Foo foo) { ... }
}
```

You would think this overrides `equals`, but it actually only gives an overload of equals, not an override.  Why?  Because the supertype's version of `equals` takes an argument of type `Object`, not of type `Foo`.

If you had annotated this with `@Override`, typically your IDE should tell you that this one isn't actually overriding anything.

**You should use the `Override` annotation on every method declaration that you believe to override a superclass declaration.**

## Use marker interfaces to define types

A _marker interface_ is an interface that contains no method declarations but merely designates a class that implements the interface as having some property/holding some invariant.  The canonical example of this is `Serializable`.

Marker interfaces have two advantages over marker annotations:
1. Marker interfaces define a type that is implemented by instances of the marked class; marker annotations do not.
1. Marker interfaces can be targeted more precisely than marker annotations.

Marker interfaces can be used for compile-time type-checking.

You can also define a marker interface to only apply to implementations of a particular interface, which gives you some guarantees over what is available to you when you are operating on that interface.
* The `Set` interface is somewhat of an example of this.  It is applicable only to `Collection` subtypes.  It does refine the contracts of several methods but it's easy to imagine a true marker interface that doesn't

**The chief advantage of marker annotations over marker interfaces is that they are part of the larger annotation facility.**
* You can use it on things beyond classes and interfaces.
* You should err towards using interfaces if you intend to write a method that accepts only objects that have the marker.

