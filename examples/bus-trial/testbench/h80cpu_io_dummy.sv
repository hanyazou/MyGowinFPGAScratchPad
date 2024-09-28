module h80cpu_io   #(
   parameter DATA_WIDTH = 8,
   parameter ADDR_WIDTH = 16
   )
   (
   input wire clk,
   input wire reset_n,
   input wire ce_n,
   input wire [ADDR_WIDTH-1:0] addr,
   input wire rd_n, wr_n,
   inout wire [DATA_WIDTH-1:0] data,
   output buswait_n,
   input wire sysclk,
   output wire uart_txp
   );

   always @(posedge clk) begin
      if (!reset_n) begin

      end else begin
         if ((!ce_n && !wr_n)) begin
            case (addr)
            'h0000: begin
                  $write("%c", data[7:0]);
            end
            endcase
         end
      end
   end // always @ (posedge clk)

endmodule
