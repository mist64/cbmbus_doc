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

To make sure we are talking about the same thing, let's clarify the naming. Commodore calls the three-wire protocol used e.g. by the Commodore C64 and the 1541 disk drives "Serial" in its reference documents. Later documentation called it "Standard Serial" to distinguish it from the later backwards-compatible "Fast Serial"[^1] protocol of the C128.

This also matches the naming in [Commodore's source code](https://github.com/mist64/cbmsrc/tree/master/KERNAL_C64_03), where the protocol is called "serial"[^2].

Commodore "Standard Serial" is a serial version of the PET's parallel IEEE-488 bus (covered in [part 1](https://www.pagetable.com/?p=1023)), which was standardized internationally as IEC-625. In Europe, IEEE-488 was therefore commonly referred to as the "IEC-Bus". The serial version was then often called "Serial IEC", even though the serial version was never standardized by IEC. Finally, the "serial" attribute was often dropped in European books and magazines, which is why "Standard Serial" is most often refered to as just the "IEC Bus".

There are two extensions of Standard Serial: The already mentioned "Fast Serial" (C128), as well as the third party "JiffyDOS". They both share the same basic idea but are incompatible with each other. Both protocols share the same cable with Standard Serial and are completely backwards-compatible. If they detect that their peers also speak the improved protocol, they will then switch to it. Fast Serial and JiffyDOS will be covered in separate articles.

## History and Development

Commodore had been using the standard IEEE-488 bus on the PET series of computers and its disk drives and printers. Unhappy with the price of the parallel connectors and cables, they developed a serial version of the protocol.

The design goal was to retain all of the core properties of the IEEE-488 bus:

* All participants are **daisy-chained**.
* **One dedicated controller** (the computer) does bus arbitration of **up to 31 devices**.
* **One-to-many**: Any participant can send data to any set of participants.
* A device has **multiple channels** for different functions.
* Data transmission is **byte stream** based.

IEEE-488 has 16 data lines. The serial version reduces this to 5:

| IEEE-488 Signal | Description        | Serial Signal |
|-----------------|--------------------|---------------|
| DIO1-8          | Data I/O           | DATA, CLK     |
| EOI             | End Or Identify    | (timing)      |
| DAV             | Data Valid         | (CLK)         |
| NRFD            | Not Ready For Data | (DATA)        |
| NDAC            | No Data Accepted   | -             |
| IFC             | Interface Clear    | RESET         |
| SRQ             | Service Request    | SRQ           |
| ATN             | Attention          | ATN           |
| REN             | Remote Enable      | -             |

* Instead of transmitting 8 bits in parallel, they are sent serially, with CLK and a DATA line.
* The EOI line was removed. The information is now transmitted through a timing sidechannel.
* The function of the DAV and NRFD lines was taken over by the existing CLK and DATA lines.
* NDAC was removed. XXX
* IFC/RESET, SRQ and ATN were retained.
* REN (always connected to ground and thus already unsupported on the PET) was removed.


<!---
XXX
* overview, idea, motivation, features
	* SAME: multiple devices, daisy-chained
	* SAME: byte oriented
	* SAME: any device can send data to any set of devices (one-to-many)
	* SAME: channels
	* timing based on min/max delays, not strict implicit clock (like RS-232), can be implemented in software
	* no way to do full asynchrounous (all handshake) with just 2 wires, timing requirements!
	-> 3 wires total
	-> one dedicated controller
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
* ATN and SRQ are control lines. (SRQ is unused, see below)
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

During the transmission of a byte stream, the CLK line is exclusively operated by the sender, while the DATA line is operated by the sender and all receivers.

#### 0: Initial State
![](docs/cbmbus/serial-01.png =601x131)
In the initial state, the sender is holding the CLK line to indicate that it it is not ready to send. The receivers are holding the DATA line.

#### 1: Sender is ready to send
![](docs/cbmbus/serial-02.png =601x131)
Transmission of a byte begins with the sender indicating that it is ready to send. It does this by releasing the CLK line.

#### 2: A is now ready to receive data
![](docs/cbmbus/serial-03.png =601x131)
Transmission of a byte cannot begin until all receivers are ready to receive. So at some point the first receiver is done handling the previous byte it may have received and signals that it is ready for data by releasing DATA. The DATA wire is still pulled by the other receiver though, so its value is still 1.

#### 3: All receivers are now ready to receive data
![](docs/cbmbus/serial-04.png =601x131)
Whenever the other receiver is ready to receive the next byte, it will also release DATA, so it will now read back as 0: All receivers are ready to receive data.

During the actual transmission of the data, both the CLK and the DATA line are now operated by the sender.

#### 4: Data is not valid
![](docs/cbmbus/serial-05.png =601x131)
For the transmission of the bits, the CLK line will indicate whether the data on the DATA line is valid. So for the initial state, the sender pulls CLK, indicating that data is not valid.

#### 5: Sender puts data bit #0 onto the wire
![](docs/cbmbus/serial-06.png =601x131)
The sender now puts the value of the first bit in to DATA.

#### 6: Data is now valid – hold for 60 µs
![](docs/cbmbus/serial-07.png =601x131)

#### 7: Data is not valid
![](docs/cbmbus/serial-08.png =601x131)

#### 8-28: Repeat steps 5-7 for bits #1 to #7

#### 29: Receiver A has accepted the byte
![](docs/cbmbus/serial-30.png =601x131)



* transfering bytes
	* two wires, CLK and DATA
	* CLK is the sender's handshaking flag, DATA the receivers'
	* everyone not involved will leave CLK and DATA alone
	* protocol
		* setup
			* sender pulls CLK = I am interested in sending data, but I don't have any data yet
			* all receivers pull DATA = I am interested in accepting data
			* this state can be held indefinitely
		* ready to send:
			* sender releases CLK = I am ready to send a byte
			* all receivers release DATA = I am ready to receive a byte
			* there is no time limit, any receiver that is busy can delay this indefinitely
		* prepare sending byte
			* sender pulls CLK = there is no valid bit on the DATA line
		* for every bit (LSB first)
			* sender sets/clears DATA
			* sender releases CLK, pulls this for 60+ µs = there is a valid bit on the DATA line
				* C64 holds CLK it for 42 ticks only, releases CLK and DATA at the same time
				* 1541 holds CLK for 74 ticks -> $E976, releases first CLK then DATA
			* sender pulls CLK, releases DATA = there is no valid bit on the DATA line
			* XXX does it have to release DATA???
		* byte ack
			* receiver pulls DATA within 1000 µs (any receiver!) = byte received OK
	* EOI
		* if "prepare sending byte" takes 200+ µs, the following byte is the last one
		* receiver pulls data for a short while to acknowledge
			* TODO
		* at the end of transmission
			* sender releases CLK
			* receivers release DATA
	* sender doesn't actually have any data
		* will release clock and do nothing
		* receiver first thinks it's EOI, but it takes even longer
		* receiver times out
	
	* comments:
		* transfer cannot start until all receivers are ready
		* any receiver can ACK
			* no ACK means that all receivers died
		* EOI is a timing sidechannel
		* what are the timing requirements?
			* receiver must be able to measure 200 µs reliably
			* receiver must be able to accept bit within 60 µs
			* receiver must be able to ack byte within 1000 µs
			* TODO ...
			* TODO otherwise...?
		* it's impossible to ack every bit with just two wires in order to make the protocol completely timing independent
		* problem!
			* any receiver can ack a byte buy pulling DATA
			* -> if one receiver is super fast and the other one is super slow, protocol may break
			* XXX fixed by timing requirements?
		* why use the clock at all, if we have strict timing requirements? we could just as well have "data valid" windows (Jiffy does this, and uses CLK for data as well)

![](docs/cbmbus/serial.gif =601x255)

* ATN	
		* XXX ATN in the middle of a byte transmission?

* TALK/LISTEN level differences
	* file not found detection
		* when drive becomes talker, it causes a "sender doesn't actually have any data" timeout


[^1]: Correlated with, but not the same, and often confused with "Burst Mode".

[^2]: The implementation file in the Commodore 64 KERNAL source is "`serial4.0`". The context of the version number is unknown, since no other versions have appeared. On the TED and the C128, the file is just called "`serial.src`".