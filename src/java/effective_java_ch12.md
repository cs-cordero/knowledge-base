# Serialization

## Prefer alternatives to Java serialization

Java serialization has security issues that were transformed into serious exploits.  Its _attack surface_ is too big to protect and is constantly growing.

Object graphs are deserialized by invoking `readObject` on an `ObjectInputStream`, which is essentially a magic constructor that can instantiate objects of any type on the class path, so long as that object implements the `Serializable` interface.
* In the process of deserializing the byte stream, this magic constructor can execute code from any of these types, therefore the code for _all_ serializable types is part of the attack surface.

**The best way to avoid serialization exploits is to never deserialize anything.**  There is no reason to use Java serialization in any new system you write.

Other mechanisms provide a way to translate between bytes and objects.  They are better in that they're far simpler than Java serialization because they don't support automatic serialization and deserialization of arbitrary object graphs.  In general, they support structured data objects consisting of attribute-value pairs.
* JSON
* Protobuf

If you can't avoid Java serialization entirely, i.e., you're working in a legacy codebase, the next best alternative is to **never deserialize untrusted data**.

A third alternative, worst than the first two options above, is to use object deserialization filtering `java.io.ObjectInputFilter`, which allows you to apply a filter to data streams before deserialization.
* If you do this, prefer a whilelist filter to blacklist filter.

## Implement `Serializable` with great caution

The long term costs of making a class `implements Serializable` are substantial.

**Implementing `Serializable` decreases the flexibility to change the implementation once it has been released**.  This is because the class's byte-stream encoding (or _serialized form_) becomes part of its exported API.
* You are expected to support the serialized form forever.
* As a result, if you don't design a _custom serialized form_, the default means that the class's `private` and `package-private` instance fields become part of the exported API.
* Changing internal representations is a breaking change because clients who attempt to serialize an instance of the old version will fail to deserialize it using the new version.

If you must make a class serializable, you should design a high-quality serialized form that you can support for the long-haul.

**Implementing `Serializable` increases the likelihood of bugs and security holes**.  Serialization is an _extralinguistic mechanism_ for creating objects that do not use constructors.  Deserialization is therefore a "hidden constructor" and it is easy to forget that you have to maintain all of its guarantees associated with deserialization.

**Implementing `Serializable` increases the testing burden for any new version of a class.**  Since you must always make sure that the instance can serialize and deserialize in the face of any change.

Classes designed for inheritance and interfaces should rarely implement `Serializable`.

## Consider using a custom serialized form

**Do not accept the default serialized form without first considering whether it is appropriate**.  The default serialized form is likely appropriate if an object's physical representation is identical to its logical content.

If the object's physical representation differs substantially from its logical data:
* It permanently ties the exported API (including `private` fields) to the current internal representation
* It can consume excessive space
* It can consume excessive time
* It can cause stack overflows.

**Even if you decide the default serialized form is appropriate, always provide a `readObject` method to ensure invariants and security**.  For your docstrings on fields, add the `@serial` tag, which tells Javadoc to place the documentation on a special page that documents erialized forms.

Instead of this:

```java
// Logically, this is a sequence of strings.
// Physically, it represents the sequence as a doubly linked list.
public final class StringList implements Serializable {
    private int size = 0;
    private Entry head = null;

    private static class Entry implements Serializable {
        String data;
        Entry next;
        Entry previous;
    }
}
```

This is more reasonable (but you should still avoid Java serialization):

```java
public final class StringList implements Serializable {
    private transient int size = 0;
    private transient Entry head = null;

    // No longer Serializable
    private static class Entry {
        String data;
        Entry next;
        Entry previous;
    }

    /**
     * Serialize this {@code StringList} instance.
     *
     * @serialData The size of the list (the number of strings
     * it contains) is emitted ({@code int}), followed by all of
     * its elements (each a {@code String}), in the proper
     * sequence
     */
    private void writeObject(ObjectInputStream s) throws IOException {
        s.defaultWriteObject();
        s.writeInt(size);

        for (Entry e = head; e != null; e = e.next) {
            s.writeObject(e.data);
        }
    }

    private void readObject(ObjectInputStream s) throws IOException {
        s.defaultReadObject();
        int numElements = s.readInt();

        for (int i = 0; i < numElements; i++) {
            add((String) s.readObject());
        }
    }
}
```

Whether or not you accept the default serialized form, every instant field not labeled `transient` will be serialized when the `defaultWriteObject` method is invoked.  Therefore, every instance field that can be declared `transient` should be, included derived fields.
* Remember that these `transient` fields will be initialized to their _default values_ when an instance is deserialized.  If thes values are unacceptable, you must provide a `readObject` method that invokes `defaultReadObject` then restores transient fields to acceptable values.

You should always declare an explicit serial version UID in every serializable class you write.  Example:

```java
private static final long serialVersionUID = randomLongValue;
```

It doesn't matter what value you choose for `randomLongValue`, you can pick a number from thin air.

This serial version UID requires bytes you want to deserialize to have this same value.  If you ever want to make a new version of a class incompatible with existing versions, you merely need to change the serial version UID, which will cause an `InvalidClassException` upon deserialization.

## Write `readObject` methods defensively

If you have a class that uses strict control over its constructor, getters, and setters to maintain object attribute invariants, adding `implements Serializable` adds another (hidden, if you don't implement `readObject`) constructor that could ruin those invariants.

`readObject` is effectively a constructor, albeit one that takes a byte stream as its sole parameter, and so it must also defensively construct itself.
* You should call `defaultReadObject`, then check for invariants, throwing `InvalidObjectException` to prevent deserialization from completing.
* It is critical to defensively copy any field containing an object reference that a client must not possess.

## For instance control, prefer enum types to `readResolve`

Deserialization adds additional wrinkles if you're trying to create an instance-controlled type.  Without handling it, deserialization could create additional instances beyond what you were expecting.

Single-element enum types are preferred.  Java guarantees that there can be no instances besides the declared constants.

```java
public enum Elvis {
    INSTANCE;

    private String[] favoriteSongs = { "Hound Dog", "Heartbreak Hotel" };

    public void printFavorites() {
        System.out.println(Arrays.toString(favoriteSongs));
    }
}
```

If you need a class to be both serializable AND instance-controlled, BUT you cannot use an enum type, then you must provide a `readResolve` method and ensure all the class's instance fields are either primitive or `transient`.

**If you depend on `readResolve` for instance control, all instance fields with object reference types _must_ be declared `transient`**.
* If you place `readResolve` on a final class, it should be `private`.
* If you place `readResolve` on a nonfinal class, you must carefully consider its accessibility. If private, it will not apply to any subpackages.  If package-private, it will only apply to classes in teh same package.  If it is protected or public, it will apply to all classes that do not override it.

## Consider serialization proxies instead of serialized instances

The _serialization proxy pattern_ reduces the risks of implementing `Serializable`.
1. Design a private static nested class that concisely represents the logical state of an instance of the enclosing class.
2. The private static nested class is known as the _serialization proxy_.  It should have a single constructor whose parameter type is the enclosing type.
3. This single constructor merely copies data from its argument, does not need to do any consistency checking or defensive copying.
4. Both the enclosing class and its serialization proxy must be declared to implement `Serializable`.


```java
// Example serialization proxy
class Period {

    private static class SerializationProxy implements Serializable {
        private final Date start;
        private final Date end;

        SerializationProxy(Period p) {
            this.start = p.start;
            this.end = p.end;
        }

        private static final long serialVersionUID =
            234098243823485285L;

        private Object readResolve() {
            return new Period(start, end); // Uses public constructor
        }
    }

    private Object writeReplace() {
        return new SerializationProxy(this);
    }

    private void readObject(ObjectInputStream stream) throws InvalidObjectException {
        throw new InvalidObjectException("Proxy required");
    }
}
```

This `writeReplace` generates a `SerializationProxy` instance instead of the an instance of the actual class.  The serialization system will never generate a serialized instance of the enclosing class.

An attacker may try to fabricate a serialized instance of the enclosing class so the enclosing `readObject` throws an exception to force the usage of the proxy.

The proxy gets its own `readObject` that returns an instance of the outer class.
