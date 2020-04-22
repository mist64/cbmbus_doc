# Commodore Peripheral Bus: Part 6: JiffyDOS

In the [series about the variants of the Commodore Peripheral Bus family](https://www.pagetable.com/?p=1018), this article covers the third party "JiffyDOS" extension to the Commodore Serial Bus protocol, which shipped as a ROM patch for computers and drives, replacing the byte transmission protocol of Standard Serial by using the clock and data lines in a more efficient way.


![](docs/cbmbus/jiffydos_layers.png =291x241)

<hr/>

> **_NOTE:_**  I am releasing one part every once in a while, at which time links will be added to the bullet points below. The articles will also be announced on the Twitter account <a href="https://twitter.com/pagetable">@pagetable</a> and the Mastodon account <a href="https://mastodon.social/@pagetable">@pagetable&#64;mastodon.social</a>.

<hr/>

* [Part 0: Overview and Introduction](https://www.pagetable.com/?p=1018)
* [Part 1: IEEE-488](https://www.pagetable.com/?p=1023) [PET/CBM Series; 1977]
* [Part 2: The TALK/LISTEN Layer](https://www.pagetable.com/?p=1031)
* [Part 3: The Commodore DOS Layer](https://www.pagetable.com/?p=1038)
* [Part 4: Standard Serial (IEC)](https://www.pagetable.com/?p=1135) [VIC-20, C64; 1981]
* [Part 5: TCBM](https://www.pagetable.com/?p=1324) [C16, C116, Plus/4; 1984]
* **Part 6: JiffyDOS [1986]** ← *this article*
* Part 7: Fast Serial [C128; 1985] *(coming soon)*
* Part 8: CBDOS [C65; 1991] *(coming soon)*

# History and Development

* history
	* Mark Fellows, 1985
	* ROM replacements
	* available for all Commodore computers and practically all IEC disk drives
	* supported by modern devices like SD2IEC
	* as of 2020, JiffyDOS ROMs for all supported computers are drives are still commercially available
* software-only faster protocol

# Overview

* same connector, same wires (ATN, CLK, DATA)
* fully backwards compatible, any combination of JD and non-JD controller and devices
* 10x faster point-to-point byte stream transmission protocol if controller and device support it
* ATN command layer identical, using the slow byte transmission protocol

* secret handshake between controller and device during TALK/LISTEN command to detect whether both sides support JD
* if supported on both sides, faster byte send protocol during TALK and LISTEN sessions
* point-to-point between controller and one device; does not allow one-to-many

* new byte send protocol
	* two-way handshake after every byte
	* transmission of byte timing based: 2 bits at a time, every 11-13 µs
* controller must guarantee 75 µs window without interruptions
* device must be real-time

* original protocol has a "no slower than" requirement
* JiffyDOS has a "no faster or slower than" requirement
* within 7 µs windows, receiver must be able to read two bits every 10 µs

* supports EOI and timeout flags (Consistent with IEEE-488, this event is called "EOI", "End Or Identify".)
 
* backwards compatibility
	* devices that can speak JiffyDOS and devices that can't can share the same bus
	* all devices that speak JiffyDOS also speak the original protocol
	* -> ok if a controller and one device speak JiffyDOS, while others are passive
	* -> if not everyone of the two participands can speak JiffyDOS, they will revert to the original protocol
	* commands from the controller have to be received by all devices
	* -> commands have to use the regular protocol


## Detection

* controller delays 400 µs (at least 218 µs) between bit 6 and 7 of LISTEN or TALK commands
* addressed device pulls DATA for 100 µs
* protocol resumes with bit 7
* -> controller and device will speak JD protocol in this TALK/LISTEN session

![](docs/cbmbus/jiffydos-detection.png =601x301)

## Byte Transfer

* byte transmission starts out and ends with the sender holding CLK and the receiver holding DATA
	* just like with the original protocol
	* -> interoperability
* not symmetric
	* controller has to signal t=0 because of the C64's tricky timing
	* device is real-time capable, C64 is not
* dedicated "LOAD" protocol does away with the two-way-handshake, makes it one-way, and adds a device-to-host "escape" flag to switch to a different phase of the protocol

### Sending Bytes

When the controller sends data to the device, it transmits two bits at a time roughly every 13 µs using the CLK and DATA lines, with no handshake. For each byte, the device signals that it is ready to receive, followed by the controller signaling it about to start the transmission, thus starting the timing critical window of about 75 µs.

The following animation shows a byte being sent from the controller to the device.

![](docs/cbmbus/jiffydos-send.gif =601x344)

Let's go through it step by step:

#### 0: Initial State
![](docs/cbmbus/jiffydos-13.png =601x131)

Since the JiffyDOS protocol integrates with the Standard Serial protocol, its initial state must match the state of the parent protocol at this point: After the "LISTEN"/"SECOND" command, the sender (the controller) is holding the CLK line and the receiver (the device) is holding the DATA line.

#### 1: Device is ready to receive
![](docs/cbmbus/jiffydos-14.png =601x131)

Transmission of a new byte is initiated by the device, indicating that it is ready to receive by releasing the DATA line.

#### 2: Controller sends the "Go!" signal
![](docs/cbmbus/jiffydos-15.png =601x131)

Triggered by DATA being 1, the controller indicates that it will start sending a data byte by releasing the CLK line - this is the "Go!" signal. During the transmission of the byte, both lines will be owned by the controller, and the sequence of steps is purely based on timing; there are no ACK signals.

#### 3: Controller puts data bits #4 and #5 onto wires
![](docs/cbmbus/jiffydos-16.png =601x131)

First, the controller puts the first pair of data bits onto the two wires:

* CLK = #4
* DATA = #5

The wires have to be valid between 14 and 21 µs after the "Go!" signal.

The bits are sent in the order 4-5/6-7/3-1/2-0 - this is an optimization based on the C64/1541 port layout minimizing shifts.

#### 4: Controller puts data bits #6 and #7 onto wires
![](docs/cbmbus/jiffydos-17.png =601x131)

The controller puts the second pair of data bits onto the two wires:

* CLK = #6
* DATA = #7

The wires have to be valid between 27 and 34 µs after the "Go!" signal.

#### 5: Controller puts data bits #3 and #1 onto wires
![](docs/cbmbus/jiffydos-18.png =601x131)

The controller puts the third pair of data bits onto the two wires:

* CLK = #3
* DATA = #1

The wires have to be valid between 38 and 45 µs after the "Go!" signal.

#### 6: Controller puts data bits #2 and #0 onto wires
![](docs/cbmbus/jiffydos-19.png =601x131)

The controller puts the final pair of data bits onto the two wires:

* CLK = #2
* DATA = #0

The wires have to be valid between 51 and 58 µs after the "Go!" signal.

#### 7: Controller signals no EOI, and is now busy again
![](docs/cbmbus/jiffydos-20.png =601x131)

Still timing-based, the controller releases the DATA line so it can be operated by the device again, and pulls the CLK line, signaling that there is no EOI. A pulled CLK line also means that the controller is now busy again, so the transmission of the next data byte cannot start.

The wires have to be valid no later than 64 µs after the "Go!" signal.

#### 8: Device is now busy again
![](docs/cbmbus/jiffydos-21.png =601x131)

Also timing-based, the device pulls the DATA line as soon as it has read the CLK line. This is the same as the initial state, so the protocol continues with step 1 for the next data byte.

Of course, the controller can alternatively pull ATN at this point, and send an "UNLISTEN" command, for example.

### End of Stream (Send)

An EOI event is signaled through the CLK line in step 7.

#### 7a: Controller signals EOI status
![](docs/cbmbus/jiffydos-10.png =601x131)

If there is an EOI, instead of pulling the CLK line at 64 µs, the controller keeps CLK released at least between 64 µs and 71 µs.

#### 7b: Controller is now busy again
![](docs/cbmbus/jiffydos-11.png =601x131)

At 71 µs, the controller can now pull the CLK line, signaling that it is busy again and transmission of the next data byte cannot start.

![](docs/cbmbus/jiffydos-send.png =601x301)

### Receiving Bytes

When the device sends data to the controller, it transmits two bits at a time roughly every 11 µs using the CLK and DATA lines, with no handshake. For each byte, the device signals that it is ready to send, followed by the controller signaling the device to start the transmission, thus starting the timing critical window of about 55 µs.

Compared to the byte send case, the ownership of the CLK and DATA lines outside the core data transmission is swapped, but it is the controller that sends the "Go!" signal in both cases.

The following animation shows a byte being received by the controller from the device.

![](docs/cbmbus/jiffydos-receive.gif =601x344)

Again, let's go through it step by step:

#### 0: Initial State
![](docs/cbmbus/jiffydos-01.png =601x131)

Like in the "send" case, the initial state is the same is with Standard Serial, since this is the natural state after the "LISTEN"/"SECOND" command: The sender (the device) is holding the CLK line and the receiver (the controller) is holding the DATA line.

#### 1: Device is ready to send
![](docs/cbmbus/jiffydos-02.png =601x131)

Transmission of a new byte is initiated by the device, indicating that it is ready to send by releasing the CLK line.

#### 2: Controller sends the "Go!" signal
![](docs/cbmbus/jiffydos-03.png =601x131)

Triggered by CLK being 1, the controller indicates that the device must now start sending a data byte by releasing the DATA line - this is the "Go!" signal. During the transmission of the byte, both lines will be owned by the device, and the sequence of steps is purely based on timing; there are no ACK signals.

#### 3: Device puts data bits #0 and #1 onto wires
![](docs/cbmbus/jiffydos-04.png =601x131)

First, the device puts the first pair of data bits onto the two wires:

* CLK = #0
* DATA = #1

The wires have to be valid 15 µs after the "Go!" signal.

In the receive case, the bits are sent in the order 0-1/2-3/4-5/6-7.

#### 4: Device puts data bits #2 and #3 onto wires
![](docs/cbmbus/jiffydos-05.png =601x131)

The device puts the second pair of data bits onto the two wires:

* CLK = #2
* DATA = #3

The wires have to be valid 25 µs after the "Go!" signal.

#### 5: Device puts data bits #4 and #5 onto wires
![](docs/cbmbus/jiffydos-06.png =601x131)

The device puts the third pair of data bits onto the two wires:

* CLK = #4
* DATA = #5

The wires have to be valid 36 µs after the "Go!" signal.

#### 6: Device puts data bits #6 and #7 onto wires
![](docs/cbmbus/jiffydos-07.png =601x131)

The device puts the final pair of data bits onto the two wires:

* CLK = #6
* DATA = #7

The wires have to be valid 47 µs after the "Go!" signal.

#### 7: Device signals no EOI, and is now busy again
![](docs/cbmbus/jiffydos-08.png =601x131)

Still timing-based, the device releases the DATA line so it can be operated by the controller again, and pulls the CLK line, signaling that there is no EOI. A pulled CLK line also means that the device is now busy again, so the transmission of the next byte cannot start.

The CLK line has to be pulled no later than 58 µs after the "Go!" signal.

#### 8: Controller is now busy again
![](docs/cbmbus/jiffydos-09.png =601x131)

Also timing-based, the controller pulls the DATA line as soon as it has read the CLK line. This is the same as the initial state, so the protocol continues with step 1 for the next data byte.

As with the send case, the controller can alternatively pull ATN at this point, and send an "UNTALK" command, for example.

### End of Stream (Receive)

An EOI event is signaled through the CLK line in step 7.

#### 7a: Device signals EOI status
![](docs/cbmbus/jiffydos-10.png =601x131)

If there is an EOI, instead of pulling the CLK line at 58 µs, the device keeps CLK released at least between 58 µs and 71 µs.

#### 7b: Device is now busy again
![](docs/cbmbus/jiffydos-11.png =601x131)

At 71 µs, the device can now pull the CLK line, signaling that it is busy again and transmission of the next data byte cannot start.

![](docs/cbmbus/jiffydos-receive.png =601x301)

### LOAD

* 1: inter-block
* 2: block transmission
	* one-way handshake
		* device is assumed to always be ready as long as there is data immediately available
		* i.e. within a block
	* device can signal end of block

* Timing: device holds timed values for at least for a total of 3 µs around the key time.

	(1541: 7-14 -> 17-24; 14-17 = 15.5 +/ 1.5 VS 15)
	(1541: 17-24 -> 28-35; 24-28 = 26 +- 2 VS 25)
	(1541: 28-35 -> 38-45; 35-38 = 36.5 +- 1.5 VS 36)
	(1541: 38-45 -> X; 45- VS 47)


#### 0: Initial State, start of inter-block signaling
![](docs/cbmbus/jiffydos-25.png =601x131)

Since the JiffyDOS LOAD protocol integrates with the standard serial protocol, its initial state must match the state of the parent protocol at this point: After the "TALK" command, the sender (the device) is holding the CLK line and the receiver (the controller) is holding the DATA line.

This is the "inter-block" phase of the protocol, where the device tells the controller whether more data is about to be transmitted, or whether this is the end of the stream or an error has occured. This part is purely-timing based: The device sends flags to the controller with a certain timing, and does not wait for the controller to be ready or to ACK anything.

#### 1: Controller clears DATA wire (not a signal)
![](docs/cbmbus/jiffydos-26.png =601x131)

First, the controller releases the DATA wire. This is not a signal for the device, but necessary so that the controller can read the DATA line in step 3 - for the next few steps, the device will send timed information on both wires. The controller can therefore choose to release the wire as late as in step 3, just before reading it.

#### 2: Device puts "end of data?" flag onto DATA
![](docs/cbmbus/jiffydos-27.png =601x131)

Next, the device puts a flag whether there is more data to be transmitted onto the DATA line. 1 means there is more data, while 0 means that there is no more data: the end of the stream has been reached or there has been an error.

Let's continue with "more data".

#### 3: Device signals flag is valid – hold for 80 µs
![](docs/cbmbus/jiffydos-28.png =601x131)

To signal that the state of the DATA line is now valid, the device releases the CLK line and holds this state for 80 µs.

#### 4: Device clears DATA wire
![](docs/cbmbus/jiffydos-29.png =601x131)

After the device has indicated that there is more data, the protocol goes into the "block data" phase.

First, the device releases DATA in order to clear the wire, so that the controller can use it later.

#### 5: Device puts "end of block?" flag onto CLK
![](docs/cbmbus/jiffydos-30.png =601x131)

At the beginning of the loop for each data byte, the device signals whether the end of the block has been reached.

If this is the end of the block, the device sets CLK to 1. If there are more bytes to be transmitted within this block, it sets CLK to 0.

The value of CLK has to be valid no later than 25 µs after step 4.

#### 6: Controller signals "Go!" for 12+ µs
![](docs/cbmbus/jiffydos-31.png =601x131)

Triggered by DATA being 0, but no earlier than CLK being valid from the step before, the controller pulls the DATA line for at least 12 µs, telling the device to immediately start the transmission of the 8 data bits.

#### 7: Controller clears DATA wire (not a signal)
![](docs/cbmbus/jiffydos-32.png =601x131)

In order to be able to read the data bits from both DATA and CLK in the next steps, the controller releases DATA before it reads the first pair of bits. Like in step 0, this is not a signal for the device.

#### 8: Device puts data bits #0 and #1 onto wires
![](docs/cbmbus/jiffydos-33.png =601x131)

Triggered by DATA being 1 (step 6), the device puts the first two data bits onto the two wires:

* CLK = NOT #0
* DATA = NOT #1

The bits are sent starting with the least significant bit, and all bit values are inverted.

The controller reads the wires exactly 15 µs after setting DATA to 1 (step 6).

#### 9: Device puts data bits #2 and #3 onto wires
![](docs/cbmbus/jiffydos-34.png =601x131)

Based solely on timing, the device puts the second pair of data bits onto the wires:

* CLK = NOT #2
* DATA = NOT #3

The controller reads the wires exactly 25 µs after setting DATA to 1 (step 6).

#### 10: Device puts data bits #4 and #5 onto wires
![](docs/cbmbus/jiffydos-35.png =601x131)

The device puts the third pair of data bits onto the wires:

* CLK = NOT #4
* DATA = NOT #5

The controller reads the wires exactly 36 µs after setting DATA to 1 (step 6).

#### 11: Device puts data bits #6 and #7 onto wires
![](docs/cbmbus/jiffydos-36.png =601x131)

The device puts the final pair of data bits onto the wires:

* CLK = NOT #6
* DATA = NOT #7

The controller reads the wires exactly 47 µs after setting DATA to 1 (step 6).

#### 4': Device clears DATA wire
![](docs/cbmbus/jiffydos-37.png =601x131)

At this point, the protocol loops back to step 4, the first step of the "block data" phase.

First, the device clears the DATA wire again (which contained the last bit of the previous data byte), so the controller can use it to signal "Go!" in step 6. The CLK wire still contains a bit from the last data byte.

#### 5': Device puts "end of block?" flag onto CLK
![](docs/cbmbus/jiffydos-38.png =601x131)

Let's assume there is one more byte in this block, so the device sets CLK ("end of block?") to 0.

Again, the validity is based purely on timing: At the earliest, the controller reads the CLK wire 84 µs after the previous "Go!" signal, but may read it as late as it chooses - the device will hold it until the controller signals "Go!" again (step 6).

#### 6-11, 4': Repeat for next byte

The second byte is transmitted the same way as before.

#### 5a: Device puts "end of block?" flag onto CLK
![](docs/cbmbus/jiffydos-39.png =601x131)

In the third iteration of the "block data" loop, let's assume the end of the block has been reached, so the device now sets CLK ("end of block?") to 1.

#### 2a: Device puts "end of data?" flag onto DATA
![](docs/cbmbus/jiffydos-40.png =601x131)

The protocol now jumps back to the "inter-block" phase.

Let's assume there are no more blocks to be transmitted, so the device sets the DATA line ("more blocks?") to 0.

#### 3a: Device signals flag is valid – hold for 80 µs
![](docs/cbmbus/jiffydos-41.png =601x131)

To signal that the contents of the DATA line are valid, the device releases the CLK line, and holds this state for at least 80 µs.


#### 3b: Device signals EOI within 1100 µs – hold for 100 µs
![](docs/cbmbus/jiffydos-42.png =601x131)

To indicate that this is an EOI event, that is, the regular end of the stream, the device has to pull CLK and hold it for 100 µs no later than 1100 µs after releasing CLK in the previous step.

### Canceling

* ATN in any state will be respected by the device

## Discussion

### No formal specification

* compliance means staying within the timing bounds of all existing implementations

### C64/1541-specific

* bit order and negation based on C64/1541 ports
	* send case: high nybble decoded by device, low-nybble encoded by controller
	* receive case: encoded by device
* all non-C64/1541 devices are faster, so they can handle the overhead
* not symmetric, can't do one-to-many
	* but that's not solvable if it's always the C64 that needs to initiate a byte transmission
	* in general: one-to-many not possible if there are ready-*windows*
	* if all participants have to say they are ready, by the time the last participant is ready, one of the other participant may not be ready any more

### Protocol not optimal

* 37 µs slows down everything
* device should prepare the data before, then signal that it's ready
* this allows faster implementations

* then again, only the LOAD case really matters...

* 2 bits can be done in 8 µs instead of 10/11
* or even faster: LDA zp, STA $1800, LDA zp, STA $1800; LDA $DD00, PHA, LDA $DD00, PHA...
* or the standard LDA $DD00, LSR, LSR, EOR $DD00
* C128/1581 (both 2 MHz) suffer from delays everywhere
* even if C64/1541 have to do pre-/post-processing, they could be as fast by shifting complexity out of the transmission loop
* so C128/1571 would benefit from the faster loop

* 10/10/11/10/11 is ugly - check with other implementations

### LOAD protocol not suitable for IRQs

* once-per-block status transmission doesn't wait for host
* host must be in a tight loop with IRQs off

### Layer violation

* technically, signaling specifically on TALK and LISTEN violates the layering
* some implementation signal on all bytes under ATN, which is cleaner
* but it's spec-compliant to send the TALK/LISTEN secondary will be sent without the signal
* so device that turns Jiffy on/off based on whether last ATN byte had signal or not would not work right
* -> it's okay to send the signal with every ATN, but the device must detect it only on TALK/LISTEN

### Error handling?

### Conclusion

...

### Next Up

Part 7 of the series of articles on the Commodore Peripheral Bus family will cover Commodore's "Fast Serial" protocol on layer 2, which is supported on the C128 and C65 as well as the 1571 and 1581 drives. Like JiffyDOS, it replaces the byte transmission protocol of Standard Serial with a faster version that uses a previously unused wire in the serial cable.

> This article series is an Open Source project. Corrections, clarifications and additions are **highly** appreciated. I will regularly update the articles from the repository at [https://github.com/mist64/cbmbus_doc](https://github.com/mist64/cbmbus_doc).


# References

* http://www.nlq.de
* https://web.archive.org/web/20130128220953/http://hem.passagen.se/harlekin/download.htm
* https://sites.google.com/site/h2obsession/CBM/C128/JiffySoft128
* https://www.c64-wiki.com/wiki/SJLOAD
* http://www.baltissen.org/newhtm/sourcecodes.htm
* https://retrocomputing.stackexchange.com/questions/12755/what-is-the-c64-disk-drive-jiffy-protocol
* https://github.com/rkrajnc/sd2iec/blob/07b7731d3d10ae87c45c29787856b9fee594ce16/src/iec.c
* https://github.com/rkrajnc/sd2iec/blob/master/src/lpc17xx/fastloader-ll.c
* https://github.com/gummyworm/skippydos
* https://web.archive.org/web/20060718184600/http://cmdrkey.com/cbm/misc/history.html