# Commodore Peripheral Bus: Part 4: Standard Serial

In the [series about the variants of the Commodore Peripheral Bus family](https://www.pagetable.com/?p=1018), this article covers the lowest two layers (electrical and byte transfer) of the "Serial" bus as found on the VIC-20/C64 and supported by all Commodore home computers.

![](docs/cbmbus/serial_layers.png =371x241)

<hr/>

> **_NOTE:_**  I am releasing one part every week, at which time links will be added to the bullet points below. The articles will also be announced on my Twitter account <a href="https://twitter.com/pagetable">@pagetable</a> and my Mastodon account <a href="https://mastodon.social/@pagetable">@pagetable&#64;mastodon.social</a>.

<hr/>

* [Part 0: Overview and Introduction](https://www.pagetable.com/?p=1018)
* [Part 1: IEEE-488](https://www.pagetable.com/?p=1023) [PET/CBM Series; 1977]
* [Part 2: The TALK/LISTEN Layer](https://www.pagetable.com/?p=1031)
* [Part 3: The Commodore DOS Layer](https://www.pagetable.com/?p=1038)
* **Part 4: Standard Serial (IEC) [VIC-20, C64; 1981]** ← *this article*
* Part 5: TCBM [C16, C116, Plus/4; 1984] *(coming soon)*
* Part 6: JiffyDOS [1985] *(coming soon)*
* Part 7: Fast Serial [C128; 1986] *(coming soon)*
* Part 8: CBDOS [C65; 1991] *(coming soon)*

## Naming and Context

To make sure we are talking about the same thing, let's clarify the naming. Commodore calls the three-wire protocol used e.g. by the Commodore C64 and the 1541 disk drives "Serial" in its reference documents. Later documentation calls it "Standard Serial" to distinguish it from the later backwards-compatible "Fast Serial"[^1] protocol of the C128.

This also matches the naming in [Commodore's source code](https://github.com/mist64/cbmsrc/tree/master/KERNAL_C64_03), where the protocol is called "serial"[^2].

"Standard Serial" is based on the PET's parallel IEEE-488 bus (covered in [part 1](https://www.pagetable.com/?p=1023)), which was standardized internationally as IEC-625. In Europe, IEEE-488 was therefore commonly referred to as the "IEC bus". The serial version was then often called "Serial IEC", even though this variant was never standardized by IEC. Finally, the "serial" attribute was often dropped in European books and magazines, which is why "Standard Serial" is most often refered to as just the "IEC bus".

There are two extensions to Standard Serial: The already mentioned "Fast Serial" (C128), as well as the third party "JiffyDOS". They both share the same basic idea but are incompatible with each other. Both protocols also share the same cable with Standard Serial and are completely backwards-compatible with it. If they detect that their peers also speak the improved protocol, they will then switch to it. Fast Serial and JiffyDOS will be covered in separate articles.

## History and Development

Commodore had been using the standard IEEE-488 bus on the PET series of computers and its disk drives and printers. Unhappy with the price of the parallel connectors and cables, they developed a serial version of the protocol.

The design goal was to retain all of the core properties of the IEEE-488 bus:

* All participants are **daisy-chained**.
* **One dedicated controller** (the computer) does bus arbitration of **up to 31 devices**.
* **One-to-many**: Any participant can send data to any set of participants.
* A device has **multiple channels** for different functions.
* Data transmission is **byte stream** based.

One property they could not keep was the relaxed timing requirement of IEEE-488: At most points in an IEEE-488 communication, any participant can stall for any amount of time. This make it easy to implement the protocol completely in software, without any hardware that would guarantee strict timings. Serial on the other hand was designed with a dedicated hardware shift register in mind.

For those who already have experience with IEEE-488, here is a short overview of how the serial version reduces the number of data lines from 16 to 5:

* **Data**: Instead of transmitting 8 bits in parallel, they are sent serially, with a CLK and a DATA line.
* **Handshake**: The function of the DAV and NRFD lines is taken over by the CLK and DATA lines. There is no NDAC signal, accepting data is based on timing.
* **Management**: REN (already unsupported on the PET) is removed. EOI is removed, the information is now transmitted through a timing sidechannel. RESET (IFC), SRQ and ATN are retained. 

| IEEE-488 Signal | Description        | Serial Signal |
|-----------------|--------------------|---------------|
| DIO1-8          | Data I/O           | DATA, CLK     |
| EOI             | End Or Identify    | (timing)      |
| DAV             | Data Valid         | (CLK)         |
| NRFD            | Not Ready For Data | (DATA)        |
| NDAC            | No Data Accepted   | (timing)      |
| IFC             | Interface Clear    | RESET         |
| SRQ             | Service Request    | SRQ           |
| ATN             | Attention          | ATN           |
| REN             | Remote Enable      | -             |

<!---
XXX
* overview, idea, motivation, features
	* timing based on min/max delays, not strict implicit clock (like RS-232), can be implemented in software
	* no way to do full asynchrounous (all handshake) with just 2 wires, timing requirements!
	-> 3 wires total
--->

## Layer 1: Electrical

### Connectors and Pinout

Both computers and devices use female 6-pin [DIN](https://en.wikipedia.org/wiki/DIN_connector) 45322 connectors.

![](docs/cbmbus/serial_connector.svg =220x220)

![](docs/cbmbus/serial_cable.jpg =300x207)

Since devices can be daisy-chained, most peripherals have two serial ports to connect to both the previous device (or the computer) and to the next device, if any. Either port can be used for the previous or the next device in the chain, but some devices labeled them one way anyway.

![](docs/cbmbus/serial_port_1541-II.jpg =300x171)

<!--- XXX pic two ports on a 1541 --->

This is the pinout:

| Pin | Signal | Description        |
|-----|--------|--------------------|
| 1   | SRQ    | Service Request    |
| 2   | GND    | Ground             |
| 3   | ATN    | Attention          |
| 4   | CLK    | Clock              |
| 5   | DATA   | Data               |
| 6   | RESET  | Reset              |

* The CLK and DATA line carry the data and are used for handshaking.
* ATN and SRQ are control lines. (SRQ is unused, see below.)
* The RESET line resets all devices.

### Open Collector Logic

<!--- this is the same as in part 1 -->

All signal lines are TTL open collector, which means:

* All participants of the bus can not only read, but also write to the line.
* When **all** participants write 0, the line will read back 0, but if any device writes 1, the bus will read back as 1.
* The logic is inverted: 5V is 0 (false), and 0V is 1 (true).

In other words: If the line is *released* by all bus participants, it will be 5V (logically 0), and any participant can *pull* it to 0V (logically 1).

This can be visualized with two (or more) hands that can pull the line to 1, and a spring that pushes it to 0:

![](docs/cbmbus/open_collector.gif =302x162)

So when a line reads as 0, it is known that it is currently released by all participants, but if a line reads as 1, it is impossible to know who or even how many are currently pulling it.

## Layer 2: Byte Transfer

Like with IEEE-488, the basic byte transfer protocol of the Serial Bus is based on transmissions of byte streams from one sender to one or more receivers. Additional bus participants will remain silent. There are no fixed assignments of senders and receivers, the roles of sender and receiver are per transmission.

### Sending Bytes

For the transmission of a byte stream, just two wires, CLK and DATA are used. The CLK line is exclusively operated by the sender, while the DATA line is operated by the sender in some steps, and by the receivers in other steps.

The CLK line is the sender's handshake, and outside of bit transmission, the DATA line is the receiver's handshake.

The following animation shows a byte being sent to two receivers.

![](docs/cbmbus/serial.gif =601x344)

Let's go through it step by step:

#### 0: Initial State
![](docs/cbmbus/serial-01.png =601x131)
In the initial state, the sender is holding the CLK line to indicate that it it is not ready to send. The receivers are holding the DATA line, meaning they are not ready to receive.

#### 1: Sender is ready to send
![](docs/cbmbus/serial-02.png =601x131)
Transmission of a new byte is initiated by the sender, indicating that it is ready to send by releasing the CLK line.

#### 2: A is now ready to receive data
![](docs/cbmbus/serial-03.png =601x131)
Transmission of the bits cannot begin until all receivers are ready to receive. So at some point the first receiver is done handling the previous byte it may have received and signals that it is ready for data by releasing DATA. The DATA wire is still pulled by the other receiver though, so its value is still 1.

#### 3: All receivers are now ready to receive data
![](docs/cbmbus/serial-04.png =601x131)
Whenever the other receiver is ready to receive the next byte, it will also release DATA, so it will now read back as 0: All receivers are ready to receive data.

During the actual transmission of the data, both CLK and DATA are now operated by the sender.

#### 4: Data is not valid
![](docs/cbmbus/serial-05.png =601x131)
For the transmission of the bits, the CLK line will indicate whether the data on the DATA line is valid. So for the initial state, the sender pulls CLK, indicating that data is not valid.

Since both lines are now controlled by the sender, there is no back channel for the receivers, and they cannot acklowledge any state transition. So from now on, everything is based on timing. As a part of this, the CLK line has to be pulled for at least 60 µs until it is released again in step 6.
 
#### 5: Sender puts data bit #0 onto the wire
![](docs/cbmbus/serial-06.png =601x131)
The sender now puts the value of the first bit into DATA.

#### 6: Data is now valid – hold for 60 µs
![](docs/cbmbus/serial-07.png =601x131)
After that, the sender releases CLK, signaling that the data bit in DATA is valid.

There is no way for the receivers to signal "data accepted" for the bit. The sender must hold this state for at least 60 µs, and receivers must be able to accept the bit within this time.

#### 7: Data is not valid
![](docs/cbmbus/serial-08.png =601x131)
After the 60 µs, the sender pulls CLK again to signal that the data is not valid, and releases the DATA line.

#### 8-27: Repeat steps 5-7 for bits #1 to #7
The wires are in the same state again as in step 4, before sending the bit. The seven remaining bits will be transmitted the same way.

#### 28: Data is not valid
![](docs/cbmbus/serial-29.png =601x131)
Like for the previous bits, the last step of the last bit has the sender pulling CLK and releasing DATA.

From now on, the DATA line will be operated by the receivers again.

#### 29: Receiver A is now busy again
![](docs/cbmbus/serial-30.png =601x131)
Once all 8 bits have been transmitted, the receivers have to signal that they are busy, so that after accepting the data, the sender won't think the receivers are immediately ready for the next byte. So now, the first receiver pulls DATA, so DATA is 1.

XXX any listener must react within 1000 µs

#### 30: Receiver B is now busy
![](docs/cbmbus/serial-31.png =601x131)
The other receiver also has to signal that it is busy by pulling DATA. The line was already 1 and will stay at 1. All wires are now in the initial state again. All steps are repeated as long as there is more data to be sent.

XXX sender must wait 100 µs until releasing CLK

Note that the protocol only specifies the triggers: For example, the receivers are to read the bit from DATA while CLK = 0, so it would be just as legal in step 7 for the the sender to hold CLK and release DATA in two steps (the 1541 does this, the C64 doesn't).

Also, there is no ordering on which receiver pulls or releases its line first. The receivers don’t care about the other receivers, they only follow the protocol with the sender. The open collector property of the signal lines automatically combines the outputs of the different receivers.

### End of Stream

If there is no more data to be transmitted, the sequence stops at step 30 (which is the same as step 0). In this step, there is no way for the sender to signal the end of the stream, because it only controls one bit (0 = ready to send the next byte, 1 = it has more data but is not ready to send yet). Therefore, the sender already signals this during the transmission of the last byte. The number of wires for carrrying information are still limited, but it can do it through a timing sidechannel[^3].

#### 3a: Sender delays for 256 µs to signal EOI
![](docs/cbmbus/serial-32.png =601x131)
To indicate the end of the stream, the sender delays step 4 by at least 200 µs. That is, after the sender has signaled that it has more data available (CLK = 0), and after all receivers have signaled that they are ready for data (DATA = 0), the sender doesn't immediately pull the CLK line to start transmission:

#### 4: Data is not valid
![](docs/cbmbus/serial-33.png =601x131)

After the delay, it then pulls CLK, signaling that the data is not valid.

#### 4a: Receiver A acknowledges EOI – hold for 60 µs
![](docs/cbmbus/serial-34.png =601x131)

All receivers have to acknowledge that they have understood the EOI signal. So the first receiver will
do this by holding the DATA line for at least 60 µs.

#### 4b: Receiver B acknowledges EOI – hold for 60 µs
![](docs/cbmbus/serial-35.png =601x131)

The other receiver also has to hold the DATA line for 60 µs.

#### 4c: A has finished acknowledging EOI
![](docs/cbmbus/serial-36.png =601x131)

After the delay, the first receiver releases DATA agin. The wire is still pulled by the other receiver though, so its value is still 1.

#### 4d: B has finished acknowledging EOI
![](docs/cbmbus/serial-37.png =601x131)

After its delay, the other receiver will also release DATA, so it will now read back as 0.

So after the sender has signaled EOI, it will wait for the DATA line to become 1, and then 0 again, until resuming transmission at step 5.

![](docs/cbmbus/serial.png =601x301)

As a side effect of this, the Serial protocol does not allow empty streams - they would have to be at least one byte long.

### Sending Commands

<!--- this is almost the same as in part 1 -->

The assignment of senders and receivers to transmissions is the job of layer 3 (Bus Arbitration), described in [part 3](https://www.pagetable.com/?p=1031) of this series.

But there are also **command** transmissions, where one particiant can start a transmission to *all* other participants at any time.

Only so-called "controllers" may perform a command transmission, and on Commodore busses, there is always only one controller: the computer. All bus participants that are not controllers are called "devices".

When the controller wants to send a command, it pulls the ATN ("Attention") line. All devices on the bus have to respond by pulling DATA ("ATN Response Timing") within 1000 µs, and participate in receiving the command byte stream.

The controller sends the command data like any other transmission, and releases ATN afterwards. It does not signal EOI during the transmission of the last byte, since the release of ATN signals the end of the stream already.

The encoding of commands is part of the [layer 3 bus arbitrarion protocol](https://www.pagetable.com/?p=1031).

### Initiating/Ending a Transmission and Bus Turnaround

On an idle bus, CLK and DATA are released, so they read as 0. The initial state of the transmission of a byte has both lines pulled, so first, the sender has to pull CLK, then the receivers has to pull DATA. This is what happens at the beginning of a command transmission when the bus was idle. Similarly, at the end of the transmission, the sender releases CLK, and the receivers release DATA, so the bus is idle again.

It becomes interesting when two transmissions follow each other immediately, and the sender and receiver roles are different between transmissions. The assignment of senders and receivers can only be changed by a command (during ATN = 1), which is a transmission with a potentially different set of senders and receivers anyway. So at the end of the command, there needs to be an orderly transision from the end state of the old to the initial state of the new transmission – a bus turnaround.

#### A: End state of the original transmission
![](docs/cbmbus/serial-39.png =601x131)

In the last step of a command transmission – like in any transmission – the controller (the sender), is holding CLK, and the devices (the receivers) are holding DATA. (For simplicity, this visualization only has two devices on the bus.)
 
#### B: Reversed roles
![](docs/cbmbus/serial-40.png =601x131)

The command reverses the roles of sender and receiver, so the previous receiver is now the new sender and is still holding DATA, and the previous sender is now the receiver and is still holding CLK. This needs to be reversed.

#### C: New receiver switches lines
![](docs/cbmbus/serial-41.png =601x131)

First, the new receiver pulls DATA and lets go of CLK. DATA remains 1, but CLK is now released by both the sender and the receiver and will read back as 0.

#### D: New sender switches lines
![](docs/cbmbus/serial-42.png =601x131)

Triggered by CLK being 0, the new sender pulls down CLK and releases DATA. Both lines now read back as 1, which is the initial state for byte transmission, and the correct lines are held by the respective bus participants.

### Errors

* sender must pull CLK to show its presence
	* otherwise "I don't actually have any data" error, i.e. FNF
* receiver must pull DATA to show its presence
	* either listener after the command
	* or all devices during ATN
	* if not within 256 µs, device not present
* sender then releases CLK
* receiver then releases DATA when it's actually ready

* sender delays for > 512 µs = timeout
* no receiver pulls DATA within 1000 µs at the end of the byte = timeout
* no device pulls DATA within 1000 µs after ATN – no devices present

### Timing

* transfering bytes
	* C64 holds CLK it for 42 ticks only
	* 1541 holds CLK for 74 ticks -> $E976

* byte ack
	* receiver pulls DATA within 1000 µs (any receiver!) = byte received OK


* Timing
	* ready to receive means being able to make the timing for the whole byte
	* receivers can stall between bytes, but not within a byte
	* receiver must be able to measure 200 µs reliably
	* receiver must be able to accept bit within 60 µs
	* receiver must be able to ack byte within 1000 µs
	* TODO ...
	* TODO otherwise...?
* sender doesn't actually have any data
	* will release clock and do nothing
	* receiver first thinks it's EOI, but it takes even longer
	* receiver times out

* comments:
	* limitations
		* transfer cannot start until all receivers are ready
		* signaling buys after a byte is also basically an ACK
			* any receiver can ACK
			* no ACK means that all receivers died
			* -> if one receiver is super fast and the other one is super slow, protocol may break?? TODO
			* XXX fixed by timing requirements?
		* it's impossible to ack every bit with just two wires in order to make the protocol completely timing independent
	* why use the clock at all, if we have strict timing requirements? we could just as well have "data valid" windows (Jiffy does this, and uses CLK for data as well)

* ATN	
		* XXX ATN in the middle of a byte transmission?

* TALK/LISTEN level differences
	* file not found detection
		* when drive becomes talker, it causes a "sender doesn't actually have any data" timeout

### Next Up

Part 5 of the series of articles on the Commodore Peripheral Bus family will cover layers 1 and 2 of the TCBM protocol as used on the TED series of computers (C16, C116, Plus/4).

> This article series is an Open Source project. Corrections, clarifications and additions are **highly** appreciated. I will regularly update the articles from the repository at [https://github.com/mist64/cbmbus_doc](https://github.com/mist64/cbmbus_doc).

### References

XXX

* https://codebase64.org/doku.php?id=base:how_the_vic_64_serial_bus_works
* http://www.zimmers.net/anonftp/pub/cbm/programming/serial-bus.pdf


[^1]: Related to, but not the same as, and often confused with "Burst Mode".

[^2]: The implementation file in the Commodore 64 KERNAL source is "`serial4.0`". The context of the version number is unknown, since no other versions have appeared. On the TED and the C128, the file is just called "`serial.src`".

[^3]: IEEE-488 also signals this during the last byte, by pulling the dedicated EOI line to 1 while the data is valid.
