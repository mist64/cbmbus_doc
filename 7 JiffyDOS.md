# Commodore Peripheral Bus: Part 7: JiffyDOS

In the [series about the variants of the Commodore Peripheral Bus family](https://www.pagetable.com/?p=1018), this article covers the third party "JiffyDOS" extension to the Commodore Serial Bus protocol, which shipped as a ROM patch for computers and drives, replacing the byte transmission protocol of Standard Serial ("IEC") by using the clock and data lines in a more efficient way.


![](docs/cbmbus/jiffydos_layers.png =291x241)

<hr/>

> **_NOTE:_**  I am releasing one part every once in a while, at which time links will be added to the bullet points below. The articles will also be announced on the Twitter account <a href="https://twitter.com/pagetable">@pagetable</a> and the Mastodon account <a href="https://mastodon.social/@pagetable">@pagetable&#64;mastodon.social</a>.

<hr/>

* [Part 0: Overview and Introduction](https://www.pagetable.com/?p=1018)
* [Part 1: IEEE-488](https://www.pagetable.com/?p=1023) [PET/CBM Series; 1977]
* [Part 2: The TALK/LISTEN Layer](https://www.pagetable.com/?p=1031)
* [Part 3: The Commodore DOS Layer](https://www.pagetable.com/?p=1038)
* [Part 4: Standard Serial (IEC)](https://www.pagetable.com/?p=1135) [VIC-20, C64; 1981]
* [Part 5: TCBM](https://www.pagetable.com/?p=1324) [C16, C116, Plus/4; 1984]
* Part 6: Fast Serial [C128; 1985] *(coming soon)*
* **Part 7: JiffyDOS [1986]** ← *this article*
* Part 8: CBDOS [C65; 1991] *(coming soon)*

# History and Development

Commodore's [Serial Bus](https://www.pagetable.com/?p=1135) from 1981 as used by the VIC-20 and the C64 was supposed to be a cheaper, but similarly fast variant of its earlier parallel IEEE-488 bus. To work around buggy hardware, a last minute change to drive the protocol in software made it 5x slower on the VIC-20 (1981) than it should have been. With the C64 (1982), the protocol was slowed down by an additional factor of 3, because its shared RAM system architecture did not allow software to reliably detect pulses shorter than 60 µs.

In 1984, the TED series of computers (C16, C116, Plus/4) added [TCBM](https://www.pagetable.com/?p=1324), a new type of parallel bus for disk drives, but it required awkward and ugly cabling, supported only two drives, and was not meant for other types of devices like printers, so these computers still had a regular Serial Bus as well.

The C128 (1985) went back to the idea of the Serial Bus and added an optional faster protocol ("Fast Serial") that implemented sending data serially in hardware, using a previously unused wire in the cable. It delivered what the original design had promised, but it required new computers and drives with the additional transmission hardware - the wildly popular C64 computer and 1541 disk drive were left out.

In late 1986, Mark Fellows (Fellows Inc.) released JiffyDOS, and a year later, it became the flagship product of the new company Creative Micro Designs (CMD), which went on to becoming popular for releasing new floppy drives (FD-2000/FD-4000) as well as hard drives (HD Series) for Commodore systems.

Similarly to fast loader systems that were either built into games and applications or available as stand-alone utility software, JiffyDOS is a software solution to speed up transmissions on existing hardware and cabling. It was – [and still is](http://store.go4retro.com) – sold as a set of replacement ROM chips available for all Commodore computers with a Serial Bus (originally C64, C128; later also VIC-20 and Plus/4) and practically all disk drives with a Serial Bus. For JiffyDOS to be effective, the operating system ROM of both the computer and the drive(s) has to be replaced. Since they were made by the same company as JiffyDOS, all devices by CMD speak JiffyDOS out of the box, and modern devices like [SD2IEC](https://www.c64-wiki.com/wiki/sd2iec_(firmware)) speak it as well.

The backwards-compatibility and ubiquity make JiffyDOS the de-facto successor of the Standard Serial protocol.

# Overview

All controllers and devices that support the JiffyDOS protocol are primarily "[Standard Serial](https://www.pagetable.com/?p=1135)" devices. (The remainder of this article assumes a good understanding of it.)

* Layer 1: They use the Standard Serial 6-pin DIN connector with three TTL communication lines.
* Layer 2: They speak a serial protocol over the CLK and DATA lines, and a controller can send commands by sending data bytes with the ATN line pulled.
* Layer 3: Bus arbitration is done by the controller sending command bytes using the TALK/LISTEN protocol.
* Layer 4: Disk drives speak the Commodore DOS protocol, support multiple open streams and a command/status channel; other types of devices like printers speak their own protocols on this layer.

The basic idea of JiffyDOS is the following: Layer 2 of the original Serial protocol had to be slowed down for the C64 because the video chip frequently blocked the memory bus, stalling the CPU, which would make it miss deadlines. With JiffyDOS, the controller (i.e. the computer) only initiates the transmission of a data byte when it can guarantee that it will be undisturbed for the duration of the whole byte – which can then be sent way faster, enabling a 10x speedup for the whole data transmission.

JiffyDOS adds three alternative byte transmission protocols to layer 2. These protocols also only use the CLK and DATA wires, and they are purely optional – they are used in place of the standard protocol in cases where the involved parties explicitly negotiate their use.

Since a bus can have JiffyDOS and non-JiffyDOS devices, commands (ATN = 1) that the controller sends to all devices always use the Standard Serial byte transmission protocol.

All three new byte transmission protocols only work between the controller and a single device. One-to-many transmissions, like with the original protocol, are not supported.

# Detection

The new protocols can only be used if both the controller and the device support it. Before every TALK or LISTEN session, the controller and the device therefore negotiate whether they can use the JiffyDOS protocols.

This negotiation is based on a timing sidechannel during the TALK or LISTEN command sent by the controller:

![](docs/cbmbus/jiffydos-detection.png =601x301)

Like all commands, TALK and LISTEN are sent using the Standard Serial byte transmission protocol. The sender, which in the case of a command is the controller, puts the eight bits onto the DATA line, one after the other. Whenever the DATA line is valid, it releases CLK for 60 µs, and between bits, it pulls CLK for 60 µs.

These are the command codes for TALK and LISTEN:

| hex           | binary      | description   |
|---------------|-------------|---------------|
| `0x20` + _pa_ | `%001aaaaa` | `LISTEN`      |
| `0x40` + _pa_ | `%010aaaaa` | `TALK`        |

The codes are sent starting with the least significant bit, so the 5 bits of the device's primary address (`aaaaa`) are sent first, followed by the bits 1 followed by 0 (LISTEN) or 0 followed by 1 (TALK). The last bit will always be 0: The command codes `%101aaaaa` (`0xA0` + _pa_) and `%110aaaaa` (`0xC0` + _pa_) are unassigned.


So by the time seven of the eight bits are transmitted, the specified device effectively already knows that it is being addressed, and that it's a TALK or LISTEN command.

Now if the controller supports JiffyDOS, the delay with CLK=1 between the 6th and the 7th (the last) bit will be 400 µs[^1] instead of 60 µs. If the device detects this delay, it will pull the DATA line, hold this state for 100 µs, and release the DATA line again.

Both participants now know that the other supports JiffyDOS, and the transmission of the TALK or LISTEN command will resume with the last bit.

Commands are always received by all devices on the bus, which will just ignore the extra communication: JiffyDOS-aware devices know they are not being addressed, and they don't pull the DATA line. For non-JiffyDOS devices, the extra delay by the controller will be ignored – the protocol only specifies a minimum delay of 60 µs, but no maximum – and so will be the DATA line pulled by the device, since it is only considered valid while CLK is released.

Note that this sidechannel communication will be repeated with every TALK and LISTEN command, and the result is only valid for the subsequent TALK/LISTEN session. This is necessary, because a device could be replaced with a different one between sessions, or the JiffyDOS ROM of either the computer or the drive could be switched on or off.

XXX it's possible for a device to only support RECEIVE & LOAD, and for a host to only support SEND, or just RECEIVE, or just RECEIVE & LOAD

# Byte Transfer

The new byte transmission protocols all have in common that the CLK and DATA lines are used to transmit two data bits at a time. Since there is now no wire left to signal when the data is valid, the whole transmission is timing-based. After a handshake before every byte, 2 bits are transmitted every 11-13 µs – close to the maximum speed the wires can be driven by a 1 MHz 6502 CPU, which JiffyDOS was designed for. This makes data transmission with JiffyDOS about 10x faster than with Standard Serial.

JiffyDOS considers devices real-time capable. During communication, they must be able to react to any signal within no more than 13 µs and exact to a window of 7 µs. Controllers may have many things going on, like interrupts and DMA and are thus not considered real-time capable[^2]. No matter the transmission direction, it is therefore always the controller that starts the timed transmission window of about XXX 65 µs during which both participants must be uninterrupted.

The following graphic illustrates this – it will be described in detail in later sections.

![](docs/cbmbus/jiffydos-send-receive.png =601x301)

## Send and Receive

The three new protocols have different use cases:

* JiffyDOS send (controller to device, LISTEN)
* JiffyDOS receive (device to controller, TALK)
* JiffyDOS LOAD (device to controller, TALK on channel 1)

Because the controller always initiates the timed transmission window, the send and receive protocols of JiffyDOS are not symmetric, which is why, unlike with Standard Serial, there are two separate protocols depending on the direction of transmission. This is also why one-to-many communcation is not possible. Whenever JiffyDOS is detected, regular TALK/LISTEN sessions use one of these protocols.

The dedicated LOAD protocol is a variant of the receive protocol that is optimized for transmitting a complete Commodore DOS "PRG" file in one go. It is used if the controller sends a TALK on the magic channel number 1 if there is an open file on channel 0.

All new protocols have in common that they start with the sender holding CLK and the receiver holding DATA. This matches the state in the original protocol, and is necessary for interoperability.

![](docs/cbmbus/jiffydos-vs-serial.png =601x167)

All three protocols support reporting the EOI and timeout conditions: EOI ("end of identify") is the end-of-stream flag of the IEEE-488 family of protocols that gets sent with the last byte of the stream. "Timeout" is the generic error flag – the original IEEE-488 protocol did not have an error flag, so Commodore defined that delaying a requested response should be used to signal an error.

### JiffyDOS Byte Send

When the controller sends data to the device, it transmits two bits at a time every 11-13 µs using the CLK and DATA lines, with no handshake. For each byte, the device signals that it is ready to receive, followed by the controller signaling it is about to start the transmission, thus starting the timing critical window of XXX 65 µs.

The following animation shows a byte being sent from the controller to the device.

![](docs/cbmbus/jiffydos-send.gif =601x344)

Let's go through it step by step:

#### S0: Initial State
![](docs/cbmbus/jiffydos-13.png =601x131)

Since the JiffyDOS protocol integrates with the Standard Serial protocol, its initial state must match the state of the parent protocol at this point: After the "LISTEN"/"SECOND" command, the sender (the controller) is holding the CLK line and the receiver (the device) is holding the DATA line.

#### S1: Device is ready to receive
![](docs/cbmbus/jiffydos-14.png =601x131)

Once the device is done processing the previous data, which may for instance include writing a sector to the media, it indicates that it is ready to receive by releasing the DATA line. It may delay this step indefinitely.

#### S2: Controller sends the *Go* signal
![](docs/cbmbus/jiffydos-15.png =601x131)

Triggered by DATA being 1, the controller indicates that it will start sending a data byte by releasing the CLK line - this is the *Go* signal. During the transmission of the byte, both lines will be owned by the controller, and the sequence of steps is purely based on timing; there are no ACK signals.

The controller may delay this step indefinitely. In practice, it will until it has a guaranteed XXX 65 µs time window without interruptions.

#### S3: Controller puts data bits #4 and #5 onto wires
![](docs/cbmbus/jiffydos-16.png =601x131)

First, the controller puts the first pair of data bits onto the two wires (CLK: #4, DATA: #5).

The wires have to be valid for 5 µs starting after 14 µs.

The order of bits (4-5, 6-7, 3-1, 2-0) is an optimization based on the C64/1541 port layout, minimizing shift operations.

#### S4: Controller puts data bits #6 and #7 onto wires
![](docs/cbmbus/jiffydos-17.png =601x131)

The controller puts the second pair of data bits onto the two wires (CLK: #6, DATA: #7).

The wires have to be valid for 7 µs starting after 13 µs.

#### S5: Controller puts data bits #3 and #1 onto wires
![](docs/cbmbus/jiffydos-18.png =601x131)

The controller puts the third pair of data bits onto the two wires (CLK: #3, DATA: #1).

The wires have to be valid for 7 µs starting after 11 µs.

#### S6: Controller puts data bits #2 and #0 onto wires
![](docs/cbmbus/jiffydos-19.png =601x131)

The controller puts the final pair of data bits onto the two wires (CLK: #2, DATA: #0).

The wires have to be valid after 13 µs and the state has to remain held.

#### S7: Controller signals no EOI, and is now busy again
![](docs/cbmbus/jiffydos-20.png =601x131)

Still timing-based, the controller pulls the CLK line, signaling that there is no EOI (end-of-stream). A pulled CLK line also means that the controller is now busy again, so the transmission of the next data byte cannot start yet.

In the no-EOI case, it also releases the DATA line so it can be operated by the device again.

The wires have to be valid after 13 µs and remain held.

#### S8: Device is now busy again
![](docs/cbmbus/jiffydos-21.png =601x131)

After reading the CLK line, the device pulls the DATA line. This is the same as the initial state, so the protocol continues with step S1 for the next data byte.

Of course, the controller can alternatively pull ATN at this point, and send an "UNLISTEN" command, for example.

### JiffyDOS Byte Send - EOI & Error

An EOI event is signaled through the CLK line in step S7.

#### S7a: Controller signals EOI/Error status
![](docs/cbmbus/jiffydos-22.png =601x131)

If there is an EOI or an error, the controller releases CLK.

In the EOI case, DATA is pulled, and in the error case, DATA is released.

If both CLK and DATA are released, this indicates a "timeout" error. Note that this combination has been carefully chosen: An idle device would also keep both wires released, and both wires released is also the default bus state if no device is attached, so a non-responsive or nonexistent device would also lead to this case.

As with the regular case, the wires have to be valid after 13 µs. And in this case, they need to be held for 7 µs.

#### S7b: Controller is now busy again
![](docs/cbmbus/jiffydos-23.png =601x131)

In the EOI case, the controller will then pull the CLK line, signaling that it is busy again.

EOI/error signaling can be seen as delaying the controller's last step in the sequence by keeping CLK released for some time after the last data bits:

![](docs/cbmbus/jiffydos-send.png =601x422)

### JiffyDOS Byte Receive

When the device sends data to the controller, it transmits two bits at a time every 10-11 µs using the CLK and DATA lines, with no handshake. For each byte, the device signals that it is ready to send, followed by the controller signaling the device to start the transmission, thus starting the timing critical window of XXX 55 µs.

Compared to the byte send case, the ownership of the CLK and DATA lines outside the core data transmission is swapped, but it is the controller that sends the *Go* signal in both the send and the receive case.

The following animation shows a byte being received by the controller from the device.

![](docs/cbmbus/jiffydos-receive.gif =601x344)

Again, let's go through it step by step:

#### R0: Initial State
![](docs/cbmbus/jiffydos-01.png =601x131)

Like in the "send" case, the initial state is the same as with Standard Serial, since this is the natural state after the "LISTEN"/"SECOND" command: The sender (the device) is holding the CLK line and the receiver (the controller) is holding the DATA line.

#### R1: Device is ready to send
![](docs/cbmbus/jiffydos-02.png =601x131)

Once the device has the next data byte at hand, that is, for example, after reading it from a buffer, or after reading a new sector from the media, it indicates that it is ready to send by releasing the CLK line. It may delay this step indefinitely.

#### R2: Controller sends the *Go* signal
![](docs/cbmbus/jiffydos-03.png =601x131)

Triggered by CLK being 0, the controller indicates by releasing the DATA line that the device must now start sending a data byte - this is the *Go* signal. During the transmission of the byte, both lines will be owned by the device, and the sequence of steps is purely based on timing; there are no ACK signals.

The controller may delay this step indefinitely. In practice, it will until it has a guaranteed XXX 55 µs time window without interruptions.

#### R3: Device puts data bits #0 and #1 onto wires
![](docs/cbmbus/jiffydos-04.png =601x131)

First, the device puts the first pair of data bits onto the two wires (CLK: NOT #0, DATA: NOT #1).

The wires have to be valid for 1 µs after 15 µs.

In the receive case, the bits are sent starting with the least significant bit, and all bit values are inverted.

#### R4: Device puts data bits #2 and #3 onto wires
![](docs/cbmbus/jiffydos-05.png =601x131)

The device puts the second pair of data bits onto the two wires (CLK: NOT #2, DATA: NOT #3).

The wires have to be valid for 1 µs after 10 µs.

#### R5: Device puts data bits #4 and #5 onto wires
![](docs/cbmbus/jiffydos-06.png =601x131)

The device puts the third pair of data bits onto the two wires (CLK: NOT #4, DATA: NOT #5).

The wires have to be valid for 1 µs after 11 µs.

#### R6: Device puts data bits #6 and #7 onto wires
![](docs/cbmbus/jiffydos-07.png =601x131)

The device puts the final pair of data bits onto the two wires (CLK: NOT #6, DATA: NOT #7).

The wires have to be valid for 1 µs after 11 µs.

#### R7: Device signals no EOI, and is now busy again
![](docs/cbmbus/jiffydos-08.png =601x131)

Still timing-based, the device pulls the CLK line, signaling that there is no EOI. A pulled CLK line also means that the device is now busy again, so the transmission of the next byte cannot start.

In the no-EOI case, it also releases the DATA line so it can be operated by the controller again.
 
The wires have to be valid after 11 µs and the state has to remain held.

#### R8: Controller is now busy again
![](docs/cbmbus/jiffydos-09.png =601x131)

After reading the CLK line, the controller pulls the DATA line. This is the same as the initial state, so the protocol continues with step R1 for the next data byte.

Similarly to the send case, the controller can alternatively pull ATN at this point, and send an "UNTALK" command, for example.

### JiffyDOS Byte Receive - EOI & Error

An EOI event is signaled through the CLK line in step R7.

#### R7a: Device signals EOI/Error status
![](docs/cbmbus/jiffydos-10.png =601x131)

If there is an EOI or an error, the device releases CLK.

In the EOI case, DATA is pulled, and in the error case, DATA is released.

As with the regular case, the wires have to be valid after 13 µs. And in this case, they need to be held for 13 µs.

#### R7b: Device is now busy again
![](docs/cbmbus/jiffydos-11.png =601x131)

In the EOI case, the device will then pull the CLK line, signaling that it is busy again.

EOI/error signaling can be seen as delaying the controller's last step in the sequence by keeping CLK released for some time after the last data bits:

![](docs/cbmbus/jiffydos-receive.png =601x422)

## JiffyDOS LOAD

The JiffyDOS "LOAD" protocol optimizes for the most common use case: loading a complete "PRG" file from a disk drive into the host's memory.

In Commodore DOS, which is layer 4 of the protocol stack, PRG files are finite byte streams that start with a two-byte (little endian) "load address", that is, target address in the host's address space. There is a dedicated KERNAL call (`LOAD` at $FFD5) on Commodore computers, and all versions of Commodore BASIC expose it through the `LOAD` statement, e.g.:

	LOAD"PROGRAM",8,1

The LOAD protocol is used under the following conditions:

1. The file has been opened on channel 0.
2. The TALK command is issued on channel 1.

And there are several restrictions:

* The LOAD protocol cannot be used to transmit anything other than regular files: Buffer channels and the command/status channel have to use the JiffyDOS receive protocol instead. The same is true for directory listing: They are opened like files, but they are not supported by the LOAD protocol.
* The LOAD protocol requires the complete file to be loaded in one go, there can be no UNTALK/TALK commands to stop and resume transmission.
* The byte stream that is transmitted through channel 1 skips the first two bytes of the file: The host's implementation is expected to fetch the PRG load address though channel 0 before.

The difference between the JiffyDOS receive and LOAD protocols is that the LOAD protocol does not have a handshake to wait for the device to be ready to send. During the byte transmission loop, the device is always assumed to be ready, but it can set an "escape" flag at the beginning of each iteration that makes both participants move to a different section of the protocol that allows stalling.

So the LOAD protocol consists of two parts: escape mode and byte send mode.

### LOAD: Escape Mode

The LOAD protocol is framed by "escape mode". It is used to allow the device to signal:

* data is ready: switch to "byte receive" mode
* data is not ready: this allows the device to stall (e.g. if it needs to fetch a new block from the media)
* "EOI": the end of the file has been reached
* "timeout": there has been an error

(In the LOAD context, "EOI" does not have the same semantics as all other IEEE-488 derivatives: Instead of *with* the last data byte, it is signaled *after* the last data byte.)

The following diagram shows the escape mode part of a LOAD protocol session:

![](docs/cbmbus/jiffydos-load-escape.png =601x167)

* The device signals that data is ready (!EOI) and the protocol switches to byte receive mode.
* After a certain number of bytes, byte receive mode switches back to escape mode.
* This can be repeated an arbitrary number of times.
* As soon as end of the file has been reached, or if there was an error, the device signals EOI.

(An empty file would cause the device to signal EOI in the first iteration of escape mode.)

In practice, byte receive mode transmits a full block worth of data, as it is cached in the device's RAM. Whenever it runs out of cached data, it switches the protocol to escape mode, stalls in the step that signals EOI/!EOI to be able to read the next block from the media.

Let's go through the steps of escape mode in detail:

#### E0: Initial State
![](docs/cbmbus/jiffydos-25.png =601x131)

Like the other protocols, JiffyDOS LOAD integrates with the Standard Serial protocol, so its initial state must match the state of the parent protocol at this point: After the "TALK" command, the sender (the device) is holding the CLK line and the receiver (the controller) is holding the DATA line.

#### E1: Controller clears DATA wire (not a signal)
![](docs/cbmbus/jiffydos-26.png =601x131)

First, the controller releases the DATA wire. This is not a signal for the device, but necessary so that the controller can read the DATA line in the next step. The controller can therefore choose to release the wire as late as just before reading it back.

#### E2: Device signals EOI/!EOI– hold for 75 µs 
![](docs/cbmbus/jiffydos-27.png =601x131)

Next, the device puts a flag whether there is more data to be transmitted onto the DATA line. 1 means there is more data (!EOI), while 0 means that there is no more data (EOI): the end of the stream has been reached or there has been an error.

To signal that the state of the DATA line is valid, the device releases the CLK line and holds this state for 75 µs.

The device can delay this step as long as it wishes, e.g. to read data from the media.

If there is more data, the protocol switches to byte receive mode (step B0), otherwise it continues with step E3.

#### E3: Device signals no error within 1100 µs – hold for 100 µs
![](docs/cbmbus/jiffydos-28.png =601x131)

In the case of the end of the transmission (EOI), the final step is for the device to signal whether there was an error or whether this is the regular end of the file.

If there is no error, the device pulls CLK and holds it for 100 µs no later than after 1100 µs, otherwise, it keeps CLK released for 1100 µs. (The DATA line was already released in the previous step, because DATA = 0 signaled EOI.)

### LOAD: Byte Receive

After the device has indicated that there is more data, the protocol goes into the "Byte Receive" mode, which can transmit zero or more data bytes.

![](docs/cbmbus/jiffydos-load-receive.png =601x167)

#### B0: Initial State
![](docs/cbmbus/jiffydos-30.png =601x131)

The initial state has the device holding DATA and keeping CLK released – this is the same as step E2 of escape mode after !EOI has been signaled.

#### B1: Device signals ESC/!ESC
![](docs/cbmbus/jiffydos-31.png =601x131)

At the beginning of the loop for each data byte, the device signals whether the protocol should switch back to escape mode. If yes, the device sets CLK to 1. Otherwise, it sets CLK to 0.

In addition, the device releases the DATA line, so the controller can use it in the next step.

In the first iteration of the byte receive loop, releasing DATA signals that CLK is now valid. In this case, the controller triggers on DATA = 0, which means the device may arbitrarily delay this step.

In subsequent iterations, the controller cannot trigger on DATA, because the value of DATA in the previous step – step 6 of the previous iteration – could have been either 0 or 1, so this step is based on timing: The value of CLK must be valid at 11 µs after the previous step. DATA still has to be cleared so that the host can use it in the next step.

#### B2: Controller signals *Go* for 12+ µs
![](docs/cbmbus/jiffydos-32.png =601x131)

As soon as the controller can guarantee a window of at least 58 µs of being undisturbed, it pulls the DATA line for at least 12 µs, telling the device to immediately start the transmission of the 8 data bits.

This happens independently of whether ESC was true or false in the previous step. It isn't until after this step that the protocol jumps to step E2 of the escape mode protocol if the device set CLK in the previous step.

#### B2b: Controller clears DATA wire (not a signal)
![](docs/cbmbus/jiffydos-33.png =601x131)

In order to be able to read the data bits from both DATA and CLK in the next steps, the controller releases DATA before it reads the first pair of bits. Again, this is not a signal for the device.

#### B3: Device puts data bits #0 and #1 onto wires
![](docs/cbmbus/jiffydos-34.png =601x131)

Triggered by the *Go* event, (step 2), the device puts the first two data bits onto the two wires (CLK: NOT #0, DATA: NOT #1).

The bits are sent starting with the least significant bit, and all bit values are inverted.

The controller reads the wires exactly 15 µs after *Go* – and they may be set no earlier than 4 µs after the *Go* signal, since the value of ESC in the CLK wire must still be valid 3 µs after the start of the *Go* signal.

#### B4: Device puts data bits #2 and #3 onto wires
![](docs/cbmbus/jiffydos-35.png =601x131)

Based solely on timing, the device puts the second pair of data bits onto the wires (CLK: NOT #2, DATA: NOT #3).

The controller reads the wires exactly 10 µs later.

#### B5: Device puts data bits #4 and #5 onto wires
![](docs/cbmbus/jiffydos-36.png =601x131)

The device puts the third pair of data bits onto the wires (CLK: NOT #4, DATA: NOT #5).

The controller reads the wires exactly 11 µs later.

#### B6: Device puts data bits #6 and #7 onto wires
![](docs/cbmbus/jiffydos-37.png =601x131)

The device puts the final pair of data bits onto the wires (CLK: NOT #6, DATA: NOT #7).

The controller reads the wires exactly 11 µs later.

At this point, the protocol loops back to step B1.

# Timing

XXX 

* ranges
	* for writes, it means:
		* sample: held in this range, upper value is exclusive
		* trigger: write some time within this range
		* -: not checked by the peer
	* for reads, it means check in this range
* (+7) fuzz of 7, i.e. can be 0-7 late

* VIC-20 means PAL

* `a~b` held or scanned in this interval
* `a~` held from `a` on, until in some later step
* `-` set some time in this interval

## Send

| Step | Event                                | Wires               | Type    | Timing     |
|------|--------------------------------------|---------------------|---------|------------|
|  S1  | Device: ready-to-receive             | DATA = 0            | trigger | 0-∞~       |
|  S2  | Controller: *Go*                     | CLK = 0             | trigger | 4-∞~       |
|  S3  | Controller: 1st pair of bits         | CLK = #4, DATA = #5 | sample  | 13~+7      |
|  S4  | Controller: 2nd pair of bits         | CLK = #6, DATA = #7 | sample  | 13~+7      |
|  S5  | Controller: 3rd pair of bits         | CLK = #3, DATA = #1 | sample  | 11~+7      |
|  S6  | Controller: 4th pair of bits         | CLK = #2, DATA = #0 | sample  | 13~+7      |
|  S7  | Controller: EOI/!EOI                 | CLK = 0/1, DATA = 0 | sample  | 13~+7      |
|  S8  | Device: OK/!OK                       | DATA = 1/0          | sample  | 0-19~      |
|  S9  | Controller: no *Go*                  | CLK = 1             | -       | ?          |

* S1: At the beginning of a LISTEN session and between bytes, the device sets DATA = 1, the host may check for DATA = 0 at any time, and S1 may be arbitrarily delayed.


* SX: all host impl. set this before S8
* XXX if not DATA = 1 in step 8, the host cancels with a timeout
* XXX S8 doubles as not ready to receive for the next iteration


* VIC PAL:  1.108404
* TED PAL:  0.884 = 1.768/2
* TED NTSC: 0.894 = 1.788/2

## Receive

| Step | Event                                | Wires               | Type    | Timing     |
|------|--------------------------------------|---------------------|---------|------------|
|  R1  | Device: ready-to-send                | DATA = 0            | trigger | 0-∞~       |
|  R2  | Controller: *Go*                     | CLK = 0             | trigger | 31-∞~      |
|  R3  | Device: 1st pair of bits             | CLK = #0, DATA = #1 | sample  | 14~+3      |
|  R4  | Device: 2nd pair of bits             | CLK = #2, DATA = #3 | sample  | 10~+2      |
|  R5  | Device: 3rd pair of bits             | CLK = #4, DATA = #5 | sample  | 10~+2      |
|  R6  | Device: 4th pair of bits             | CLK = #6, DATA = #7 | sample  | 11~+1      |
|  R7  | Device: EOI/!EOI                     | CLK = 0/1, DATA = 0 | sample  | 10~+2      |
|  R8  | Controller: not ready to send        | DATA = 1            | trigger | 0-3~       |

* 8: C64 sets DATA = 1 at 5 µs, 1541 waits for DATA = 1 starting at 3 µs.



## LOAD

### Escape Mode

Start:

| Step | Event                                | Wires                | Type    | Delay      | Hold For |
|------|--------------------------------------|----------------------|---------|------------|----------|
|  E1  | Controller clears DATA wire          | DATA = 0             | -       | 0-∞        |          |
|  E2  | Device: EOI/!EOI & valid             | DATA = !EOI, CLK = 0 | trigger | 0-∞~+75    |          |
|  E3  | Device: no error                     | CLK = 1              | trigger | 0-1100~+100|          |

* E2:
	* If EOI = 0, "Byte Receive" follows.
	* If EOI = 1, "End" follows.


### Byte Receive

| Step | Event                                | Wires               | Type    | Delay      |
|------|--------------------------------------|---------------------|---------|------------|
|  B1  | Device: ESC/!ESC & valid             | CLK = ESC, DATA = 0 | trigger | 32~ **after B6** |
|  B2  | Controller: *Go*, clears DATA        | DATA = 1; DATA = 0  | trigger | 4-∞~12     |
|  B3  | Device: 1st pair of bits             | CLK = #0, DATA = #1 | sample  | 14~3       |
|  B4  | Device: 2nd pair of bits             | CLK = #2, DATA = #3 | sample  | 10~1       |
|  B5  | Device: 3rd pair of bits             | CLK = #4, DATA = #5 | sample  | 11~1       |
|  B6  | Device: 4th pair of bits             | CLK = #6, DATA = #7 | sample  | 10~2       |

<sup>*</sup>The value of ESC in the CLK wire must still be valid 3 µs after the start of the *Go* signal, so the first pair of data bits must not be put into CLK and DATA earlier than 4 µs after *Go*.

* if ESC = 1, "Escape Mode" follows after B2

| Step | C64    | VIC-20   | TED        | 1541    |
|------|--------|----------|------------|---------|
|  S1  | -      | -        | -          | -       |
|  S2  | 30-∞   | 35       | 81         | 4~∞     |
|  S3  | 11~    | 13~      | 9~         | 13(+≤7) |
|  S4  | 13~    | 13~      | 11~        | 13      |
|  S5  | 11~    | 13~      | 10~        | 11      |
|  S6  | 13~    | 13~      | 10~        | 13      |
|  S7  | 13-14~ | 13-14~   | 11/12~     | 13      |
|  S8  | 19     | 21       | 17         | 6~      |
|  S9  | -6~    | -4~      | -3~        | -       |
|  R1  | -      | -      |        | -       |
|  R2  | 31-∞   | 38(+≤8)| 45-∞   | 37~∞    |
|  R3  | 16     | 16     | 13     | 6~(+≤7) |
|  R4  | 10     | 12     | 9      | 10~     |
|  R5  | 11     | 11     | 10     | 11~     |
|  R6  | 11     | 12     | 10     | 10~     |
|  R7  | 11     | 11     | 10     | 11~     |
|  R8  | 4~∞    | 4~∞    | 3~∞    | 3~∞     |
|  E1  | -           | -             | -      | -       |
|  E2  | 8~∞         | 9~∞           | 3~∞    | 0-∞~    |
|  E3  | 10-∞~1100   | 14-∞~1100     | ?      | 100~+100|
|  B1  | 4 **after B2** | 6 **after B2** | 3 **before B2**   | 75~ after E2, 38-39~ after B6|
|  B2  | 36 **after B6**| 76 **after B6**| 41-67 **after B6**| 4~∞     |
|  B3  | 16             | 16             | 13                | 6~      |
|  B4  | 10             | 12             | 9                 | 10~     |
|  B5  | 11             | 13             | 10                | 11~     |
|  B6  | 11             | 11             | 10                | 10~     |

| Protocol | C64   | VIC-20 | TED   | 1541  |
|----------|-------|--------|-------|-------|
| Send     | $FC27 | $FC41  | $E854 | $FBC1 |
| Receive  | $FBA5 | $FBE0  | $E7DB | $FF79 |
| LOAD     | $FAF0 | $FB6E  | $E751 | $FFA3 |

## Timing Notes


No official formal specification of JiffyDOS has ever been released. Modern JiffyDOS-compatible projects such as SD2IEC and [open-roms](https://github.com/MEGA65/open-roms) had to reconstruct the protocols from either reverse-engineering the code or analyzing the data on the wires.

This would be no problem for a protocol like the original IEEE-488: All signals are used as triggers, so the other bus participants can do continue with the next steps. With JiffyDOS, most of the protocol is timing-based, so the required timing has to be reconstructed by counting instructions in the implementations – but this is still tricky.

### Timing Windows

Let's look at wire hold times by looking at the C64 sending data to the 1541. It sets the *Go* signal for a certain amount of time. Then it puts new data onto the bus every, say, 20 µs (for simpler numbers), counting from the beginning of the *Go* signal, and then holds the wire with the data for a certain amount of time as well.

The 1541 runs at 1 Mhz, and the C64 runs pretty close to 1 MHz. The minimal loop for the 1541 to detect the signal looks like this:

	:	cpx $1800 ; GPIO
		beq :-

One iteration of this loop takes 7 clock cycles, which is 7 µs. In the best case, the GPIO pins get read in the very first cycle they changed, and in the worst case, the change one cycle after the read, introducing a latency of 7 µs.

The following diagram shows what this means for the timing of the transmission:

![](docs/cbmbus/jiffydos-timing1.png =601x167)

The 1541 checks for the *Go* signal every 7 µs. The first two times (labeled "?"), the *Go* signal is not detected yet. The third time (labeled "!"), *Go* is detected, so it knows that the actual time of the *Go* signal is somewhere between now and 7 µs ago.

The 1541 has no better idea about the exact time of the *Go* signal, so it will read the data from the bus 20 µs after the **detected** *Go* signal.

* In the case the 1541 detected the *Go* signal in the very first moment, it would read the data wire exactly 20 µs after *Go*.
* In the worst case, the 1541 would detect *Go* 7 µs late, so it would read it 20 + 7 µs after *Go*.

Therefore, the C64 has to hold the data wire for 7 µs starting 20 µs after *Go*.

Now let's look at the receive case:

![](docs/cbmbus/jiffydos-timing2.png =601x167)

The C64 will read the data wire 20 µs after it has sent the *Go* signal. The 1541 is again not sure when exactly *Go* happened, it might have been just now, or 7 µs ago. Therefore, it has to write the data onto the wire 20 µs from the earliest possible time *Go* could have happened, and hold it for 7 µs so the C64's read is guaranteed to hit it.

This looks symmetric, but since it is always the host that signals *Go*, it isn't. Imagine a device with a very different CPU or a higher clock speed that can detect *Go* with an accuracy of 0-2 µs:

![](docs/cbmbus/jiffydos-timing3.png =601x167)

For the host to be guaranteed to hit the window where the data on the wire is valid, the device has to put the data onto the wire after 20 - 2 µs, and hold it for only 2 µs. The extreme case would be a device that can react immediately, so it could put the data onto the wire just for the exact time that the C64 is reading it.

This is not the same for the send case though: Any host implementation will have to hold the wire for 7 µs, otherwise the 1541 wouldn't work. But a device only has to hold it at the exact point the host samples it – it's the only device's own accuracy, and therefore an implementation detail how long it has to hold it in practice.

### Minimum Timing Windows

So if the 1541 implementation requires a wire to be held for at least 7 µs, we should use this number for the formal specification. But it's not that easy.

The C64 implementation holds the wire for more than the necessary 7 µs. (In order to be able to work with simpler numbers, let's assume again that the next value has to be valid 20 µs after the first one.) The C64 will effectively hold the wire for the full 20 µs until it sends the new value to the GPIO:

		sta $dd00
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		stx $dd00

This means that an drive implementation reading the wire 1 µs later would also work with a C64 – and maybe all other JiffyDOS hosts. Does this mean such an implementation is also compliant?

As the other extreme, we could say that any implementation will have to hold the wire for a full 20 µs, just like the 1541 implementation. This would guarantee all hosts that work with a 1541 will also work with a device that confirms to this strict specification. But this would unnecessarily lock out hardware that is unable to meet these strict rules, e.g. one based on a CPU architecture that can only hold the wire for 19 µs, for some reason or another, even though it's compatible with all known host implementations.

So the hold time that should be written down in the specification should, in our example, be somewhere in the range of 7 µs and 20 µs.

Compliance with a protocol that is not formally defined could be defined as staying within the timing bounds of all existing implementations.

So all JiffyDOS **host** implementations that we consider standards compliant could be looked at. Analyzing the time offsets of the read operations of the different implementations would give us the minimal hold time that works with all hosts. And for all cases where the host holds a wire and the device responds to it, we have to look at all JiffyDOS **device** implementations.

That's why the timing tables contain the measured numbers of several devices:

* C64: the host reference implementation at 1 MHz. Implementations on other 1 MHz devices (NTSC VIC-20, C128[^3]) are assumed to have the same timing.
* PAL VIC-20: a host implementation running at 1.1 MHz
* TED (C16, C116, Plus/4): a host implementation running at 1.77 MHz
* 1541: the device reference implementation at 1 MHz. All other JiffyDOS-supported drives run at 1 MHz or 2 MHz and are assumed to have the same timing.

The specification timing contains the minimal hold times that are compatible with these implementations.

# Errors

XXX dead man's switch

# Discussion

JiffyDOS is a significant improvement to Standard Serial, and it can be rightly considered the de-fact successor to it. Nevertheless, there are a few points that can be critisized.

## C64/1541-specific

As the de-facto successor of Standard Serial, it's a little ugly that the C64/1541 background bleeds through so much.

The protocol always has the host signaling "Go", because the C64's design makes it incapable of a guaranteed timely reaction. The 1541 can spin in a tight loop without distractions though. While this is C64/1541-specific, it does make sense in the more general case: Devices are real-time hardware, 
after all, they usually need to read sectors from disk by hand, which requires very tight timing and cannot tolerate interruptions. The same cannot be said about hosts, which often share the memory bsu with video hardware.

But because it's the host that signals "Go" instead of the current sender, this causes an inherent asymmetry in the protocol. This, as well as some other design decisions make it so that one-to-many transmissions, which are possible with IEEE-488 and Standard Serial, can't be done with the fast JiffyDOS protocols. To be fair, nobody ever used this with Standard Serial anyway. It was a feature carries over from the original (pre-Commodore!) IEEE-488 design, allowing an measurement instrument saving its data onto storage and printing it at the same time, but it was simply unnecessary in the home computer scenario. But the original protocol can still be used with JiffyDOS setups, so if this feature is required, one can just fall back to Standard Serial.

Another detail of the asymmetry is the bit order in different protocols: The order from the device to the host is 0-1/2-3/4-5/6-7, which makes sense – except that all bits are inverted. And from the host to the device, the order is 4-5/6-7/3-1/2-0, and no bit inversion. Both of these details are directly connected to the properties of the GPIO registers of the C64 and 1541:

* Commodore saved on hardware to invert the CLK and DATA values on their way in order for them to have the correct logical value. Therefore the JiffyDOS just has the drive send inverted bits, so that the computer doesn't have to invert the final value.
* The bit layout of the 1541 GPIO register is suboptimal for efficient loading of two bits and combining them with the other bits. The protocol design has therefore the host encode the order of the bits in such a way that some work is offloaded from the 1541.

In practice, this is not really a problem though. Even in 1985, it was clear that the 1541 would always be the weakest device in terms of CPU power and that all successors would therefore be able to bear the overhead of reordering the bits.

## Protocol not Optimal

All JiffyDOS byte transmission protocols are timing-based, and the timing properties are based on the C64 and 1541 implementations. This means that the protocols have a fixed maximum speed (e.g. 12.5 KB/sec for JiffyDOS LOAD), even if both the host and the device were faster. If for instance the host did the LOAD receive loop in less than 80 µs, it would break with a 1541 as a device – it might work with other devices, but it just wouldn't be JiffyDOS-compliant.

Additionally, the original C64 and 1541 implementations, which defined the protocols, are not even optimal. At least 10 µs could have been shaved off the 1541 implementation, which would have allowed a device to do the LOAD receive loop in 70 µs and still be compliant.

## LOAD Protocol not Suitable for IRQs

JiffyDOS requires the host to be completely undisturbed – from DMA and from interrupts – during byte transmission, i.e. for XXX 65 µs. Interrupts have to be off during this short amount of time, which causes some added interrupt latency, but in practice, this should never cause any interrupts to be missed.

No other phases of the protocols should require such strict timing, but some do: After step E1 of LOAD escape mode, the host waits for the device, usually to read another block from the media. Once the device is ready, it pulls DATA – but just for 75 µs. The host must not miss this, so it must have interrupts disabled while the device is busy. With a 1541, the wait time is in the order of 1/20 of a second for every block transmitted, for a total of about 2/3 of the total load time, in which interrupts will be missed. In the C64 case, for example, this causes the KERNAL real-time clock (`SETTIM`/`RDTIM` calls) to be slow, and it makes it impossible[^4] to play music while loading.

## Layer Violation

The IEEE-488 family of protocols is strictly layered. This allows, for example, to use IEEE-488, Standard Serial or TCBM for layers 1 and 2 without any changes to layers 3 and 4.

In theory, this should also be possible the other way round. Layer 3 (bus arbitration) should be replaceable in a way that layer 2 does not have to care. I could create a new protocol stack and decide that I like the connectors and byte transmission protocols (layers 1 and 2) of IEEE-488 and Standard Serial, but I have a better idea for a bus arbitration protocol on layer 3. This would be possible, because layer 2 has no knowledge of the workings of layer 3 – and doesn't require any.

This is not the case with JiffyDOS though. The detection protocol needs knowledge of the "TALK/LISTEN" protocol on layer 3: On the device side, the Standard Serial bit receive code (layer 2) for commands has to detect the delayed last bit, and check whether it was a TALK or LISTEN command addressed to itself.

In addition, the LOAD protocol is specific to the Commodore DOS protocol on layer 4, because it is triggered by using the magic DOS channels 0 for opening and 1 for transmission. It is also specific to the PRG file format, which is even above layer 4: Reading from channel 1 skips the first two bytes, the load address of a PRG file.

## Conclusion

Even though its protocols are not completely optimal, and some parts seem a little unclean and ad-hoc, JiffyDOS is a smart extension to Standard Serial with a very clean detection and fallback design. It is justifyably considered the de-facto successor of the Standard Serial protocol, beating Commodore's own "Fast Serial" extension.

# Next Up

Part 8 of the series of articles on the Commodore Peripheral Bus family will cover the CBDOS ("computer-based DOS") bus, as used by the unreleased Commodore 65 computer, which does away with layers 1 and 2, because the drive controllers are integrated into the computer, so layer 3 sits directly on top of function calls that call into the DOS code running on the same CPU.

> This article series is an Open Source project. Corrections, clarifications and additions are **highly** appreciated. I will regularly update the articles from the repository at [https://github.com/mist64/cbmbus_doc](https://github.com/mist64/cbmbus_doc).


# References

* http://www.nlq.de/
* https://web.archive.org/web/20130128220953/http://hem.passagen.se/harlekin/download.htm
* https://sites.google.com/site/h2obsession/CBM/C128/JiffySoft128
* https://www.c64-wiki.com/wiki/SJLOAD
* http://www.baltissen.org/newhtm/sourcecodes.htm
* https://github.com/MEGA65/open-roms/blob/master/doc/Protocol-JiffyDOS.md
* https://retrocomputing.stackexchange.com/questions/12755/what-is-the-c64-disk-drive-jiffy-protocol
* https://github.com/rkrajnc/sd2iec/blob/master/src/iec.c
* https://github.com/rkrajnc/sd2iec/blob/master/src/lpc17xx/fastloader-ll.c
* https://github.com/gummyworm/skippydos
* https://web.archive.org/web/20060718184600/http://cmdrkey.com/cbm/misc/history.html


[^1]: The 1541 implementation uses a threshold of 218 µs to detect this.

[^2]: On the C64 – the computer which JiffyDOS was designed for – the CPU is halted by the video chip for 40 µs on every 8th raster line (504 µs); as well as for a little while on all raster lines that contain sprites. The C64 implemenation disables all sprites during a transmission and delays the *Go* signal whenever video chip DMA is anticipated.

[^3]: The C128 implementation runs in 1 Mhz mode to be compatible with the VIC-II video chip.

[^4]: C64 music playback usually updates the state of the sound chip every 1/50 of a second. One approach of working around this would be detecting the signal from the device by having an NMI every 75 µs that checks the wire. Each NMI would eat up about 30 µs, effectively halving the CPU throughput in this state.
