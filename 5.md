# Commodore Peripheral Bus: Part 5: TCBM

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
* byte output
	* initial state
		* PA = $00
		* DAV (PC6) = 1
		* ACK (PC7) = 1
		* ST = 00
	* store $83 into PA
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
	* Plus/4 was pro, had additional ACIA chip
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

