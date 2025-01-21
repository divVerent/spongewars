#!/bin/sh

files='
	0.pl
	1.pl
	2.pl
	3.pl
	4.pl
	5.pl
	6.pl
	7.pl
	8.pl
	9.pl
	a.pl
	b.pl
	bounce.raw
	c.pl
	d.pl
	e.pl
	explode.raw
	f.pl
	hit.raw
	intro.raw
	pledit.exe
	readme.txt
	soundset.exe
	soundtst.exe
	sp-edit.gif
	sp-game.gif
	sp-main.gif
	sponge.exe
	sponge.htm
	sponge.ini
	sponge.pcx
	sponges.dat
	throwing.raw
	vga8x8.fnt
'

set -ex

rm -rf dist
mkdir dist
for f in $files; do
	for match in $(ls | grep -i "^$f\$"); do
		cp -v "$match" "dist/$f"
	done
done
