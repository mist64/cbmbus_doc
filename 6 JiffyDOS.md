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
* within 7 µs windows, receiver must be able to read two bits every 10 µs
* sender and receiver must guarantee 85 µs window without interruptions
* two-way handshake after every byte

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


![](docs/cbmbus/jiffydos.gif =601x344)

Let's go through it step by step:

#### 0: Initial State
![](docs/cbmbus/jiffydos-01.png =601x131)

#### 1: Sender is ready to send
![](docs/cbmbus/jiffydos-02.png =601x131)

#### 2: Receiver is ready to receive
![](docs/cbmbus/jiffydos-03.png =601x131)

#### 3: Sender puts data bits #0 and #1 onto wires
![](docs/cbmbus/jiffydos-04.png =601x131)

#### 4: Sender puts data bits #2 and #3 onto wires
![](docs/cbmbus/jiffydos-05.png =601x131)

#### 5: Sender puts data bits #4 and #5 onto wires
![](docs/cbmbus/jiffydos-06.png =601x131)

#### 6: Sender puts data bits #6 and #7 onto wires
![](docs/cbmbus/jiffydos-07.png =601x131)

#### 7: Sender signals OK/busy
![](docs/cbmbus/jiffydos-08.png =601x131)

#### 8: Receiver is now busy again
![](docs/cbmbus/jiffydos-09.png =601x131)

### End of Stream

#### 7a: Sender signals EOI status
![](docs/cbmbus/jiffydos-10.png =601x131)

#### 7b: Sender is now busy again
![](docs/cbmbus/jiffydos-11.png =601x131)

### Error

#### 7a': Sender signals error status
![](docs/cbmbus/jiffydos-12.png =601x131)


![](docs/cbmbus/jiffydos.png =601x301)
