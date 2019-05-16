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
* Comments in the [KERNAL driver code](https://github.com/mist64/cbmsrc/tree/master/KERNAL_TED_05) call it **TEDISK**. Other places call it the "Kennedy" interface, which seems to be a reference to [Ted Kennedy](https://en.wikipedia.org/wiki/Ted_Kennedy).
* The 1551 power-on message contains the string **TDISK**.

## History and Development

The Commodore PET (1977) was using the industry-standard 8-bit parallel [IEEE-488 bus](https://www.pagetable.com/?p=1023) for disk drives and printers. For the VIC-20 (1981), they changed layers 1 and 2 of the protocol stack (electrical and byte transfer) into a cheaper [serial bus](https://www.pagetable.com/?p=1135), which turned out to have severe speed problems[^3]. For the TED series (1984), Commodore decided to create a new, low-cost parallel port for layers 1 and 2.

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

A device still has multiple channels, and all data transmission is still byte stream based, because these are properties of the layers 3 and 4, which are retained in TCBM.

---

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
* 264 series had up to three IEC-like busses, one serial IEC, and up to two TCBM (8 and 9)
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
* basics
	* DAV and DIO owned by sender
	* ACK and ST owned by receiver
	* ACK and DAV sometimes mean the opposite
* byte output
	* initial state
		* PA = $00
		* DAV (PC6) = 1
		* ACK (PC7) = 1
		* ST = 00
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
	* store $84 in PA
	* wait for ACK (PC7) = 0
	* set DAV (PC6) = 0
	* wait for ACK (PC7) = 1
	* read STATUS0/STATUS1 (PB0/PB1)
		* 3 means EOI
		* otherwise store into lowest 2 bits of ST (timeout r/w)
	* read PA
	* set DAV (PC6) = 1
	* wait for ACK (PC7) = 0
	* store $00 in PA
	* set DAV (PC6) = 0
* TALK/LISTEN
	* byte output with of $40/$20 with a $81 command
* SECOND/TKSA
	* byte output with of secondary address with a $82 command

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