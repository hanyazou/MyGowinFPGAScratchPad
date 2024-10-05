module h80cpu_io(
   input wire clk,
   input wire reset,
   input wire ce_n,
   input wire bus_addr_t addr,
   input wire bus_cmd_t cmd,
   inout wire bus_data_t data,
   output wait_n,
   input wire sysclk,
   output wire uart_txp
   );
   
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
