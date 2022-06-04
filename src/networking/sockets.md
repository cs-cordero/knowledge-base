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

