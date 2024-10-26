
IV_OPTS = -I../../tiny-cpu -g2012

HDRS = \

SRCS = \
    ../echo.sv \
    h80cpu_io_dummy.sv \

all: run

run: tb_top
	./tb_top

tb_top: tb_top.sv ${SRCS} ${HDRS} 
	iverilog  -o tb_top ${IV_OPTS} ${SRCS} tb_top.sv

clean::
	rm -rf tp_top
