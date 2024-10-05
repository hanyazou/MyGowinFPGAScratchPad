module h80cpu_io #(
   parameter BUS_ADDR_WIDTH = 16,
   parameter BUS_CMD_WIDTH = 3,
   parameter BUS_DATA_WIDTH = 16
   )
   (
   input wire clk,
   input wire reset,
   input wire ce_n,
   input wire [BUS_ADDR_WIDTH-1:0] addr,
   input wire [BUS_CMD_WIDTH-1:0] cmd,
   inout wire [BUS_DATA_WIDTH-1:0] data,
   output wire wait_n,
   input wire sysclk,
   output wire uart_txp
   );
   
   `include "h80bus.svh"

   reg [1:0] state;

   always @(posedge clk) begin
      if (reset) begin
         state <= 0;
      end else begin
         case (state)
         0: begin
            if (!ce_n) begin
               case (addr)
               'h0000: begin
                  if (cmd == bus_cmd_write_b) begin
                     $write("%c", data[7:0]);
                  end
               end
               endcase
            end
         end
         1: begin
            state <= 2;
         end
         2: begin
            state <= 0;
         end
         endcase // case (state)
      end // else: !if(reset)
   end // always @ (posedge clk)

endmodule
