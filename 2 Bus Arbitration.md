# Commodore Peripheral Bus: Part 2: Bus Arbitration, TALK/LISTEN

In the [series about the variants of the Commodore Peripheral Bus family](https://www.pagetable.com/?p=1018), this article covers the common layer 3: the Bus Arbitration Layer with the TALK/LISTEN protocol.

![](docs/cbmbus/layer3.png =601x251)

The variants of the Commodore Peripheral Bus family have some very different connectors and byte transfer protocols, but they all share layers 3 and 4 of the protocol stack. This article on layer 3 is therefore valid for all Commodore 8 bit computers, no matter whether they use IEEE-488, Serial, TCBM or CBDOS on the underlying layers.

All layer 2 variants provide:

* the transmission of byte streams from any bus participant to any set of bus participants
* the transmission of "command" byte streams from the designated "contoller" (the computer) to all other bus participants

<!--

Layer 2 does not designate who may send or receive at a given time, nor does it define the meaning of contents of command byte streams. That's the job of layer 3.

Layer 3 uses the features of layer 2 to provide the following features:

* devices are numbered (0-30)
* a device has channels (0-31) that can be associated with names
* controller initiates transmissions from one device/channel (or the controller) to any other devices/channels (and/or the controller)

-->

## Controller 

Layer 2 allows everyone on the bus to talk to everyone else – but there is no mechanism in place for who is sending or receiving data at what time. The primary feature of layer 3 is controlling exactly this.

For this, we need one bus participant to be the designated **controller** – this is always the computer. It sends command byte streams to all other bus participants, the **devices**.

## Primary Address

The controller needs to be able to address an individual device. Every device on the bus has a **primary addresses** from 0 to 30. The controller itself does not have an address.

Primary addresses (aka device numbers) are usually assigned through [DIP switches](https://en.wikipedia.org/wiki/DIP_switch) (e.g. Commodore 1541-II: 8-11) or by cutting a trace (e.g. original Commodore 1541: 8 or 9).

Commodore's convention for device numbers:

|#        | type                    |
|---------|-------------------------|
| 4, 5    | printers                |
| 6, 7    | plotters                |
| 8 - 11  | disk drives, hard disks |
| 12 - 30 | third party drives      |

<!--
1541 can be device #30:
	o=8:n=30:oP15,o,15:pR15,"m-w";cH(119);cH(0);cH(2);cH(n+32)+cH(n+64):clO15
	load"$",30
or #4:
	o=8:n=4:oP15,o,15:pR15,"m-w";cH(119);cH(0);cH(2);cH(n+32)+cH(n+64):clO15
	load"$",4
-->

Devices 0-3 are reserved for devices outside the Commodore Peripheral Bus. 

XXX TODO

## Talkers and Listeners

In order to tell devices that they are now supposed to send or receive data, the controller hands out two roles: "talker" and "listener".

* A **talker** is sending a byte stream.
* A **listener** is receiving a byte stream.

Any device can be either a talker, a listener, or passive. There can only be one talker at a time, and there has to be at least one listener.

The controller itself can also be the talker or a listener. In fact, in the most common cases, the controller is either the talker, with a disk drive as the single listener (e.g. writing a file), or the controller is the single listener, with a disk drive as the talker (e.g. reading a file).

## TALK and LISTEN commands

In order to hand out the talker and listener roles to devices and to withdraw them, the controller sends a command byte stream containing one of the following codes:

| command       | description   | effect                                                      |
|---------------|---------------|-------------------------------------------------------------|
| `0x20` + _pa_ | `LISTEN`      | device _pa_ becomes listener; code ignored by other devices |
| `0x3F`        | `UNLISTEN`    | all devices stop listening                                  |
| `0x40` + _pa_ | `TALK`        | device _pa_ becomes talker; all other devices stop talking  |
| `0x5F`        | `UNTALK`      | all devices stop talking                                    |

For the `LISTEN` and `TALK` commands, the primary address of the device gets added to the code. The `UNLISTEN` and `UNTALK` commands correspond to the `LISTEN` and `TALK` with a primary address of 31.  This restricts primary addresses to the range of 0 - 30.

All devices receive and interpret command bytes, so for example, a `TALK` command for device 8 will implicitly cause device 9 to stop talking, it case it currently was a talker.

A role change of the controller itself is not communicated through commands, since the controller already knows this (after all, it is the one making the decision), and the devices don't need to know.

## Secondary Address

The designer of IEEE-488 felt that a device should have multiple functions or contexts, or that multiple _actual_ devices could be sitting behind a single primary address. Each of these **channels** can be addressed using a **secondary address** from 0 to 31.

A command specifying the secondary address can _optionally_ be sent after a `TALK` or `UNTALK` command.

| command       | description   | effect                                     |
|---------------|---------------|--------------------------------------------|
| `0x60` + _sa_ | `SECOND`      | last addressed device selects channel _sa_ |

The interpretation of the secondary address is up to the device and specified on layer 4. In practice, they are interpreted as:

* options or flags, e.g. for printers
* different file contexts, e.g. for disk drives

Devices can also ignore the secondary address or only honor certain bits of it. Commodore disk drives, for example, ignore bit #4, so channels 16-31 are the same as channels 0-15.

## Examples

The following command byte stream will instruct devices 9 and 10 to listen and device 8 to talk. At the end of the command, device 8 will send whatever data it has to devices 4 and 5.

| command | description |
|---------|-------------|
| `0x24`  | `LISTEN` 4  |
| `0x25`  | `LISTEN` 5  |
| `0x48`  | `TALK` 8    |

If the controller wants to read a byte stream from device 8, it only sends this:

| command | description |
|---------|-------------|
| `0x48`  | `TALK` 8    |

The controller then becomes a listener and reads bytes from the bus, until it encounters the end of the stream (`EOI`). It then sends this:

| command | description |
|---------|-------------|
| `0x48`  | `TALK` 8    |



## named channels (OPEN/CLOSE)
* instead of having fixed functions behind secondary addresses
* a device can use names for channels
* only 16 channels available (bit #4 used for open/close)
* there are commands to open and close named channels
* E0 CLOSE
* F0 OPEN (create channel with filename)
* Commodore calls these commands "secondary address open"/"secondary address close"!
* they have to be sent with LISTEN/UNLISTEN so the correct device gets it
* 28, E1, 3F
* LISTEN 8, CLOSE 1, UNLISTEN
* open has an argument, sent with ATN off
* 28, F1, "FOO", 3F
* LISTEN 8, OPEN 1, "FOO", UNLISTEN
* disk drives use the secondary address for channels
* channels represent different open files that can be read from or written to
* TODO open error

## unsupported features in KERNAL/BASIC
* SRQ enumeration
* 00xxxxx commands

.

	?? 000xxxxx unsupported
	20 001xxxxx listen
	40 010xxxxx talk
	60 0110xxxx secondary
	E0 1110xxxx close (extension)
	F0 1111xxxx open (extension)

## KERNAL API
	* on the VIC-20 and all later machines (C64, C128, C65, Plus4, CBM-II)

### IEEE API
.

	$FFB4: TALK – send TALK command
	$FFB1: LISTEN – send LISTEN command
	$FFAE: UNLSN – send UNLISTEN command
	$FFAB: UNTLK – send UNTALK command
	$FF96: TKSA – send TALK secondary address
	$FF93: SECOND – send LISTEN secondary address (same as above, but with bus turnaround)
	$FFA8: IECOUT – send byte to serial bus
	$FFA5: IECIN – read byte from serial bus
	$FFA2: SETTMO – set timeout [no effect on non-IEEE-488]
		this is layer 2 while everything else is layer 3

### OPEN/CLOSE API

### BASIC Commands