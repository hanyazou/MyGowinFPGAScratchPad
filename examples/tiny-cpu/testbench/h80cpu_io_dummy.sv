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
   output wire uart_txp
   );
   
   `include "h80bus.svh"

   localparam LINE_DELAY = 200;

   reg [1:0] state;
   reg [BUS_DATA_WIDTH-1:0] data;
   int file_handle = 0;
   int line_delay = 0;

   assign data_ = (!ce_n && cmd[0]) ? data : {BUS_DATA_WIDTH{1'bz}};

   task open_input_file(input string file_name);
      file_handle = $fopen(file_name, "rb");
   endtask

   task close_input_file();
      $fclose(file_handle);
      file_handle = 0;
   endtask

   always @(posedge clk) begin
      if (0 < line_delay) begin
         line_delay <= line_delay - 1;
      end
      if (reset) begin
         state <= 0;
      end else begin
         case (state)
         0: begin
            if (!ce_n) begin
               case (addr)
               'h0000: begin
                  if (cmd == bus_cmd_write_b) begin
                     $write("%c", data_[7:0]);
                     $fflush();

                     // Insert a delay after each output
                     // This prevents the unimon D(ump) command from stopping
                     line_delay = LINE_DELAY;
                  end
                  if (cmd == bus_cmd_read_b) begin
                     byte input_data;
                     if (file_handle == 0) begin
                        data <= 8'h00;
                     end else
                     if ($fread(input_data, file_handle) != 1) begin
                        close_input_file();
                        data <= 8'h00;
                     end else begin
                        data <= input_data;
                        if (input_data == 'h0d || input_data == 'h0a) begin
                           line_delay = LINE_DELAY;
                        end
                     end
                  end
               end
               'h0001: begin
                  if (cmd == bus_cmd_read_b) begin
                     if (file_handle != 0 && line_delay == 0) begin
                        data <= 8'b0000_0001;
                     end else begin
                        data <= 8'b0000_0000;
                     end
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
