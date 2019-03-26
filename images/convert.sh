#convert -crop 300x160+0+0\! -bordercolor black -border 1 -loop 0 -delay 100 /tmp/Open\ Collector/*.png ../docs/cbmbus/open_collector.gif
#convert -bordercolor black -border 1 -loop 0 -delay 200 /tmp/IEEE-488/*.png ../docs/cbmbus/ieee-488.gif

for i in 01 02 03 04 05 06 07 08 09 10 11 12 13; do
	convert -crop 1200x510+0+84\! -bordercolor black -border 1 /tmp/IEEE-488/IEEE-488.0$i.png ../docs/cbmbus/ieee-488-$i.png
done

convert -crop 1200x660+0+0\! -bordercolor black -border 1 /tmp/IEEE-488\ Timing/IEEE-488\ Timing.001.png ../docs/cbmbus/ieee-488.png
#convert -crop 420x480+0+0\! -bordercolor black -border 1  IEEE-488\ Layers.001.png  ../docs/cbmbus/ieee-488_layers.png
