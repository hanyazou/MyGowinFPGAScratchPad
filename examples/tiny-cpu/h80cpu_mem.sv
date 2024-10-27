module h80cpu_mem #(
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
   output wire wait_n
   );

   `include "h80bus.svh"

   reg [15:0] mem[1024*16];  // 2 bytes x 16K words (32KB)
   reg [BUS_DATA_WIDTH-1:0] rd_data;
   int state = 0;

   assign wait_n = (!ce_n && state != 0) ? 1'b0 : 1'b1;
   assign data_ = (!ce_n && cmd[0]) ? rd_data : {BUS_DATA_WIDTH{1'bz}};

   // `include "rom/hello.svh"
   // `include "rom/mandelbrot.svh"
   // `include "rom/mandelbrot_asm.svh"
   `include "rom/unimon_h80.svh"

   always @(posedge clk) begin
      if (reset) begin
         state <= 0;
      end else begin
         case (state)
         0: begin
            if (!ce_n) begin
               case (cmd)
               bus_cmd_read: begin
                  rd_data <= { mem[addr[15:1] + 1], mem[addr[15:1] + 0] };
               end
               bus_cmd_write: begin
                  if (16 < BUS_DATA_WIDTH) begin
                     mem[addr[15:1] + 0] <= data_[15:0];
                     mem[addr[15:1] + 1] <= data_[BUS_DATA_WIDTH-1:16];
                  end else begin
                     mem[addr[15:1] + 0] <= data_[BUS_DATA_WIDTH-1:0];
                  end
               end
               bus_cmd_read_w:
                  rd_data <= mem[addr[15:1]];
               bus_cmd_write_w:
                  mem[addr[15:1]] <= data_;
               bus_cmd_read_b:
                 if (addr[0])
                   rd_data <= { 8'h00, mem[addr[15:1]][15:8] };
                 else
                   rd_data <= { 8'h00, mem[addr[15:1]][7:0] };
               bus_cmd_write_b:
                 if (addr[0])
                   mem[addr[15:1]] <= { data_[7:0], mem[addr[15:1]][7:0] };
                 else
                   mem[addr[15:1]] <= { mem[addr[15:1]][15:8], data_[7:0] };
               endcase
               state <= 0;  // there is only one state, no transition
            end
         end
         endcase
      end // else: !if(reset)
   end // always @ (posedge clk)

endmodule
