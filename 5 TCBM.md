# Commodore Peripheral Bus: Part 5: TCBM

In the [series about the variants of the Commodore Peripheral Bus family](https://www.pagetable.com/?p=1018), this article covers the lowest two layers (electrical and byte transfer) of the "TCBM" bus as found on the TED Series computers: the C16, C116 and the Plus/4.


![](docs/cbmbus/tcbm_layers.png =371x241)

<hr/>

> **_NOTE:_**  I am releasing one part every week, at which time links will be added to the bullet points below. The articles will also be announced on my Twitter account <a href="https://twitter.com/pagetable">@pagetable</a> and my Mastodon account <a href="https://mastodon.social/@pagetable">@pagetable&#64;mastodon.social</a>.

<hr/>

* [Part 0: Overview and Introduction](https://www.pagetable.com/?p=1018)
* [Part 1: IEEE-488](https://www.pagetable.com/?p=1023) [PET/CBM Series; 1977]
* [Part 2: The TALK/LISTEN Layer](https://www.pagetable.com/?p=1031)
* [Part 3: The Commodore DOS Layer](https://www.pagetable.com/?p=1038)
* [Part 4: Standard Serial (IEC)](https://www.pagetable.com/?p=1135) [VIC-20, C64; 1981]
* **Part 5: TCBM [C16, C116, Plus/4; 1984]** ← *this article*
* Part 6: JiffyDOS [1985] *(coming soon)*
* Part 7: Fast Serial [C128; 1986] *(coming soon)*
* Part 8: CBDOS [C65; 1991] *(coming soon)*

## Naming

The only computers with a TCBM bus are the Commodore C16, C116 and Plus/4. Internally, Commodore called this the TED series, named after the core IC of the system[^1]. This name can be seen in multiple places in the [TED KERNAL and BASIC sources](https://github.com/mist64/cbmsrc). Many products around the TED series, like software cartridges, had product codes prefixed with "T".[^2]

The naming for the new TED bus is not completely consistent:

* The [manual](http://www.zimmers.net/anonftp/pub/cbm/manuals/drives/1551_Disk_Drive_Users_Guide.pdf) and the [schematics](http://www.zimmers.net/anonftp/pub/cbm/schematics/drives/new/1551/251860.gif) of the 1551 disk drive call it **TCBM**. The "T" probably stands for "TED", and "CBM" is the common abbreviation of "Commodore Business Machines".
* Comments in the [KERNAL driver code](https://github.com/mist64/cbmsrc/tree/master/KERNAL_TED_05) call it **TEDISK**. Other places call it the "Kennedy" ("KDY") interface, which seems to be a reference to [Ted Kennedy](https://en.wikipedia.org/wiki/Ted_Kennedy).
* The 1551 power-on message contains the string **TDISK**.

## History and Development

The Commodore PET (1977) was using the industry-standard 8-bit parallel [IEEE-488 bus](https://www.pagetable.com/?p=1023) for disk drives and printers. For the VIC-20 (1981), they changed layers 1 and 2 of the protocol stack (electrical and byte transfer) into a cheaper [serial bus](https://www.pagetable.com/?p=1135), which turned out to have severe speed problems[^3].

So for the TED series (1984), Commodore decided to create another variant of the protocol stack, replacing layers 1 and 2 again. The new bus was supposed to combine the speed of the IEEE-488 bus with the low cost of the serial bus.


While the switch from parallel IEEE-488 to serial allowed the protocol stack to retain all key properties of the original design, TCBM drops some of these features:

| Feature | IEEE-488 | Serial | TCBM |
|---------|----------|--------|------|
| All participants are **daisy-chained**. | Yes | Yes | **No** |
| **One dedicated controller** (the computer) does bus arbitration of **up to 31 devices**. | Yes | Yes | **No** |
| **One-to-many**: Any participant can send data to any set of participants. | Yes | Yes | **No** |
| A device has **multiple channels** for different functions. | Yes | Yes | Yes |
| Data transmission is **byte stream** based. | Yes | Yes | Yes |

The key difference is that the TCBM bus is point-to-point:

* The bus is between one computer and one device.
* For multiple devices, one dedicated bus has to exist to each device.
* Multiple busses are completely separate.

TCBM only allows the primary addresses 8 and 9, practically limiting the bus to (disk) drives. This also limits the number of busses to two: One for drive 8, and one for drive 9.

XXX the bus doesn't know about 8/9, only about 0/1 to signal, which *bus* it is...

A device still has multiple channels, and all data transmission is still byte stream based, because these are properties of the layers 3 and 4, which are retained in TCBM.

TCBM has 8 data wires, but reduces the IEEE-488 signal wire count by three. (XXX REN doesn't count.)

| IEEE-488 Signal | Description        | Serial Signal | TCBM   |
|-----------------|--------------------|---------------|--------|
| DIO1-8          | Data I/O           | DATA, CLK     | DIO1-8 |
| EOI             | End Or Identify    | (timing)      | XXX    |
| DAV             | Data Valid         | (CLK)         | DAV    |
| NRFD            | Not Ready For Data | (DATA)        | XXX    |
| NDAC            | No Data Accepted   | (timing)      | ACK    |
| IFC             | Interface Clear    | RESET         | RESET  |
| SRQ             | Service Request    | SRQ           | -      |
| ATN             | Attention          | ATN           | (DIO)  |
| REN             | Remote Enable      | -             | -      |

XXX TODO

## Layer 1: Electrical

### Connectors and Pinout

* 17 pin header

| Pin | Signal  | Description |
|-----|---------|-------------|
|  1  | GND     | Ground      |
|  2  | DEV     | Device 0/1  |
|  3  | DIO1    | Data I/O    |
|  4  | DIO2    | Data I/O    |
|  5  | DIO3    | Data I/O    |
|  6  | DIO4    | Data I/O    |
|  7  | DIO5    | Data I/O    |
|  8  | DIO6    | Data I/O    |
|  9  | DIO7    | Data I/O    |
| 10  | DIO8    | Data I/O    |
| 11  | DAV     | Data Valid  |
| 12  | STATUS0 | Status 0    |
| 13  | ACK     | Acknowledge |
| 14  | STATUS1 | Status 1    |
| 15  | RESET   | Reset       |
| 16  | GND     | Ground      |
| 17  | GND     | Ground      |

* There are 8 data lines, DIO1-8[^4].
* XXX


----

* computer didn't have the port, I/O chip ("controller card") came with drive
* two drives means two I/O chips, i.e. two busses
* 264 series had up to three IEC-like busses, one serial IEC, and up to two TCBM (8 and 9)

---


* detection
	* $EDA9
	* on every TALK or LISTEN, if device 8 or 9
	* ROM driver checks for presence of first ($FEC0) or second ($FEF0) I/O chip
		* PA must retain its value
		* STATUS1 (PB1) must be 
		* offset of TIA is stored in bits #4 and #5 in $f9 ($FEC0 + MEM($F9) & 0x30)
	* if found, uses TCBM over that chip
		* TALK/LISTEN will set bit #6/#7 in $F9 to indicate TALKER/LISTENER is TCBM
		* reset of bits #6/#7 on UNTALK/UNLISTEN
	* otherwise, uses serial IEC
	* if drive has no power, detection fails – how?

---

## Layer 2: Byte Transfer

XXX

For the transmission of a byte stream, 12 wires are used. DAV is owned by the computer, ACK and the two ST lines are owned by the device. 

XXX DAV and the eight DIO lines are owned by the sender, and ACK and the two ST lines are owned by the receiver.

* there is always a command, followed by a data byte

### Sending Bytes

XXX

![](docs/cbmbus/tcbm-send.gif =601x577)

Let's go through it step by step:

#### 0: Initial State
![](docs/cbmbus/serial-01.png =601x131)
In the initial state, the controller is holding the DAV line to indicate that it it is not ready to send. The device is holding the ACK line, meaning it is not ready to receive. The DIO and ST lines are all released.

#### 1: Controller puts code 0x83 on the bus
![](docs/cbmbus/serial-02.png =601x131)
All communication is initiated by the controller by putting a TCBM command byte onto DIO. 0x83 means that the controller intends to send a byte to the device.

#### 2: Device has accepted the code
![](docs/cbmbus/serial-03.png =601x131)
Transmission cannot begin until the device is ready to receive. So at some point the device is done handling the previous byte it may have received, so it detects the most significant bit of DIO set, and signals that it is ready for data by releasing ACK.

#### 3: 
![](docs/cbmbus/serial-04.png =601x131)
Triggered by ACK being 0, the controller now puts the byte value onto DIO.

#### 4: Data on bus is now valid
![](docs/cbmbus/serial-05.png =601x131)
After that, the controller releases DAV, signaling that the data in DIO is valid.

#### 5: Device puts status on the bus
![](docs/cbmbus/serial-06.png =601x131)
Triggered by DAV being 0, the device reads the data from DIO and puts the two status bits onto ST.

#### 6: Device has accepted the data, status is valid
![](docs/cbmbus/serial-07.png =601x131)
It then pulls ACK, signaling that it has accepted the data and the status is valid.

#### 7: Controller clears data on the bus
![](docs/cbmbus/serial-08.png =601x131)
Triggered by ACK being 1, the controller reads the status, and clears the byte from the DIO lines and sets them back to 0, so they can't be interpreted as a TCBM command in the next cycle.

#### 8: Controller resets data valid
![](docs/cbmbus/serial-09.png =601x131)
In order to revert to the initial state, the sender then pulls DAV.

#### 9: 
![](docs/cbmbus/serial-10.png =601x131)
Triggered by DAV being 1 (the controller has read the status), the device clears the status. All wires are now in the initial state again. All steps are repeated as long as there is more data to be sent.


### Receiving Bytes




	* ACK and DAV sometimes mean the opposite
* byte output
	* initial state
		* PA = $00
		* DAV (PC6) = 1
		* ACK (PC7) = 1
		* ST = 00
		* DDRA is $FF
	* store $83 into PA
		* receiver detects MSB = 1
	* wait for ACK (PC7) = 0
	* store byte into PA
	* set DAV (PC6) = 0
	* wait for ACK (PC7) = 1
	* read STATUS0/STATUS1 (PB0/PB1) into lowest 2 bits of ST (timeout r/w)
	* store $00 in PA
	* set DAV (PC6) = 1
* byte input
	* initial state: same
	* store $84 in PA
	* wait for ACK (PC7) = 0
	* set DDRA to $00 (data in)
	* set DAV (PC6) = 0
	* wait for ACK (PC7) = 1
	* read STATUS0/STATUS1 (PB0/PB1)
		* 3 means EOI
		* otherwise store into lowest 2 bits of ST (timeout r/w)
	* read PA
	* set DAV (PC6) = 1
	* wait for ACK (PC7) = 0
	* set DDRA to $FF (data out)
	* store $00 in PA
	* set DAV (PC6) = 0
	* wait for ACK (PC7) = 1
	* set DAV (PC6) = 1
* TALK/LISTEN
	* byte output with of $40/$20 with a $81 command
* SECOND/TKSA
	* byte output with of secondary address with a $82 command

	kcmd1	=$81		;state change
	kcmd2	=$82		;sec. addr
	kcmd3	=$83		;dout
	kcmd4	=$84		;din

* how to signal EOI to the device?
	* not necessary, UNLISTEN does this -> XXX?

* discussion
	* C264 series had super low cost C116: rubber keyboard, 16 KB, target price $49, only sold in Europe (100 DM, 99 GBP, which was about $75)
	* Plus/4 was pro, had additional ACIA chip, user port, 64 KB
	* Plus/4 could have had a TIA for IEEE-488 or similar
	* C16/C116 would have required a cartridge to support the fast drive
		* but why would you connect a fast drive to a C16/C116?
	* they decided on having a cartridge for all systems, making the Plus/4 cheaper
	* but expansion port does not provide a chip select for the external TIAs
		* so cartridge needs its own PLA
	* they decided on point-to-point instead of existing IEEE-488
		* this requires one cartridge per drive
		* cartridge doesn't need a connector
	* but the drive was very custom and therefore expensive
		* 1541 electronics would have worked
		* maybe clocked at 2 MHz for faster transfer
	* no strict separation of layers 2 and 2
		* codes $81 and $82 have knowledge of type of command byte (main or supplementary command byte)
		* they should only signal ATN yes/no
	* with two 1551 and one 1541, all three can communicate at the same time
		* with multiple 1541, formatting one disk blocks the bus
		* with two 1551 and one 1541, all three can format at the same time

![](docs/cbmbus/tcbm.gif =601x577)

* TODO: TCBM receive


# Referencces

* [The Complete Commodore 1551 ROM disassembly](http://www.cbmhardware.de/show.php?r=7&id=21) by Attila Grósz

[^1]: The VIC-20 was named after the VIC ("Video Interface Controller"), the video chip of the system.

[^2]: These computers are also often referenced as the "264 series", since originally three machines with the names C232, C264 and C364 were planned.

[^3]: A hardware defect in the VIC-20 required a significant slowdown of the bus timing. More information in the [article about the serial bus](https://www.pagetable.com/?p=1135).

[^4]: The 1551 schematics call these pins PA0-PA7, after port A of the MOS 6523 I/O controller it is connected to.