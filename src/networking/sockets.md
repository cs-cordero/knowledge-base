# Socket Programming

When Unix programs do any sort of I/O, they do it by reading or writing to a file descriptor.

A **file descriptor** is an _integer_ associated with an open **file**.

A **file** can be a network connection, a FIFO, a pipe, a terminal, a real on-the-disk file, or just about anything else (including a socket).

A **socket** is just a special kind of file in a UNIX operating system.

There are many kinds of sockets:
* **Internet Socket**.  DARPA Internet addresses
* **Unix Socket**.  Path names on a local node
* **X.25 Socket**.  X.25 was an old communication standard (associated with Dial-Up)

When you want to communicate with another program over the Internet, you're going to do it through a file descriptor.

You can attain a file descriptor for network communication by making a system call to `socket()`.  You can then communicate through it using specialized `send()` and `recv()` socket calls.  You can also use `read()` and `write()` (since it's a file), but `send()` and `recv()` grant you better control.

There are many types of Internet socket, of which we care about two:
* **Stream Sockets**.  Often referred to as `SOCK_STREAM`.
    * These are reliable two-way connected communication streams.
    * Uses the Internet Protocol (IP) for Internet routing.  IP is not generally responsible for data integrity.
    * Uses a protocol called the Transmission Control Protocol (TCP).
    * Placing two items in the order "1,2" in the socket will arrive at the opposite end in the same "1,2" order.
* **Datagram Sockets**. Often referred to as `SOCK_DGRAM`.  Sometimes called "connectionless sockets".
    * Placing items in a datagram socket _may_ arrive.  If it does arrive, it may arrive out of order.  If it arrives, data _within_ a packet will be error-free.
    * Uses the Internet Protocol (IP) for Internet routing.
    * Uses a protocol called the User Datagram Protocol (UDP).
    * You don't have to maintain an open connection, you just build a packet, slap an IP header on it with destination infomration and send it out.  No connection needed.

`telnet` uses stream sockets. Web browsers use HTTP which is a protocol that uses stream sockets to get pages.

`tftp`, a program similar to FTP uses datagram sockets.  `dhcpcd`, a DHCP client uses datagram sockets.  Multiplayer games, streaming audio, video conferencing also use datagram sockets.

Programs like `tftp` have their own protocols built on top of UDP.  You might expect it to have one, because if `tftp` is like FTP in which they send binary applications over a network, it is probably important that all of the data is ultimately received on the opposite end.  For `tftp` in particular, its protocol on top of UDP specifies that the recipient has to send an ACK for each packet.  If the sender doesn't get an ACK, it will re-transmit the packet until it finally _does_ receive an ACK.

Some programs, like games, audio, or video, can safely just ignore dropped packets and/or cleverly compensate for them.  Games might rubber-band player positions while waiting for a packet to be received.

UDP is faster than TCP.

## Data Encapsulation

When multiple protocols are involved with the delivery of a packet of data, the data is encapsulated again-and-again by the different protocols involved.  Let's take the `tftp` program as an example.

* Ethernet
    * IP
        * UDP
            * TFTP
                * **Data**

Looking at this nested list above, we start with the **Data**.

The data is taken as a black box of data.  `tftp` and its protocol will wrap the data by adding a header (protocols may, but rarely, also include a footer).

Then the whole thing, TFTP header included, is encapsulated again by the next protocol (UDP) which adds _its own_ header and/or footer.

Then that embiggened chunk gets encapsulated again by the next protocol and so on until the final protocol on the hardware on the phyiscal layer (say, Ethernet or Wifi).  The entire chunk is now referred to as a **Packet**.

Once the recipipent computer receives the packet, the packet is unwrapped outside-in by the receiving protocols by stripping the headers until it gets down to the data.


## The Layered Network Model (aka ISO/OSI)

This is the network model in a full-blown manner.  It is designed to be incredibly generic.  It can be so generic it may be possible to use it to define non-network related things.

* Application
* Presentation
* Session
* Transport
* Network
* Data Link
* Physical

A (tighter) layered model more consistent with Unix might be:

* Application Layer (`telnet`, `ftp`, etc.)
* Host-to-Host Transport Layer (TCP, UDP)
* Internet Layer (IP and routing)
* Network Access Layer (Ethernet, WiFi, etc.)


## Sending Data as Packets in Practice

All the data encapsulation and characters in the layered network model are involved for _every_ packet sent over the network.  As a programmer, if you've got a stream socket, all you have to do is `send()` the data out.  For datagram sockets, all you ahve to do is encapsulate the packet in a method of your choosing and call `sendto()`.

The kernel builds the Transport Layer and Internet Layer for you.  The hardware does the Network Access Layer for you.
packet

## IP addresses

IPv4 was a protocol that identified addresses using dots and numbers.  In summary, they were composed of 4 bytes, encoding 32-bits of data.

IPv6 is the most recent version of IP.  It encodes addresses as eight groups of four hexadecimal digits each, separated by colons, e.g.:  `2001:0db8:0000:0000:0000:8a2e:0370:7334`.

`127.0.0.1` (IPv4) and `::1` (IPv6) are known as the **loopback address**.  It always means "this machine I'm running on now".

### Subnets

It can be convenient to declare for a given IP address that all numbers up through a certian bit is the _network portion_ and the remainder is the _host portion_.

> Example:
> 
> You might have `192.0.2.12`, we could say that the first three bytes are the network and the last byte is the host.
>
> Put another way, the above address refers to host `12` on the network `192.0.2.0`.

The subnet is identified using a `netmask`, which is an IP address that is bitwise-and'ed against your IP address to find the network portion of the address.  For example, a netmask could be `255.255.255.0`.  This identifies that the first three bytes refer to the network portion of the address.
* The netmask may specify an arbitrary number of bits not just 8, 16, or 24 for the network. (This was a concession to the eventual depletion of IP addresses).
* Netmasks continue to always be a contiguous bunch of 1-bits followed by all 0s.  They don't mix.
* A netmask my also be notated as the count of bits after the address delimited by a slash, i.e.: `192.0.2.12/30` indicates that the first 30 bits of the address is the network.

### Port Number

If IP addresses are street addresses to a hotel, port numbers are the room numbers.

If you want a single computer to handle incoming mail _and_ web services, you need port numbers to differentiate between the two on a computer which has a single IP address.

Different services have well-known port numbers, listed by IANA [here](https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml).  For a given computer, if it's a Unix box, then it'll be listed in `/etc/services`
* HTTP uses port 80.
* `telnet` uses port 23.
* SMTP uses port 25.
* Doom uses port 666.

### Byte Order (Endian)

When a number is stored with multiple bytes, computers have to decide how to store that number: Big-Endian or Little-Endian.

**Host Byte Order**.  The endian-ness of the host computer.  Program writers who are writing portable code can't rely on this being strictly Big-Endian or Little-Endian.

**Network Byte Order**.  Strictly Big-Endian.

For `short`s (2-bytes) and `long`s (4-bytes), you can convert the endian-ness of the number using a set of system calls:

| Function | Description |
|:---:|:---:|
|`htons()`|`host` to `network` `short`|
|`htonl()`|`host` to `network` `long`|
|`ntohs()`|`network` to `host` `short`|
|`ntohl()`|`network` to `host` `long`|


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
