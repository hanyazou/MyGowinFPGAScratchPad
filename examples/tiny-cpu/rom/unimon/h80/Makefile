#
# Makefile
#   Universal Monitor for H80
#

.SUFFIXES: .asm .p .hex .bin .sr

devs := dev/dev_h80.asm

all:	unimon_h80.hex

.p.hex:
	p2hex -F Intel $*.p $*.hex

.p.sr:
	p2hex -F Moto $*.p $*.sr

unimon_h80.p:	unimon_h80.asm config.inc $(devs)
	asl -L $*.asm

config.inc:
	[ -e config.inc ] || ln -s config/config.inc config.inc

clean:
	rm -f *.p *.hex *.sr *.lst
