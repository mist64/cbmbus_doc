# Part 0
convert -bordercolor black -border 1 /tmp/Overview/Overview.001.png  ../docs/cbmbus/cbmbus.png

# Part 1
convert -crop 420x480+0+0\! -bordercolor black -border 1 /tmp/IEEE-488\ Layers/IEEE-488\ Layers.001.png  ../docs/cbmbus/ieee-488_layers.png
convert -crop 300x160+0+0\! -bordercolor black -border 1 -loop 0 -delay 100 /tmp/Open\ Collector/*.png ../docs/cbmbus/open_collector.gif
convert -bordercolor black -border 1 -loop 0 -delay 200 /tmp/IEEE-488/*.png ../docs/cbmbus/ieee-488.gif
convert -crop 1200x660+0+0\! -bordercolor black -border 1 /tmp/IEEE-488\ Timing/IEEE-488\ Timing.001.png ../docs/cbmbus/ieee-488.png
for i in 01 02 03 04 05 06 07 08 09 10 11 12 13; do
	convert -crop 1200x522+0+84\! -bordercolor black -border 1 /tmp/IEEE-488/IEEE-488.0$i.png ../docs/cbmbus/ieee-488-$i.png
done

# Part 2
convert -bordercolor black -border 1 /tmp/Layer\ 3/Layer\ 3.001.png ../docs/cbmbus/layer3.png

# Part 3
convert -bordercolor black -border 1 /tmp/Layer\ 4/Layer\ 4.001.png ../docs/cbmbus/layer4.png

# Part 4
convert -crop 420x480+0+0\! -bordercolor black -border 1 /tmp/Serial\ Layers/Serial\ Layers.001.png  ../docs/cbmbus/serial_layers.png
convert -crop 1200x686+0+0\! -bordercolor black -border 1 -loop 0 -delay 200 /tmp/Serial/*.png ../docs/cbmbus/serial.gif
for i in 01 02 03 04 05 06 07 08 29 30 31 32 33 34 35 36 37 39 40 41 42; do
	convert -crop 1200x262+0+84\! -bordercolor black -border 1 /tmp/Serial/Serial.0$i.png ../docs/cbmbus/serial-$i.png
done
convert -crop 1200x600+0+0\! -bordercolor black -border 1 /tmp/Serial/Serial.038.png  ../docs/cbmbus/serial.png

# Part 5
convert -crop 420x480+0+0\! -bordercolor black -border 1 /tmp/TCBM\ Layers/TCBM\ Layers.001.png  ../docs/cbmbus/tcbm_layers.png

convert -bordercolor black -border 1 -loop 0 -delay 200 /tmp/TCBM/TCBM.00[123456789].png /tmp/TCBM/TCBM.010.png ../docs/cbmbus/tcbm-send.gif
convert -bordercolor black -border 1 -loop 0 -delay 200 /tmp/TCBM/TCBM.01[123456789].png /tmp/TCBM/TCBM.02[012345].png ../docs/cbmbus/tcbm-receive.gif

for i in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25; do
	convert -crop 1200x522+0+84\! -bordercolor black -border 1 /tmp/TCBM/TCBM.0$i.png ../docs/cbmbus/tcbm-$i.png
done
convert -crop 1200x550+0+0\! -bordercolor black -border 1 /tmp/TCBM/TCBM.026.png  ../docs/cbmbus/tcbm-send.png
convert -crop 1200x550+0+0\! -bordercolor black -border 1 /tmp/TCBM/TCBM.027.png  ../docs/cbmbus/tcbm-receive.png

# Part 6
convert -crop 580x480+0+0\! -bordercolor black -border 1 /tmp/JiffyDOS\ Layers/JiffyDOS\ Layers.001.png  ../docs/cbmbus/JiffyDOS_layers.png

convert -crop 1200x686+0+0\! -bordercolor black -border 1 -loop 0 -delay 200 /tmp/JiffyDOS/JiffyDOS.00*.png ../docs/cbmbus/jiffydos-receive.gif
convert -crop 1200x686+0+0\! -bordercolor black -border 1 -loop 0 -delay 200 /tmp/JiffyDOS/JiffyDOS.01[3456789].png /tmp/JiffyDOS/JiffyDOS.02[01].png ../docs/cbmbus/jiffydos-send.gif

a=/tmp/JiffyDOS/JiffyDOS.0; b=.png; convert -crop 1200x686+0+0\! -bordercolor black -border 1 -loop 0 -delay 200 ${a}25${b} ${a}26${b} ${a}27${b} ${a}28${b} ${a}29${b} ${a}30${b} ${a}31${b} ${a}32${b} ${a}33${b} ${a}34${b} ${a}35${b} ${a}36${b} ${a}29${b} ${a}37${b} ${a}31${b} ${a}32${b} ${a}33${b} ${a}34${b} ${a}35${b} ${a}36${b} ${a}29${b} ${a}38${b} ${a}39${b} ${a}40${b} ${a}41${b} ../docs/cbmbus/jiffydos-load.gif

for i in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41; do
	convert -crop 1200x262+0+84\! -bordercolor black -border 1 /tmp/JiffyDOS/JiffyDOS.0$i.png ../docs/cbmbus/jiffydos-$i.png
done

convert -crop 1200x600+0+0\! -bordercolor black -border 1 /tmp/JiffyDOS/JiffyDOS.012.png  ../docs/cbmbus/jiffydos-receive.png
convert -crop 1200x600+0+0\! -bordercolor black -border 1 /tmp/JiffyDOS/JiffyDOS.024.png  ../docs/cbmbus/jiffydos-send.png
