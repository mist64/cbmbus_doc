# Commodore Peripheral Bus: Part 2: Bus Arbitration, TALK/LISTEN

In the [series about the variants of the Commodore Peripheral Bus family](https://www.pagetable.com/?p=1018), this article covers the common layer 3: the Bus Arbitration Layer with the TALK/LISTEN protocol.

![](docs/cbmbus/layer3.png =601x251)

The variants of the Commodore Peripheral Bus family have some very different connectors and byte transfer protocols, but they all share layers 3 and 4 of the protocol stack. This article on layer 3 is therefore valid for all Commodore 8 bit computers, no matter whether they use IEEE-488, Serial, TCBM or CBDOS on the underlying layers.

All layer 2 variants provide:

* the transmission of byte streams from any bus participant to any set of bus participants
* the transmission of "command" byte streams from the designated "contoller" (the computer) to all other bus participants

Layer 2 does not designate who may send or receive at a given time, nor does it define the meaning of contents of command byte streams. That's the job of layer 3.

Layer 3 uses the features of layer 2 to provide the following features:

* devices are numbered
* devices have numbered channels
* devices have named channels
* controller instructs channels to send a byte stream or receive a byte stream


* interface vs. device

## primary addresses and TALK/LISTEN
* anyone can talk to anyone - just not at the same time
* time division: at any time, there can only be one sender and its receivers, but controller redefines the current sender and receivers
* a device that is currently a sender is a "talker"
* a device that is currently a receiver is a "listener"
* every *other* device has a predefined (think: dip-switches) "primary" address, 0 to 30
* the controller tells devices to become talkers or listeners
	* and can decide to become a talker or listener

* sends one byte to start/stop takling/listening

.

	20 + address LISTEN
	40 + address TALK

	3F UNLISTEN
	5F UNTALK


## device numbers, convention
* 4, 5 printer
* 6, 7 plotter
* 8-11 (hard) disk drives
* third party drives support 12+

## secondary addresses
* multiplexing functions/contexts of a device would be nice
* 32 secondary addresses per device (0-31) [C64PRG agrees to IEEE spec]
	* OPEN/CLOSE only support 16!
	* all drives only support 16 (ignore bit #4)
	* C64 will send all bits though
* after talk/untalk, an extra command has to be sent to select channel
* 60 + secondary address
* image showing "interface" != "device" (c't)
* in practice, this could be
	* different devices behind the same interface
	* different functions of the same device
	* options/flags (printer 0 vs. 7)
	* contexts (disk drive)

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