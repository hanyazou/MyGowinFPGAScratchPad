module peripheral #(
   parameter [3:0] ID = 4'h0,
   parameter DATA_WIDTH = 8,
   parameter ADDR_WIDTH = 16
   )
   (
   input clk, reset_n,
   input ce_n,
   input [ADDR_WIDTH-1:0] addr,
   input rd_n, wr_n,
   inout [DATA_WIDTH-1:0] data,
   output buswait_n, busrq_n,
   input busack_n
   );

   typedef logic [DATA_WIDTH-1:0] bus_data_t;
   typedef logic [ADDR_WIDTH-1:0] bus_addr_t;

   bus_data_t mem[4];
   reg [1:0] state;

   assign buswait_n = (!ce_n && state != 0) ? 1'b0 : 'bz;
   assign data = (!ce_n && !rd_n) ? mem[addr] : 'bz;

   always @(posedge clk) begin
      if (!reset_n) begin
         state <= 0;
         mem[0] <= { ID, 4'h0 };
         mem[1] <= { ID, 4'h1 };
         mem[2] <= { ID, 4'h2 };
         mem[3] <= { ID, 4'h3 };
      end else begin
         case (state)
         0: begin
            if (!ce_n && !wr_n) begin
               state <= 1;
               mem[addr] <= data;
            end
         end
         1: begin
            state <= 2;
         end
         2: begin
            state <= 0;
         end
         endcase // case (state)
      end
   end // always @ (posedge clk)
endmodule

module cpu #(
   parameter DATA_WIDTH = 8,
   parameter ADDR_WIDTH = 16
   )
   (
   input clk, reset_n,
   output iorq_n_, mreq_n_,
   input [ADDR_WIDTH-1:0] addr_,
   input rd_n_, wr_n_,
   inout [DATA_WIDTH-1:0] data_,
   input buswait_n, busrq_n,
   output busack_n_
   );


   typedef logic [DATA_WIDTH-1:0] bus_data_t;
   typedef logic [ADDR_WIDTH-1:0] bus_addr_t;

   reg iorq_n, mreq_n;
   bus_addr_t addr;
   reg rd_n, wr_n;
   bus_data_t data;
   reg busack_n;

   reg [3:0] state;

   wire busmaster;

   /*
   pullup(iorq_n_);
   pullup(mreq_n_);
   pullup(rd_n_);
   pullup(wr_n_);
   pullup(busrq_n_);
    */

   assign busmaster = (reset_n && busack_n);
   assign iorq_n_ = busmaster ? iorq_n : 'bz;
   assign mreq_n_ = busmaster ? mreq_n : 'bz;
   assign addr_  = busmaster ? addr : 'bz;
   assign rd_n_ = busmaster ? rd_n : 'bz;
   assign wr_n_ = busmaster ? wr_n : 'bz;
   assign data_ = (busmaster && !wr_n) ? data : 'bz;
   assign busack_n_ = reset_n ? busack_n : 'bz;
   
   always @(posedge clk) begin
      if (!reset_n) begin
         $display("cpu: in reset...");
         state <= 0;
         data <= 8'hzz;
         addr <= 16'hzz;
         rd_n <= 1'bz;
         wr_n <= 1'bz;
         iorq_n <= 1'bz;
         mreq_n <= 1'bz;
         busack_n <= 1;
      end else begin
         if (!buswait_n)
            $display("cpu: %d wait ...", state);
         else
         case (state)
         0: begin
            $display("cpu: %d read mem 0000 ...", state);
            iorq_n <= 1;
            mreq_n <= 0;
            rd_n <= 0;
            wr_n <= 1;
            addr <= bus_addr_t'(0);
            state <= 1;
         end
         1: begin
            $display("cpu: %d read mem %h %h", state, addr, data_);
            $display("cpu: %d read mem 8000 ...", state);
            iorq_n <= 1;
            mreq_n <= 0;
            rd_n <= 0;
            wr_n <= 1;
            addr <= bus_addr_t'(1 << ADDR_WIDTH-1);
            state <= 2;
         end
         2: begin
            $display("cpu: %d read mem %h %h", state, addr, data_);
            $display("cpu: %d write mem 0001 99", state);
            iorq_n <= 1;
            mreq_n <= 0;
            rd_n <= 1;
            wr_n <= 0;
            addr <= bus_addr_t'(1);
            data <= 8'h99;
            state <= 3;
         end
         3: begin
            $display("cpu: %d read mem 0000 ...", state);
            iorq_n <= 1;
            mreq_n <= 0;
            rd_n <= 0;
            wr_n <= 1;
            addr <= bus_addr_t'(0);
            state <= 4;
         end
         4: begin
            $display("cpu: %d read mem %h %h", state, addr, data_);
            $display("cpu: %d read mem 0001 ...", state);
            iorq_n <= 1;
            mreq_n <= 0;
            rd_n <= 0;
            wr_n <= 1;
            addr <= bus_addr_t'(1);
            state <= 5;
         end
         5: begin
            $display("cpu: %d read mem %h %h", state, addr, data_);
            iorq_n <= 1;
            mreq_n <= 1;
            rd_n <= 1;
            wr_n <= 1;
            state <= 6;
         end
         6: begin
            $display("cpu: %d done", state);
            state <= 7;
         end
         7: begin
         end
         endcase
      end
   end // always @ (posedge clk)
endmodule

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
