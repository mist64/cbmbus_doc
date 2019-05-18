# Commodore Peripheral Bus: Part 5: TCBM

In the [series about the variants of the Commodore Peripheral Bus family](https://www.pagetable.com/?p=1018), this article covers the lowest two layers (electrical and byte transfer) of the "TCBM" bus as found on the TED series computers: the C16, C116 and the Plus/4.


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

The only computers with a TCBM bus are the Commodore C16, C116 and Plus/4. Internally, Commodore called these the TED series, named after the core IC of the system[^1]. This name can be seen in multiple places in the [TED KERNAL and BASIC sources](https://github.com/mist64/cbmsrc) as well as [internal documentation](https://www.pagetable.com/?p=541). Many products around the TED series, like software cartridges, had product codes prefixed with "T".[^2]

The naming for the new peripheral bus of the TED is not completely consistent:

* Comments in the [KERNAL driver code](https://github.com/mist64/cbmsrc/tree/master/KERNAL_TED_05) call it the **Kennedy** or **KDY** interface – a reference to [the politician](https://en.wikipedia.org/wiki/Ted_Kennedy). Some places call it **TEDISK**.
* The 1551 power-on message is "CBM DOS 2.6 **TDISK**", which seems a variant of "TEDISK".
* The [users manual](http://www.zimmers.net/anonftp/pub/cbm/manuals/drives/1551_Disk_Drive_Users_Guide.pdf) and the [schematics](http://www.zimmers.net/anonftp/pub/cbm/schematics/drives/new/1551/251860.gif) of the 1551 disk drive call it **TCBM**. "CBM" is the common abbreviation of "Commodore Business Machines", and the "T", as always, stands for "TED".

## History and Development

The Commodore PET (1977) was using the industry-standard 8-bit parallel [IEEE-488 bus](https://www.pagetable.com/?p=1023) for disk drives and printers. For the VIC-20 (1981), Commodore changed layers 1 and 2 of the protocol stack (electrical and byte transfer) into a cheaper [serial bus](https://www.pagetable.com/?p=1135), which turned out to have severe speed problems[^3].

For the TED series (1984), Commodore decided to create another variant of the protocol stack, replacing layers 1 and 2 again. The new bus was supposed to combine the speed of the IEEE-488 bus with the low cost of the serial bus.


While the switch from parallel IEEE-488 to serial allowed the protocol stack to retain all key properties of the original design, TCBM drops some of these features:

| Feature | IEEE-488 | Serial | TCBM |
|---------|----------|--------|------|
| All participants are **daisy-chained**. | Yes | Yes | **No** |
| **One dedicated controller** (the computer) does bus arbitration of **up to 31 devices**. | Yes | Yes | **No** |
| **One-to-many**: Any participant can send data to any set of participants. | Yes | Yes | **No** |
| A device has **multiple channels** for different functions. | Yes | Yes | Yes |
| Data transmission is **byte stream** based. | Yes | Yes | Yes |

A device still has multiple channels, and all data transmission is still byte stream based, because these are properties of the layers 3 and 4, which are retained in TCBM.

The key difference is that the TCBM bus is point-to-point:

* The bus is between one controller (the computer) and one device.
* For connecting multiple devices to one computer, the computer needs one dedicated bus per device.
* Multiple busses are completely separate.

TCBM only allows the primary addresses 8 and 9, practically limiting the bus to (disk) drives. This also limits the number of busses to two: One for drive 8, and one for drive 9.

XXX the bus doesn't know about 8/9, only about 0/1 to signal, which *bus* it is...


TCBM has 8 data wires, but reduces the IEEE-488 signal wire count by three. (XXX REN doesn't count.)

| IEEE-488 Signal | Description        | Serial Signal | TCBM Signal |
|-----------------|--------------------|---------------|-------------|
| DIO1-8          | Data I/O           | DATA, CLK     | DIO1-8      |
| EOI             | End Or Identify    | (timing)      | STATUS0-1   |
| DAV             | Data Valid         | (CLK)         | (DAV/ACK)   |
| NRFD            | Not Ready For Data | (DATA)        | (DAV/ACK)   |
| NDAC            | No Data Accepted   | (timing)      | (DAV/ACK)   |
| IFC             | Interface Clear    | RESET         | RESET       |
| SRQ             | Service Request    | SRQ           | -           |
| ATN             | Attention          | ATN           | (DIO)       |
| REN             | Remote Enable      | -             | -           |

XXX TODO

## Layer 1: Electrical

### Connectors and Pinout

There are no standardized connectors. Both on the computer and the device side, the 17 wires are connected directly to the board through pin headers. This is the computer side:

[![](docs/cbmbus/tcbm_connector_small.jpg =600x311)](docs/cbmbus/tcbm_connector.jpg)

And the device side:

[![](docs/cbmbus/tcbm_connector2_small.jpg =600x311)](docs/cbmbus/tcbm_connector2.jpg)

This is the pinout:

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
* The two STATUS lines are used by the device to signal errors.
* The DAV and ACK lines are used for handshaking.
* The DEV line tells the computer whether the device number is 0 or 1.
* The RESET line resets the device.

### Paddle

The TED series spans from the super-low-cost[^5] C116 (rubber keyboard, 16 KB) to the "pro" Plus/4 with 64 KB, an additional ACIA chip for RS232 and built-in productivity software. The [Standard Serial](https://www.pagetable.com/?p=1135) port only requires 3 GPIO lines and was natively supported by all TED machines. A parallel bus would have required adding a I/O controller.

To save on costs, the I/O controller did not come with the machine, but one shipped with every disk drive, where the costs of the chip were eclipsed by the cost of the drive (USD 269).

The 1551 disk drive, the only TCBM device made, came with a fixed cable that ended in the so-called "Paddle", a cartridge for the TED expansion port. The expansion port on Commodore computers exposes the complete internal bus, allowing the I/O controller in the paddle to map itself into the computer's address space, at one of two locations, decided by the DEV line from the 1551.

XXX pic

So two 1551 drives required two paddles, each with an I/O controller mapped at a different location. Each paddle has a pass-through connector to allow connecting a another paddle or any other cartridge.

#### Multiple Busses

The TED computers support the Standard Serial bus and send all traffic to devices 4-30 to this bus. If a paddle with DEV = 0 is detected, it will direct traffic to drive 8 to this TCBM bus. And if there is a paddle with DEV = 1, all traffic to drive 9 will go to that TCBM bus. This allows a TED to have up to three separate Commodore Peripheral busses. All participants of the Standard Serial bus can talk to each other, but the TCBM busses are point-to-point.[^6]

The presence of a TCBM device is detected whenever a communication channel is initiated ([layer 3](https://www.pagetable.com/?p=1031) TALK or LISTEN) for devices 8 or 9.

## Layer 2: Byte Transfer

The byte transfer layer of TCBM defines the roles of the controller (which is the computer) and the device.

The controller and the device each own one handshaking line: DAV and ACK, respectively. The names stand for "Data Valid" and "Acklowledge", but in practice, they are just general handshaking lines with different meanings across the protocol.

The device also owns the two STATUS lines to communicacte error codes to the controller. The eight DIO lines are shared and used to send data in either direction. The protocol defines at what point which participant owns it.

All communication is initiated by the controller by telling the device whether data is sent to it or received from it, or whether a layer 3 command is sent to the device.

### Sending Bytes

When the controller sends data to the device, it owns the eight DIO lines during the whole process. The basic idea is that the controller sends a TCBM code of 0x83 to indicate a byte send, then sends the byte, and the device returns a two-bit status code.

![](docs/cbmbus/tcbm-send.gif =601x577)

Let's go through it step by step:

#### 0: Initial State
![](docs/cbmbus/tcbm-01.png =601x261)
In the initial state, the controller is holding the DAV line to indicate that it it is not ready for the next transmission. The device is holding the ACK line, meaning it is not ready either. The DIO and ST lines are all released.

#### 1: Controller puts code 0x83 on the bus
![](docs/cbmbus/tcbm-02.png =601x261)
All communication is initiated by the controller by putting a TCBM code byte onto DIO. 0x83 means that the controller intends to send a byte to the device.

#### 2: Device has accepted the code
![](docs/cbmbus/tcbm-03.png =601x261)
At some point the device is done handling the previous byte it may have received, so it detects the most significant bit of DIO set, reads the TCBM code, and signals that it has received the code by releasing ACK.

#### 3: Controller puts data on the bus
![](docs/cbmbus/tcbm-04.png =601x261)
Triggered by ACK being 0, the controller now puts the byte value onto DIO.

#### 4: Data on bus is now valid
![](docs/cbmbus/tcbm-05.png =601x261)
After that, the controller releases DAV, signaling that the data in DIO is valid.

#### 5: Device puts status on the bus
![](docs/cbmbus/tcbm-06.png =601x261)
Triggered by DAV being 0, the device reads the data from DIO and puts the two status bits onto ST.

#### 6: Device has accepted the data, status is valid
![](docs/cbmbus/tcbm-07.png =601x261)
It then pulls ACK, signaling that it has accepted the data and the status is valid.

#### 7: Controller clears data on the bus
![](docs/cbmbus/tcbm-08.png =601x261)
Triggered by ACK being 1, the controller reads the status, and clears the byte from the DIO lines and sets them back to 0, so they can't be interpreted as a TCBM code in the next cycle.

#### 8: Controller resets data valid
![](docs/cbmbus/tcbm-09.png =601x261)
In order to revert to the initial state, the sender then pulls DAV.

#### 9: Device resets status
![](docs/cbmbus/tcbm-10.png =601x261)
Triggered by DAV being 1 (the controller has read the status), the device clears the status. All wires are now in the initial state again. All steps are repeated as long as there is more data to be sent.

![](docs/cbmbus/tcbm-send.png =601x275)

### Receiving Bytes

When the controller wants to receive data from the device, ownership of the eight DIO lines is passed to the device and back. The basic idea is that the controller sends a TCBM code of 0x84 to indicate a byte receive, passes DIO to the device, the device returns the byte and a two-bit status code, and DIO is passed back to the controller.

![](docs/cbmbus/tcbm-receive.gif =601x577)

Here it is step by step:

#### 0: Initial State
![](docs/cbmbus/tcbm-11.png =601x261)
The initial state between bytes when receiving is the same as when sending: The controller is holding the DAV line to indicate that it it is not ready for the next transmission and the device is holding the ACK line, meaning it is not ready either. The DIO and ST lines are all released.

#### 1: Controller puts code 0x84 on the bus
![](docs/cbmbus/tcbm-12.png =601x261)
For receiving, the controller puts the TCBM code of 0x84 into DIO, indicating that it is now ready to receive a byte.

#### 2: Device has accepted the code
![](docs/cbmbus/tcbm-13.png =601x261)
As soon as the device is done handling the last transmission, it detects the most significant bit of DIO set, reads the TCBM code, and signals that it has received the code by releasing ACK.

#### 3: Controller clears data on the bus
![](docs/cbmbus/tcbm-14.png =601x261)
For the transmission of the data, the DIO lines will be operated by the device, so triggered by ACK being 0 (the device has received the code), the controller releases all DIO lines.

#### 4: Controller signals DIO belongs to device
![](docs/cbmbus/tcbm-15.png =601x261)
To signal that the DIO lines now belong to the device, the controller then releases DAV.

#### 5: Device puts data on the bus
![](docs/cbmbus/tcbm-16.png =601x261)
Triggered by DAV being 0, the device puts the data onto DIO.

#### 6: Device puts status on the bus
![](docs/cbmbus/tcbm-17.png =601x261)
It also puts the status bits onto ST.

#### 7: Data on bus is now valid
![](docs/cbmbus/tcbm-18.png =601x261)
After that, the device pulls ACK, signaling that the data in DIO is valid.

#### 8: Controller has accepted the data
![](docs/cbmbus/tcbm-19.png =601x261)
Triggered by ACK being 1, the controller reads the data from DIO and pulls DAV, indicating that it has accepted the data.

#### 9: Device clears data on the bus
![](docs/cbmbus/tcbm-20.png =601x261)
Triggered by DAV being 1, the device clears the data from DIO, in order to return ownership of these lines to the controller.

#### 10: Device clears status
![](docs/cbmbus/tcbm-21.png =601x261)
It then resets the status lines, so they are in the initial state again.

#### 11: Device signals it is done with DIO
![](docs/cbmbus/tcbm-22.png =601x261)
Finally, it releases ACK to indicate that it is no longer using DIO.

#### 12: Controller signals it owns DIO
![](docs/cbmbus/tcbm-23.png =601x261)
Triggered by ACK being 0, the controller releases DAV, meaning it now own the DIO lines again.

#### 13: Device returns to initial state
![](docs/cbmbus/tcbm-24.png =601x261)
Triggered by DAV being 0, the device pulls ACK, which is the initial state.

#### 14: Controller returns to initial state
![](docs/cbmbus/tcbm-25.png =601x261)
Triggered by ACK being 1, the controller pulls DAV. All wires are now in the initial state again. All steps are repeated as long as there is more data to be received.

Note that the protocol only specifies the triggers: For example, the controller is to read the data from DIO once ACK = 1, so it would be just as legal for the the device to put the status before the data on the bus, or put both the status and the data on the bus and pull ACK at the same time.

![](docs/cbmbus/tcbm-receive.png =601x275)

### Sending Commands

* TALK/LISTEN
	* byte output with of $40/$20 with a $81 command
* SECOND/TKSA
	* byte output with of secondary address with a $82 command

	kcmd1	=$81		;state change
	kcmd2	=$82		;sec. addr
	kcmd3	=$83		;dout
	kcmd4	=$84		;din

### Status Codes

* device can signal EOI to controller
* how to signal EOI to the device?
	* not necessary, UNLISTEN does this -> XXX?
* errors
	* fnf etc over "timeout" codes

* 01 Timeout during reading
* 10 Timeout during writing
* 11 End of data

### Timing

* timing completely flexible, no timeouts

### Discussion
* but expansion port does not provide a chip select for the external TIAs
	* so cartridge needs its own PLA
* they decided on point-to-point instead of existing IEEE-488
	* this requires one cartridge per drive
	* cartridge doesn't need a connector
* but the drive was very custom and therefore expensive
	* 1541 electronics would have worked
	* maybe clocked at 2 MHz for faster transfer
* no strict separation of layers 2 and 3
	* codes $81 and $82 have knowledge of type of command byte (main or supplementary command byte)
	* they should only signal ATN yes/no

* receiving (common case) is more expensive than sending :(
* why not just use (single-device?) IEEE-488?? this is not cheaper, but much slower!
* receiving step 4: not necessary. device can see DIO8 = 0
* versions
	* last bits were changed VERY LATE, patches in source!
	* sending: clear DIO, set DAV = 1
	* receiving: wait for ACK = 1, set DAV = 1
	* no, this was for supporting DEV=0/1; all protoytpe ROMs only support one paddle at $FEF0


# References

* [The Complete ROM dissasembly](http://yape.homeserver.hu/download/kernal.txt) by Mike Dailly
* [The Complete Commodore 1551 ROM disassembly](http://www.cbmhardware.de/show.php?r=7&id=21) by Attila Grósz
* [Original source code of various Commodore computers and peripherals](https://www.github.com/mist64/cbmsrc)

[^1]: The VIC-20 was named after the VIC ("Video Interface Controller"), the video chip of the system.

[^2]: These computers are also often referenced as the "264 series", since originally three machines with the names C232, C264 and C364 were planned.

[^3]: A hardware defect in the VIC-20 required a significant slowdown of the bus timing. More information in the [article about the serial bus](https://www.pagetable.com/?p=1135).

[^4]: The 1551 schematics call these pins PA0-PA7, after port A of the MOS 6523 I/O controller it is connected to.

[^5]: The C116 was supposed to compete with the Sinclair ZX81 and had a target price of $49. If ended up being sold only in Europe, for 100 DM or 99 GBP (which was about 75 USD).

[^6]: Here is a party trick: On a system with IEEE-488 or Standard Serial, the bus is blocked for all communication while one drive is busy with a long-running task, like formatting a disk. On a TED with one 1541 connected to Serial, and two 1551 drives connected to two separate TCBM busses, it is possible to all three drives format disks at the same time.






