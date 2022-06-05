# Generics

| Term                    | Example                                   |
|:------------------------|:------------------------------------------|
| Parameterized type      | `List<String>`                            |
| Actual type parameter   | `String`                                  |
| Generic type            | `List<E>`                                 |
| Formal type parameter   | `E`                                       |
| Unbounded wildcard type | `List<?>`                                 |
| Raw type                | `List`                                    |
| Bounded type parameter  | `<E extends Number>`                      |
| Recursive type bound    | `<T extends Comparable<T>>`               |
| Bounded wildcard type   | `List<? extends Number>`                  |
| Generic method          | `static <E> List<E> asList(E[] elements)` |
| Type token              | `String.class`                            |

A class or interface whose declaration has one or more _type parameters_ is a _generic_ class or interface, e.g., `List<E>`.  Generic classes and interfaces are collectively known as _generic types_.

Each generic type defines a set of _parameterized types_, which consist of the class or interface name followed by an angle-bracketed list of _actual type parameters_ corresponding to the generic type's formal type parameters.

For example: `List<String>`:
* `List` is the "raw type".
* `String` is the "actual type parameter" corresponding to the formal type parameter `E` (from `List<E>`)

## Don't use raw types

Raw types behave as if all of the generic type information were erased from the type declaration.  They exist only for compatibility with pre-generics code (i.e., pre-Java 5).

Without the actual type parameters, raw types require you to do a lot of casting to get the code compiling.

**If you use raw types, you lose all the safety and expressiveness benefits of generics**.

`List<Object>` is even better than `List`.  The latter tells the compiler that it is explicitly opting out of the generic type system.
* If a method takes a `List<Object>` you can't pass it a `List<String>`.   But if it were a `List`, you could pass `List<String>`.
* You lose type safety if you use a raw type such as `List`, but not if you use a parameterized type such as `List<Object>`

```javase
public static void main(String[] args) {
    List<String> strings = new ArrayList<>();
    unsafeAdd(strings, Integer.valueOf(42));   // should have failed!
    String s = strings.get(0);                 // has a compiler-generated cast
}

private static void unsafeAdd(List list, Object o) {
    list.add(o);
}
```

If you want to write a method that takes a generic type but don't care about the actual type parameter, you should use an _unbounded wildcard type_.

```javase
static int numElementsInCommon(Set<?> s1, Set<?> s2) { ... }
```

What's the difference between `Set<?>` and `Set`?
* You can put _any_ element into `Set`.
* You can't put any element (other than `null`) into a `Set<?>`
    * The fact that you're telling the compiler that it's unbounded and that you don't care about the type means that it will force you to not write code that relies on the generic type parameter of `Set`, which is a good thing.


**The only times you should use a raw type:**
1. You want to write a class literal.  Parameterized types are not permitted for class literals, so you have to use `List.class`, `String[].class`, ir `int.class` instead of `List<String>.class` and `List<?>.class`.
2. You want to use the `instanceof` operator at runtime.  At runtime,  generic type information is erased,so it is illegal to use `instanceof` on parameterized types other than unbounded wildcard types.
    * Once you determined the type of the object using `instanceof`, you must cast it to the wildcard type instead of the raw type.

```javase
// Valid use of raw type (number 2 above)
if (o instanceof Set) {
    Set<?> s = (Set<?>) o;
}
```

## Eliminate unchecked warnings

Persevere and don't allow any unchecked warnings persist.  Eliminate all of them.

If you can't eliminate a warning, but you can prove that the code that provoked the warning is typesafe, then and only then, suppress the warning with an `@SuppressWarnings("unchecked")` annotation.
* Always use this annotation on the smallest scope possible.  It can be used from as tight as a variable declaration or as wide as an entire class, but stick to the smallest scope possible.
* Its OK to declare new local variables to add this annotation.  For example, you can't put the annotation on the return statement, even if it returns the value that needs to be suppressed.  So store the result in a local variable, suppress _that_ assignment, then return the result.  Don't suppress the entire method.
* Every time you use a `@SuppressWarnings("unchecked")` annotation, add a comment saying why it is safe to do so.


## Prefer lists to arrays

Arrays are covariant, meaning that `Subclass[]` is a subtype of the array type `Superclass[]`.  Arrays are _reified_, meaning that element types are enforced at runtime.  If you try to place a `String` into an array of `Long`, you get an `ArrayStoreException`.

Generics are _invariant_, by contrast.  `List<Type1>` is neither a subtype or supertype of `List<Type2>`.  Generics are implemented by _erasure_, meaning they enforce their type constraints only at compile time and discard their element type at runtime.

This is an issue:
```java
Object[] objectArray = new Long[1];
objectArray[0] = "I don't fit in";  // compiles, but throws an exception at runtime!
```

Generics are safer due to their invariance:
```java
// this won't compile

List<Object> ol = new ArrayList<Long>(); // incompatible
ol.add("I don't fit in");
```

Generics and arrays are so incompatible that arrays cannot hold generic types.

## Favor generic types

Generic types are safer and easier to use than types that require casts in client code.

When you design new types, make sure that they can be used without such casts, which often means making the types generic.

It is not always possible or desirable to use lists inside your generic types.  Java does not support lists natively, so some generic types such as `ArrayList` must be implemented atop arrays.  Other generic types, such as `HashMap` are implemented atop arrays for performance.

In some cases, you want or need to use arrays internally within your class, but you want the class overall to be generic.  There are two reasonable ways to do this:

**Option 1:  Create an array of `Object`, i.e., `Object[]`, and then cast it to the generic array type.**
* This does cause _heap pollution_ since the runtime type of the array does not match its compile-time type.  At runtime the array `elements` is `Object[]`.

```java
class Stack<E> {
    private E[] elements;
    ...
    
    // The elements array will only contain E instances from push(E).
    // Runtiume type of elements won't be E[], it will always be Object[]
    @SuppressWarnings("unchecked")
    public Stack() {
        elements = (E[]) new Object[DEFAULT_INITIAL_CAPACITY];  // cast it to the generic array type
    }

    public void push(E element) {
        ensureCapacity();
        elements[size++] = e;
    }

    public E pop() {
        if (size == 0)
            throw new EmptyStackException();
        E result = elements[--size];  // no cast needed here
        elements[size] = null;
        return result;
    }

    ...
}
```

**Option 2:  Store the values internally as `Object[]`, but cast it upon usage.**
```java
class Stack<E> {
    private Object[] elements;

    public E pop() {
        if (size == 0)
            throw new EmptyStackException();

        // push requires elements to be of type E so this cast is safe
        @SuppressWarnings("unchecked") E result = (E) elements[--size];  // cast here

        elements[size] = null;
        return result;
    }
}
```

Some generic types restrict the possible values of their type parameters.  These generic types have a bounded type parameter:

```javase
// Example

class DelayQueue<E extends Delayed> implements BlockingQueue<E>
```

In the above, `E` must be a subtype of `java.util.concurrent.Delayed`

## Favor generic methods

Methods can be generic too.  Most static utlity methods are written to be generic.

You can make them more flexible by using _bounded wildcard types_.  Type parameters may also be bounded by some expression involving the type parameter itself.  Java doesn't have a `Self` type, so we must use something called a _recursive type bound_.  For example, if you want to create a `max` function for a collection, you'd need the elements be comparable to other elements:

```java
public static <E extends Comparable<E>> E max(Collection<E> collection);
```

## Use bounded wildcards to increase API flexibility

Parameterized types are _invariant_.  `List<String>` is not a subtype of `List<Object>`.

**For maximum flexibility, use wildcard types on input parameters that represent producers or consumers**.

> PECS -> "`producer-extends`, `consumer-super`"
* If a parameterized type represents a `T` producer, use `<? extends T>`.
* If a parameterized type represents a `T` consumer, use `<? super T>`.

`<? extends E>` can be read simply as "some subtype of E", but don't forget that all types are subtypes of themselves, so 'some subtype of E' is inclusive of E.

```java
public void pushAll(Iterable<? extends E> src) {
    for (E e : src) {
        push(e);
    }
}
```

`<? super E>` can be read as "some supertype of E", where types are defined to be supertypes of themselves too, so it is inclusive of E.

```java
public void transferElements(Collection<? super E> dst) {
    while (!isEmpty()) {
        final E element = pop();
        dst.add(element);  // dst needs to be generic to accept E and its supertypes.
    }
}
```

**Do not use bounded wildcard types as return types**.  If the user of a class has to think about wildcard types, there is probably something wrong with its API.


Bounded wildcard types can be combined with recursive bounded types!  The below `T` is very flexible by comparison to just a naked `<T>`.  It says "any type that is comparable to itself or a supertype of itself"

```java
public static <T extends Comparable<? super T>> T max(List<? extends T> list);
```

Comparison of unbounded type parameters vs unbounded wildcards:
```java
// Two possible declarations to do the same thing:
public static <E> void swap(List<E> list, int i, int j);
public static void swap(List<?> list, int i, int j);
```

**If a type parameter appears only once in a method declaration, replace it with a wildcard**.  If it's unbounded, replace it with an unbounded wildcard.  If it's bounded, replace it with a bounded wildcard.

The main trouble with the second one is that the type of `list` is `List<?>`, and you can't set or add any value except `null` into a `List<?>`. To get around this, you can use a private helper method to _capture_ the wildcard type:

```java
public static void swap(List<?> list, int i, int j) {
    swapHelper(list, i, j);
}

private static <E> void swapHelper(List<E> list, int i, int j) {
    list.set(i, list.set(j, list.get(i)));
}
```

The above is convoluted, but allows us to export nice wildcard-based declarations for clients.

## Combine generics and varargs judiciously

Varargs methods and generics do not interact gracefully.  Varargs is a _leaky abstraction_.  When you invoke a varargs method, an array is created to hold the varargs parameters.  This array is visible.

Not only that, but all generic types are non-reifiable types which do not interop with arrays very well.  If a method declares its varargs to be a non-reifiable type, you'll get a warning.  Subsequently, if the method is called, you'll also get a warning.  The warning will mention something about "heap pollution".

_Heap pollution_ is when a variable of a parameterized type refers to an object that is not of that type.  This may cause the compiler's automatically generated casts to fail, which can break the type system.

```java
// Heap pollution example
static void dangerous(List<String>... stringLists) {  // ... is varargs
    List<Integer> intList = List.of(42);
    Object[] objects = stringLists;
    objects[0] = intList;              // Heap pollution
    String s = stringLists[0].get(0);  // ClassCastException, even with no visible casts
}
```

**It is unsafe to store a value in a generic varargs array parameter**.

Java language designers kept this potential problem in the language because in some cases, having methods with varargs parameters of generic or parameterized types can be very useful in practice.  The Java libraries export several such methods, i.e., `Arrays.asList(T... a)`, `Collections.addAll(Collection<? super T> c, T... elements)`, `EnumSet.of(E first, E... rest)`.

The `@SafeVarargs` annotation was added to the platform to allow th author of such methods to suppress client warnings (remember that client invocations of the method will get the warning. Warnings don't appear just where it's declared).
* **The `@SafeVarargs` annotation constitutes a promise by the author of a method that it is typesafe.**
* If the method doesn't store anything into the generic array created by the generic varargs AND doessn't allow a reference in the array to escape, then it's safe.
* If the varargs parameter array is used _only_ to transmit a variable number of arguments from the caller to the method, then the method is safe.

Be warned: you can still violate type safety without ever storing anything in the varargs parameter array.

```java
// UNSAFE - Exposes a reference to its generic parameter array!
static <T> T[] toArray(T... args) {
    return args;
}
```

The above is unsafe because:
* The type of the array is determined at compile-time by the types of the arguments passed into the method.
* The compiler may not have enough information to make an accurate determination

**Use `@SafeVarargs` on every method with a varargs parameter of a generic or parameterized type**.  Never write unsafe varargs methods.

## Consider typesafe heterogenous containers

When you use `Set<E>`, `Map<K, V>`, `ThreadLocal<T>`, `AtomicReference<T>` and other similar generic containers, the generic itself is parameterized, which limits you to a fixed number of type parameters per container.  The `Set` has a single type parameter, `Map` has two, etc.  Normally this is what you want.

Sometimes you want more flexibility.  For example, a database row can have arbitrarily many columns.

```
// Don't do this, but this demonstrates what you would _want_ to do sometimes.

DataBaseRowOneColumn<A>;
DataBaseRowTwoColumns<A, B>;
DataBaseRowThreeColumns<A, B, C>;
DataBaseRowFouorColumns<A, B, C, D>;
...
```

To support something similar to the above, but in a sane way, you can parameterize the _key_ instead of the _container_.  Then you can present the parametrized key to the container to insert or retrieve a value.  You can present the key to the container in methods that ask for a _class literal_, e.g., `Integer.class` which evaluates to `Class<Integer>`.  When a class literal is passed to communicate both compile-time and runtime type information, it is called a _type token_.

As useful as this is, it doesn't work for non-reifiable types, but otherwise, it can be quite useful.

```
// Typesafe heterogenous container pattern
public class Favorites {
    private Map<Class<?>, Object> favorites = new HashMap<>();

    public <T> void putFavorite(Class<T> type, T instance) {
        // since `favorites` stores Object, we actually "lose" the type from a type system perspective.
        // the data is stored alongside the type token, so we don't _practically_ lose it, really.
        favorites.put(Objects.requireNonNull(type), instance);


        // alternative implementation, it adds some overhead with a dynamic cast, but prevents bad actors from storing
        // the wrong instance next to a given type token (which would cause heap pollution)
        favorites.put(Objects.requireNonNull(type), type.cast(instance));
    }

    public <T> T getFavorite(Class<T> type) {
        // cast is required here to re-establish the linkage of `type` to the type of the object pulled out of the Map.
        // this is called a dynamic cast
        return type.cast(favorites.get(type));
    }
}

// Usage of the above
public static void main(String[] args) {
    Favorites f = new Favorites();
    f.putFavorite(String.class, "Java");
    f.putFavorite(Integer.class, 0xcafebabe);
    f.putFavorite(Class.class, Favorites.class);

    String favoriteString = f.getFavorite(String.class);
    int favoriteInteger = f.getFavorite(Integer.class);
    Class<?> favoriteClass = f.getFavorite(Class.class);

    System.out.printf("%s %x %s%n", favoriteString, favoriteInteger, favoriteClass.getName());
}
```
