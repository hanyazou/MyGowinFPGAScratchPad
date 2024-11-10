module h80cpu_io  #(
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

   reg prev_clk;
   reg uart_en = 0;
   reg [7:0] uart_tx = 0;
   wire uart_busy;

   assign buswait_n = (!ce_n && state != S_IDLE) ? 1'b0 : 1'b1;

   uart_tx_V2 #( .clk_freq(50000000), .uart_freq(115200))
       tx(sysclk, uart_tx, uart_en, uart_busy, uart_txp);
   
   localparam S_IDLE = 'h0;
   localparam S_WAIT_UART = 'h1;
   reg [1:0] state = S_IDLE;

   always @(posedge sysclk) begin
      prev_clk <= clk;
      if (!reset_n) begin
         state <= 0;
         uart_en <= 0;
      end else begin
         if (~uart_busy) begin
            uart_en <= 0;
         end

         // posedge clk
         if (~prev_clk && clk)  begin
            case (state)
            S_IDLE: begin
               if ((!ce_n && !wr_n)) begin
                  case (addr)
                  'h0000: begin
                     if (!uart_busy) begin
                        uart_tx <= data[7:0];
                        uart_en <= 1;
                     end else begin
                        state <= S_WAIT_UART;
                     end
                  end
                  endcase
               end
            end
            S_WAIT_UART: begin
               if (!uart_en && !uart_busy) begin
                  uart_tx <= data[7:0];
                  uart_en <= 1;
                  state <= S_IDLE;
               end
            end
            endcase // case (state)
         end // if (~prev_clk && clk)
      end // else: !if(!reset_n)
   end // always @ (posedge sysclk)

endmodule
