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
   inout wire [BUS_DATA_WIDTH-1:0] data_,
   output wire wait_n,
   input wire sysclk,
   input wire uart_rxp,
   output wire uart_txp
   );

   `include "../tiny-cpu/h80bus.svh"

   reg prev_clk;
   reg uart_en = 0;
   reg [7:0] uart_tx = 0;
   reg [BUS_DATA_WIDTH-1:0] data;
   wire uart_busy;
   wire [7:0] uart_rx_data;
   wire uart_rx_break;
   wire uart_rx_valid;
   reg [7:0] uart_rx_data_buf;
   reg [7:0] uart_rx_data_buf_count;

   assign wait_n = (!ce_n && state != S_IDLE) ? 1'b0 : 1'b1;
   assign data_ = (!ce_n && cmd[0]) ? data : {BUS_DATA_WIDTH{1'bz}};

   uart_tx #( .CLK_HZ(50000000), .BIT_RATE(115200), .PAYLOAD_BITS(8))
      tx(
         .clk (sysclk),
         .resetn (~reset),
         .uart_txd(uart_txp),
         .uart_tx_busy( uart_busy),
         .uart_tx_en(uart_en),
         .uart_tx_data(uart_tx));
   uart_rx #( .CLK_HZ(50000000), .BIT_RATE(115200), .PAYLOAD_BITS(8))
      rx(
         .clk (sysclk),
         .resetn (~reset),
         .uart_rxd(uart_rxp),
         .uart_rx_en(1'b1),
         .uart_rx_break(uart_rx_break),
         .uart_rx_valid(uart_rx_valid),
         .uart_rx_data(uart_rx_data));
   
   localparam S_IDLE = 'h0;
   localparam S_WAIT_UART = 'h1;
   reg [1:0] state = S_IDLE;

   always @(posedge sysclk) begin
      prev_clk <= clk;
      if (reset) begin
         state <= 0;
         uart_en <= 0;
         uart_rx_data_buf_count <= 0;
      end else begin
         if (~uart_busy) begin
            uart_en <= 0;
         end
         if (uart_rx_valid) begin
            uart_rx_data_buf <= uart_rx_data;
            uart_rx_data_buf_count <= 1;
         end

         // posedge clk
         if (~prev_clk && clk)  begin
            case (state)
            S_IDLE: begin
               if (!ce_n) begin
                  case (addr)
                  'h0000: begin
                     if (cmd == bus_cmd_write_b) begin
                        if (!uart_busy) begin
                           uart_tx <= data[7:0];
                           uart_en <= 1;
                        end else begin
                           state <= S_WAIT_UART;
                        end
                     end else
                     if (cmd == bus_cmd_read_b) begin
                        if (uart_rx_data_buf_count) begin
                           data <= uart_rx_data_buf;
                           uart_rx_data_buf_count <= 0;
                        end else begin
                           data <= 0;
                        end
                     end
                  end
                  'h0001: begin
                     if (cmd == bus_cmd_read_b) begin
                        if (uart_rx_data_buf_count != 0) begin
                           data <= 8'b0000_0001;
                        end else begin
                           data <= 8'b0000_0000;
                        end
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
            endcase
         end
      end // else: !if(reset)
   end // always @ (posedge sysclk)

endmodule
