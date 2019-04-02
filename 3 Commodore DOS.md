# Commodore Peripheral Bus: Part 3: Commodore DOS

In the [series about the variants of the Commodore Peripheral Bus family](https://www.pagetable.com/?p=1018), this article covers the common layer 4: The "Commodore DOS" interface to disk drives.

![](docs/cbmbus/layer4.png =601x251)

From a device's point of view, the layer below, layer 3 ("TALK/LISTEN") provides the following:

* A device has 32 channels (0-31).
* A channel (0-15) can be associated with a name and dissociated from it again.
* A device can send byte streams from channels.
* A device can receive byte streams into channels.

The Commodore DOS API defines the meaning of channel numbers, channel names in the context of disk drives. This article covers the common feature set of Commodore DOS, extensions will be described at the end of the article.

In contrast to all other articles of the series, this one is only meant as a conceptual overview of the design and not as a complete reference. The respective user manuals of Commodore and CMD disk drives are already very good references.

## Overview

What is usually called a disk drive and is associated with a primary address is actually a **unit**, because a unit can have more than one drive in its enclosure, like two mechanisms for two diskettes. Drives are numbered starting with 0, and there is no upper limit to the number of drives.

Every drive has its own independent filesystem. A filesystem has a name, a two-character ID, and contains an unsorted set of files. All files have a unique **name** and a file **type**, and have to be at least one byte in size[^1].

DOS does not specify a maximum size for disk or file names, but the limit for all Commodore devices is 16 characters. There is also no specified character encoding: Names consist of 8 bit characters, and DOS does not interpret them. Names have very few limitations:

* The comma and colon characters are illegal in disk or file names (because of the encoding of channel names and commands).
* The code `0xa0` (SPACE with with bit 7 set; PETSCII shifted SPACE) is illegal in file names (it is used as the terminating character on disk).

There are four file types (`SEQ`, `PRG`, `USR` and `REL`) that fall into two categories: sequential and relative.

**Sequential files** only allow linear access, i.e. it is impossible to position the read or write pointer. They can be appended to though. There are three types of sequential files: `SEQ`, `PRG` and `USR`. They are treated the same by DOS, but the user convention is to store executable programs in PRG files and data into SEQ files.

**Relative files** (`REL`) have a fixed record size of 1-254 bytes and allow positioning the read or write pointer to any record and thus allow random access.

While the interface to DOS often requres to specify the file type, it is not part of a file's identifier, i.e. there can not be two files with the same name but just a different type.

## Channel Numbers

| Channel | Description       |
|---------|-------------------|
| 0       | named (PRG read)  |
| 1       | named (PRG write) |
| 2-14    | named             |
| 15      | commands/status   |
| 16-31   | illegal           |

Channels 0 to 14 need to be associated with a name. 0 and 1 only support special kinds of names and will be discussed later. Channel 15 is used to send either global commands, or commands that deal with named channels, and to read the result code or general status of the unit.

While the underlying layers of the bus specifies channel numbers (secondary addressed) from 0 to 31, Commodore DOS does not support numbers 16-31.

## Named Channels

Channels 0 to 14 need to be associated with names. Names are used to create channels for reading or writing a file, reading the directory listing and reading/writing sectors directly. Empty names are illegal.

Channels 0 and 1 are special. They both force XXX

### Files

A named channel can be used to open a file for reading or writing. The syntax for the channel's name is as follows:

[[`@`][_drive_]`:`]_filename_[`,`_type_[`,`_access_]]

The core of the channel name is the name of the file to be accessed. If an existing file is opened, wildcards (see below) are allowed.

There are optional prefixes and suffixes.

* By default, drive 0 is assumed. This can be overridden by a leading drive number, followed by a colon[^2].

* The modifier flag "`@`" specifies that the file is supposed to be overwritten, if it is opened for writing and it already exists[^3] - the default is to return an error. The use of "`@`", a drive number, or both, requires to add a colon character as a delimiter between the prefix and the filename.

* By using the drive prefix (or just using a "`:`" prefix, it is possible to use filenames that start with "`$`", "`#`" or "`&`". These letters would otherwise indicate special named channels (see next sections).

* The file type is one of "`S`" (`SEQ`), "`P`" (`PRG`),  "`U`" (`USR`), or "`L`" (`REL`). If the type is omitted, `PRG` is assumed.

* The _access_ byte depends on the file type: For `SEQ`, `PRG` and `USR`, a file can be opened for reading, by specifying "`R`", for writing using "`W`" and for appending using "`A`". The default is for reading. For relative files, the access byte is the binary-encoded record size. For creating a relative file, it must be specified, for opening an existing one, it can be omitted. Relative files are always open for reading _and_ writing.

Sequential files can then be read from or written to, depending on the access type. Files opened for writing need to be closed again for all data structures on disk to be valid. Relative files allow reading and writing and do not have to be closed for the data on disk to be consistent. In order to position the read/write pointer to a particular record, the command channel is used (see below).

### Directory Listing

The "`$`" name is used to read the directory listing. This is the syntax:

`$`[[_drive_]`:`][_pattern_]

Just using "`$`" as the name will return the complete directory contents of drive 0. Specifying the drive number, followed by a colon, will override this. Additionally, a file name pattern can be appended to filter which directory entries are returned.

The [format of the data returned is tokenized Microsoft BASIC](https://www.pagetable.com/?p=273).

### Direct-Access Buffer I/O
* "#"
	* fn "#" or "#n", where n is the buffer number (0-4 on 1541)
	* command channel will return buffer number

### "&"
* "&"

## command channel

* write: command
	* uppercase ASCII commands (= PETSCII)
	* terminated by CR or UNLISTEN :(

| Name           | Syntax                                                | Description                     |
|----------------|-------------------------------------------------------|---------------------------------|
| NEW            | `N`[_drv_]`:`_name_[,_id_]                            | Low-level or quick format       |
| VALIDATE       | `V`[_drv_]                                            | Re-build block availability map |
| INITIALIZE     | `I`[_drv_]                                            | Force reading disk metadata     |
| RENAME         | `R`[_drv_]`:`_new_name_`=`_old_name_                  | Rename file                     |
| COPY           | `C`[_drv_a_]`:`_target_name_`=`[_drv_b_]`:`_source_name_[,...] | Copy/concatenate files |
| SCRATCH        | `S`[_drv_]`:`_name_[`,`...]                           | Delete files                    |
| DUPICATE       | `D:`[_drv_a_]``=``[_drv_b_]                           | Duplicate disk                  |
| POSITION       | `P` _channel_ _pos_lo_ _pos_hi_ _offset_              | Set record index in REL file    |
| BLOCK-READ     | `B-R` _channel_ _track_ _sector_                      | Read sector                     |
| BLOCK-WRITE    | `B-W` _channel_ _track_ _sector_                      | Write sector                    |
| MEMORY-WRITE   | `M-W` _addr_lo_ _addr_hi_ _count_ _data_              | Write RAM                       |
| MEMORY-READ    | `M-R` _addr_lo_ _addr_hi_ _count_                     | Read RAM                        |
| MEMORY-EXECUTE | `M-E` _addr_lo_ _addr_hi_                             | Execute code                    |
| U1/UA          | `U1` _channel_ _track_ _sector_                       | Synonym of B-R                  |
| U2/UB          | `U2` _channel_ _track_ _sector_                       | Synonym of B-W                  |
| U3-U8/UC-UH    | `U3-U7`                                               | Execute code                    |
| U9/UI          | `U9`                                                  | Soft RESET                      |
| U:/UJ          | `U9`                                                  | Hard RESET                      |


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

## Wildcards

## limitations

* 0 byte files don't exist
* all Commodore drives:
	* 0 and 1 byte files buggy
	* read back as 13 0 2 13
* CMD drives
	* 0 byte files will have single 13

<--
10 open 1,8,15,"ui"
20 get#1,a$:?a$;:ifa$<>chr$(13)goto20
30 close 1
40 open 1,8,15,"s:test"
50 get#1,a$:?a$;:ifa$<>chr$(13)goto50
60 close 1
70 open2,8,2,"test,p,w"
75 print#2,"ab";
80 close2
90 open2,8,2,"test,p,r"
100 fori=1to10
110 get#2,a$:?asc(a$+chr$(0)),st
120 next
run
-->

## optional features

* consistent feature set on
	* all IEEE-488 drives (e.g. 2040 [1978], D9060/D9090 HD, SFD 1001 [1985])
	* 1540, 1541(-C, -II), 1551; 1541 clones
* later "Fast Serial" devices had additions

### 1571

* burst commands

### 1581

* partitions (`CBM`)

| Name           | Syntax                                                | Description                     |
|----------------|-------------------------------------------------------|---------------------------------|
| PARTITION      | `/`[_drv_][`:`_name_[`,`_track_ _sector_ _count_lo_ _count_hi_ `,C`]] | Select/create partition |

### CMD
* CMD-style partitions
* subdirectories (`DIR`), CMD
* real-time clock
* lots of commands

## Extra: Printers

* printers use the secondary address to pre-select a character set
* 0 Print data in Uppercase/Graphics mode
* 7 Print data in Upper/lowercase

## References

* http://www.softwolves.pp.se/idoc/alternative/vc1541_de/
* Schramm, K.: [Die Floppy 1541](https://spiro.trikaliotis.net/Book#vic1541). Haar bei München: Markt-und-Technik-Verlag, 1985. ISBN 3-89090-098-4
* Inside Commodore DOS
* https://www.lyonlabs.org/commodore/onrequest/cmd/CMD_Hard_Drive_Users_Manual.pdf
* ftp://www.zimmers.net/pub/cbm/manuals/printers/MPS-801_Printer_Users_Manual.pdf

<!---

### Notes

* Scratch needs type? no, gets ignored


/Users/mist/Library/Mobile\ Documents/com~apple~CloudDocs/Applications/x64.app/Contents/MacOS/x64 -dos4000 /Users/mist/Libry/Mobile\ Documents/com~apple~CloudDocs/JiffyDOS/JiffyDOS_Complete_Manual_PDF/CMD\ FD-2000\ DOS\ V1.40\ CS\ 33CC6F.bin -drive8type 4000

10 open 1,8,15,"ui"
20 get#1,a$:?a$;:ifa$<>chr$(13)goto20
30 close 1
40 open 1,8,15,"s:test"
50 get#1,a$:?a$;:ifa$<>chr$(13)goto50
60 close 1
70 open2,8,2,"test,p,w"
rem 75 print#2,"ab";
80 close2
90 open2,8,2,"test,p,r"
100 fori=1to10
110 get#2,a$:?asc(a$+chr$(0)),st
120 next
run


10 open 1,8,15,"ui"
100 fori=1to10
110 get#1,a$:?asc(a$+chr$(0)),st
120 next
run


--->

[^1]: This is a limitation of the layer 2 protocol: It is impossible to send a 0-byte stream of bytes.

[^2]: Most devices only have a single drive, so in practice, drive numbers are rarely specified.

[^3]: All single-drive Commodore devices except the 1571 (revision 5 ROM only), 1541-C, 1541-II and 1581 have a [bug](https://groups.google.com/forum/#!topic/comp.sys.cbm/TKKl8a-3EPA) that can currupt the filesystem when using the overwrite feature.