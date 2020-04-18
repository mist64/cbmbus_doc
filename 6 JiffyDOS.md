# Commodore Peripheral Bus: Part 6: JiffyDOS

In the [series about the variants of the Commodore Peripheral Bus family](https://www.pagetable.com/?p=1018), this article covers the third party "JiffyDOS" extension to the Commodore Serial Bus protocol, which shipped as a ROM patch for computers and drives, replacing the byte transmission protocol of Standard Serial by using the clock and data lines in a more efficient way.


<!-- ![](docs/cbmbus/tcbm_layers.png =371x241) -->

<hr/>

> **_NOTE:_**  I am releasing one part every once in a while, at which time links will be added to the bullet points below. The articles will also be announced on my Twitter account <a href="https://twitter.com/pagetable">@pagetable</a> and my Mastodon account <a href="https://mastodon.social/@pagetable">@pagetable&#64;mastodon.social</a>.

<hr/>

* [Part 0: Overview and Introduction](https://www.pagetable.com/?p=1018)
* [Part 1: IEEE-488](https://www.pagetable.com/?p=1023) [PET/CBM Series; 1977]
* [Part 2: The TALK/LISTEN Layer](https://www.pagetable.com/?p=1031)
* [Part 3: The Commodore DOS Layer](https://www.pagetable.com/?p=1038)
* [Part 4: Standard Serial (IEC)](https://www.pagetable.com/?p=1135) [VIC-20, C64; 1981]
* [Part 5: TCBM](https://www.pagetable.com/?p=1324) [C16, C116, Plus/4; 1984]
* **Part 6: JiffyDOS [1985]** ← *this article*
* Part 7: Fast Serial [C128; 1985] *(coming soon)*
* Part 8: CBDOS [C65; 1991] *(coming soon)*

# History and Development

* history
	* Mark Fellows, 1985
	* ROM replacements
	* available for all Commodore computers and practically all IEC disk drives
	* supported by modern devices ike SD2IEC
	* as of 2020, JiffyDOS ROMs for all supported computers are drives are still commercially available
* software-only faster protocol

# Overview

* same connector, same wires (ATN, CLK, DATA)
* faster byte send
* same ATN command protocol above

* new byte send protocol
	* send 2 bits at a time
	* every 10 µs
* original protocol has a "no slower than" requirement
* JiffyDOS has a "no faster or slower than" requirement
* sender and receiver must guarantee 85 µs window without interruptions
* within 7 µs windows, receiver must be able to read two bits every 10 µs
* two-way handshake after every byte

* point-to-point between controller and one device

* backwards compatibility
	* devices that can speak JiffyDOS and devices that can't can share the same bus
	* all devices that speak JiffyDOS also speak the original protocol
	* -> ok if a controller and one device speak JiffyDOS, while others are passive
	* -> if not everyone of the two participands can speak JiffyDOS, they will revert to the original protocol
	* commands from the controller have to be received by all devices
	* -> commands have to use the regular protocol


## Detection

* controller waits TODO µs (400?) between bit 6 and 7 of LISTEN or TALK
* -> device will speak fast protocol in this TALK/LISTEN session
* addressed device pulls DATA for at least TODO µs
* -> controller knows device will speak fast protocol
* controller will wait for DATA being released

## Byte Transfer

### Receiving Bytes

The following animation shows a byte being received from the controller by the device.

![](docs/cbmbus/jiffydos.gif =601x344)

Let's go through it step by step:

#### 0: Initial State
![](docs/cbmbus/jiffydos-01.png =601x131)

#### 1: Sender is ready to send
![](docs/cbmbus/jiffydos-02.png =601x131)

#### 2: Receiver is ready to receive
![](docs/cbmbus/jiffydos-03.png =601x131)

#### 3: Sender puts data bits #0 and #1 onto wires
![](docs/cbmbus/jiffydos-04.png =601x131)

#### 4: Sender puts data bits #2 and #3 onto wires
![](docs/cbmbus/jiffydos-05.png =601x131)

#### 5: Sender puts data bits #4 and #5 onto wires
![](docs/cbmbus/jiffydos-06.png =601x131)

#### 6: Sender puts data bits #6 and #7 onto wires
![](docs/cbmbus/jiffydos-07.png =601x131)

#### 7: Sender signals OK/busy
![](docs/cbmbus/jiffydos-08.png =601x131)

#### 8: Receiver is now busy again
![](docs/cbmbus/jiffydos-09.png =601x131)

### End of Stream

#### 7a: Sender signals EOI status
![](docs/cbmbus/jiffydos-10.png =601x131)

#### 7b: Sender is now busy again
![](docs/cbmbus/jiffydos-11.png =601x131)

### Error

#### 7a': Sender signals error status
![](docs/cbmbus/jiffydos-12.png =601x131)


![](docs/cbmbus/jiffydos.png =601x301)

### Sending Bytes

### LOAD

## Discussion

### ...

### Conclusion

...

### Next Up

Part 7 of the series of articles on the Commodore Peripheral Bus family will cover Commodore's "Fast Serial" protocol on layer 2, which is supported on the C128 and C65 as well as the 1571 and 1581 drives. Like JiffyDOS, it replaces the byte transmission protocol of Standard Serial with a faster version that uses a previously unused wire in the serial cable.

> This article series is an Open Source project. Corrections, clarifications and additions are **highly** appreciated. I will regularly update the articles from the repository at [https://github.com/mist64/cbmbus_doc](https://github.com/mist64/cbmbus_doc).


# References
