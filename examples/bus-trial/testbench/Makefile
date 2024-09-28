
IV_OPTS = -I.. -g2012

HDRS =

SRCS = \
    ../cpu.sv \
    ../peripheral.sv \

all: run

run: tb_top
	rm -f tb_top.vcd
	./tb_top

tb_top: tb_top.sv ${SRCS} ${HDRS} 
	iverilog  -o tb_top ${IV_OPTS} ${SRCS} tb_top.sv

clean::
	rm -rf tb_top tb_top.vcd
