# Commodore Peripheral Bus: Part 3: Commodore DOS

## disk drive overview

* one or more drives
* file types:
	* PRG/SEQ/USR: sequential, only linear access, no seeking
	* REL: relative
* some drives:
	* partitions
	* subdirectories
	* burst commands

## channel number overview

* channel = 0 is reserved for a reading a PRG file.
* channel = 1 is reserved for a writing a PRG file.
* channel = 2-14 need the filetype and the read/write flag in the filename as ",P,W" for example.
* channel = 15 for DOS commands or device status info.

## command channel

* write: command
	* terminated by CR or UNLISTEN :(
* read: status
	* terminated by CR, will keep repeating
	* aa,sssss,bb,cc,d
	* with d:
		* 1001, 8050, 8250
	* without d:
		* 2031

	
<!--

10 open 1,8,15:rem,"ui"
20 get#1,a$:?a$;:ifa$<>chr$(13)goto20
rem25 goto20
30 close 1
run

-->

## files

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

### special files:
* "$"
	* $n for drive 0/1
	* $:abc*
	* link to post
* "#"
* "&"

## direct channels
	* fn "#" or "#n", where n is the buffer number (0-4 on 1541)
	* command channel will return buffer number

* limitations
	* 0 byte files don't exist

## Extra: Printers
* printers use the secondary address to pre-select a character set
* 0 Print data in Uppercase/Graphics mode
* 7 Print data in Upper/lowercase

## References
* http://www.softwolves.pp.se/idoc/alternative/vc1541_de/
* Schramm, K.: [Die Floppy 1541](https://spiro.trikaliotis.net/Book#vic1541). Haar bei München: Markt-und-Technik-Verlag, 1985. ISBN 3-89090-098-4
* ftp://www.zimmers.net/pub/cbm/manuals/printers/MPS-801_Printer_Users_Manual.pdf
