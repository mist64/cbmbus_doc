# Commodore Peripheral Bus

* 6 part series about the "IEC" family peripheral bus of the 8 bit Commodore machines
* family of connectors and protocols
* from the PET, over VIC-20 and the C64/C128, up to the C65
* based on IEEE-488
	* with added features
	* some features removed
* variants use different connectors and different byte transfer protocols
* but the same bus arbitration and device API

| layer              | IEEE-488                    | Serial              | JiffyDOS    | Fast Serial | TCBM                   | CBDOS       |
|--------------------|-----------------------------|---------------------|-------------|-------------|------------------------|-------------|
| 4: device API      | Commodore DOS               | Commodore DOS       | Commodore DOS | Commodore DOS | Commodore DOS          | CBM DOS     |
| 3: bus arbitration | TALK/LISTEN                 | TALK/LISTEN         | TALK/LISTEN | TALK/LISTEN | TALK/LISTEN            | TALK/LISTEN |
| 2: byte transfer   | 8 bit, 3-way handshake, ATN | 1 bit CLK/DATA, ATN | *different* | + SRQ       | 8 bit, DAV ACK ST0 ST1 | *none*      |
| 1: electrical      | 24 pin, TTL                 | 6 pin DIN TTL       | *same*      | *same*      | 16 pin TTL             | *none*      |

* overview/features
	* multiple devices, daisy-chained
	* byte oriented
	* generally, any device can send data to any set of devices (one-to-many)
	* one dedicated controller for bus arbitration - the computer
	* a device has multiple channels for different functions
	* and named channels

* parts
	* Part 1a: IEEE-488 (IEC)
		* PET, CBM
		* parallel
	* Part 1b: TALK/LISTEN
	* Part 1c: CBM DOS
	* Part 2: Serial IEC
		* VIC-20, C64, 264, C128, C65
		* serial
	* Part 3: TCBM
		* parallel, 1-to-1
		* 264
	* Part 4: Fast Serial
		* improvement of serial
		* C128, C65
	* Part 5: Jiffy DOS
		* improvement of serial
		* third party, all serial IEC computers/devices
	* Part 6: CBDOS
		* computer-based
		* C65

* interesting historical detail:
	* they started with a complex industry standard
	* didn't support all use features, but allowed users to do so
	* newer variants tried to pull over some of the unused features as well
		* Serial supports one-to-many
		* Serial supports device-to-device
	* they were only slowly removed
		* Fast Serial breaks SRQ
		* Fast Serial breaks device-to-device for different protocol versions
		* TCBM amnd CBDOS break device-to-device and one-to-many

# Part 1a: IEEE-488 (IEC)

* HP-IB, standardized as IEEE-488, "IEC Bus" (name used in Europe)
* electrical
	* TTL
	* 24 pin Centronics or 24 pin board connector
	* Data
		* DIO1-8
	* Handshake
		* NRFD
		* DAV
		* NDAC
	* Protocol
		* IFC (RESET)
		* ATN
		* SRQ
		* REN (remote enable, grounded on PET "to prevent remote devices from returning to local control")
		* EOI

.

         1  2  3  4  5  6  7  8  9 10 11 12   
      +--o--o--o--o--o--o--o--o--o--o--o--o--+
      |                                      |
       +-o--o--o--o--o--o--o--o--o--o--o--o-+ 
        13 14 15 16 17 18 19 20 21 22 23 24   

      Pin Signal                   Pin Signal
       01: DIO1(Data Input/Output)  13: DIO5(Data Input/Output)
       02: DIO2(Data Input/Output)  14: DIO6(Data Input/Output)
       03: DIO3(Data Input/Output)  15: DIO7(Data Input/Output)
       04: DIO4(Data Input/Output)  16: DIO8(Data Input/Output)
       05: EOI(End Or Identify)     17: REN(Remote ENable)
       06: DAV(DAta Valid)          18: GND (for DAV)
       07: NRFD(Not Ready For Data) 19: GND (for NRFD)
       08: NDAC(No Data ACcepted)   20: GND (for NDAC)
       09: IFC(InterFace Clear)     21: GND (for IFC)
       10: SRQ(Service ReQuest)     22: GND (for SRQ)
       11: ATN(ATteNtion)           23: GND (for ATN)
       12: SHIELD                   24: Signal GND              
      

         1  2  3  4  5  6  7  8  9 10 11 12   
      +--o--o--o--o--o--o--o--o--o--o--o--o--+
      |                                      |
      +--o--o--o--o--o--o--o--o--o--o--o--o--+
         A  B  C  D  E  F  H  J  K  L  M  N
      
      Pin  Signal       Pin Signal
       1   DIO 1         A   DIO 5
       2   DIO 2         B   DIO 6
       3   DIO 3         C   DIO 7
       4   DIO 4         D   DIO 8
       5   EOI           E   REN  
       6   DAV           F   GND  
       7   NRFD          H   GND  
       8   NDAC          J   GND  
       9   IFC           K   GND  
      10   SRQ           L   GND  
      11   ATN           M   GND  
      12   CHASSIS GND   N   GND  


	* IFC is RESET
	* all other lines are open collector
		* defaults to 5V (line is "incative")
		* will be 0V if any device pulls it down ("asserts" it, line is "active")
		* it's impossible to tell who pulls it down
		* for data, pulled = 0V = logical 1
* transfering bytes
	* bus is byte oriented
	* 8-bit parallel
		* 8 bit data DIO1-DIO8
	* one sender
		* puts data on DIO and participates in handshake
	* any number of receivers
		* read data off DIO and participate in handshake
	* any number of passive devices
		* will leave everything alone
	* send byte: three-wire-handshake
		* ownership
			* DIO1-8 and DAV is owned by the sender
			* NDAC and NRFD are owned by the receivers
			* lines that are not owned are released
		* initial state
			* sender releases DAV (data not available)
			* every receiver pulls NDAC (not all receivers have accepted the data)
			* every receiver pulls NRFD (not all receivers are ready for data)
		* as soon as a receiver is no longer busy
			* release NRFD (receiver is ready for data)
			* as soon as all receivers do this, NRFD is released
		* sender waits for NRFD to be released
		* sender puts inverted data byte on DIO
			* (inverted because pulled is logical 1)
		* sender pulls DAV (data is available)
		* receiver waits for DAV
		* receiver gets inverted data byte from DIO
		* receiver pulls NRFD (receiver is not ready for data)
			* this is the default state for a receiver so the sender doesn't continue
			  with the next byte until the receiver has done something with the data
		* receiver releases NDAC (receiver has accepted the data)
			* as soon as all receivers do this, NDAC is released
		* sender releases DAV (data is not available)
		* sender sets data to $00 (all DIO lines are released)
		* receiver waits for DAV to be released
		* receiver pulls NDAC (receiver has not accepted data)
		* we're in the original state again
	* errors
		* device not present
			* if there is no receiver, NDAC *and* NRFD are released
				* this can be detected by sender at "start"
			* XXX if there is no sender?
				* can't be detected?
		* timeout (Commodore extension)
			* receiver timeout: if data not accepted within 64 us
			* sender timeout: if data not available within 64 us
			* for compatibility with IEEE, this can be disabled (SETTMO #$80)
	* EOI
		* EOI pulled by sender while data is valid
	* bus turnaround
		* sender becomes receiver (secondary after talk)
			* while ATN pulled
			* pull NRFD and NDAC
			* release ATN
		* receiver becomes sender
			* TODO
			
	
	* comments:
		* no timing requirements!
		* slowest device defines speed
			* anyone can pause at any time
			* great for CPUs that have other things to do as well
			* IRQs remain on, NMIs and DMA okay
		* Commodore
			* timeouts, so it can detect that sender has no data
			* implicit communication through timing!

![alt text](ieee-488.gif  =600x315)

* controller and command bytes
	* just this supports the use case of one device that is always the sender, and plus some devices which are only receivers
		* e.g with a computer and a printer or a disk copy station with one source and one or many destinations
	* one device needs to be the designated "controller"
	
	* controller can interrupt the bus at any time
	* sends one control byte
		* controller pulls ATN
		* controller sends 1 byte
		* *all* other devices receive control byte
		* controller releases ATN

* SRQ and REN
	* TODO

# Part 1b: Bus Arbitration, TALK/LISTEN

* primary addresses and TALK/LISTEN
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


* device numbers, convention
	* 4, 5 printer
	* 6, 7 plotter
	* 8-11 (hard) disk drives
	* third party drives support 12+

* secondary addresses
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

* named channels (OPEN/CLOSE)
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

* unsupported features
	* TODO

.

	?? 000xxxxx unsupported
	20 001xxxxx listen
	40 010xxxxx talk
	60 0110xxxx secondary
	E0 1110xxxx close (extension)
	F0 1111xxxx open (extension)



* KERNAL API
	* on the VIC-20 and all later machines (C64, C128, C65, Plus4, CBM-II)

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

# Part 1c: CBM DOS

* disk drives
	* channel = 0 is reserved for a reading a PRG file.
	* channel = 1 is reserved for a writing a PRG file.
	* channel = 2-14 need the filetype and the read/write flag in the filename as ",P,W" for example.
	* channel = 15 for DOS commands or device status info.

* Printers
	* printers use the secondary address to pre-select a character set

0 graphic
7 business

	ftp://www.zimmers.net/pub/cbm/manuals/printers/MPS-801_Printer_Users_Manual.pdf
Sa= 0: Print data exactly as received
Sa= 6: Setting spacing between lines
Sa= 7: Select business mode
Sa= S: Select graphic mode
Sa=10: Reset the printer

	https://www.mocagh.org/forsale/mps1000-manual.pdf
0 Print data exactly as received in Uppercase/Graphics mode
1 Print data according to a previously-defined format
2 Store the formatting data
3 Set the number of lines per page to be printed
4 Enable the printer format diagnostic messages
5 Define a programmable character
6 Set spacing between lines
7 Print data excactly as received in Upper/lowercase
9 Suppress diagnostic message printing
10 Reset printer

* practice:
	* listen 4, secondary 7, "Hello", unlisten
	* TODO: bus turnaround

# Part 2: Serial IEC

* Commodore calls it the serial bus
* literature calls it serial IEC or IEC, but it's not an IEC standard

* overview, idea, motivation, features
	* SAME: multiple devices, daisy-chained
	* SAME: byte oriented
	* SAME: any device can send data to any set of devices (one-to-many)
	* SAME: channels
	* timing based on min/max delays, not strict implicit clock (like RS-232), can be implemented in software
	-> 3 wires total
	-> one dedicated controller

* IEEE -> IEC:
	* 16->4 wires (incl. SRQ) 
	* NDAC removed
	* DAV replaced by CLK
	* NRFD replaced by DATA

* connector & electrical
	* 6-pin DIN
		* 1 SRQ
		* 2 GND
		* 3 ATN
		* 4 CLK
		* 5 DATA
		* 6 RESET
	* all 3 data lines are open collector
		* defaults to 5V (line is "incative")
		* will be 0V if any device pulls it down ("asserts" it, line is "active")
		* it's impossible to tell who pulls it down

* transfering bytes
	* bus is byte oriented
	* one sender
	* any number of receivers
	* any number of passive devices
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

* ATN	
		* XXX ATN in the middle of a byte transmission?

* TALK/LISTEN level differences
	* file not found detection
		* when drive becomes talker, it causes a "sender doesn't actually have any data" timeout

# Part 3: TCBM

* history
	* Commodore 1984
	* only used in the 264 series (C16, C116, Plus/4)
* 17 pin header
	*  1  GND
	*  2  DEV
	*  3  pa0
	*  4  pa1
	*  5  pa2
	*  6  pa3
	*  7  pa4
	*  8  pa5
	*  9  pa6
	* 10  pa7
	* 11  DAV: data available
	* 12  ST0: status0
	* 13  ACK
	* 14  ST1: status1
	* 15  RESET
	* 16  GND
	* 17  GND
* Point-to-point, two TCBM drives talk can't to each other
* computer didn't have the port, I/O chip ("controller card") came with drive
* two drives means two I/O chips, i.e. two busses
* 264 series had up to three IEC-like busses, one serial IEC, and up to two TCBM
* if device 8 or 9
	* ROM driver checks for presence of first or second I/O chip
	* if found, uses TCBM over that chip
	* otherwise, uses serial IEC

# Part 4: Fast Serial

* "synchronous serial", "burst"
* "Commodore Fast Serial Interface Protocol"
* history
	* Commodore 1985
	* supported by C128, C65, 1570, 1571, 1581
	* supported by classic 3rd party devices, like CMD hard disks
* requires hardware device for CLK/DATA, like CIA 6526
* requires a fourth wire, reuses "SRQ" wire
	* clock is used to ack every byte (cbdos.spec), probably to allow for slow receivers like C64 with badlines

* new byte send protocol
	* uses SRQ as clock, DATA for data
	* MSB first
	* 10 µs per bit
		* 6526 docs says min clock is Phi0/4, so 8 µs per bit
	* TODO same byte handshaking using DATA

* timing properties
	* talker and listener need a TODO ~80 µs window 
	* makes quite some assumptions
	* but they are true on the C64, which is pretty much the worst case

* backwards compatibility
	* idea
		* controller must tell device that it supports *and* requests fast serial
		* when device receives, it must request fast serial
		* when device sends, it can send fast serial if receiver supports it
	* controller
	    * before TALK/LISTEN
		* sends HRF, waits 100 µs
			* TODO why
		* every fast device knows the controller supports fast serial
	    * listener
		* check bit 3 ICR (for a fast byte) and the CLK line (for the start of the slow protocol)
		* if a fast byte arrived, set the fast serial flags
	    * talker
	    	* if DRF arrives before sending data, set the fast serial flags
		* if fast serial flag set, send fast byte
	    * UNTALK/UNLISTEN/error
		* clear fast serial bits
	* device (if it knows the controller supports fast serial)
	    * listener
		* before receiving the first byte, before releasing DATA
		* send DRF
	    * talker
		* send fast byte

* TODO can two devices talk fast serial?
	* does device-to-device talking work at all any more?
	* any LISTEN/TALK from the controller will signal devices should speak fast serial
	* slow/slow should still work
	* fast-capable/slow probably breaks
	* does fast-fast work?
	* is it possible to tell a fast serial device that it shouldn't do fast serial any more to set it up for a session with a slow device? yes, UNTALK/UNLISTEN.

	* in theory, it's a two-way communication
		* for every TALK/LISTEN, controller requests fast serial
		* request gets canceled on UNTALK/UNLISTEN
		* so it's a request for a single session
		* but device does not immediately answer whether it supports it
			* when device listens, it doesn't ack until talker starts sending first byte (can this be canceled?)
			* when device talks, it doesn't ack until it has sent the first byte (which is in fast serial protocol!)
	* in practice, 1571/1581 turn on fast serial as soon as they see HRF, no matter whether the following command is for them (there doesn't even have to be a command, HRF can be sent at any time)
		* so the HRF is valid for the session as a whole, for both the talker and the listener
		* i.e. HRF TALK8 SEC0 LISTEN9 SEC0 -> 8 and 9 speak fast serial
		* but the only way to detect whether a device supports fast serial is to transfer data, e.g. by reading the error channel
		* -> that's communication on a higher layer :(

* bust mode
	* "When fast serial communications are available, files are loaded by sectors (254-byte chunks of data) using a special feature of the 1571 drive known as burst mode. However, fast mode SAVEs are still done byte by byte." (Mapping the 128)
	* TODO

* Notes
	* Fast: setzen devices beim Unlisten das fast Flag zurück?
	* Fast macht SRQ kaputt :(
		* PET kann SRQ in Hardware, aber Software hat keinen Support
		* SRQ als Feature hat parallel nach seriell überlebt, VIC-20 und C64 können SRQ 
		* wenn auch 1541 kein SRQ in Hardware kann
		* beim 264 ist SRQ Hardware Support weggefallen
		* C128 benutzt SRQ-Leitung für Fast
		* -> ansich war SRQ noch mit erweiterter Software möglich, wenn auch ungenutzt aber C128 macht das kaputt

	* cbdos.spec:
		Standard serial: Actual transfer rate = 4800-6800 baud.
		    Fast serial: Actual transfer rate = 21000-23000 baud.
		   Burst serial: Actual transfer rate = 78400-80000 baud.

# Part 5: Jiffy DOS

* history
	* Mark Fellows, 1985
	* ROM replacements
	* available for all Commodore computers and practically all IEC disk drives
	* supported by modern devices ike SD2IEC
* software-only faster protocol
* same connector, same wires (ATN, CLK, DATA)
* faster byte send
* same ATN command protocol above

* new byte send protocol
	* send 2 bits at a time
	* every TODO µs
* original protocol has a "no slower than" requirement
* Jiffy DOS has a "no faster or slower than" requirement
* within TODO µs, receiver must be able to read two bits every TODO µs

* backwards compatibility
	* devices that can speak Jiffy DOS and devices that can't can share the same bus
	* all devices that speak Jiffy DOS also speak the original protocol
	* -> ok if a set of devices speak Jiffy DOS, while others are passive
	* -> if not everyone in a set of devices can speak Jiffy DOS, they can revert to the original protocol
	* commands from the controller have to be received by all devices
	* -> commands have to use the regular protocol
	* detection & enabling
		* controller waits TODO µs between bit 6 and 7 of LISTEN or TALK
		* -> device will speak fast protocol in this TALK/LISTEN session
		* addressed device pulls DATA for TODO µs
		* -> controller knows device will speak fast protocol
	* if all listeners and talkers speak Jiffy DOS, everything is OK
	* otherwise UNTALT, UNLISTEN and try again with original protocol
	* common case: point-to-point between controller and one device
	* -> signal Jiffy DOS protocol, if device replies, speak Jiffy DOS

* is the send/receive protocol actually symmetrical? could two devices talk to each other?

# Part 6: CBDOS

* history
	* Commodore, 1991, canceled
	* C64 successor
	* "Computer Based DOS"
* drives are not external computers any more
* floppy disk controller ("F011") on the computer's mainboard (not on the "classroom" version)
* built-in 3.5" drive
* optional external second drive
* DOS runs on main CPU
* IEC calls are going to CBDOS drive first, and if failure, to IEC


