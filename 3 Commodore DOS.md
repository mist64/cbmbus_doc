# Commodore Peripheral Bus: Part 3: Commodore DOS

In the [series about the variants of the Commodore Peripheral Bus family](https://www.pagetable.com/?p=1018), this article covers the common layer 4: The "Commodore DOS" interface to disk drives.

Commodore DOS provides file as well as direct block access APIs, and is supported by all floppy disk and hard disk drives for the Commodore 8 bit family (such as the well-known 1541), independently of the connectors and byte transfer protocols on the lower layers of the protocol stack.

![](docs/cbmbus/layer4.png =601x251)

From a device's point of view, the layer below, layer 3 ("TALK/LISTEN") defines the following:

* A device has 32 channels (a.k.a. secondary addresses, 0-31).
* A channel (0-15) can be associated with a name and dissociated from it again.
* A device can send byte streams from channels.
* A device can receive byte streams into channels.

The Commodore DOS API defines the meaning of channel numbers, channel names and the data traveling over channels in the context of disk drives. This article covers the common feature set of Commodore DOS since version 2.0, extensions will be described at the end of the article.

Contrary to the other articles of the series, this one is only meant as a conceptual overview of the design and not as a complete reference. The respective user manuals of Commodore and CMD disk drives are already very good references.

## Concepts

### Units and Drives

What is usually called a disk drive and is associated with a primary address is actually a **unit**, because a unit can have more than one drive in its enclosure, like two mechanisms for two diskettes. Drives are numbered starting with 0, and there is no upper limit to the number of drives.

### Files

Every drive has its own independent filesystem. A filesystem has a name, a two-character ID, and contains an unsorted set of files. All files have a unique **name** and a file **type**, and have to be at least one byte in size[^1].

DOS does not specify a maximum size for disk or file names, but the limit for all Commodore devices is 16 characters. There is also no specified character encoding: Names consist of 8 bit characters, and DOS does not interpret them. Names have very few limitations:

* The comma, colon and `CR` (carriage return) characters are illegal in disk or file names (because of the encoding of channel names and commands).
* The code `0xa0` (ISO 8859-1 non-breaking space, PETSCII shifted SPACE) is illegal in file names (it is used as the terminating character on disk).

There are four file types (`SEQ`, `PRG`, `USR` and `REL`) that fall into two categories: sequential and relative.

**Sequential files** only allow linear access, i.e. it is impossible to position the read or write pointer. They can be appended to though. There are three types of sequential files: `SEQ`, `PRG` and `USR`. They are treated the same by DOS, but the user convention is to store executable programs in PRG files and data into SEQ files.

**Relative files** (`REL`) have a fixed record size of 1-254 bytes and allow positioning the read/write pointer to any record and thus allow random access.

While the interface to DOS often requres to specify the file type, it is not part of a file's identifier, i.e. there can not be two files with the same name but just a different type.

### Wildcards

Some interfaces features permit using wildcard characters:
* A question mark ("`?`") matches any character.
* An asterisk ("`*`") matches zero or more characters. Characters in the pattern after the asterisk are ignored.

### Blocks

XXX
* describe three APIs:
	* level 1: file level API - for built-in data structures
	* level 2: block API - for custom optimized data structures
	* level 3: code execution - meant to extend the functionality

There is a set of lower-level APIs that allows reading and writing individual blocks (of 256 bytes) and marking them as allocated or free in the disk's metadata. For certain use cases, this does not require an understanding of any of the disk's internal data structures.

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

Channels 0 to 14 need to be associated with names. Names are used to create channels for reading or writing a file, reading the directory listing and reading/writing blocks directly. Empty names are illegal.

Channels 0 and 1 are special shortcuts to drive the cases below with less syntax:

* Channel 0 is the `LOAD` channel: It forces a type of `PRG` and an access mode of "read". It works with regular files and the directory listing.
* Channel 1 is the `SAVE` channel: It forces a type of `PRG` and an access mode of "write". It works with regular files only.

### Files

A named channel can be used to open a file for reading or writing. The syntax for the channel's name is as follows:

[[`@`][_drive_]`:`]_filename_[`,`_type_[`,`_access_]]

The core of the channel name is the name of the file to be accessed. If an existing file is opened, wildcards (see below) are allowed.

There are optional prefixes and suffixes.

* By default, drive 0 is assumed. This can be overridden by a leading drive number, followed by a colon[^2].

* The modifier flag "`@`" specifies that the file is supposed to be overwritten, if it is opened for writing and it already exists[^3] - the default is to return an error. The use of "`@`", a drive number, or both, requires to add a colon character as a delimiter between the prefix and the filename.

* By using the drive prefix (or just using a "`:`" prefix, it is possible to use filenames that start with "`$`" or "`#`". These letters would otherwise indicate special named channels (see next sections).

* The file type is one of "`S`" (`SEQ`), "`P`" (`PRG`),  "`U`" (`USR`), or "`L`" (`REL`). If the type is omitted, `PRG` is assumed.

* The _access_ byte depends on the file type: For `SEQ`, `PRG` and `USR`, a file can be opened for reading, by specifying "`R`", for writing using "`W`" and for appending using "`A`". The default is for reading. For relative files, the access byte is the binary-encoded record size. For creating a relative file, it must be specified, for opening an existing one, it can be omitted. Relative files are always open for reading _and_ writing.

Sequential files can then be read from or written to, depending on the access type. Files opened for writing need to be closed again for all data structures on disk to be valid. Relative files allow reading and writing and do not have to be closed for the data on disk to be consistent. Positioning of the read/write pointer to a particular record is done using the command channel ("`P`" command, see below).

### Directory Listing

The "`$`" name is used to read the directory listing. This is the syntax:

`$`[[_drive_]`:`][_pattern_[`,`...][`=`_type_]]

Just using "`$`" as the name will return the complete directory contents of drive 0. Specifying the drive number, followed by a colon, will override this. Additionally, one or more file name patterns can be appended to filter which directory entries are returned. Finally, specifying "`=`" followed by a single-character file type specifier, will only show files of a particular type.

The [format of the data returned is tokenized Microsoft BASIC](https://www.pagetable.com/?p=273).

### Direct Access Buffer I/O

The "`#`" name is used to allocate a block-sized buffer inside the device. This is the syntax:

`#`[_buffer_number_]

There are two use cases for allocated buffers:

* When specifying a number, a particular buffer will be allocated, if available. This is useful for allocating a specific memory area in the device in order to upload code for execution. The mapping from buffer number to RAM address is device-specific - but so is the uploaded code: On a Commodore 1541, for example, buffer 2, which is located from `$0500` to `$05ff` in RAM, is the "user buffer". The "`U3`"-"`U8`" command channel commands are shortcuts to execute code in this buffer.
* Without an explicit number, any free buffer in the device's RAM will be allocated. This is what you do to have a buffer for reading and writing blocks.

<!--
10 fori=0to10
20 open2,8,2,"#"+str$(i)
30 dos
40 close2
50 next
run
-->

The buffer stays allocated as long as the named channel is open. The "`B-R`", "`B-W`", "`B-P`", "`U1`" and "`U2`" commands on the command channel take the channel number of the buffer as an argument.

## Command Channel

The command channel is always available as channel 15. When writing to it, the device interprets the byte stream as commands in a unified format. When reading from it, the byte stream from the device is usually status information in a unified format (with the exception of the reply to "`M-R`", see below).

## Status

The status information that is sent from channel 15 is a `CR`-delimited ASCII-encoded string with a uniform encoding:

_code_`,`_string_`,`_a_`,`_b_[`,`_c_]

* _code_ is a two-digit decimal error code.
* _string_ is a short English-language version of the error code.
* _a_ and _b_ are two additional at least two-digit decimal numbers[^4] that depend on the type of error ("`00`" if unused).
* _c_ is the single-digit decimal number drive that caused the status message. Devices with only a single drive don't usually return this[^5].

A status code of 0 will return the string "`00, OK,00,00`" (or "`00, OK,00,00,0`" on dual-drive devices, assuming the last command was performed on drive 0).

The first decimal digit encodes the category of the error.

| First Digit | Description                  |
|-------------|------------------------------|
| 0, 1        | No error, informational only |
| 2           | Physical disk error          |
| 3           | Error parsing the command    |
| 4           | Controller error (CMD only)  |
| 5           | Relative file related error  |
| 6           | File error                   |
| 7           | Generic disk or device error |
| 8, 9        | unused                       |

Note that a program cannot rely on any of these strings, just on the codes.

The full list of error messages can be found in practically every disk drive users manual, here are just some examples:

* `00, OK,00,00`: There was no error.
* `01, FILES SCRATCHED,03,00`: Informational: 3 files have been deleted ("scratched").
* `23,READ ERROR,18,00`: There was a checksum error when trying to read track 18, sector 0.
* `31,SYNTAX ERROR,00,00`: The command sent was not understood.
* `51,OVERFLOW IN RECORD,00,00`: More data was written into a REL file record that fits.
* `65,NO BLOCK,17,01`: When trying to allocate a block using the `B-A` command, the given block was already allocated. Track 17, sector 1 is the next free block.
* `66,ILLEGAL TRACK OR SECTOR,99,00`: A user command or data structures on disk referenced track 99, sector 00, which does not exist.
* `73,CBM DOS V2.6 1541,00,00`: This status is returned after the RESET of a device (and after the command "`UI`"). The actual message is specific to the device and can be used to detect the type and sometimes the ROM version[^6].

Reading the status will clear it. Keeping on reading will keep returning status messages.

The following BASIC program will read a single status message:

	10 OPEN 1,8,15
	20 GET#1,A$: PRINT A$;: IF A$<>CHR$(13) GOTO 20
	30 CLOSE 1

## Commands

All commands are byte streams that are mostly ASCII/PETSCII, but with some binary arguments in some cases. There are two different ways to send them:

They can be sent as a byte stream to channel 15, terminated an `EOI` or `UNLISTEN` event[^7]. The follwing BASIC code send the command "`I`" to drive 8 this way:

    OPEN 1,8,15
    PRINT#1, "I";
    CLOSE 1

(On layer 3, this will send `LISTEN 8`/`SECOND 15`/"`I`"/`UNLISTEN`.)

Alternatively, channel 15 can be opened as a named channel with the command as the name. This does not actually perform an open operation, and a closing would be a no-op. It just allows shorter code, e.g. in BASIC:

	OPEN 1,8,15,"I"
	CLOSE 1

(On layer 3, this will send `LISTEN 8`/`OPEN 15`/"`I`"/`UNLISTEN`/`LISTEN 8`/`CLOSE 15`/`UNLISTEN`.)

In both cases, commands that don't contain binary arguments can also be terminated by the `CR` character.

The following sections will give an overview of the different command categories.

### Filesystem Commands

The filesystem commands deal with creating, fixing and modifying the filesystem. There is also a command that does a block-for-block disk copy for units with more than one drive.

On multi-drive units, the copy command can also copy files between drives, while on single-drive units, it can only duplicate files. In either case, it can concatenate several files into one.

All arguments for these commands are text. Except for the duplicate command, all drive numbers are optional and default to 0.

| Name           | Syntax                                                | Description                     |
|----------------|-------------------------------------------------------|---------------------------------|
| INITIALIZE     | `I`[_drv_]                                            | Force reading disk metadata     |
| VALIDATE       | `V`[_drv_]                                            | Re-build block availability map |
| NEW            | `N`[_drv_]`:`_name_[,_id_]                            | Low-level or quick format       |
| RENAME         | `R`[_drv_]`:`_new_name_`=`_old_name_                  | Rename file                     |
| SCRATCH        | `S`[_drv_]`:`_pattern_[`,`...]                        | Delete files                    |
| COPY           | `C`[_drv_a_]`:`_target_name_`=`[_drv_b_]`:`_source_name_[,...] | Copy/concatenate files |
| COPY           | `C`_dst_drv_`=`_src_drv_                              | Copy all files between disk     |
| DUPLICATE      | `D:`_dst_drv_``=``_src_drv_                           | Duplicate disk                  |

### Command for Relative Files

While a relative file is open, a command on the command channel is used to position the read/write pointer to a particular record. The arguments are four binary-encoded bytes.

| Name           | Syntax                                                | Description                     |
|----------------|-------------------------------------------------------|---------------------------------|
| POSITION       | `P` _channel_ _record_lo_ _record_hi_ _offset_        | Set record index in REL file    |

### Direct Access Commands

The direct access commands require a direct access buffer to be allocated ("`#`"). The `U1` and `U2` commands allow reading a block into the buffer and writing the buffer into a block. Reading from the channel will read from the buffer and writing to the channel will write to it. Both operations will advance the buffer pointer, which can be set to an explicit offset using the "`B-P`" command.

The `B-R` and `B-W` commands are deceptive: The names suggest they are general-purpose block read/write commands, but they assume a certain data format of the blocks: The first byte is the block's buffer pointer. When writing a block, the current buffer pointer will be put into it, signaling how many valid bytes are contained in the block. When reading, it marks the end of the buffer that cannot be read past[^8].

Commodore DOS specifies that all devices have logical blocks that are 256 bytes in size and are addressed by an 8 bit track number (starting from 1) and an 8 bit sector number (starting from 1)[^9].

All arguments are decimal ASCII values and can be separated by a space, a comma or a code `0x1d` (ASCII "Group Separator", PETSCII "Cursor Right"). The command name and the first argument have to be separated by any of the above or a colon.

| Name           | Syntax                                                | Description                     |
|----------------|-------------------------------------------------------|---------------------------------|
| U1/UA          | `U1` _channel_ _track_ _sector_                       | Raw read of a block             |
| U2/UB          | `U2` _channel_ _track_ _sector_                       | Raw write of a block            |
| BUFFER-POINTER | `B-P` _channel_ _index_                               | Set r/w pointer within block    |
| BLOCK-READ     | `B-R` _channel_ _track_ _sector_                      | Read block                      |
| BLOCK-WRITE    | `B-W` _channel_ _track_ _sector_                      | Write block                     |
| BLOCK-EXECUTE  | `B-E` _channel_ _track_ _sector_                      | Load and execute a block        |

### Block Avariability Map Commands

The "`B-A`" and "`B-F`" commands allow marking a block as allocated or free in the "block availability map" (BAM). Allocating a block makes sure the filesystem won't use it. The `V` (validate) command will re-build the BAM from the filesystems metadata and undo any "`B-A`" commands.

The argument encoding is the same as for direct access.

| Name           | Syntax                                                | Description                     |
|----------------|-------------------------------------------------------|---------------------------------|
| BLOCK-ALLOCATE | `B-A` _drive_ _track_ _sector_                        | Allocate a block in the BAM     |
| BLOCK-FREE     | `B-F` _drive_ _track_ _sector_                        | Free a block in the BAM         |

### Memory Commands

The memory commands allow reading and writing device memory as well as executing code in the context of the interface CPU. This CPU is usually a 6502 derivative, but executing code is highly device-specific in any case.

The resulting bytes from the "`M-R`" command will be delivered through channel 15 in place of the status string.

The arguments are binary-encoded bytes.

| Name           | Syntax                                                | Description                     |
|----------------|-------------------------------------------------------|---------------------------------|
| MEMORY-WRITE   | `M-W` _addr_lo_ _addr_hi_ _count_ _data_              | Write RAM                       |
| MEMORY-READ    | `M-R` _addr_lo_ _addr_hi_ _count_                     | Read RAM                        |
| MEMORY-EXECUTE | `M-E` _addr_lo_ _addr_hi_                             | Execute code                    |

### Utility Loader Command

The utility loader command instructs the unit to load a file into its RAM and execute it. The file has to follow a certain format and contains checksums[^10].

| Name           | Syntax                                                | Description                     |
|----------------|-------------------------------------------------------|---------------------------------|
| UTILITY LOADER | `&`[[_drv_]`:`]_name_                                 | Load and execute program        |

### USER Commands

The `USER` commands were meant to give the user a command interface that calls uploaded code or code in expansion ROM (if available).

The commands `U1` to `U9` and `U:` (and their synonyms `U1` to `U:`) execute code through a jump table. There is a default jump table that can be replaced using a device-specific `M-W` command, and reset to the default using `U0`.

The default jump table contains the already discussed `U1` and `U2` commands for reading and writing blocks[^11]. `U3` to `U8` jump into some useful device-specific locations. On most devices, all these jumps point into the user buffer, on some older devices, some jumps point into expansion ROM.

The commands `U9` and `U:` execute a soft and a hard reset, respectively. In both cases, the status will read back code 73.

| Name           | Syntax                                                | Description                     |
|----------------|-------------------------------------------------------|---------------------------------|
| U0             | `U0`                                                  | Init user vectors               |
| U1-U2/UA-UB    | (see above)                                           | Raw read/write of a block       |
| U3-U8/UC-UH    | `U3` - `U8`                                           | Execute in user buffer or expansion ROM |
| U9/UI          | `UI`                                                  | Soft RESET (NMI)                |
| U:/UJ          | `UJ`                                                  | Hard RESET                      |

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

## Optional Features

Practically all features described so far are supported on all but the very first (1.x) Commodore devices. Third party devices also generally support even the low-level and code execution APIs, even though these APIs require knowledge of the differences in the architecture of the interface.

With the advent of "Fast Serial" devices (1571, 1581), the APIs were significantly extended. Devices by CMD added their own extensions as well.

### 1541

For the 1541, the timing of the layer 2 Serial protocol was slowed down to support the C64's unique timing properties. Since the 1541 replaced the 1540, it came with a mode to switch back to the faster VIC-20 Serial protocol[^12].

| Name           | Syntax                                                | Description                     |
|----------------|-------------------------------------------------------|---------------------------------|
| USER           | `UI`{`+`&#x7c;`-`}                                    | Use C64/VIC-20 Serial protocol  |

### 1571

The 1571 adds several new generic commands:

| Name           | Syntax                                                | Description                     |
|----------------|-------------------------------------------------------|---------------------------------|
| USER           | `U0>S` _val_                                          | Set sector interleave           |
| USER           | `U0>R` _num_                                          | Set number fo retries           |
| USER           | `U0>T`                                                | Test ROM checksum               |
| USER           | `U0>` + CHR$(#DEV), where #DEV = 4 - 30

XXX they're U0 because it was easy to add them to the 1571 without changing the ROM layout too much

The following two additions are 1571-specific:

| Name           | Syntax                                                | Description                     |
|----------------|-------------------------------------------------------|---------------------------------|
| USER           | `U0>M` _flag_                                         | Enable/disable 1541 emulation mode|
| USER           | `U0>H` _number_                                       | Select head 0/1                 |


XXX burst commands
* only support drives 0 and 1

### 1581

In addition to all generic 1571 commands, the 1581 adds support for partitions. They occupy any number of contiguous sectors, are treated as files by the root filesystem (type `CBM`) and can be arbitrarily nested.

| Name           | Syntax                                                | Description                     |
|----------------|-------------------------------------------------------|---------------------------------|
| PARTITION      | `/`[_drv_][`:`_name_]                                 | Select partition |
| PARTITION      | `/`[_drv_]`:`_name_`,`_track_ _sector_ _count_lo_ _count_hi_ `,C` | Create partition |

And there are a few more generic commands:

| Name           | Syntax                                                | Description                     |
|----------------|-------------------------------------------------------|---------------------------------|
| USER           | `U0>B` _flag_                                         | Enable/disable Fast Serial      |
| USER           | `U0>V` _flag_                                         | Enable/disable verify           |
| USER           | `U0>I` _val_                                          | Set Serial timeout value        |
| USER           | `U0>MR` _addr_hi_ _count_hi_                          | Read RAM (Burst protocol)       |
| USER           | `U0>MW` _addr_hi_ _count_hi_                          | Write RAM (Burst protocol)      |

XXX ;	"U0>I"+CHR$(IEEE_TIMEOUT_VALUE)

XXX new path syntax with partitions

### Commodore RAMDOS

XXX

* ftp://www.zimmers.net/pub/cbm/manuals/peripherals/1764_Ram_Expansion_Module_Users_Guide.pdf
* https://github.com/xlar54/ramdos2crt-master/blob/master/src/c128devpack/ramdos12.src

### JiffyDOS

XXX jiffydos.manual.txt

### CMD Devices

Floppy drives and hard drives by Creative Micro Devices (CMD) support all 1581 commands and features, and have some additions of their own.

XXX RAMLink

#### CMD-style partitions

Independently of 1581 partitions, CMD devices have "native" partitions that cannot be nested. There is a global partition table on disk.

| Name           | Syntax                                                | Description                     |
|----------------|-------------------------------------------------------|---------------------------------|
| CHANGE PARTITION | `CP` _num_                                          | Make a partition the default    |
| GET PARTITION  | `GP` _num_                                            | Get information about partition |
| RENAME-PARTITION | `R-P:`_new_name_`=`_old_name_                       | Rename a partition              |
| RENAME-HEADER  | `R-H`[_drv_]`:`_new_name_                             | Rename a filesystem             |

#### Sub-Directories

CMD devices also add subdirectory support.

| Name           | Syntax                                                | Description                     |
|----------------|-------------------------------------------------------|---------------------------------|
| CHANGE DIRECTORY | `CD`[_drv_]`:`_name_                                | Change the current sub-directory|
| MAKE DIRECTORY | `MD`[_drv_]`:`_name_                                  | Create a sub-directory          |
| REMOVE DIRECTORY | `RD`[_drv_]`:`_name_                                | Delete a sub-directory          |

#### Real-Time Clock

Some CMD devices have a real-time clock that can be read and written in multiple formats.

| Name           | Syntax                                                | Description                     |
|----------------|-------------------------------------------------------|---------------------------------|
| TIME READ ASCII | `T-RA`                                               | Read Time/Date (ASCII)          |
| TIME WRITE ASCII | `T-WA` _dow_ _mo_`/`_da_`/`_yr_ _hr_`:`_mi_`:`_se_ _ampm_ | Write Time/Date (ASCII)   |
| TIME READ DECIMAL | `T-RD`                                             | Read Time/Date (Decimal)        |
| TIME WRITE DECIMAL | `T-WD` _b0_ _b1_ _b2_ _b3_ _b4_ _b5_ _b6_ _b7_    | Write Time/Date (Decimal)       |
| TIME READ BCD  | `T-RB`                                                | Read Time/Date (BCD)            |
| TIME WRITE BCD | `T-WB` _b0_ _b1_ _b2_ _b3_ _b4_ _b5_ _b6_ _b7_ _b8_   | Write Time/Date (BCD)           |

#### Misc

And finally, there are some miscellaneous new commands.

| Name           | Syntax                                                | Description                     |
|----------------|-------------------------------------------------------|---------------------------------|
| LOCK           | `L`[_drv_]`:`_name_                                   | Toggle file write protect       |
| WRITE PROTECT  | `W-`{`0`&#x7c;`1`}                                    | Set/unset device write protect  |
| GET DISKCHANGE | `G-D`                                                 | Query disk change (FD only)     |
| SCSI COMMAND   | `S-C` _scsi_dev_num_ _buf_ptr_lp_ _buf_ptr_hi_ _num_bytes_ | Send SCSI Command (HD only) |
| SWAP           | `S-`{`8`&#x7c;`9`&#x7c;`D`}                           | Change primary address          |

#### Syntax Additions

XXX

* partitions
	* Partition numbers can be used in place of drive numbers in all file specifiers and commands. Partition 0 is the current partition.
* directories
* more options for directory listings
	* partition directory

### C65 Disk Drive

For the internal C65 disk drive, support for CMD-style partitions and sub-directories was planned, but never implemented. None of the other commands added by CMD are supported, but the DOS of the C65 drive has some additions of its own:

| Name           | Syntax                                                | Description                     |
|----------------|-------------------------------------------------------|---------------------------------|
| FILE LOCK      | `F-L`[_drv_]`:`_name_[`,`...]                         | Enable file write-protect       |
| FILE UNLOCK    | `F-U`[_drv_]`:`_name_[`,`...]                         | Disable file write-protect      |
| FILE RESTORE   | `F-R`[_drv_]`:`_name_[`,`...]                         | Restore a deleted file          |
| USER           | `U0>D`_val_                                           | Set directory sector interleave |
| USER           | `U0>?`_pa_                                            | Set unit primary address        |
| USER           | `U0>L`_flag_                                          | Large REL file support on/off   |

## Extra: Printers

XXX

* printers use the secondary address to pre-select a character set
* 0 Print data in Uppercase/Graphics mode
* 7 Print data in Upper/lowercase

## Next Up

XXX

## References

XXX

* http://www.softwolves.pp.se/idoc/alternative/vc1541_de/
* Schramm, K.: [Die Floppy 1541](https://spiro.trikaliotis.net/Book#vic1541). Haar bei München: Markt-und-Technik-Verlag, 1985. ISBN 3-89090-098-4
* Inside Commodore DOS
* http://the-cbm-files.tripod.com/diskdrive/1571-6.txt
* 8061UsersManual.pdf
* cbm4031.pdf
* CBM\ 2040-3040-4040-8050\ Disk\ Drive\ Manual.pdf
* commodore_vic_1541_floppy_drive_users_manual.pdf
* https://www.lyonlabs.org/commodore/onrequest/cmd/CMD_Hard_Drive_Users_Manual.pdf
* cmd_fd-2000_manual.pdf
* http://commodore64.se/wiki/index.php/1541_tricks#Utility_loader_.28.22.26.22_command.29
* ftp://www.zimmers.net/pub/cbm/manuals/printers/MPS-801_Printer_Users_Manual.pdf

<!---

### Notes

XXX U0 on 1540/1541?

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

10 open15,8,15
20 open2,8,2,"#"
30 print#15, "b-r 2 0 123 0"
40 dos
50 close 2
60 close 10
run



--->

[^1]: This is a limitation of the layer 2 protocol: It is impossible to send a 0-byte stream of bytes.

[^2]: Most devices only have a single drive, so in practice, drive numbers are rarely specified.

[^3]: All single-drive Commodore devices except the 1571 (revision 5 ROM only), 1541-C, 1541-II and 1581 have a [bug](https://groups.google.com/forum/#!topic/comp.sys.cbm/TKKl8a-3EPA) that can currupt the filesystem when using the overwrite feature.

[^4]: The two arguments always have to be at least two digits, and on most Commodore drives, they are always two digits. CMD drives support larger track and sector numbers, so while arguments less than 100 will be two digits wide, they can also return three-digit arguments.

[^5]: The SFD-1001 is the exception to this: It is single-drive device that shares its firmware with the dual-drive CBM 8250.

[^6]: The version is sometimes more of a compatibility level though and hints at the supported features. These strings are too inconsistent between devices for parsing, so in practice, the whole string has to be compared in order to detect a particular device.

[^7]: Commodore DOS breaks the layer 3 convention in this case. An `UNLISTEN` event does not signal the termination of a byte stream, it should merely pause it.

[^8]: [Many]( http://mirror.thelifeofkenneth.com/sites/remotecpu.com/Commodore/Reference%20Material/Books/Commodore%20Peripheral%20Reference/1541%20Users%20Guide.pdf) [sources](https://spiro.trikaliotis.net/Book#vic1541) describe the "`B-R`" and "`B-W`" commands as buggy because their behavior didn't seem to make sense and the explanation seemed to have been missing from common forms of documentation. Where they are documented, they are called the "random access files" commands, for a third type of file (next to sequential and relative) that was based on the user keeping track of allocation and linking, but using the "first byte holds block pointer" format provided by these commands.

[^9]: On disks that do not use Commodore's native "GCR" bit encoding (e.g. CBM 8280, D9060/D9090, 1581, the C65 drive and all drives by CMD), the physical layout doesn't match the logical layout, i.e. the medium may have a different sector size or track/sector(/head) numbering. On the CMD HD, the track and sector numbers are interpreted as a linear block address, and the constraint of 255 tracks and 256 sectors of 256 bytes limited the maximum partition size to just under 16 MB.

[^10]: The feature has existed in all Commodore drives [since the release of the 1540](https://github.com/mist64/cbmsrc/blob/master/DOS_1540/utlodr), but they only started documenting it with the 1551 drive, and never documented the actual file format or the algorithm for the required checksum. The 1540, early 1541 drives, the 8250/8050/4040 with DOS V2.7 as well as the D9060/D9090 hard disks supported the also undocumented "boot clip": a device that grounds certain pins on the data connector and will force the unit to execute the first file on disk. All this hints at this mostly being a feature that was used in-house.

[^11]: `U1` and `U2` were added in a firmware update to the Commodore 4040 drive because of bugs in `B-R` and `B-W` in version 2.1. They were probably added as `USER` commands as opposed to proper commands (or fixing the broken commands) in order to keep the changes to the new ROM version contained to one ROM chip. Later drives retained this feature.

[^12]: The command was piggy-backed onto `UI` in order to keep the changes between the 1540 an the 1541 contained to the second ROM chip.
