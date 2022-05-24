# Creating and Destroying Objects

## Consider static factory methods instead of constructors

* A public constructor is the traditional way to get an instance of a class.
* This is different from the _Factory Method_ pattern from _Design Patterns_.
* Classes may provide a _static factory method_ as well, which is a static method that returns an instance of the class.

### Advantages
1. Unlike constructors, the static method gives it a name.
1. Classes only allow one constructor with one signature, but static methods get around this.
1. Static factory methods are not required to create a new object each time they're invoked, allowing you to return pre-constructed immutable instances.
1. Static factory methods can, unlike constructors, return an object of any subtype.  As a result, an API can return objects without making their classes public.
1. The returned object can vary from call to call as a function of the input parameters.
1. The class of the returned object need not exist when the class contianing the method is written.
    * This is the basis for _service provider frameworks_ like the Java Database Connectivity API (JDBC), in which providers implement a service and the system makes the implementations available to clients, decoupling clients from the implementations.
    * There is usually (1) a _service interface_ which represents an implementation, (2) a _provider registration API_, (3) a _service access API_, which allows cleints to obtain instances of the service, and (4) a _service provider interface_, which describes a factory object that produces instances of the service interface.
    * For example, for JDBC, `Connection` is the service interface, `DriverManger.registerDriver` is the provider registration API, `DriverManager.getConnection` is the service access API, and `Driver` is the service provider interface.


### Disadvantages
1. Classes without a public or protected constructors cannot be subclassed.
    * (Chris: this is a good thing IMHO)
1. Static factory methods are harder for programmers to find.
    * One way to reduce this issue is to use a common nomenclature for static factory methods: `from`, `of`, `valueOf`, `instance`, or `getInstance`, `create` or `newInstance`, `get[TypeName]`, `new[TypeName]`, `[TypeName]` (e.g., `Collections.list(...)`)


## Consider a builder when faced with many constructor parameters

When you have a class that requires many parameters, some of which are required and others are optional, the two most common things you might see in the wild are two patterns:

**Telescoping parameters**.  This abuses Java's parameter overloading to create many constructors for each variation of acceptable parameter arrangement.  This gets unwieldly with the number of variables you'd have to support.

```java
// DON'T DO THIS

public class NutritionFacts {
    public NutritionFacts(int servingSize, int servings) {
        this(servingSize, servings, 0);
    }

    public NutritionFacts(int servingSize, int servings, int calories) {
        this(servingSize, servings, calories, 0);
    }

    public NutritionFacts(int servingSize, int servings, int calories, int fat) {
        this(servingSize, servings, calories, fat, 0);
    }

    ...
}
```

**JavaBeans pattern**.  This is a pattern where you allow the class to be instantiated with all nulls then expect the programmer to call a set of `setter` methods to set the values on the class.  This is bad because it allows for the class to be in an inconsistent state and mandates mutability.

```java
// DON'T DO THIS

NutritionFacts cocaCola = new NutritionFacts();
cocaCola.setServingSize(240);
cocaCola.setServings(8);
cocaCola.setCalories(100);
cocaCola.setSodium(35);
cocaCola.setCarbohydrate(27);
```

Instead, use a **Builder** pattern:

```java
// When checking for invariants, throw an IllegalArgumentException if inputs are invalid

public class NutritionFacts {
    private final int servingSize;
    private final int servings;
    private final int calories;
    private final int fat;
    private final int sodium;
    private final int carbohydrate;

    public static class Builder {
        // Required parameters
        private final int servingSize;
        private final int servings;

        // Optional parameters - initialize to default values
        private int calories = 0;
        private int fat = 0;
        private int sodium = 0;
        private int carbohydrate = 0;

        public Builder(int servingSize, int servings) {
            // Check for invariants for the individual values here.
            this.servingSize = servingSize;
            this.servings = servings;
        }

        public Builder calories(int val) {
            // Check for invariants for the individual values here.
            calories = val;
            return this;
        }
        public Builder fat(int val) { fat = val; return this; }
        public Builder sodium(int val) { sodium = val; return this; }
        public Builder carbohydrate(int val) { carbohydrate = val; return this; }

        public NutritionFacts build() {
            // Check for invariants between multiple values here

            return new NutritionFacts(this);
        }
    }

    private NutritionFacts(Builder builder) {
        servingSize = builder.servingSize;
        servings = builder.servings;
        calories = builder.calories;
        fat = builder.fat;
        sodium = builder.sodium;
        carbohydrate = builder.carbohydrate;

        // Check for invariants one more time here to prevent against attacks
    }
}
```

## Enforce the singleton property with a private constructor or an enum type

There are two common ways to implement singletons, both based on keeping the constructor private and exporting a public static member.

In this first example, the constructor is made `private`.  The lack of a `public` or `protected` constructor means that it can never be instantiated beyond the `INSTANCE` static object.  One downside to this approach is that a privileged client can access the constructor reflectively using `AccessibleObject.setAccessible`.  The same downside is present in the second example.

```java
public class Elvis {
    public static final Elvis INSTANCE = new Elvis();
    private Elvis() { ... }
```

In this second example, the public member is not the instance directly but uses a static getter method.

```java
public class Elvis {
    private static final Elvis INSTANCE = new Elvis();
    private Elvis() { ... }

    public static Elvis getInstance() { return INSTANCE; }
}
```

The advantages of this second example are the following.  If none of these are interesting for your use case, you should just use the first example:
1. You can change you rmind about whether the class is a singleton without changing its API.
1. You can write a _generic singleton factory_ if your application requires it.
1. A method reference can be used as a supplier.  For example, `Elvis::instance` is a `Supplier<Elvis>`

A disadvantage to either of these approaches is when it comes to Serialization.  If you need the singleton to be serializable, you have to be careful because upon deserialization, the singleton will no longer be a singleton: deserialization produces new instances!
* To maintain the guarantee, you must remember to set all instance fields `transient`, and then provide a `readResolve` method.

A third way to implement a singleton **and the preferred approach** is to declare a single-element enum:

```java
public enum Elvis {
    INSTANCE;

    public void someInstanceMethod() { ... }
}
```

This way is similar to the public field approach, but is more concise, provides the serialization machinery for free, and guarantees against multiple instantiation.  It feels unnatural but in Java, **a single-element enum type is often the best way to implement a singleton**.
* It won't be the best way if your singleton needs to extend another class.  But enums _can_ implement interfaces.

## Enforce noninstantiability with a private constructor

For utility classes (classes that are a grouping of static methods and static fields), they are not meant to be instantiated.

**DO NOT** omit a constructor entirely.  Classes get a default public constructor.

**DO NOT** attempt to enforce noninstantiability by making a class abstract.

**DO** make a class noninstantiable by include a private constructor.  Example:

```java
public class UtilityClass {
    private UtilityClass() {
        throw new AssertionError();
    }

    // static methods omitted
}
```

## Prefer dependency injection to hardwiring resources

Static utility classes and singletons are inappropriate for classes whose behavior is parametrized by an underlying resources.

The simplest pattern to enable dependency injection is to pass the resource into the constructor of a class when creating a new instance of that class.

```java
public class SpellChecker {
    private final Lexicon dictionary;

    public SpellChecker(Lexicon dictionary) { // require passing in the resource
        this.dictionary = Objects.requireNonNull(dictionary);
    }

    // other methods omitted...
}
```

A useful **variant** of this pattern is to pass a resource _factory_ to the constructor.  Factories are objects that can be called repeatedly to create instances of a type.  The `Supplier<T>` interface from Java 8 is perfect for representing factories.  Methods that take a `Supplier<T>` should constrain the type parameter using a _bounded wildcard type_. For example:

```java
// This takes any Supplier<T> where T is either a Tile or a subtype of Tile
Mosaic create(Supplier<? extends Tile> tileFactory) { ... }
```

## Avoid creating unnecessary objects

This item should not be misconstrued to imply that object creation is expen- sive and should be avoided. On the contrary, the creation and reclamation of small objects whose constructors do little explicit work is cheap, especially on modern JVM implementations. Creating additional objects to enhance the clarity, simplicity, or power of a program is generally a good thing

Avoid doing dumb stuff like this:

```java
// DON'T DO THIS
String s = new String("hello");
```

This allocates the string literal "hello" then passes that string to the constructor of `String` to create another string.  This is better:

```java
String s = "hello";
```

Static factory methods can help you avoid unnecessary instantiation over constructors.  Constructors are _required_ to return new instances each time, but static factory methods can reuse objects (and it's a good idea to do so if a given object is immutable).
* The factory method `Boolean.valueOf(String)` is preferable to `Boolean(String)` because the latter always creates new objects whereas the former will return the same immutable objects.  The latter is actually deprecated as of Java 9.

Another pitfall is in Autoboxing, which performs heap allocations.  It's harder to spot, but you should always prefer primitives to boxed primitives.  Look out for where there is unintentional autoboxing.

## Eliminate obsolete object references

Most times, since Java is garbage-collected, you don't need to worry about object references once they can no longer be reached. However, **whenever a class manages its own memory, the programmer should be allert for memory leaks**.  References should be explicitly nulled out (set to `null`).

Common sources of memory leaks:
* Caches.  It's easy to forget values placed in a cache and leave it there long after the value is relevant.  You can use a `WeakHashMap` if that fits your use case, or you can clear the cache periodically using a background thread (perhaps using a `ScheduledThreadPoolExecutor`), or you can clear the cache as a side effect to adding new entries.
* Listeners and Callbacks.  If you don't deregister callbacks explicitly, they will accumulate unless you take action.

## Avoid finalizers and cleaners

_Finalizers_ are deprecated as of Java 9, but were replaced with _cleaners_.  Cleaners are less dangerous but still unpredictible, slow, and generally unnecessary.

These features are NOT the same as a C++ destructor.

Why?
1. There is no guarantee they will be executed promptly.  It can take an arbitrarily long time before the finalizer or cleaner runs.  As a result you can't rely on anything time-sensitive on the finalizer/cleaner.  For example, closing files in a finalizer is a huge mistake because open file descriptors are a limited resource.
1. There is no guarantee that they will be executed at all.  As a result you can't rely on a finalizer or cleaner to update persistent state.  For example, never handle lock APIs from a finalizer or cleaner.
    * This includes `System.gc` and `System.runFinalization`.  They increase the likelihood that they will be executed, but do not guarantee it.
    * `System.runFinalizersOnExit` and `Runtime.runFinalizersOnExit` are fatally flawed as well and have been deprecated for decades.
1. The finalizer thread that actually reclaims instances is JVM-implementation-specific and may be run at a lower priority than another application thread, which may cause an `OutOfMemoryError` eventually.
1. Uncaught exceptions thrown during finalization are ignored.  Uncaught exceptions can leave other objects in a corrupt state.
1. There is a _severe_ performance penalty for using finalizers and cleaners.  It's about 50x slower than using `try-with-resources`.
1. Finalizers open your class up to _finalizer attacks_.  If an exception thrown from a constructor or its serialization equivalents, the finalizer of a malicious subclass can run on the partially constructed object that should have "died on the vine".  This finalizer can then record a reference to the object in a static field, preventing it from being garbage collected.  Then the attacker can invoke arbitrary methods on this object that should have never existed in the first place.
    * Non-final classes are subject to finalizer attaks.  To combat it, you can write a final `finalize` method that does nothing.


**What to do instead?**  Have your classes implement `AutoCloseable`, then use `try-with-resources` or manually call `close` instead.


## Prefer `try-with-resources` to `try-finally`

Instead of this:

```java
// DON'T DO THIS
static String firstLineOfFile(String path) throws IOException {
    BufferedReader br = new BufferedReader(new FileReader(path));
    try {
        return br.readLine();
    } finally {
        br.close();
    }
}
```

Do this:

```java
static String firstLineOfFile(String path) throws IOException {
    try (BufferedReader br = new BufferedReader(new FileReader(path))) {
        return br.readLine();
    }
}
```

**Why?**
1. Exceptions may be thrown in either the `try` block or the `finally` block.  If they happen in both, then the exception in the `finally` block blows out the first.  There is no record of the first exception ever occurring.
    * `try-with-resources` works in the opposite way: the first is preferred over the second.
