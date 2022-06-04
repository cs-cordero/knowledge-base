# Concepts

## Covariant return typing
When a subtype implementation overrides a method to return a subtype of the extending type.  For example, the builder on the abstract `Pizza` class returns a `Pizza` on its `build` method.  The implementing `NyPizza` concrete class overrides this method but returns a `NyPizza` class, which is a subtype of `Pizza`.

```java
public abstract class Pizza {
    abstract static class Builder<T extends Builder<T>> {
        abstract Pizza build(); // build is supposed to return a type Pizza
        ...
    }
    ...
}

public class Calzone extends Pizza {
    public static class Builder extends Pizza.Builder<Builder> {
        @Override
        public Calzone build() { ... }  // build is overridden to return a type Calzone, which is a covariant return type of Pizza
    }
}
```

## Generic type with recursive type parameter
A workaround for the fact that Java lacks a "self" type.  This is also known as the "simulated self-type" idiom.  It looks like this: `class Builder<T extends Builder<T>>`.

When do you need this? Take this as an example:

```java
public abstract class Pizza {
    abstract static class Builder {
        public [SELF] addTopping(Topping topping) { ... }
    }
}
```

In the above, we want the `addTopping` to return a generic type of `Self`, aka a type of the same type as a concrete `Builder` that we aren't defining here.  Java doesn't support a `Self` syntax, so instead you have to use a _recursive type parameter_, like so:

```java
public abstract class Pizza {
    abstract static class Builder<T extends Builder<T>> {
        public T addTopping(Topping topping) { ... }
    }
}
```

## Telescoping constructor pattern
An anti-pattern in which you provide a constructor with only the required parameters, a second with a single optional parameter, a third with a second optional parameter, and so on until you have a constructor with all optional parameters.

## JavaBean
A class definition that follows the [JavaBean standard](http://www.oracle.com/technetwork/java/javase/documentation/spec-136004.html).  Essentially:
1. The class should set all of its properties to be `private` and only accessible via `getters/setters`.
1. The class should have a public **no-argument** constructor.  This means that properties will either get a default value or, more likely, set to null.
1. The class should implement `Serializable`.

## Primitives
`java.lang` defines 8 primitive types that have their own reserved keywords:
1. `byte`. 8-bit signed two's complement integer.
1. `short`. 16-bit signed two's complement integer.
1. `int`. 32-bit signed two's complement integer.  Java 8 allows you to represent unsigned integers.
1. `long`.  64-bit two's complement integer.  Java 8 allows you to represent unsigned integers.
1. `float`. 32-bit IEEE 754 floating point number.
1. `double`. 64-bit IEEE 754 floating point number.
1. `boolean`. Represents true or false, but its actual "size" isn't precisely defined.
1. `char`. A single 16-bit Unicode "character".

## Objects
Distinct from primitives.  They must define regions of memory that consist of (1) state and (2) behavior.  Objects store their state in _fields_ (aka variables) and their behavior through _methods_ (aka functions).
    * In Java, all objects are heap-allocated.  Unlike Rust, there is no way to specify a stack-allocated object.
    * In contrast, a locally defined primitive value is generally held on a stack, unless it is owned by an object, in which case it is of course colocated with the object on the heap.

## Boxed Primitives
Object-versions of primitive data types, i.e., `Integer` is the boxed version of `int`.  They hold a value of that primitive data type.  Why does Java have boxed primitives?  You can get all the benefits of using objects:  integer variables can have methods and can be passed to functions/classes that accept objects.  For example, `List` cannot contain any `int` or primitive data types, they must be boxed.
* Boxed primitives are stored on the heap.
* Unless you need the features, **you should prefer primitives over boxed**.  Doing so avoids unnecessary heap allocations and garbage cleanup.
* Java has a feature since Java 5 called **Autoboxing** and **Unboxing** which handles the automatic type conversion to/from primitives to their boxed primitive equivalents.

## Value Class

A value class is a class that represents a value, such as an `Integer` or a `String`.  They can get more complex, like `Point`, which has an `x` and `y` (or more) coordinates.

When programmers use value classes and compare two instances, they typically don't think of the class as being inherently unique.  Two different instances of `Point(5, 3)` and `Point(5, 3)` are expected to be "equal" even though they aren't the exact same object in memory.

## Instance-controlled Classes

A class is said to be _instance-controlled_ if the class maintains strict control over what instances exist at any time. In general, these kinds of classes include:

1. Enum types (there is only ever one instance of each member)
1. Singletons
1. Noninstantiables.  Typically instance controlled classes have a private constructor and then static methods for when programmers want to get an instance of the class.  The class itself will decide how an instance is returned, and oftentimes may reuse the object.
1. Immutables.  When an immutable value class is instance-controlled, it can guarantee that equality is the same as logical equally and the same as object identity.

## Constructor Chaining

A given class may have one or more constructors.  Calling a constructor from within another constructor is called "constructor chaining".  This is performed _within_ a class (between its multiple constructors) by using `this(...)`.  This can also be performed by a subclass calling a constructor of its superclass by using `super(...)`.

## Default Access

When no visibility modifier is set on a member or top-level class or top-level interface, the default access is `package-private`, which means it is accessible from any class within the same package.  As an exception, interface members are `public` by default.

## Binary Compatibility

See [Stack Overflow](https://stackoverflow.com/questions/14973380/what-is-binary-compatibility-in-java#14973523)

> Binary compatibility means that when you change you rclass, you do not need to recompile classes that use it.  For example, you removed or renamed a public or protected method from your `log-1.jar` library and released a new version as `log-2.jar`.  When users of your `log-1.jar` download the new version, it will break their apps when they try to use the missing methods.
