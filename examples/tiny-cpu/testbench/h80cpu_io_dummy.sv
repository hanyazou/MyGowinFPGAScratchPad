module h80cpu_io(
   input wire clk,
   input wire reset,
   input wire bus_addr_t addr,
   input wire bus_cmd_t cmd,
   input wire run,
   input wire bus_data_t wr_data,
   output bus_data_t rd_data,
   output logic done,
   input wire sysclk,
   output wire uart_txp
   );

   reg prev_clk;
   
   initial begin
      done <= 0;
   end

   always @(posedge sysclk or negedge sysclk) begin
      rd_data <= 0;
      prev_clk <= clk;
      if (reset) begin
         done <= 0;
      end else begin
      // posedge clk
      if (~prev_clk && clk)  begin
         if (run != done) begin
            case (addr)
            'h0000: begin
               if (cmd == bus_cmd_write_b) begin
                  $write("%c", wr_data[7:0]);
               end
            end
            endcase
            done <= ~done;
         end
      end
      end // else: !if(reset)

   end // always @ (posedge sysclk)

endmodule
