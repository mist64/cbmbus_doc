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
convert -crop 420x480+0+0\! -bordercolor black -border 1 /tmp/Serial\ Layers/Serial\ Layers.001.png  ../docs/cbmbus/serial_layers.png
convert -crop 1200x686+0+0\! -bordercolor black -border 1 -loop 0 -delay 200 /tmp/Serial/*.png ../docs/cbmbus/serial.gif
for i in 01 02 03 04 05 06 07 08 29 30 31; do
	convert -crop 1200x262+0+84\! -bordercolor black -border 1 /tmp/Serial/Serial.0$i.png ../docs/cbmbus/serial-$i.png
done

