# Unhandled Exceptions

The Java language divides its exceptions into two groups: _Handled Exceptions_ and _Unhandled Exceptions_.

Using the `throws` keyword indicates that the function `checkAge` may or may not throw a given Exception.  This enables the compiler to check whether callers of this method handles the exception or propagates it.

You may `throws` checked or even unchecked exceptions, but even if it is in the `throws` statement, __unchecked exceptions are STILL unchecked!__

```java
public class MyClass {
  static void checkAge(int age) throws ArithmeticException {
    if (age < 18) {
      throw new ArithmeticException("Access denied - You must be at least 18 years old.");
    }
  }

  public static void main(String[] args) {
    // Note that calling checkAge doesn't raise any compiler errors even though
    // there is an `ArithmeticException` in a throws statement on `checkAge`.
    // This is because `ArithmeticException` is still a subclass of `RuntimeException`,
    // and is therefore unchecked.  It does, however, give some readability to
    // users of the method.
    checkAge(15);
  }
}
```

If you use a method that throws a checked exception, you must either:
1. Handle the exception, or
2. Propagate the exception

```java
import java.io.IOException;

public class MyClass {
    public static void throwsIOExceptionWhichIsChecked() throws IOException {
        throw new IOException("whatever");
    }

    public static void handlesTheException() {
        try {
            throwsIOExceptionWhichIsChecked();
        } catch (IOException exception) {
            System.out.println("Caught an IOException!");
        }
    }

    public static void propagatesTheException() throws IOException {
        throwsIOExceptionWhichIsChecked();
    }   
}
```

### So what is an Unhandled Exception?
In contrast, an _Unhandled Exception_ is not _required_ to appear in the function signature of a method.  They all extend from `RuntimeException`, meaning they otherwise compile and look to the compiler that the program is correct, but given certain inputs it may fail.

When using third party packages, you have no guarantees on whether it may throw an unhandled exception or not.

Most common Unhandled Exceptions:
* `NullPointerException`
* `ArrayIndexOutofBound`
* `IllegalArgumentException`
* `IllegalStateException`
* `NumberFormatException`
* `ArithmeticException`


### TL;dr

1. Putting `RuntimeException` and its ilk in a `throws` statement doesn't do anything other than provide documentation to method users.
1. You have no guarantees about whether a third party package might throw a `RuntimeException` or not, you'd have to read their code to know.
1. Make sure you know whether errors you are using extend from `RuntimeException` or not, they are treated very differently by the compiler.
1. Checked exceptions must be handled in one of the two ways explained above.
