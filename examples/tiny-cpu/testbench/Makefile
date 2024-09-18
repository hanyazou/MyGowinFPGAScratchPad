
IV_OPTS = -I.. -g2012

HDRS = \
    tb.svh \
    tb_h80cpu.svh

SRCS = \
    ../h80cpu.sv \
    h80cpu_io_dummy.sv \

all: run

run: tb_top
	./tb_top

tb_top: tb_top.sv ${SRCS} ${HDRS} 
	iverilog  -o tb_top ${IV_OPTS} ${SRCS} tb_top.sv

clean::
	rm -rf tp_top
