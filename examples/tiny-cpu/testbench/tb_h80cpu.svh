   reg logic clk, reset;
   reg logic spi_clk, dout, cs, stop;
   reg logic [10:1] pin;
   reg logic uart_txp;

   wire bus_addr_t bus_addr;
   wire ins_t ins;
   wire reg_t regs[reg_numregs];

   h80cpu cpu0(clk, clk, reset, bus_addr, ins, regs, uart_txp);

   task cpu_run_clk(int n);
      integer i;
      for (i = 0; i < n; i++) begin
         #1 clk = ~clk;
      end
   endtask

   task cpu_init();
      integer i;
      
      clk = 0;
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
      for (clk = 0; !regs[reg_stat][reg_stat_halt] && (max_clks < 0 || clk < max_clks); clk++)
        cpu_run_clk(1);
      cpu_run_clk(1);
   endtask

   task cpu_cont(integer max_clks = -1);
      integer clk;
      bus_data_t data;
      mem_read(regs[reg_pc], data);  // read next instruction again before release HALT
      cpu0.set_halt(0);
      for (clk = 0; !regs[reg_stat][reg_stat_halt] && (max_clks < 0 || clk < max_clks); clk++)
        cpu_run_clk(1);
      cpu_run_clk(1);
   endtask

   task mem_write(input bus_addr_t addr, input bus_data_t data);
      reg logic busy;
      cpu0.bus_rw(BUS_MEM, bus_cmd_write_w, addr, data);
      cpu_run_clk(2);
      cpu0.bus_wait(BUS_MEM, busy, data);
      if (busy) begin
         $display("mem_write: busy at %h", bus_addr_t'(addr));
      end
   endtask

   task mem_read(input bus_addr_t addr, output bus_data_t data);
      reg logic busy;
      cpu0.bus_rw(BUS_MEM, bus_cmd_read_w, addr);
      cpu_run_clk(2);
      cpu0.bus_wait(BUS_MEM, busy, data);
      if (busy) begin
         $display("mem_read: busy at %h", bus_addr_t'(addr));
      end
   endtask

   task mem_dump(int addr, int len);
      integer i;
      integer addr_end;

      for (addr_end = addr + len; addr < addr_end; addr += 16) begin
         bus_data_t data[8];
         for (i = 0; i < 8; i++) begin
            mem_read(addr + i * 2, data[i]);
         end
         $display("%h: %h %h %h %h %h %h %h %h", bus_addr_t'(addr),
             data[0], data[1], data[2], data[3],
             data[4], data[5], data[6], data[7]);
      end
   endtask

   task reg_dump(int reg_num, int n = reg_numregs - 1);
      integer i;
      for (i = reg_num; i < reg_num + n; i += 4) begin
         $display("%h: %h %h %h %h", reg_num_t'(i),
            regs[i + 0], regs[i + 1], regs[i + 2], regs[i + 3]);
      end
   endtask
