module h80cpu_io(
   input wire clk,
   input wire reset,
   input wire bus_addr_t addr,
   input wire bus_cmd_t cmd,
   input wire run,
   input wire bus_data_t wr_data,
   ref bus_data_t rd_data,
   output logic done,
   input wire sysclk,
   output wire uart_txp
   );

   reg prev_clk;
   reg uart_en = 0;
   reg [7:0] uart_tx = 0;
   wire uart_busy;
   uart_tx_V2 #( .clk_freq(50000000), .uart_freq(115200))
       tx(sysclk, uart_tx, uart_en, uart_busy, uart_txp);
   
   localparam S_IDLE = 'h0;
   localparam S_WAIT_UART = 'h1;
   reg [1:0] state = S_IDLE;

   initial begin
      done <= 0;
   end

   always @(posedge sysclk) begin
      prev_clk <= clk;
      if (reset) begin
         state <= 0;
         done <= 0;
         uart_en <= 0;
      end else begin
         if (~uart_busy) begin
            uart_en <= 0;
         end

         // posedge clk
         if (~prev_clk && clk)  begin
            case (state)
            S_IDLE: begin
               if (run != done) begin
                  case (addr)
                  'h0000: begin
                     if (cmd == bus_cmd_write_b) begin
                        if (!uart_busy) begin
                           uart_tx <= wr_data[7:0];
                              uart_en <= 1;
                           done <= ~done;
                        end else begin
                          state <= S_WAIT_UART;
                        end
                     end
                  end
                  endcase
               end
            end
            S_WAIT_UART: begin
               if (!uart_en && !uart_busy) begin
                  uart_tx <= wr_data[7:0];
                  uart_en <= 1;
                  done <= ~done;
                  state <= S_IDLE;
               end
            end
            endcase
         end
      end // else: !if(reset)
   end // always @ (posedge sysclk)

endmodule
