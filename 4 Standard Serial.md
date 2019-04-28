# Commodore Peripheral Bus: Part 4: Standard Serial

In the [series about the variants of the Commodore Peripheral Bus family](https://www.pagetable.com/?p=1018), this article covers the lowest two layers (electrical and byte transfer) of the "Serial" bus as found on the VIC-20/C64 and supported by all later members of the Commodore 8 bit series.

![](docs/cbmbus/serial_layers.png =211x241)



* Commodore calls it the serial bus
* source calls it "serial4.0" (C64)
* literature calls it serial IEC or IEC, but it's not an IEC standard

* overview, idea, motivation, features
	* SAME: multiple devices, daisy-chained
	* SAME: byte oriented
	* SAME: any device can send data to any set of devices (one-to-many)
	* SAME: channels
	* timing based on min/max delays, not strict implicit clock (like RS-232), can be implemented in software
	* no way to do full asynchrounous (all handshake) with just 2 wires, timing requirements!
	-> 3 wires total
	-> one dedicated controller

* IEEE -> IEC:
	* 16->4 wires (incl. SRQ) 
	* NDAC removed
	* DAV replaced by CLK
	* NRFD replaced by DATA

* connector & electrical
	* 6-pin DIN
		* 1 SRQ
		* 2 GND
		* 3 ATN
		* 4 CLK
		* 5 DATA
		* 6 RESET
	* all 3 data lines are open collector
		* defaults to 5V (line is "incative")
		* will be 0V if any device pulls it down ("asserts" it, line is "active")
		* it's impossible to tell who pulls it down

* transfering bytes
	* bus is byte oriented
	* one sender
	* any number of receivers
	* any number of passive devices
	* two wires, CLK and DATA
	* CLK is the sender's handshaking flag, DATA the receivers'
	* everyone not involved will leave CLK and DATA alone
	* protocol
		* setup
			* sender pulls CLK = I am interested in sending data, but I don't have any data yet
			* all receivers pull DATA = I am interested in accepting data
			* this state can be held indefinitely
		* ready to send:
			* sender releases CLK = I am ready to send a byte
			* all receivers release DATA = I am ready to receive a byte
			* there is no time limit, any receiver that is busy can delay this indefinitely
		* prepare sending byte
			* sender pulls CLK = there is no valid bit on the DATA line
		* for every bit (LSB first)
			* sender sets/clears DATA
			* sender releases CLK, pulls this for 60+ µs = there is a valid bit on the DATA line
				* C64 holds CLK it for 42 ticks only, releases CLK and DATA at the same time
				* 1541 holds CLK for 74 ticks -> $E976, releases first CLK then DATA
			* sender pulls CLK, releases DATA = there is no valid bit on the DATA line
			* XXX does it have to release DATA???
		* byte ack
			* receiver pulls DATA within 1000 µs (any receiver!) = byte received OK
	* EOI
		* if "prepare sending byte" takes 200+ µs, the following byte is the last one
		* receiver pulls data for a short while to acknowledge
			* TODO
		* at the end of transmission
			* sender releases CLK
			* receivers release DATA
	* sender doesn't actually have any data
		* will release clock and do nothing
		* receiver first thinks it's EOI, but it takes even longer
		* receiver times out
	
	* comments:
		* transfer cannot start until all receivers are ready
		* any receiver can ACK
			* no ACK means that all receivers died
		* EOI is a timing sidechannel
		* what are the timing requirements?
			* receiver must be able to measure 200 µs reliably
			* receiver must be able to accept bit within 60 µs
			* receiver must be able to ack byte within 1000 µs
			* TODO ...
			* TODO otherwise...?
		* it's impossible to ack every bit with just two wires in order to make the protocol completely timing independent
		* problem!
			* any receiver can ack a byte buy pulling DATA
			* -> if one receiver is super fast and the other one is super slow, protocol may break
			* XXX fixed by timing requirements?
		* why use the clock at all, if we have strict timing requirements? we could just as well have "data valid" windows (Jiffy does this, and uses CLK for data as well)

![](docs/cbmbus/serial.gif =601x255)

* ATN	
		* XXX ATN in the middle of a byte transmission?

* TALK/LISTEN level differences
	* file not found detection
		* when drive becomes talker, it causes a "sender doesn't actually have any data" timeout

