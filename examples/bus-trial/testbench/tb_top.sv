module main();

   parameter DATA_WIDTH = 8;
   parameter ADDR_WIDTH = 16;

   typedef logic [DATA_WIDTH-1:0] bus_data_t;
   typedef logic [ADDR_WIDTH-1:0] bus_addr_t;

   reg clk, reset_n;
   wire periph0_en_n, periph1_en_n;
   wire iorq_n, mreq_n;
   wire bus_addr_t addr;
   wire rd_n, wr_n, buswait_n, busrq_n;
   wire bus_data_t data;
   wire buack_n;

   assign periph0_en_n = !(addr[ADDR_WIDTH-1] == 0 && ~mreq_n);
   assign periph1_en_n = !(addr[ADDR_WIDTH-1] == 1 && ~mreq_n);

   cpu #( .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH) ) 
       cpu0(clk, reset_n, iorq_n, mreq_n, addr, rd_n, wr_n, data, buswait_n, busrq_n, buack_n);
   peripheral #(.ID('h0), .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH-1) ) 
      periph0(~clk, reset_n, periph0_en_n, addr[ADDR_WIDTH-2:0], rd_n, wr_n, data, buswait_n, busrq_n, buack_n);
   peripheral #(.ID('h1), .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH-1) ) 
      periph1(~clk, reset_n, periph1_en_n, addr[ADDR_WIDTH-2:0], rd_n, wr_n, data, buswait_n, busrq_n, buack_n);

   task cpu_run_clk(int n);
      integer i;
      for (i = 0; i < n; i++) begin
         #1 clk = ~clk;
         #1 clk = ~clk;
      end
   endtask

   initial begin
      /*
      $monitor("reset_n=%h, iorq_n=%h, mreq_n=%h, addr=%h, periph0_en_n=%h, periph1_en_n=%h, rd_n=%h, wr_n=%h, data=%h, buswait_n=%h, busrq_n=%h, buack_n=%h",
         reset_n, iorq_n, mreq_n, addr, periph0_en_n, periph1_en_n, rd_n, wr_n, data,
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
