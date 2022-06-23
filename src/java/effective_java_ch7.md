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

## Use streams judiciously

Streams were added in Java 8 to ease performing bulk operations sequentially or in parallel.

There are two key abstractions:
1. the _stream_: a finite or infinite sequence of data elements
2. the _stream pipeline_:  a multistage computation on the elements on the stream

Data elements can come from anywhere and can be object references or `int`, `long`, or `double`s.

Stream pipelines are a source stream followed by zero or more _intermediate operations_ and one _terminal operation_.
* Intermediate operations transform the stream in some way, mapping elements or filtering elements.  Intermediate operations transform the stream from one stream to another.
* Terminal operations perform a final computation on the stream, such as storing its elements into a collection, returning a single element, or no elements at all, i.e., performing side effects like printing each element.
* Stream pipelines are executed _lazily_.  Evaluation begins once the terminal operation is invoked.  Data elements unused in the terminal operation are never computed.  This means that streams are a no-op if they don't have a terminal operation.
* By default, stream pipelines run sequentially.  They may run in parallel by invoking the `parallel` method.


There's no hard and fast rules, but you shouldn't _always_ use a stream.  Sometimes imperative programming is more readable.

**Overusing streams makes programs hard to read and maintain**.  Use good parameter names for your lambdas inside each intermediate operation.  Use helper methods for complex calculations to help with readability.

**Do not use streams to process char values**. `"Hello world".chars()` confusingly returns a stream of `int` instead of `char`.

There are things you can do from code blocks that you can't do from function objects:
1. Code blocks may read and modify local variables in scope.  From a lambda you can only read `final` or effectively `final` variables, and you can't modify local variables.
2. Code blocks can `return` from the enclosing method, `break` or `continue` an enclosing loop, or `throw` any checked exception.  From a lambda, you can do none of these things.

If you have to do any of these things, then streams are not a good fit.

Streams are a good fit when you want to:
* Uniformly transform sequences of elements
* Filter sequences of elements
* Combine sequences of elements using a single operation
* Accumulate sequences of elements into a collection
* Search a sequence of elements for an element satisfying some predicate

## Prefer side-effect-free functions in streams

Streams aren't just an API, it's a paradigm based on functional programming.  It's best to structure each intermediate operation as close as possible to a _pure function_ of the previous stage.  They should be free of side effects.

Don't use `forEach` for anything other than to present the result of the computation.  Don't write lambdas that mutate state.  These are both bad code smells.
* Author says its okay to use `forEach` to append to an existing collection.

```java
// DON'T DO THIS:
Map<String, Long> freq;
try (Stream<String> words = new Scanner(file).tokens()) {
    words.forEach(word -> {
        freq.merge(word.toLowerCase(), 1L, Long::sum);
    });
}

// DO THIS INSTEAD;
Map<String, Long> freq;
try (Stream<String> words = new Scanner(file).tokens()) {
    freq = words.collect(groupingBy(String::toLowerCase, counting()));
}
```

The `Collectors` API has 39 methods, some of which have as many as 5 type parameters.  It'd be pretty hard to memorize these. But similar to functional interfaces, you can derive most of the benefit without memorizing everything.
* Ignore the `Collector` interface and just think of a collector as a _reduction_ strategy.  As in a "reducer".

**It is customary to statically import members of `Collectors` because it makes stream pipelines more readable**.

There are three collectors to gather elements of a stream to an actual `Collection`
1. `toList()`
2. `toSet()`
3. `toCollection(collectionFactory)`

Most of the remaining collectors exist to assist with collecting into maps.
* The simplest of them is `toMap(keyMapper, valueMapper)`.  If multiple stream elements map to the same key, it throws an `IllegalStateException`.
* They get more complex in order to allow you to provide strategies for dealing with key collisions as the collector does its job.
    * There is even a three-argument overload of `toMap`: `toMap(keyMapper, valueMapper, BinaryOperator<V>)`
    * There is also a four-argument overload, adding a way to specify the particular map implementation: `toMap(keyMapper, valueMapper, BinaryOperator<V>, mapFactory)`
    * There are variants available for `toConcurrentMap`, providing `ConcurrentHashMap` instances.
* The `Collectors` API also provides `groupingBy` to produce maps from classifiers to collections of instances using a _classifier function_.
    * The unary variant of `groupingBy` groups stream elements into `List`s of those elements, grouped by the classifier.
    * The binary variant of `groupingBy` allows you, with the second parameter, to proovide a _downstream collector_ which specifies the type of collection to collect into, not just a `List`.  You can use `toSet` or `toCollection(collectionFactory)`.
    * The ternary variant of `groupingBy` allows you to specify a map factory.
    * There is also variants for `groupingByConcurrent` which run in parallel.
    * There is also `partitioningBy`, which is rarely used, but it partitions the stream into two collections based on a `Predicate` parameter.
* There a set of functions from the `Collectors` API that is _only_ intended for use as a downstream collector. These include:
    * `counting()`
    * `summing()`
    * `averaging()`
    * `summarizing()`
    * All overloads of `reducing()`
    * All overloads of `mapping()`
    * All overloads of `filtering()`
    * All overloads of `flatMapping()`
    * All overloads of `collectingAndThen()`
* Finally there are `Collectors` methods that do not involve collections:
    * `minBy` and `maxBy`, which take a comparator and return the elemnt found by using the comparator.
    * `joining`, which only operates on streams of `CharSequence` and produce a `String`.  It has many overloads as well.

## Prefer Collection to Stream as a return type

Prior to Java 8:
* For methods that returned a sequence of elements, the norm was a collection: `Collection`, `Set`, or `List`.
* If the method was written specifically to enable iteration/for-each loops, then the norm was to return an `Iterable`.
* If the method was written to return a sequence of primitives, then an array was used.

With Java 8, we have streams.  So should we return streams from the return type?

Clients can't iterate over them with a for-each loop, since `Stream` does not extend `Iterable`.

As a result you may have to write adapter code like so:

```java
// This adapter helps you translate from Stream<E> to Iterable<E>
public static <E> Iterable<E> iterableOf(Stream<E> stream) {
    return stream::iterator;
}

for (ProcessHandle p : iterableOf(streamOfProcesses)) {
    // do something
}
```

On the flip side, if a method only returns an `Iterable`, clients cannot use stream pipeline APIs.

As a result you may write adapter code to go in the opposite direction:

```java
// This adapter helps you translate from Iterable<E> to Stream<E>
public static <E> Stream<E> streamOf(Iterable<E> iterable) {
    return StreamSupport.stream(iterable.spliterator(), false);
}
```

If you're writing application code destined to be used only in a stream pipeline, feel free to write your methods to return streams.  If they're destined to only be used for iteration, feel free to return iterables.

Otherwise, if you're writing a public API, provide a way for users to do both: write stream pipelines and write for-each statements.

`Collection` is a subtype of `Iterable` and has a `stream` method, so it provides access for both iteration and stream access.
* **`Collection` or an appropriate subtype is generally the best return type for a public, sequence-returning method.**

**Large sequences**.  The exception is to not store a large sequence in memory just to return it as a collection.
* You can consider implementing a special-purpose collection.

If in the future, Java is updated to allow `Stream` to extend `Iterable`, then feel free to return streams because they'll automatically handle both stream processing and iteration.

## Use caution when making streams parallel

**Parallelizing a stream pipeline is unlikely to increase its performance if the source is from `Stream.iterate`, or the intermediate operation `limit` is used.**
* The default parallelization strategy assumes there's no harm in processing beyond `limit`, then discarding unneeded results.
* Do not parallelize streams indiscriminately.

**Performance gains from parallelism are best on streams over `ArrayList`, `HashMap`, `HashSet`, `ConcurrentHashMap`, arrays, `int` ranges, and `long` ranges.**
* All of these can be accurately and cheaply split into subranges of any desired size.
* They use an abstraction called a _Spliterator_.
    * If you write your own `Stream`, `Iterable`, or `Collection`, you must override the `spliterator` method if you want decent parallel performance.  High-quality spliterators are difficult to get right.
* They provide good-to-excellent _locality of reference_ when processed sequentially, meaning sequential element references are stored together in memory.  While the references have good locality of reference, the objects referred to by the references may be disparate, which reduces locality of reference.  Locality of reference is important for parallelizing bulk operations.

A stream pipeline's terminal operation also affects parallelism.
* If the terminal operation is inherently sequential, then parallelism gets undercut.
* The best terminal operation are _reductions_, e.g., `min`, `max`, `count`, `sum`.
* Also good are _short circuiting_ operations, e.g., `anyMatch`, `allMatch`, `noneMatch`.
* `collect` is a form of a _mutable reduction_, because combining collections from the parallel threads is costly.

Always remember parallelizing a stream is a performance optimization that you have to pay for by adhering to various contracts to make sure it works properly.  Normally parallel stream pipelines operate in a common fork-join pool, meaning a misbehaving pipeline can mess up the rest of the system.
* Do not evena attempt to parallelize a stream pipeline unless you have good reason to believe that it will preserve the correctness of the calculation _and_ increase its speed.
