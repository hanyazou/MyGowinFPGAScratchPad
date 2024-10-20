   localparam BUS_ADDR_WIDTH = 16;
   localparam BUS_CMD_WIDTH = 3;
   //localparam BUS_DATA_WIDTH = 16;
   localparam BUS_DATA_WIDTH = 32;

   `include "h80bus.svh"
   `include "h80cpu.svh"

   `define cpu_mem(a, i) do begin mem_write(a, i); \
                            //$display("mem['h%h] = 'h%h;  \/\/ %s", bus_addr_t'(a / 2), \
                            //         bus_data_t'(i), `"i`"); \
                            a += 2; \
                         end while (0)

   reg logic clk, reset;
   reg logic spi_clk, dout, cs, stop;
   reg logic [10:1] pin;
   reg logic uart_txp;

   wire iorq_n, mreq_n;
   wire bus_addr_t bus_addr;
   wire bus_cmd_t bus_cmd;
   wire bus_data_t bus_data;
   wire bus_wait_n;
   wire mem_en_n, io_en_n;
   wire mem_wait_n, io_wait_n;

   assign mem_en_n = mreq_n;
   assign io_en_n = iorq_n;
   assign bus_wait_n = (mem_wait_n && io_wait_n) ? 1'b1 : 1'b0;

   h80cpu #(
      .BUS_ADDR_WIDTH(BUS_ADDR_WIDTH),
      .BUS_CMD_WIDTH(BUS_CMD_WIDTH),
      .BUS_DATA_WIDTH(BUS_DATA_WIDTH))
      cpu0(clk, reset, iorq_n, mreq_n, bus_addr, bus_cmd, bus_data, bus_wait_n);
   h80cpu_mem  #(
      .BUS_ADDR_WIDTH(BUS_ADDR_WIDTH),
      .BUS_CMD_WIDTH(BUS_CMD_WIDTH),
      .BUS_DATA_WIDTH(BUS_DATA_WIDTH))
      mem0(~clk, reset, mem_en_n, bus_addr, bus_cmd, bus_data, mem_wait_n);
   h80cpu_io  #(
      .BUS_ADDR_WIDTH(BUS_ADDR_WIDTH),
      .BUS_CMD_WIDTH(BUS_CMD_WIDTH),
      .BUS_DATA_WIDTH(BUS_DATA_WIDTH))
      io0(~clk, reset, io_en_n, bus_addr, bus_cmd, bus_data, io_wait_n, clk, uart_txp);

   function reg_t regs(reg_num_t n);
      return cpu0.reg_read(n);
   endfunction

   task cpu_run_clk(int n);
      integer i;
      for (i = 0; i < n; i++) begin
         #1 clk = ~clk;
         #1 clk = ~clk;
      end
   endtask

   task cpu_init();
      integer i;
      
      clk = 1;
      reset = 0;
      for (i = 0; i < 10; i++) begin
         cpu0.set_halt(1);
         cpu_run_clk(1);
      end
   endtask

   task cpu_run(integer max_clks = -1);
      integer clk;

      reset = 1;
      cpu_run_clk(5);
      reset = 0;
      for (clk = 0; !(regs(reg_flag) & (1 << reg_flag_halt))  && (max_clks < 0 || clk < max_clks);
           clk++)
        cpu_run_clk(1);
   endtask

   task cpu_cont(integer max_clks = -1);
      integer clk;
      bus_data_t data;
      mem_read(regs(reg_pc), data);  // read next instruction again before release HALT
      cpu0.set_halt(0);
      for (clk = 0; !(regs(reg_flag) & (1 << reg_flag_halt)) && (max_clks < 0 || clk < max_clks);
           clk++)
        cpu_run_clk(1);
   endtask

   task mem_write(input bus_addr_t addr, input bus_data_t data);
      reg logic busy;
      cpu0.bus_rw(BUS_MEM, bus_cmd_write_w, addr, data);
      cpu_run_clk(1);
      cpu0.bus_wait(BUS_MEM, busy, data);
      if (busy) begin
         $display("mem_write: busy at %h", bus_addr_t'(addr));
      end
   endtask

   task mem_read(input bus_addr_t addr, output bus_data_t data);
      reg logic busy;
      cpu0.bus_rw(BUS_MEM, bus_cmd_read_w, addr);
      cpu_run_clk(1);
      cpu0.bus_wait(BUS_MEM, busy, data);
      if (busy) begin
         $display("mem_read: busy at %h", bus_addr_t'(addr));
      end
   endtask

   task mem_fill(int addr, bus_data_t data, int len);
      integer addr_end;

      for (addr_end = addr + len; addr < addr_end; addr++) begin
         mem_write(addr, data);
      end
   endtask

   function bit [7:0] to_c([7:0] v);
      return (8'h20 <= v && v <= 8'h7e) ? v : ".";
   endfunction

   task mem_dump(int addr, int len);
      integer i;
      integer addr_end;

      for (addr_end = addr + len; addr < addr_end; addr += 16) begin
         bus_data_t data[8];
         for (i = 0; i < 8; i++) begin
            mem_read(addr + i * 2, data[i]);
         end
         $display("%h  %h %h %h %h %h %h %h %h  %h %h %h %h %h %h %h %h  |%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c|",
             addr,
             data[0][7:0], data[0][15:8], data[1][7:0], data[1][15:8],
             data[2][7:0], data[2][15:8], data[3][7:0], data[3][15:8],
             data[4][7:0], data[4][15:8], data[5][7:0], data[5][15:8],
             data[6][7:0], data[6][15:8], data[7][7:0], data[7][15:8],
             to_c(data[0][7:0]), to_c(data[0][15:8]), to_c(data[1][7:0]), to_c(data[1][15:8]),
             to_c(data[2][7:0]), to_c(data[2][15:8]), to_c(data[3][7:0]), to_c(data[3][15:8]),
             to_c(data[4][7:0]), to_c(data[4][15:8]), to_c(data[5][7:0]), to_c(data[5][15:8]),
             to_c(data[6][7:0]), to_c(data[6][15:8]), to_c(data[7][7:0]), to_c(data[7][15:8]));
      end
   endtask

   task mem_dump_sv(int addr, int len);
      integer i;
      integer addr_end;
      bus_data_t data;

      addr = addr / 2;
      len = len / 2;
      for (addr_end = addr + len; addr < addr_end; addr += 1) begin
         mem_read(addr * 2, data);
         $display("      mem['h%h] = 'h%h;", addr[15:0], data[15:0]);
      end
   endtask

   task reg_dump(int reg_num, int n = CPU_NUMREGS - 1);
      integer i;
      for (i = reg_num; i < reg_num + n; i += 4) begin
         $display("%h: %h %h %h %h", reg_num_t'(i),
            regs(i + 0), regs(i + 1), regs(i + 2), regs(i + 3));
      end
   endtask
