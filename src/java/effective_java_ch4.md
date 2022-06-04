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
