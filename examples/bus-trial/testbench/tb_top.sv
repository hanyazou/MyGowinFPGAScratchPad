module main();

   parameter DATA_WIDTH = 8;
   parameter ADDR_WIDTH = 16;

   typedef logic [DATA_WIDTH-1:0] bus_data_t;
   typedef logic [ADDR_WIDTH-1:0] bus_addr_t;

   reg clk, reset_n;
   wire mem0_en_n, mem1_en_n, io0_en_n;
   wire iorq_n, mreq_n;
   wire bus_addr_t addr;
   wire rd_n, wr_n, buswait_n, busrq_n;
   wire bus_data_t data;
   wire buack_n;

   assign mem0_en_n = !(addr[ADDR_WIDTH-1] == 0 && ~mreq_n);
   assign mem1_en_n = !(addr[ADDR_WIDTH-1] == 1 && ~mreq_n);
   assign io0_en_n = !(addr[ADDR_WIDTH-1:4] == 0 && ~iorq_n);

   cpu #( .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH) ) 
       cpu0(clk, reset_n, iorq_n, mreq_n, addr, rd_n, wr_n, data, buswait_n, busrq_n, buack_n);
   memory #(.ID('h0), .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH-1) ) 
      mem0(~clk, reset_n, mem0_en_n, addr[ADDR_WIDTH-2:0], rd_n, wr_n, data, buswait_n, busrq_n, buack_n);
   memory #(.ID('h1), .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH-1) ) 
      mem1(~clk, reset_n, mem1_en_n, addr[ADDR_WIDTH-2:0], rd_n, wr_n, data, buswait_n, busrq_n, buack_n);
   h80cpu_io #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH) ) 
      io01(~clk, reset_n, io0_en_n, addr, rd_n, wr_n, data, buswait_n, busrq_n, buack_n);

   task cpu_run_clk(int n);
      integer i;
      for (i = 0; i < n; i++) begin
         #1 clk = ~clk;
         #1 clk = ~clk;
      end
   endtask

   initial begin
      /*
      $monitor("reset_n=%h, iorq_n=%h, mreq_n=%h, addr=%h, mem0_en_n=%h, mem1_en_n=%h, rd_n=%h, wr_n=%h, data=%h, buswait_n=%h, busrq_n=%h, buack_n=%h",
         reset_n, iorq_n, mreq_n, addr, mem0_en_n, mem1_en_n, rd_n, wr_n, data,
         buswait_n, busrq_n, buack_n);
       */
      $dumpfile("tb_top.vcd");
      $dumpvars(0, cpu0);
      $display("bus trial");
      reset_n = 0;
      clk = 0;
      cpu_run_clk(1);
      reset_n = 1;
      cpu_run_clk(100);
      $finish;
   end

endmodule
