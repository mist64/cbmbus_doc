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

Here are some examples.

### Receiving Data from a Device

If the controller wants to read a byte stream from device 8, channel 2, it sends this:

| command | description |
|---------|-------------|
| `0x48`  | `TALK` 8    |
| `0x62`  | `SECOND` 2  |

The controller then becomes a listener and reads bytes from the bus. If the controller has had enough data, it can send this:

| command | description |
|---------|-------------|
| `0x5F`  | `UNTALK`    |

The current talker will then release the bus. The controller can resume the transmission of data from the channel by sending the same `TALK`/`SECOND` commands again.

The controller has to stop receiving bytes onces it encounters the end of the stream (`EOI`). There is no need to send `UNTALK` in this case, since the talker will automatically release the bus.

### Sending Data to a Device

Here is the equivalent example that sends a byte stream to device 4, channel 7:

| command | description |
|---------|-------------|
| `0x24`  | `LISTEN` 4  |
| `0x67`  | `SECOND` 7  |

The controller then sends the byte stream. Like in the case of receiving data, the controller can pause transmission like this:

| command | description |
|---------|-------------|
| `0x3F`  | `UNLISTEN`  |

and resume it using the same `LISTEN`/`SECOND` combination. If the controller has reached the end of its byte stream, it signals `EOI`. Again, there is no need to send `UNLISTEN` in this case.

(Somewhat breaking conventions, some devices interpret `UNLISTEN` as a record delimiter, e.g. Commodore disk drives will execute commands to channel 15 on the `UNLISTEN` event. See layer 4.)

### Copying Data Between Devices

The following example has the controller manually copy a byte stream from device 8, channel 2 (a disk drive) to device 4 (a printer). First, it tells device 8, channel 2 to talk:

| command | description |
|---------|-------------|
| `0x48`  | `TALK` 8    |
| `0x62`  | `SECOND` 2  |

Now the controller reads one byte from the bus. It then instructs the talker to stop talking and tells device 4 to listen:

| command | description |
|---------|-------------|
| `0x5F`  | `UNTALK`    |
| `0x24`  | `LISTEN` 4  |

In this case, there is no secondary address for device 4, so the device picks its default channel. The controller then sends the byte it just read back onto the bus and tells device 4 to stop listening.

| command | description |
|---------|-------------|
| `0x3F`  | `UNLISTEN`  |

Now it can repeat the whole procedure from the start, until the read operation signaled the end of the stream.

Obviously this is slow, because it transmits 7 bytes for every byte of payload. A more optimized version would read and write something like 256 bytes at a time.

### Having Devices Talk to Each Other

But devices can also talk directly to each other, without the controller's involvement. This way, data only travels over the bus once.

This command byte stream will instruct devices 4 and 5 to listen and device 8, channel 2 to talk. After the transmission of the command, device 8 will send whatever data it can provide from channel 2 to devices 4 and 5.

| command | description |
|---------|-------------|
| `0x24`  | `LISTEN` 4  |
| `0x25`  | `LISTEN` 5  |
| `0x48`  | `TALK` 8    |
| `0x62`  | `SECOND` 2  |

Device 8 now starts sending bytes, and devices 4 and 5 will receive them. The layer 2 protocol makes sure that the listeners will adapt to the talker's speed and wait patiently when it stalls (e.g. the disk drive has to read a new sector), and the talker will adapt to the speed of the slowest listener and wait patiently when one of them stalls (e.g. when the printer has to move the paper).

The controller can interrupt the transmission at any time by sending new commands. If it wants to know when the transmission is finished though, it will have to be a listener as well and detect the end of the stream (`EOI`).

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