# Lambdas and Streams

## Prefer lambdas to anonymous classes

Historically, interfaces with a single abstract method were used as _function types_.  Instances of them were known as _function objects_, and they represented a function or an action.  At the time, the primary means of creating a function object was an _anonymous class_.

```java
// The old way of doing things

Collections.sort(words, new Comparator<String>() {
    public int compare(String s1, String s2) {
        return Integer.compare(s1.length(), s2.length());
    }
});
```

In Java 8, the language designers decided that interfaces with a single abstract method are special and deserve special treatment.  They are called _functional interfaces_.  You can create an instance of such an interface using _lambda expressions_.
* They are similar to anonymous classes, but less boilerplate syntax.

```java
// Same example as above, except using the new lambda expression syntax

Collections.sort(words, (s1, s2) -> Integer.compare(s1.length(), s2.length()));
```

Interesting things to note from the above example:
* The type of the lambda above is `Comparator<String>`, which isn't necessarily evident in the source explicitly.
* `s1` and `s2` are deduced by the typechecker to be `String`.
* The return value of the lambda (`int`), is not explicitly stated in the code either.
* Most of the time the compiler is able to determine types using generics.  For example, `words` should be of type `List<String>`.  If you used a raw type (and you shouldn't), then it would reduce the compiler's ability to infer types of the lambda.

If the compiler can't deduce the types of your lambda, you'll have to provide them explicitly. Otherwise, you should **omit the types of all lambda parameters unless their presence makes your program clearer**.


Lambdas could have simplified the `Operation` enum from chapter 6.

```javase
public enum Operation {
    PLUS("+", (x, y) -> x + y),
    MINUS("-", (x, y) -> x - y),
    TIMES("*", (x, y) -> x * y),
    DIVIDE("/", (x, y) -> x / y);

    private final String symbol;
    private final DoubleBinaryOperator op;

    Operation(String symbol, DoubleBinaryOperator op) {
        this.symbol = symbol;
        this.op = op;
    }

    @Override
    public String toString() { return symbol; }

    public double apply(double x, double y) {
        return op.applyAsDouble(x, y);
    }
}
```

Worth noting is the usage of `DoubleBinaryOperator` interface, which represents one of many predefined functional interfaces in `java.util.function`.  This interface happens to represent a function that takes two `double` arguments and returns a `double`.

The original constant-specific method declarations would be better than lambdas if the computation was complex.  **Lambdas lack names and documentation; if a computation isn't self-explanatory, or exceeds a few lines, don't put it in a lambda**.  In this particular circumstance, lambdas are clearly the better option.

Anonymous classes have these advantages over lambdas:
1. Lambdas are restricted to functional interfaces.  If you want an instance of an abstract class you can do it with an anonymous class but not a lambda.
2. You can use anonymous classes to create instances of interfaces with multiple abstract methods.
3. Lambdas cannot obtain a reference to itself.  In a lambda, the `this` keyword refers to the enclosing instance.

Neither lambdas nor anonymous classes cannot reliably serialize and deserialize.  **You should rarely, if ever, serialize a lambda or an anonymous class instance**.  If you want a function object that you want serializable (such as `Comparator`), use an instance of a private static nested class.

## Prefer method references to lambdas

Java provides a way to generate function objects more succinct than lambdas: _method references_.

```java
// uses a lambda
map.merge(key, 1, (count, incr) -> count + incr);

// uses a method reference
map.merge(key, 1, Integer::sum);
```

`Integer::sum` is a static method on `Integer` added in Java 8 that takes two `Integer`s and adds them together, returing the result.  A `BinaryOperator` functional interface, inherently.
* This has the advantage of removing the boilerplate of having to specify the lambda arguments
* More arguments means a method reference removes more boilerplate.

There's nothing you can do with a method reference that you can't also do with a lambda.

Method references often refer to `static` methods.  But there are additional versions which do not.

| Method Ref Type | Example | Lambda Equivalent|
|:---|:---|:---|
| Static | `Integer::parseInt` | `str -> Integer.parseInt(str)` |
| Bound | `Instant.now()::isAfter` | `Instant then = Instant.now(); t -> then.isAfter(t)` |
| Unbound | `String::toLowerCase` | `str -> str.toLowerCase()` |
| Class Constructor | `TreeMap<K, V>::new` | `() -> new TreeMap<K, V>` |
| Array Constructor | `int[]::new` | `len -> new int[len]` |

**Bound method references**.  The receiving object is specified in the reference.  The function object takes the same arguments as the referenced method.

**Unbound method references**.  The receiving object is specified when the function object is applied, via an additional parameter before the method's declared parameters.

The two constructor references serve as factory objects.  They are functions which product new objects.

**Use method references over lambdas when they are shorter and clearer, otherwise use lambdas**.

## Favor the use of standard functional interfaces

The `java.util.function` package provides a large collection of standard functional interfaces for your use.

**If one of the standard functional interfaces does the job, you should generally use it in preference to a purpose-built functional interface**.
* Makes your API easier to learn, by reducing conceptual surface area.
* Provides interoperability benefits, since many standard functional interfaces provide useful default methods.

There are 43 interfaces in `java.util.Function`.  You only need to remember 6 basic interfaces, then derive the rest when you need them.
* These 6 operate on object reference types.
    * The `Operator` interface represent functions whose argument and result types are the same. `T -> T`
    * There is also `BinaryOperator`, which is `T, T -> T`
    * The `Predicate` interface represents functions that takes an argument and returns a boolean. `T -> Boolean`
    * The `Function` interface represents a function whose arguments and result types differ. `T -> U`
    * The `Supplier` interface represents a function that takes no arguments but returns a value. `() -> T`
    * The `Consumer` interface represents a function that takes an argument but returns nothing. `T -> ()`

| Interface | Function Signature | Example |
|:---|:---|:---|
| `UnaryOperator<T>` | `T apply(T t)` | `String::toLowerCase` |
| `BinaryOperator<T>` | `T apply(T t1, T t2)` | `BigInteger::add` |
| `Predicate<T>` | `boolean test(T t)` | `Collection::isEmpty` |
| `Function<T, R>` | `R apply(T t)` | `Arrays::asList` |
| `Supplier<T>` | `T get()` | `Instant::now` |
| `Consumer<T>` | `void accept(T t)` | `System.out::println` |

Each of these variants have versions for the primitive types `int`, `long`, and `double`. For example: `IntPredicate` or `LongFunction`.

The `Function` interface also has additional variants for when the result type is one of the three primitives and the argument is not the same type (otherwise it would be a `UnaryOperator`).
* If the argument and result are both primitive, there are six variants that take the prefix `SrcToResult`, for example: `LongToIntFunction`.
* If the argument is an object but the result are primitive, there are three variants: `ToDoubleFunction`, `ToIntFunction`, `ToLongFunction`.
* If the argument is a primitive but the result is an object, you'd just use one of the `Function` interfaces.

There are two-argument versions of `Predicate`, `Consumer`, and `Function`: `BiPredicate`, `BiConsumer`, `BiFunction`, respectively.  As well as two-argument interfaces for other arrangements as well.

Most of the standard functional interfaces exist to support primitive types.  **Don't be tempted to use basic functional interfaces with boxed primitives instead of primtivie functional interfaces**.

You write your own functional interface if none of the standard interfaces have what you need, e.g., a ternary (three-argument) function, or a function that throws a checked exception.

You should also write a functional interface even if one of the standard ones is structurally identical if:
* The name of a custom functional interface would be excellent and useful, e.g., `Comparator` vs `ToIntBiFunction`.
* If the custom functional interface has a strong contract that must be upheld by clients.
* The interface is outfitted with default methods.

**Always annotate your functional interfaces with the `@FunctionalInterface` annotation**.

Do not provide a method with multiple overloadings that take different functional interfaces in the same argument position if it could create a possible ambiguity in the client.
* `ExecutorService.submit` takes either a `Callable<T>` or a `Runnable`.  This sometimes requires clients to write a cast to indicate the correct overloading.
* Just don't write overloadings that take different functional interfaces in the same position.

**You should design your APIs with lambdas in mind**.  Accept functional interface types on input and return them on output.
