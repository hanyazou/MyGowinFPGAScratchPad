module main();

   localparam BUS_ADDR_WIDTH = 16;
   localparam BUS_CMD_WIDTH = 3;
   //localparam BUS_DATA_WIDTH = 16;
   localparam BUS_DATA_WIDTH = 32;

   `include "h80bus.svh"
   `include "h80cpu.svh"

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

   echo #(
      .BUS_ADDR_WIDTH(BUS_ADDR_WIDTH),
      .BUS_CMD_WIDTH(BUS_CMD_WIDTH),
      .BUS_DATA_WIDTH(BUS_DATA_WIDTH))
      cpu0(clk, reset, iorq_n, mreq_n, bus_addr, bus_cmd, bus_data, bus_wait_n);
   h80cpu_io  #(
      .BUS_ADDR_WIDTH(BUS_ADDR_WIDTH),
      .BUS_CMD_WIDTH(BUS_CMD_WIDTH),
      .BUS_DATA_WIDTH(BUS_DATA_WIDTH))
      io0(~clk, reset, io_en_n, bus_addr, bus_cmd, bus_data, io_wait_n, clk, uart_txp);

   task cpu_run_clk(int n);
      integer i;
      for (i = 0; i < n; i++) begin
         #1 clk = ~clk;
         #1 clk = ~clk;
      end
   endtask

   task cpu_run(integer max_clks = -1);
      integer clk;

      reset = 1;
      cpu_run_clk(5);
      reset = 0;
      for (clk = 0; max_clks < 0 || clk < max_clks; clk++)
        cpu_run_clk(1);
   endtask

   initial begin
      clk = 0;
      cpu_run(100);
      $display("");
   end

endmodule
