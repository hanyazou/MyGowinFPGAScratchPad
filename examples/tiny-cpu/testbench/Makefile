
IV_OPTS = -I.. -g2012

HDRS = \
    tb.svh \
    tb_h80cpu.svh \
    ../h80cpu_instmacros.svh \
    ../rom/hello.svh \
    ../rom/mandelbrot.svh \
    ../rom/mandelbrot_asm.svh \

SRCS = \
    ../h80cpu.sv \
    ../h80cpu_mem.sv \
    h80cpu_io_dummy.sv \

all: run

run: tb_top
	./tb_top

tb_top: tb_top.sv ${SRCS} ${HDRS} 
	iverilog  -o tb_top ${IV_OPTS} ${SRCS} tb_top.sv

../rom/mandelbrot_asm.svh: mandelbrot.bin
	echo '   `include "h80cpu.svh"' > $@
	echo '   `include "h80cpu_instmacros.svh"' >> $@
	echo '   initial begin' >> $@
	hexdump $< \
    | awk '{ printf("%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n",$$2,$$3,$$4,$$5,$$6,$$7,$$8,$$9) }' \
    | awk '{ \
             if ($$1 == "") \
               next; \
             printf("      mem[16'"'"'h%04x]=16'"'"'h%s;\n", addr / 2, $$1); \
             addr += 2; }' \
          >> $@
	echo end >> $@

mandelbrot.bin: ../rom/mandelbrot.asm
	asl $< -o mandelbrot.p
	p2bin mandelbrot.p $@
	rm mandelbrot.p

clean::
	rm -rf tp_top mandelbrot.p mandelbrot.bin
