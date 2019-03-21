# Commodore Peripheral Bus: Part 6: JiffyDOS

* history
	* Mark Fellows, 1985
	* ROM replacements
	* available for all Commodore computers and practically all IEC disk drives
	* supported by modern devices ike SD2IEC
* software-only faster protocol
* same connector, same wires (ATN, CLK, DATA)
* faster byte send
* same ATN command protocol above

* new byte send protocol
	* send 2 bits at a time
	* every TODO µs
* original protocol has a "no slower than" requirement
* JiffyDOS has a "no faster or slower than" requirement
* within TODO µs, receiver must be able to read two bits every TODO µs

* backwards compatibility
	* devices that can speak JiffyDOS and devices that can't can share the same bus
	* all devices that speak JiffyDOS also speak the original protocol
	* -> ok if a set of devices speak JiffyDOS, while others are passive
	* -> if not everyone in a set of devices can speak JiffyDOS, they can revert to the original protocol
	* commands from the controller have to be received by all devices
	* -> commands have to use the regular protocol
	* detection & enabling
		* controller waits TODO µs between bit 6 and 7 of LISTEN or TALK
		* -> device will speak fast protocol in this TALK/LISTEN session
		* addressed device pulls DATA for TODO µs
		* -> controller knows device will speak fast protocol
	* if all listeners and talkers speak JiffyDOS, everything is OK
	* otherwise UNTALT, UNLISTEN and try again with original protocol
	* common case: point-to-point between controller and one device
	* -> signal JiffyDOS protocol, if device replies, speak JiffyDOS

* is the send/receive protocol actually symmetrical? could two devices talk to each other?

* JiffyDOS LOAD/SAVE
	* TODO