module cpu #(
   parameter DATA_WIDTH = 8,
   parameter ADDR_WIDTH = 16
   )
   (
   input clk, reset_n,
   output iorq_n_, mreq_n_,
   output [ADDR_WIDTH-1:0] addr_,
   output rd_n_, wr_n_,
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
            iorq_n <= 0;
            mreq_n <= 1;
            rd_n <= 1;
            wr_n <= 0;
            addr <= bus_addr_t'(0);
            data <= "H";
            state <= 6;
         end
         6: begin
            data <= "e";
            state <= 7;
         end
         7: begin
            data <= "l";
            state <= 8;
         end
         8: begin
            data <= "l";
            state <= 9;
         end
         9: begin
            data <= "o";
            state <= 10;
         end
         10: begin
            data <= 8'h0d;
            state <= 11;
         end
         11: begin
            data <= 8'h0a;
            state <= 12;
         end
         12: begin
            iorq_n <= 1;
            mreq_n <= 1;
            rd_n <= 1;
            wr_n <= 1;
            state <= 13;
         end
         13: begin
            $display("cpu: %d done", state);
            state <= 14;
         end
         14: begin
         end
         endcase
      end
   end // always @ (posedge clk)
endmodule
