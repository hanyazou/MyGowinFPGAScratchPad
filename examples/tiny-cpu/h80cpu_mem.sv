module h80cpu_mem #(
   parameter BUS_ADDR_WIDTH = 16,
   parameter BUS_CMD_WIDTH = 3,
   parameter BUS_DATA_WIDTH = 16,
   parameter MEM_SIZE = 1024*64
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

   `include "sim_utils.svh"
   `include "h80bus.svh"

   reg [15:0] mem0[MEM_SIZE/4];
   reg [15:0] mem1[MEM_SIZE/4];
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
            if (!ce_n && addr < MEM_SIZE) begin
               case (cmd)
               bus_cmd_read: begin
                  if (addr[1:0] != 2'b00) begin
                     `SIM_DISPLAY(("### Address error: read long %h", addr));
                  end
                  rd_data <= { mem1[addr[15:2]], mem0[addr[15:2]] };
               end
               bus_cmd_write: begin
                  if (addr[1:0] != 2'b00) begin
                     `SIM_DISPLAY(("### Address error: write long %h", addr));
                  end
                  mem0[addr[15:2]] <= data_[15:0];
                  mem1[addr[15:2]] <= data_[31:16];
               end
               bus_cmd_read_w: begin
                  if (addr[0]) begin
                     `SIM_DISPLAY(("### Address error: read half %h", addr));
                  end
                  if (addr[1]) begin
                     rd_data <= { 16'h00, mem1[addr[15:2]] };
                  end else begin
                     rd_data <= { 16'h00, mem0[addr[15:2]] };
                  end
               end
               bus_cmd_write_w: begin
                  if (addr[0]) begin
                     `SIM_DISPLAY(("### Address error: write half %h", addr));
                  end
                  if (addr[1]) begin
                     mem1[addr[15:2]] <= data_[15:0];
                  end else begin
                     mem0[addr[15:2]] <= data_[15:0];
                  end
               end
               bus_cmd_read_b: begin
                  case (addr[1:0])
                  2'b00: rd_data <= { 24'h00, mem0[addr[15:2]][7:0] };
                  2'b01: rd_data <= { 24'h00, mem0[addr[15:2]][15:8] };
                  2'b10: rd_data <= { 24'h00, mem1[addr[15:2]][7:0] };
                  2'b11: rd_data <= { 24'h00, mem1[addr[15:2]][15:8] };
                  endcase
               end
               bus_cmd_write_b: begin
                  case (addr[1:0])
                  2'b00: mem0[addr[15:2]] <= { mem0[addr[15:2]][15:8], data_[7:0] };
                  2'b01: mem0[addr[15:2]] <= { data_[7:0], mem0[addr[15:2]][7:0] };
                  2'b10: mem1[addr[15:2]] <= { mem1[addr[15:2]][15:8], data_[7:0] };
                  2'b11: mem1[addr[15:2]] <= { data_[7:0], mem1[addr[15:2]][7:0] };
                  endcase
               end
               endcase // case (cmd)
               state <= 0;  // there is only one state, no transition
            end
         end
         endcase
      end // else: !if(reset)
   end // always @ (posedge clk)

endmodule
