# OSI Model

The OSI model was created by the ISO. It's based on the concept of splitting up a communication system into 7 layers, each one stacked upon the last.

### Layer 7: Application

* The only layer that directly interacts with data from the user.
* Client software applications (browsers, email clients) are **NOT** part of the application layer.
* The application layer is responsible for protocols and data manipulation, including HTTP and SMTP.

### Layer 6: Presentation

* Prepares data so that it can be used by the application layer.
* Responsible for translation, encryption, and compression of data.
* If two communicating devices are using different encoding methods, layer 6 translates incoming data into a syntax that the receiving device can understand.
* Over an encrypted connection. layer 6 is responsible for adding encryption on the sender's end and decrypting on the receiver's end.
* Also will compress data received from layer 7 before sending it to layer 5.

### Layer 5: Session

* Responsible for opening and closing communication between two devices.
* Time between open and close is called the session.
* Also synchronizes data transfers with checkpoints, so that if a 100MB is being transferred and certain packets are lost, the network has a way to resume the transfer at the last checkpoint.

### Layer 4: Transport

* Responsible for end-to-end communication between two devices.
* Takes data from the session layer and breaks it up into chunks called segments before sending it to layer 3.
* The transport layer on the receiving device is responsible for reassembling segments.
* Responsible for flow control and error control.
  * Flow control is ensuring that a sender with a fast connection doesn't overwhelm a receiver with a slow connection.

### Layer 3: Network

* Facilitates the data transfer between two different networks.  If devices are on the same network, then this layer is unnecessary.
* Network layer takes segments and breaks them up further, into packets, on the sender's device, then reassembles them on the receiving device.
* This layer is also responsible for finding the best physical path for data to reach its destination (aka routing).

### Layer 2: Data Link

* Similar to network layer, except it facilitates data transfers between two devices on the SAME network.
* Takes packets from the network layer and breaks them into even smaller pieces called frames.
* Also responsible for flow control and intra-network communication. (Transport layer only does flow control for inter-network comunications.)

### Layer 1: Physical

* Includes the physical equipment involved in the data transfer, i.e., cables and switches.
* Frames are chopped up to its smallest unit - a bit stream.  The physical layer of both devices must agree on a signal convention so that the bits can be distinguished on both devices (i.e., a 1 is a 1 and a 0 is a 0).







