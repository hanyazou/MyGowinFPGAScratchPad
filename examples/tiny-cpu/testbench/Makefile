
IV_OPTS = -I.. -g2012

HDRS = \
    tb.svh \
    tb_h80cpu.svh \
    ../h80cpu_instmacros.svh \
    ../rom/hello.svh \
    ../rom/mandelbrot.svh \
    ../rom/mandelbrot_asm.svh \
    ../rom/unimon_h80.svh \

SRCS = \
    ../h80cpu.sv \
    ../h80cpu_mem.sv \
    h80cpu_io_dummy.sv \

.SUFFIXES: .asm .bin .svh

all: run

run: tb_top
	./tb_top

tb_top: tb_top.sv ${SRCS} ${HDRS} 
	iverilog  -o tb_top ${IV_OPTS} ${SRCS} tb_top.sv

asm_to_bin = \
	asl $< -o $*.p -L -olist $*.lst && \
	p2bin $*.p $@ && \
	rm $*.p

bin_to_svh = \
	echo '   `include "h80cpu.svh"' > $@ && \
	echo '   `include "h80cpu_instmacros.svh"' >> $@ && \
	echo '   initial begin' >> $@ && \
	hexdump -v $< \
    | awk '{ printf("%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n",$$2,$$3,$$4,$$5,$$6,$$7,$$8,$$9) }' \
    | awk '{ \
             if ($$1 == "") \
               next; \
             printf("      mem[16'"'"'h%04x]=16'"'"'h%s;\n", addr / 2, $$1); \
             addr += 2; }' \
          >> $@ && \
	echo end >> $@

../rom/mandelbrot_asm.svh: mandelbrot.bin
	$(bin_to_svh)
mandelbrot.bin: ../rom/mandelbrot.asm
	$(asm_to_bin)
../rom/unimon_h80.svh: unimon_h80.bin
	$(bin_to_svh)
unimon_h80.bin: ../rom/unimon/h80/unimon_h80.asm ../rom/unimon/h80/config.inc
	$(asm_to_bin)

clean::
	rm -rf tp_top mandelbrot.bin unimon_h80.bin
