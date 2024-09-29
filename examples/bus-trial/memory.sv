module memory #(
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

   assign buswait_n = (!ce_n && state != 0) ? 1'b0 : 1'b1;
   assign data = (!ce_n && !rd_n) ? mem[addr] : {DATA_WIDTH{1'bz}};

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
