# Classes and Interfaces

## Minimize the accessibility of classes and members

**Make each class or member as inaccessible as possible**.  The accessibility of an entity is determined by the location of its declaration and by which, if any, of the access modifiers (`public`, `protected`, `private`) is present on the declaration.

Top-level classes and interfaces are either `package-private` or `public`.  Without any modifier specified, it's `package-private` by default.
* If the class is used by only one class, consider making the class a private static nested class of the sole class that uses it.

Members (fields, methods, nested classes, nested interfaces) there are four possible access levels:
* `private`.  Member is accessible only from the top-level class where it is declared.
* `package-private`.  Member is accessible from any class in the package where it is declared.  This is also known as _default access_.
* `protected`.  Member is accessible from subclasses of the class where it is declared and from any class in the package where it is defined.
* `public`. Accessible from anywhere.

Both `private` and `package-private` members are part of a class's implementation, and do not normally impact its exported API.  However, if the class implements `Serializable`, these fields may "leak" into the exported API.

The difference between `package-private` and `protected` is huge.  Once a member is `protected`, it is now part of the public API.  It also represents a public commitment to an implementation detail.

**If a method overrides a superclass method, it cannot have a _more_ restrictive access level in the subclass than in the superclass**.  Otherwise, it would break the _Liskov substitution principle_.

If a class implements an interface, all of the class methods that are in the interface must be declared `public` in the class.

> **Note about testing**
>
> It is OK to relax accessibility modifiers from `private` to `pakage-private` in order to test it.  It is NOT ok to raise it any higher (or even allow `protected` to become `public`).
> 
> Tests can be made to run _as part of the package being tested_, thus gaining access to its `package-private` elements, so raising accessibility above this is not necessary.

**Instance fields of public classes should rarely be public**.  If the field is nonfinal or a reference to a mutable object, then making the field public limits your ability to limit the values that can be stored in the field.
* You also give up the ability to enforce invariants and take action when the field is modified, meaning that **classes with public mutable fields are generally not thread-safe**.
* Even if the field is final and its referent is immutable, you give up the ability to change the internal data representation.
* You _may_ expose constants via static final fields, but it is critical that these fields contain either primitives or references to immutable objects.  Note that nonzero-length arrays are ALWAYS mutable, so it is **wrong for a class to have a public static final array field or an accessor that returns such a field**.

```java
// Never do this!!
public static final Thing[] VALUES = { ... };
```

> **Notes about Java 9's Module System
>
> There are two more additional implicit access levels introduced as part of the module system provided by Java 9.  If a package is a grouping of classes, a module is a grouping of packages.  Modules decide what packages within its group is exported via a _module declaration_ (by convention this is a source file named `module-info.java`)
>
> If a module does not expose a package within its group, even `public` fields are inaccessible outside the module.  Within the module, accessibility is unaffected by export declarations.
>
> Its not advisable to rely on this implicit system.  If you place a module's JAR file on the classpath instead of its module path, the packages in the module revert to their non-modular behavior.
>
> In order to take advantage of modules, it requires pre-Java 9 projects to create groupings, set module declarations, rearrange the source tree, and take additional actions to make sure non-modularized packages don't get access.  It is best to avoid modules unless you have a compelling need.

## In public classes, use accessor methods, not public fields

Example of what _not_ to do:

```java
// Don't do this!
class Point {
    public double x;
    public double y;
}
```

These classes do not offer the benefits of _encapsulation_.  You can't:
* Change the representation without changing the API
* Enforce invariants
* Take auxiliary action when a field is accessed

OOP-folks think these classes should be replaced with private fields and public _accessor methods_ (getters), and for mutable fields, public _mutators_ (setters).

```java
class Point {
    private double x;
    private double y;

    public Point(double x, double y) {
        this.x = x;
        this.y = y;
    }

    public double getX() { return x; }
    public double getY() { return y; }
    public void setX(double x) { this.x = x; }
    public void setY(double y) { this.y = y; }
}
```

These OOP folks are correct when it comes to `public` classes.  However, **if a class is package-private or is a private nested class, there is nothing inherently wrong with exposing its data fields**.

It is less harmful, but still questionable, for public classes to expose _immutable_ fields.

## Minimize mutability

An immutable classes is a class whose instances cannot be modified.  All the information contained in each instance is fixed for the lifetime of the object.

Five rules to making classes immutable:
1. Don't provide methods that modify the object's state (setters aka _mutators_).
1. Ensure that the class can't be extended.  This is generally done by making the class `final` but there is an alternative method: make all constructors `package-private` or `private` and use public static factoreis in place of the constructors.
1. Make all fields `final`.  This grants additional enforcement by the type system.
1. Make all fields `private`.
1. Ensure exclusive access to any mutable components.  If the class has fields that refer to mutable objects, ensure that clients of the class cannot obtain references to these objects.  Never return the field from an accessor.  Never initialize such a field to a object reference.  Make _defensive copies_ in constructors, accessors, and `readObject` methods.

Truly immutable objects never need to be `clone`d or copied.  So don't provide these methods for them.

If you choose to have your immutable class implement `Serializable`, and it contains one or more fields that refer to mutable objects, you _must_ provide an explicit `readObject` or `readResolve` method.

**If a class cannot be made immutable, limit it mutability as much as possible**.  Your natural inclination should be to declare every fioeld `private final` until you have a reason to do otherwise.

**Constructors should create fully initialized objects with all of their invariants established**.  Don't provide a public initialization method separate from (1) a constructor or (2) a static factory method.


## Favor composition over inheritance

In this item, _inheritance_ is meant to be specifically _implementation inheritance_ instead of _interface inheritance_, i.e., classes extend another.

It is safe to use inheritance within a package, where the subclass and the superclass implementations are under the control of the same programmers.

It is also safe to use inheritance when extending classes specifically designed and documented for extension.

**However**, it is dangerous to extend concrete classes across package boundaries.

**Inheritance violates encapsulation**.  A subclass depends on the implementation details of its superclass for its proper function.  The superclass's implementation may chagne from release to release and if it does, the subclass may break, even though the code has not been touched.
* A related issue is that superclasses may acquire new methods in subsequent releases.  If the subclass makes certain assumptions about the "entry points" into the public API for the class, the new methods might introduce new entry points and break invariants.

Composition involves making your would-be-subclass a brand new, non-sub, class and giving it a private field that references an instance of the class it _would_ have extended.
* Each instance method in your new class would _forward_ method calls by invoking corresponding methods on the private field.
* This removes dependencies on the implementation details of the existing class and keeps only a dependency on the private field's public API, which is what you wanted to do anyway.
* We sometimes call composing classes "wrapper" classes.  It is also sometimes referred to as the _Decorator_ pattern.  Even more loosely, it is sometimes referred to as _delegation_.  It's not technically delegation unless the wrapper object passes itself to the wrapped object, though.

There aren't a lot of issues with composition, but here are some:
* The `SELF` problem:  When objects pass self-references to other objects for subsequent invocations ("callbacks"), the wrapped object doesn't know of its wrapper and so it passes a reference to itself that eludes the wrapper.
* There is a performance cost associated with method forwarding that wouldn't exist if the JVM was dispatching directly to a specific subclass implementation.

Neither of these drawbacks are really that big of a deal.

**Test for whether you should have a class inherit from another class**.  Inheritance is only appropriate in circumstances where the subclass _really_ is a _subtype_ of the superclass.  There is an "is-a" relationship.
* Is every B really an A?  If you cannot definitively say "yes!", then B should not extend A.
* Does A have any flaws in its API?  If so, are you comfortable propagating those flaws to your new B class?  Composition allows you to design a new API that hides these flaws.

## Design and document for inheritance or else prohibit it

What does it mean for a class to be designed and documented for inheritance?
1. The class must document precisely the effects of overriding any method.  **The class must document its self-use of overridable methods**.  The documentation must indicate which overridable methods the method invokes, in what sequence, and how the results of each invocation affect subsequent processing.
    * This description is usually in a special section of the specification labeled "Implementation Requirements".
    * This unfortunately breaks the rules that good API documentation should describe the _what_ and not the _how_.  But this is a concession to the fact that inheritance violates encapsulation.
1. To allow efficient subclassing without undue pain, **a class may have to provide hooks into its internal workings in the form of judiciously chosen protected methods**.
1. The _only_ way to test a class designed for inheritance is to write subclasses.  If several subclasses are written and none uses a protected member, you should probably make it private.  Three subclasses are _usually_ sufficient to test an extendable class.
1. **Constructors must not invoke overridable methods**, directly or indirectly.  Conversely, it _is_ safe to invoke private, final, and static methods from a constructor.
1. It is advised to **not implement `Cloneable` and `Serializable`** because it makes designing classes for inheritance much harder. If you do, neither `clone` nor `readObject` may invoke an overridable method, indirectly or directly.  If the class has a `readResolve` or `writeReplace` method, you must make them `protected` rather than private.

**The best solution is to prohibit subclassing in classes that are not designed and documented to be safely subclassed**.
* You can declare the class `final`.
* You can make all constructors `private` or package-private (and use static factories in place of them).
* If your nonfinal class implements some `interface`, you should not feel bad about not allowing inheritance.

If you must make your class nonfinal, one easy-mode thing you could do is make sure that the class never invokes any of its overridable methods and then document that.
* You could move the body of each overridable method to a private "helper method", then have each overridable method invoke its private helper method, then replace each self-use of an overridable method with a direct invocation of the overridable method's private helper method.

## Prefer interfaces to abstract classes

Java has two mechanisms to define a type that permits multiple implementations: `interface`s and `abstract class`es.

Both mechanisms allow you to provide default implementations.

The difference between the two is what happens when a class wants to implement them.
* For an `abstract class`, the implementing class must be a subclass of the abstract class.  And since Java only permits single inheritance, this severely constrains their use as type definitions.
* Any class that implements an `interface` may do so, regardless of class hierarchy.
* Existing classes can be retrofitted to implement a new `interface`, but in general it is more difficult to do so for `abstract class`es due to the inheritance requirement.
* `interface` is ideal for defining mixins.
* `interface` allows for non-hierarchical type frameworks.
* `interface` enables safe, powerful functionality enhancements via the _wrapper class_ pattern.

_Skeletal implementation class_ go with interfaces.  The interface defines the type, perhaps providing some default methods, while the skeletel implementation class implements the remaining non-primitive interface methods atop the primitive interface methods.  Extending a skeletal implementation takes most of the work out of implementing an interface.  This is the _Template Method_ pattern.
* By convention, skeletal implementation classes are called `AbstractInterface` where `Interface` is the name of the interface tehy implement.
* Skeletal implementations can make it very easy for programmers to provide their own implementations of an interface.
* Skeletal implementations provide the implementation assistance of abstract classes without imposing the severe constraints that abstract classes impose.  It is strictly optional for users to extend the skeleton class.  If it cannot do so, it can just implement the interface directly.
* Classes implementing an interface can forward invocations of interface methods to a contained private inner class that extends the skeletal implementation.  This technique is known as _simulated multiple inheritance_.  It is closely related to the wrapper class idiom.

```java
// Skeletal implementation example

interface Entry<K, V> {   // Map.Entry
    K getKey();
    V getValue();
    V setValue(V value);
    boolean equals(Object o);
    int hashCode();
    ...
}


// The convention is to call the skeletal implementation class "AbstractXXXX" where "XXXX" is the name of the interface.
public abstract class AbstractMapEntry<K, V> implements Map.Entry<K, V> {
    // If a subclass/interface-implementer wants to allow mutation, they have to override this, otherwise we
    // have default behavior to not allow mutation.
    @Override public V setValue(V value) {
        throw new UnsupportedOperationException();
    }

    // implements the general contract of Map.Entry.equals
    @Override public boolean equals(Object o) {
        if (o == this)
            return true;
        if (!(o instanceof Map.Entry))
            return false;
        Map.Entry<?,?> e = (Map.Entry) o;
        return Objects.equals(e.getKey(), getKey()) && Objects.equals(e.getValue(), getValue());
    }

    // implements the general contract of Map.Entry.hashCode
    @Override public int hashCode() {
        return Objects.hashCode(getKey()) ^ Objects.hashCode(getValue());
    }

    @Override public String toString() {
        return getKey() + "=" + getValue();
    }
}
```

The above skeletal implementation class `AbstractMapEntry` could not be defined entirely as an interface because `equals`, `hashCode`, and `toString` are prohibited from having default methods in interfaces.

Skeletal implementations are designed to be extended/inherited, so you should follow all the rules outlined for designing classes for inheritance.

**Simple implementation**s are a variant on skeletal implementations, but differ in that they are not `abstract`.  They provide the simplest possible working implementation of the interface, so it can be used on its own or be subclassed.

## Design interfaces for posterity

Prior to Java 8 it was impossible to add methods to an interface without breaking existing implementations, since existing implementations would not have the new method defined.

You can define a default method when adding a method to an interface, which would indeed prevent breaking existing implementations, but in so doing, you are injecting new methods and behavior on existing implementations without their consent.
* **It is not possible to write a default method that maintains all invariants of every conceivable implementation.**

Default methods may allow compiles to succeed but fail at runtime.

As a result, **using default methods to add new methods to existing interfaces should be avoided unless the need is critical**.  Default methods remain useful at the time the interface is being designed/created to ease the task of implementing the interface.

## Use interfaces only to define types

When a class implements an interface, the interface serves as a _type_ that can be used to refer to instances of the class.  The interface says something about what a client can do with instances of the class.
* This expectation is broken by _constant interface_.  These are interfaces which contain no methods and only consists of static final fields, each exporting a constant.  Classes implement the interface to avoid having to qualify constant names with a class name.
* **The constant interface pattern is a poor use of interfaces**.  If a class chooses to use a constant internally, it should be an implementation detail.  Implementing a constant interface causes this implementation detail to leak into the class's exported API.
    * If in a future release, the class is modified so that it no longer needs the constants, it must still implmement the interface to ensure _binary compatibility_.  Removing the interface breaks _binary compatibility_ because all of the `static final`s are public (since everything on an interface is public), so clients which rely on their existence will break.

If you want to export constants:
1. If they are strongly tied to an existing class, define them on that class.
2. If they are best viewed as members of an enumerated type, then define them on an enum.
3. Otherwise, export them with a noninstantiable _utility class_.

```java
// Constants example

public class PhysicalConstants {
    private PhysicalConstants() { } // prevent instantiation
    public static final double AVOGADROS_NUMBER = 6.022_140_857e23
    public static final double BOLTZMANN_CONST = 1.380_648_52e-23
    public static final double ELECTRON_MASS = 9.109_383_56e-31
}
```

## Prefer class hierarchies to tagged classes

Sometimes you'll discover a class with instances that come in two or more flavors and contain a _tag_ field to disambiguate which "flavor" the instance is.  For example:

```java
class Figure {
    enum Shape { RECTANGLE, CIRCLE };

    final Shape shape;  // the shape of this figure (the "tag")

    double length;      // only used if shape == RECTANGLE
    double width;       // only used if shape == RECTANGLE

    double radius;      // only used if shape == CIRCLE

    Figure(double radius) {
        shape = Shape.CIRCLE;
        this.radius = radius;
    }

    Figure(double length, double width) {
        shape = Shape.RECTANGLE;
        this.length = length;
        this.width = width;
    }

    double area() {
        switch (shape) {
            case RECTANGLE:
                return length * width;
            case CIRCLE:
                return Math.PI * (radius * radius);
            default:
                throw new AssertionError(shape);
        }
    }
}
```

We call these **tagged classes** and they are NOT like TypeScript's discriminated unions, despite sort of looking like one.  Tagged classes, by contrast, suck:
* They are verbose
* They are error-prone (hard to maintain invariants)
* They are inefficient (they have to do conditional switch logic everywhere)
* They are wanna-be class hierarchies.  So just make them a class hierarchy.

## Favor static member classes over nonstatic

**Nested class**.  A nested class is a class defined within another class.  Nested classes should exist only to serve its enclosing class.  If it is more useful than that, then it should be its own top-level class.

**Static member class**.  A type of nested class.  Think of this class as a ordinary class that just happens to be declared inside another class and has access to all the enclosing class's members, even private ones.  Static member classes are static members of the enclosing class and obeys the same accessibility rules.
* It is common to use a static member class as a public helper class, but useful only in conjunction with its outer class.
* Instances of these can exist in isolation from its enclosing class.
* If you do not need access to the enclosing instance, _always_ use a `static` member class instead.
* A common use case for a `private` version of these is to represent components of the object represented by the enclosing class.  For example, `Map` classes associate keys with values.  There may be internal `Entry` objects for each key-value pair in the map.  Each `Entry` is associated with a `Map`, but the `Entry`'s methods do not need access to the map itself.

**Nonstatic member class**.  A type of nested class. Also known as an "inner class".  Each instance of a nonstatic member class is implicitly associated with an _enclosing instance_ of its containing class.  Nonstatic member class instance methods can invoke methods on the enclosing instance or obtain references to the enclosing instance using the _qualified this_ construct.
* It is impossible to create an instance of a nonstatic member class without an enclosing instance.
* The association between the nonstatic member class instance and its enclosing instance is defined at the time of instantiation and cannot be modified afterward.
* A common use case for these is an _Adapter_ pattern where an instance of an outer class wants to be viewed as an instance of some unrelated class.  For example, a `Map` that wants to have a nonstatic member class for an `Iterator`.
* If you do not need access to the enclosing instance, _always_ use a `static` member class instead.

**Anonymous class**.  A type of nested class. Also known as an "inner class".  Has no name.  Not a member of its enclosing class.  It is simultaneously declared and instantiated at the point of use.  Anonymous classes are permitted anywhere where an expression is legal.  Anonymous classes have access to enclosing instances if and only if they occur in a nonstatic context.  They cannot have static members other than _constant variables_ (primitive `final`s or string fileds initialized to constant expressions)
* Before lambdas were added to Java, these were the means of creating small function objects on the fly, but now lambdas are preferred.
* A common use is in the implementation of static factory methods, e.g., `intArrayAsList`.

**Local class**.  A type of nested class. Also known as an "inner class". Least frequently used of the above.  Can be declared anywhere a local variable can be declared and obeys the same scoping rules.  They can have names and be used repeatedly.  They cannot contain static members, and may have access to enclosing instances if they are defined in a nonstatic context.

## Limit source files to a single top-level class

There are risks to defining multiple top-level classes in a single source file.

Defining multiple top-level classes in a source file makes it possible to provide multiple definitions for a class via a name collision.

Source files are fed to the compiler one-by-one, so having them in separate files would prevent this from being able to compile if there were a name collision (which is a good thing)

If you are tempted to put multiple top-level classes into a signle source file, consider using static member clases.
