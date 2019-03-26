# Commodore Peripheral Bus: Part 2: Bus Arbitration, TALK/LISTEN

* family of Commodore Peripheral Bus protocols
* different layers 1 and 2
* they all share layers 3 and 4
* image
* this article is valid for
	* IEEE-488
	* Serial family
	* TCBM
	* CBDOS
* each layer 2 variant provides
	* any sender to transmit byte stream to any set of receivers; any number of passive participants
	* dedicated controller (computer) to transmit command byte stream to all devices
* layer 3 uses these features to provide the following features
	* controller can connect talker with listeners
	* numbered devices
	* numbered channels
	* named channels


## primary addresses and TALK/LISTEN
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