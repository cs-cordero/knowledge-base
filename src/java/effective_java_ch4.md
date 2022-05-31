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
