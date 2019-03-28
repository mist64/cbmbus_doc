# Commodore Peripheral Bus: Part 3: Commodore DOS

## layer 3 features relevant from a device's view

* a device has 32 channels
* a channel can be associated (and dissociated) with a name
* device can send byte streams from channels
* device can receive byte streams into channels

## disk drive overview

* one or more drives
	* one "unit", drives 0 and 1
* file types
	* SEQ/PRG/USR: sequential, only linear access, no random access (seeking)
	* REL: relative

<!--
* some drives:
	* subdirectories
	* partitions
	* burst commands
-->

## channel number overview

* channels 0-14 need to be associated with names
	* filenames
	* special names
* channel 15 is status
* channels 16-31 illegal

<!--
|      |                 |
|------|-----------------|
| 0    | implicit ,P,R   |
| 1    | implicit ,P,W   |
| 2-14 | files           |
| 15   | commands/status |
-->

## named channels

* channels 0-14 need to be associated with names

### regular files

* filenames don't contain
	* 0xA0
	* ","
* don't start with
	* "$"
	* "#"
	* "&"
* filename length not specified (usually 16)

* file access string:
	* ,P/S/U/L
	* ,P/S/U/L,R/W/A
	* 0/1: (drive select)
	* @: (overwrite)
		* ,W fails if file exists
	* wildcards
		* ?
		* `*`

### special files:
* "$"
	* $n for drive 0/1
	* $:abc*
	* link to post
* "#"
	* fn "#" or "#n", where n is the buffer number (0-4 on 1541)
	* command channel will return buffer number
* "&"

## command channel

* write: command
	* uppercase ASCII commands (= PETSCII)
	* terminated by CR or UNLISTEN :(

| Name           | Syntax                                                   | Description                     |
|----------------|----------------------------------------------------------|---------------------------------|
| NEW            | `N`[_drv_]`:`_name_[,_id_]                               | Low-level or quick format       |
| VALIDATE       | `V`[_drv_]                                               | Re-build block availability map |
| INITIALIZE     | `I`[_drv_]                                               | Force reading disk metadata     |
| RENAME         | `R`[_drv_]`:`_new_name_`=`_old_name_                     | Rename file                     |
| COPY           | `C`[_drv_a_]`:`_target_name_`=`[_drv_b_]`:`_source_name_ | Copy file                       |
| SCRATCH        | `S`[_drv_]`:`_name_                                      | Delete file                     |
| DUPICATE       | `D:`[_drv_a_]``=``[_drv_b_]                              | Duplicate disk                  |
| POSITION       | `P`, _channel_ _position_                                | XXX                             |
| BLOCK-READ     | `B-R` _channel_ _track_ _sector_                         | Read sector                     |
| BLOCK-WRITE    | `B-W` _channel_ _track_ _sector_                         | Write sector                    |
| MEMORY-WRITE   | `M-W` _addr_lo_ _addr_hi_ _count_ _data_                 | Write RAM                       |
| MEMORY-READ    | `M-R` _addr_lo_ _addr_hi_ _count_                        | Read RAM                        |
| MEMORY-EXECUTE | `M-E` _addr_lo_ _addr_hi_                                | Execute code                    |
| U1/UA          | `U1` _channel_ _track_ _sector_                          | Read sector                     |
| U2/UB          | `U2` _channel_ _track_ _sector_                          | Write sector                    |
| U3-U8/UC-UH    | `U3-U7`                                                  | Execute code                    |
| U9/UI          | `U9`                                                     | Soft RESET                      |
| U:/UJ          | `U9`                                                     | RESET                           |

* read: status
	* terminated by CR, will keep repeating
	* aa,sssss,bb,cc,d
	* with d:
		* 1001, 8050, 8250
	* without d:
		* 2031, all serial devices



	
<!--

10 open 1,8,15,"ui"
20 get#1,a$:?a$;:ifa$<>chr$(13)goto20
30 close 1
run

-->

### limitations

* 0 byte files don't exist

## Extra: Printers

* printers use the secondary address to pre-select a character set
* 0 Print data in Uppercase/Graphics mode
* 7 Print data in Upper/lowercase

## References

* http://www.softwolves.pp.se/idoc/alternative/vc1541_de/
* Schramm, K.: [Die Floppy 1541](https://spiro.trikaliotis.net/Book#vic1541). Haar bei München: Markt-und-Technik-Verlag, 1985. ISBN 3-89090-098-4
* Inside Commodore DOS
* ftp://www.zimmers.net/pub/cbm/manuals/printers/MPS-801_Printer_Users_Manual.pdf


### Notes

* Data model first
* Then file names
* copy merge
* Wildcards
* Dup files diff types?
* S/R needs type?
