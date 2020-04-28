# Commodore Peripheral Bus: Part 6: JiffyDOS

In the [series about the variants of the Commodore Peripheral Bus family](https://www.pagetable.com/?p=1018), this article covers the third party "JiffyDOS" extension to the Commodore Serial Bus protocol, which shipped as a ROM patch for computers and drives, replacing the byte transmission protocol of Standard Serial by using the clock and data lines in a more efficient way.


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

The basic idea of JiffyDOS is the following: Layer 2 of the original Serial protocol had to be slowed down for the C64 because the video chip frequently blocked the memory bus, stalling the CPU, which would make it miss deadlines. With JiffyDOS, the controller (i.e. the computer) only initiates the transmission of a data byte when it can guarantee that it will be undisturbed for the duration of the whole byte – which can then be sent way faster. This makes data transmission speedups of 10x possible.

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

#### 0: Initial State
![](docs/cbmbus/jiffydos-13.png =601x131)

Since the JiffyDOS protocol integrates with the Standard Serial protocol, its initial state must match the state of the parent protocol at this point: After the "LISTEN"/"SECOND" command, the sender (the controller) is holding the CLK line and the receiver (the device) is holding the DATA line.

#### 1: Device is ready to receive
![](docs/cbmbus/jiffydos-14.png =601x131)

Once the device is done processing the previous data, which may for instance include writing a sector to the media, it indicates that it is ready to receive by releasing the DATA line. It may delay this step indefinitely.

#### 2: Controller sends the "Go" signal
![](docs/cbmbus/jiffydos-15.png =601x131)

Triggered by DATA being 1, the controller indicates that it will start sending a data byte by releasing the CLK line - this is the "Go" signal. During the transmission of the byte, both lines will be owned by the controller, and the sequence of steps is purely based on timing; there are no ACK signals.

XXX but no earlier than 37 µs after DATA turning 1

The controller may delay this step indefinitely. In practice, it will until it has a guaranteed XXX 65 µs time window without interruptions.

#### 3: Controller puts data bits #4 and #5 onto wires
![](docs/cbmbus/jiffydos-16.png =601x131)

First, the controller puts the first pair of data bits onto the two wires (CLK: #4, DATA: #5).

The wires have to be valid for 5 µs starting after 14 µs.

The order of bits (4-5, 6-7, 3-1, 2-0) is an optimization based on the C64/1541 port layout, minimizing shift operations.

#### 4: Controller puts data bits #6 and #7 onto wires
![](docs/cbmbus/jiffydos-17.png =601x131)

The controller puts the second pair of data bits onto the two wires (CLK: #6, DATA: #7).

The wires have to be valid for 7 µs starting after 13 µs.

#### 5: Controller puts data bits #3 and #1 onto wires
![](docs/cbmbus/jiffydos-18.png =601x131)

The controller puts the third pair of data bits onto the two wires (CLK: #3, DATA: #1).

The wires have to be valid for 7 µs starting after 11 µs.

#### 6: Controller puts data bits #2 and #0 onto wires
![](docs/cbmbus/jiffydos-19.png =601x131)

The controller puts the final pair of data bits onto the two wires (CLK: #2, DATA = #0).

The wires have to be valid after 13 µs and the state has to remain held.

#### 7: Controller signals no EOI, and is now busy again
![](docs/cbmbus/jiffydos-20.png =601x131)

Still timing-based, the controller pulls the CLK line, signaling that there is no EOI (end-of-stream). A pulled CLK line also means that the controller is now busy again, so the transmission of the next data byte cannot start yet.

In the no-EOI case, it also releases the DATA line so it can be operated by the device again.

The wires have to be valid after 13 µs and hold it.

#### 8: Device is now busy again
![](docs/cbmbus/jiffydos-21.png =601x131)

After reading the CLK line, the device pulls the DATA line. This is the same as the initial state, so the protocol continues with step 1 for the next data byte.

Of course, the controller can alternatively pull ATN at this point, and send an "UNLISTEN" command, for example.

### JiffyDOS Byte Send - EOI & Error

An EOI event is signaled through the CLK line in step 7.

#### 7a: Controller signals EOI/Error status
![](docs/cbmbus/jiffydos-22.png =601x131)

If there is an EOI or an error, the controller releases CLK.

In the EOI case, DATA is pulled, and in the error case, DATA is released.

If both CLK and DATA are released, this indicates a "timeout" error. Note that this combination has been carefully chosen: An idle device would also keep both wires released, and both wires released is also the default bus state if no device is attached, so a non-responsive or nonexistent device would also lead to this case.

As with the regular case, the wires have to be valid after 13 µs. And in this case, they need to be held for 7 µs.

#### 7b: Controller is now busy again
![](docs/cbmbus/jiffydos-23.png =601x131)

In the EOI case, the controller will then pull the CLK line, signaling that it is busy again.

EOI/error signaling can be seen as delaying the controller's last step in the sequence by keeping CLK released for some time after the last data bits:

![](docs/cbmbus/jiffydos-send.png =601x422)

### JiffyDOS Byte Receive

When the device sends data to the controller, it transmits two bits at a time every 10-11 µs using the CLK and DATA lines, with no handshake. For each byte, the device signals that it is ready to send, followed by the controller signaling the device to start the transmission, thus starting the timing critical window of XXX 55 µs.

Compared to the byte send case, the ownership of the CLK and DATA lines outside the core data transmission is swapped, but it is the controller that sends the "Go" signal in both the send and the receive case.

The following animation shows a byte being received by the controller from the device.

![](docs/cbmbus/jiffydos-receive.gif =601x344)

Again, let's go through it step by step:

#### 0: Initial State
![](docs/cbmbus/jiffydos-01.png =601x131)

Like in the "send" case, the initial state is the same as with Standard Serial, since this is the natural state after the "LISTEN"/"SECOND" command: The sender (the device) is holding the CLK line and the receiver (the controller) is holding the DATA line.

#### 1: Device is ready to send
![](docs/cbmbus/jiffydos-02.png =601x131)

Once the device has the next data byte at hand, that is, for example, after reading it from a buffer, or after reading a new sector from the media, it indicates that it is ready to send by releasing the CLK line. It may delay this step indefinitely.

#### 2: Controller sends the "Go" signal
![](docs/cbmbus/jiffydos-03.png =601x131)

Triggered by CLK being 0, the controller indicates by releasing the DATA line that the device must now start sending a data byte - this is the "Go" signal. During the transmission of the byte, both lines will be owned by the device, and the sequence of steps is purely based on timing; there are no ACK signals.

The controller may delay this step indefinitely. In practice, it will until it has a guaranteed XXX 55 µs time window without interruptions.

#### 3: Device puts data bits #0 and #1 onto wires
![](docs/cbmbus/jiffydos-04.png =601x131)

First, the device puts the first pair of data bits onto the two wires (CLK: NOT #0, DATA: NOT #1).

The wires have to be valid for 1 µs after 15 µs.

In the receive case, the bits are sent starting with the least significant bit, and all bit values are inverted.

#### 4: Device puts data bits #2 and #3 onto wires
![](docs/cbmbus/jiffydos-05.png =601x131)

The device puts the second pair of data bits onto the two wires (CLK: NOT #2, DATA: NOT #3).

The wires have to be valid for 1 µs after 10 µs.

#### 5: Device puts data bits #4 and #5 onto wires
![](docs/cbmbus/jiffydos-06.png =601x131)

The device puts the third pair of data bits onto the two wires (CLK: NOT #4, DATA: NOT #5).

The wires have to be valid for 1 µs after 11 µs.

#### 6: Device puts data bits #6 and #7 onto wires
![](docs/cbmbus/jiffydos-07.png =601x131)

The device puts the final pair of data bits onto the two wires (CLK: NOT #6, DATA: NOT #7).

The wires have to be valid for 1 µs after 11 µs.

#### 7: Device signals no EOI, and is now busy again
![](docs/cbmbus/jiffydos-08.png =601x131)

Still timing-based, the device pulls the CLK line, signaling that there is no EOI. A pulled CLK line also means that the device is now busy again, so the transmission of the next byte cannot start.

In the no-EOI case, it also releases the DATA line so it can be operated by the controller again.
 
The wires have to be valid after 11 µs and the state has to remain held.

#### 8: Controller is now busy again
![](docs/cbmbus/jiffydos-09.png =601x131)

After reading the CLK line, the controller pulls the DATA line. This is the same as the initial state, so the protocol continues with step 1 for the next data byte.

Similarly to the send case, the controller can alternatively pull ATN at this point, and send an "UNTALK" command, for example.

### JiffyDOS Byte Receive - EOI & Error

An EOI event is signaled through the CLK line in step 7.

#### 7a: Device signals EOI/Error status
![](docs/cbmbus/jiffydos-10.png =601x131)

If there is an EOI or an error, the device releases CLK.

In the EOI case, DATA is pulled, and in the error case, DATA is released.

As with the regular case, the wires have to be valid after 13 µs. And in this case, they need to be held for 13 µs.

#### 7b: Device is now busy again
![](docs/cbmbus/jiffydos-11.png =601x131)

In the EOI case, the device will then pull the CLK line, signaling that it is busy again.

EOI/error signaling can be seen as delaying the controller's last step in the sequence by keeping CLK released for some time after the last data bits:

![](docs/cbmbus/jiffydos-receive.png =601x422)

## JiffyDOS LOAD

The JiffyDOS "LOAD" protocol optimizes for the most common use case: loading a complete "PRG" file from a disk drive into the host's memory.

In Commodore DOS, which is layer 4 of the protocol stack, PRG files are finite byte streams that start with a two-byte (little endian) "load address", that is, target address in the host's address space. There is a dedicated KERNAL call (`LOAD` at $FFD5) on Commodore computers, and all versions of Commodore BASIC expose it through the `LOAD` statement:

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

#### 0: Initial State
![](docs/cbmbus/jiffydos-25.png =601x131)

Like the other protocols, JiffyDOS LOAD integrates with the Standard Serial protocol, so its initial state must match the state of the parent protocol at this point: After the "TALK" command, the sender (the device) is holding the CLK line and the receiver (the controller) is holding the DATA line.

#### 1: Controller clears DATA wire (not a signal)
![](docs/cbmbus/jiffydos-26.png =601x131)

First, the controller releases the DATA wire. This is not a signal for the device, but necessary so that the controller can read the DATA line in the next step. The controller can therefore choose to release the wire as late as just before reading it back.

#### 2: Device signals EOI/!EOI– hold for 75 µs 
![](docs/cbmbus/jiffydos-27.png =601x131)

Next, the device puts a flag whether there is more data to be transmitted onto the DATA line. 1 means there is more data (!EOI), while 0 means that there is no more data (EOI): the end of the stream has been reached or there has been an error.

To signal that the state of the DATA line is valid, the device releases the CLK line and holds this state for 75 µs.

The device can delay this step as long as it wishes, e.g. to read data from the media.

If there is more data, the protocol switches to byte receive mode, otherwise it continues with step 3.

#### 3: Device signals no error within 1100 µs – hold for 100 µs
![](docs/cbmbus/jiffydos-28.png =601x131)

In the case of the end of the transmission (EOI), the final step is for the device to signal whether there was an error or whether this is the regular end of the file.

If there is no error, the device pulls CLK and holds it for 100 µs no later than after 1100 µs, otherwise, it keeps CLK released for 1100 µs. (The DATA line was already released in the previous step, because DATA = 0 signaled EOI.)

### LOAD: Byte Receive

After the device has indicated that there is more data, the protocol goes into the "Byte Receive" mode, which can transmit zero or more data bytes.

![](docs/cbmbus/jiffydos-load-receive.png =601x167)

#### 0: Initial State
![](docs/cbmbus/jiffydos-30.png =601x131)

The initial state has the device holding DATA and keeping CLK released – this is the same as step 2 of escape mode after !EOI has been signaled.

#### 1: Device signals ESC/!ESC
![](docs/cbmbus/jiffydos-31.png =601x131)

At the beginning of the loop for each data byte, the device signals whether the protocol should switch back to escape mode. If yes, the device sets CLK to 1. Otherwise, it sets CLK to 0.

In addition, the device releases the DATA line, so the controller can use it in the next step.

In the first iteration of the byte receive loop, releasing DATA signals that CLK is now valid. In this case, the controller triggers on DATA = 0, which means the device may arbitrarily delay this step.

In subsequent iterations, the controller cannot trigger on DATA, because the value of DATA in the previous step – step 6 of the previous iteration – could have been either 0 or 1, so this step is based on timing: The value of CLK must be valid at 11 µs after the previous step. DATA still has to be cleared so that the host can use it in the next step.

#### 2: Controller signals "Go" for 12+ µs
![](docs/cbmbus/jiffydos-32.png =601x131)

As soon as the controller can guarantee a window of at least 58 µs of being undisturbed, it pulls the DATA line for at least 12 µs, telling the device to immediately start the transmission of the 8 data bits.

This happens independently of whether ESC was true or false in the previous step. It isn't until after this step that the protocol jumps to step 2 of the escape mode protocol if the device set CLK in the previous step.

#### 2b: Controller clears DATA wire (not a signal)
![](docs/cbmbus/jiffydos-33.png =601x131)

In order to be able to read the data bits from both DATA and CLK in the next steps, the controller releases DATA before it reads the first pair of bits. Again, this is not a signal for the device.

#### 3: Device puts data bits #0 and #1 onto wires
![](docs/cbmbus/jiffydos-34.png =601x131)

Triggered by the "Go" event, (step 2), the device puts the first two data bits onto the two wires (CLK: NOT #0, DATA: NOT #1).

The bits are sent starting with the least significant bit, and all bit values are inverted.

The controller reads the wires exactly 15 µs after "Go" – and they may be set no earlier than 4 µs after the "Go" signal, since the value of ESC in the CLK wire must still be valid 3 µs after the start of the "Go" signal.

#### 4: Device puts data bits #2 and #3 onto wires
![](docs/cbmbus/jiffydos-35.png =601x131)

Based solely on timing, the device puts the second pair of data bits onto the wires (CLK: NOT #2, DATA = NOT #3).

The controller reads the wires exactly 10 µs later.

#### 5: Device puts data bits #4 and #5 onto wires
![](docs/cbmbus/jiffydos-36.png =601x131)

The device puts the third pair of data bits onto the wires (CLK: NOT #4, DATA = NOT #5).

The controller reads the wires exactly 11 µs later.

#### 6: Device puts data bits #6 and #7 onto wires
![](docs/cbmbus/jiffydos-37.png =601x131)

The device puts the final pair of data bits onto the wires (CLK: NOT #6, DATA: NOT #7).

The controller reads the wires exactly 11 µs later.

At this point, the protocol loops back to step 1.

### Timing Summary

#### Send

| Step | Event                                | Wires               | Type    | Delay                   | Hold For |
|------|--------------------------------------|---------------------|---------|-------------------------|----------|
|   1  | Device signals ready-to-receive      | DATA = 0            | trigger | 0 - ∞                   | ∞        |
|   2  | Controller signals "Go"              | CLK = 0             | trigger | 37 µs - ∞               | ∞        |
|   3  | Controller sends 1st pair of bits    | CLK = #4, DATA = #5 | sample  | 14 µs                   | 5 µs     |
|   4  | Controller sends 2nd pair of bits    | CLK = #6, DATA = #7 | sample  | 13 µs                   | 7 µs     |
|   5  | Controller sends 3rd pair of bits    | CLK = #3, DATA = #1 | sample  | 11 µs                   | 7 µs     |
|   6  | Controller sends 4th pair of bits    | CLK = #2, DATA = #0 | sample  | 13 µs                   | 7 µs     |
|   7  | Controller signals EOI               | CLK = 1/0, DATA = 0 | sample  | 7 - 13 µs               | ∞        |
|   8  | Device signals not ready to receive  | DATA = 1            | ?       | 0 - ∞                   | ∞        | XXXX!!!

#### Receive

| Step | Event                                | Wires               | Type    | Delay                   | Hold For |
|------|--------------------------------------|---------------------|---------|-------------------------|----------|
|   1  | Device signals ready-to-send         | DATA = 0            | trigger | 0 - ∞                   | ∞        |
|   2  | Controller signals "Go"              | CLK = 0             | trigger | 0 - ∞                   | ∞        |
|   3  | Device sends 1st pair of bits        | CLK = #0, DATA = #1 | sample  | 15 µs                   | 1 µs     |
|   4  | Device sends 2nd pair of bits        | CLK = #2, DATA = #3 | sample  | 10 µs                   | 1 µs     |
|   5  | Device sends 3rd pair of bits        | CLK = #4, DATA = #5 | sample  | 11 µs                   | 1 µs     |
|   6  | Device sends 4th pair of bits        | CLK = #6, DATA = #7 | sample  | 11 µs                   | 1 µs     |
|   7  | Device signals no EOI                | CLK = 1, DATA = 0   | sample  | 1 - 11 µs               | ∞        | XXXX!!!!
|   8  | Controller signals not ready to send | DATA = 1            | ?       | 0 - ∞                   | ∞        | XXXX!!!!

### LOAD

#### Escape Mode

Start:

| Step | Event                                | Wires                | Type    | Delay                   | Hold For |
|------|--------------------------------------|----------------------|---------|-------------------------|----------|
|   1  | Controller clears DATA wire          | DATA = 0             | -       |                         |          |
|   2  | Device signals EOI/!EOI & valid      | DATA = !EOI, CLK = 0 | trigger | 0 - ∞                   | 75 µs    |

* If EOI = 0, "Byte Receive" follows.
* If EOI = 1, "End" follows.

#### End

| Step | Event                                | Wires               | Type    | Delay                   | Hold For |
|------|--------------------------------------|---------------------|---------|-------------------------|----------|
|   3  | Device signals no error              | CLK = 1             | trigger | 0 - 1100 µs             | 100 µs   |

#### Byte Receive

| Step | Event                                | Wires               | Type    | Delay                   | Hold For |
|------|--------------------------------------|---------------------|---------|-------------------------|----------|
|   1  | Device signals ESC/!ESC & valid      | CLK = ESC, DATA = 0 | trigger | 0 - 84 µs               | ∞<sup>*</sup>|
|   2  | Controller signals "Go", clears DATA | DATA = 1; DATA = 0  | trigger | 0 - ∞                   | 12 µs    |
|   3  | Device sends 1st pair of bits        | CLK = #0, DATA = #1 | sample  | 15 µs<sup>*</sup>       | 1 µs     |
|   4  | Device sends 2nd pair of bits        | CLK = #2, DATA = #3 | sample  | 10 µs                   | 1 µs     |
|   5  | Device sends 3rd pair of bits        | CLK = #4, DATA = #5 | sample  | 11 µs                   | 1 µs     |
|   6  | Device sends 4th pair of bits        | CLK = #6, DATA = #7 | sample  | 11 µs                   | 1 µs     |

<sup>*</sup>The value of ESC in the CLK wire must still be valid 3 µs after the start of the "Go" signal, so the first pair of data bits must not be put into CLK and DATA earlier than 4 µs after "Go".

* if ESC = 1, "Escape Mode" follows after B

# Discussion

JiffyDOS is a significant improvement to Standard Serial, and it can be rightly considered the de-fact successor to it. Nevertheless, there are a few points that can be critisized.

## No formal specification

No official formal specification of JiffyDOS has ever been released. In practice, this was never much of a problem, since official versions of JiffyDOS were available for practically all computers and devices with a Commodore Serial Bus. Nevertheless, modern JiffyDOS-compatible projects such as SD2IEC and [open-roms](https://github.com/MEGA65/open-roms) had to reverse-engineer the protocols from either reverse-engineering the code or analyzing the data on the wires.

This document could now be considered the formal specification, even though it's not official. But the problem is that this is just the C64 and 1541 reference implementations converted into English, which is not the same as a formal specification.

The timing data above states for example that when sending data bits, the controller needs to hold the wire state for 7 µs. The reason for this is that the 1541 implementation uses a loop like this to check for the "Go" signal that started the transmission:

	:	cpx $1800 ; GPIO
		beq :-

One iteration of this loop takes 7 clock cycles, which is 7 µs on a 1 MHz 1541. In the best case, the GPIO pins get read in the very first cycle they changed, and in the worst case, the change one cycle after the read, introcuing a latency of 7 µs.

This means that the 1541 can measure the start time of the "Go" signal only with an accuracy of 0-7 µs. So if the host holds the data wires constant for a 7 µs window, it gives the 1541 a chance to read the value no matter what latency was introduced in the wait loop.

It's different when data gets transmitted from the device to the host though: The timing data above states that the device needs to hold the wire state only for a single µs. Let's look at what C64 code to receive data bits would look like:

		sta $dd00 ; GPIO, "Go" signal
		nop
		nop
		nop
		nop
		lda $dd00 ; GPIO

In this case, the GPIO gets read exactly 11 µs after the "Go" signal. The device has to make sure the data bits are on the bus in this very cycle. In practice though, the 1541 code will use the same "cpx $1800" code as above to check for "Go", and then put the data onto the wires fo at least 7 µs, to make sure that in spite of the variable latency, the host will read the correct data at 11 µs.

So all communication has a 7 µs fuzz when a 1541 is involved, but because it's always the host that it initiating timing windows, this fuzz is on the receiver side. Therefore, when sending, values have to be held for 7 µs, and when receiving, they only have to be held for 1 µs.

XXXXX

* compliance means staying within the timing bounds of all existing implementations

## C64/1541-specific

* bit order and negation based on C64/1541 ports
	* send case: high nybble decoded by device, low-nybble encoded by controller
	* receive case: encoded by device
* all non-C64/1541 devices are faster, so they can handle the overhead
* not symmetric, can't do one-to-many
	* but that's not solvable if it's always the C64 that needs to initiate a byte transmission
	* in general: one-to-many not possible if there are ready-*windows*
	* if all participants have to say they are ready, by the time the last participant is ready, one of the other participant may not be ready any more

## Protocol not optimal

* 37 µs slows down everything
* device should prepare the data before, then signal that it's ready
* this allows faster implementations

* then again, only the LOAD case really matters...

* 2 bits can be done in 8 µs instead of 10/11
* or even faster: LDA zp, STA $1800, LDA zp, STA $1800; LDA $DD00, PHA, LDA $DD00, PHA...
* or the standard LDA $DD00, LSR, LSR, EOR $DD00
* C128/1581 (both 2 MHz) suffer from delays everywhere
* even if C64/1541 have to do pre-/post-processing, they could be as fast by shifting complexity out of the transmission loop
* so C128/1571 would benefit from the faster loop

* 10/10/11/10/11 is ugly

## LOAD protocol not suitable for IRQs

* once-per-block status transmission doesn't wait for host
* host must be in a tight loop with IRQs off

## Layer violation

* detection
	* technically, signaling specifically on TALK and LISTEN violates the layering
	* some implementation signal on all bytes under ATN, which is cleaner
	* but it's spec-compliant to send the TALK/LISTEN secondary will be sent without the signal
	* so device that turns Jiffy on/off based on whether last ATN byte had signal or not would not work right
	* -> it's okay to send the signal with every ATN, but the device must detect it only on TALK/LISTEN
* LOAD
	* magic channel 1
	* skips 2 bytes (PRG)

## Error handling?

## Conclusion

...

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

[^2]: On the C64 – the computer which JiffyDOS was designed for – the CPU is halted by the video chip for 40 µs on every 8th raster line (504 µs); as well as for a little while on all raster lines that contain sprites. The C64 implemenation disables all sprites during a transmission and delays the "Go" signal whenever video chip DMA is anticipated.