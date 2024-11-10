`default_nettype none

module echo #(
   parameter BUS_ADDR_WIDTH = 16,
   parameter BUS_CMD_WIDTH = 3,
   parameter BUS_DATA_WIDTH = 16
   )
   (
   input wire  clk, reset,
   output wire iorq_n_, mreq_n_,
   output wire [BUS_ADDR_WIDTH-1:0] bus_addr_,
   output wire [BUS_CMD_WIDTH-1:0] bus_cmd_,
   inout wire  [BUS_DATA_WIDTH-1:0] bus_data_,
   input wire  bus_wait_n
   );

   `include "../tiny-cpu/h80bus.svh"
   `include "../tiny-cpu/h80cpu.svh"

   bus_num_t bus_num = BUS_IO;
   bus_addr_t bus_addr = 'h0000;
   bus_cmd_t bus_cmd;
   bus_data_t bus_wr_data = 0;
   enum { S_TEST, S_READ, S_WRITE } state = S_TEST;

   assign iorq_n_ = !(bus_num == BUS_IO && bus_cmd != bus_cmd_none);
   assign mreq_n_ = !(bus_num == BUS_MEM && bus_cmd != bus_cmd_none);
   assign bus_addr_ = bus_addr;
   assign bus_cmd_ = bus_cmd;
   assign bus_data_ = !bus_cmd[0] ? bus_wr_data : {BUS_DATA_WIDTH{1'bz}};

   always @(posedge clk) begin
      if (reset) begin
         bus_num = BUS_IO;
         bus_cmd <= bus_cmd_none;
         state = S_TEST;
      end else
      if (!bus_wait_n) begin
         // wait for I/O access completion
      end else
      case (state)
      S_TEST: begin
         bus_cmd <= bus_cmd_read_b;
         bus_addr <= 'h0001;
         state <= S_READ;
      end
      S_READ: begin
         if (bus_data_ != 0) begin
            bus_cmd <= bus_cmd_read_b;
            bus_addr <= 'h0000;
            state <= S_WRITE;
         end else begin
            bus_cmd <= bus_cmd_none;
            state <= S_TEST;
         end
      end
      S_WRITE: begin
         if ("A" <= bus_data_ && bus_data_ <= "Z") begin
            bus_wr_data <= bus_data_ - "A" + "a";
         end else
         if ("a" <= bus_data_ && bus_data_ <= "z") begin
            bus_wr_data <= bus_data_ - "a" + "A";
         end else begin
            bus_wr_data <= bus_data_;
         end
         bus_cmd <= bus_cmd_write_b;
         bus_addr <= 'h0000;
         state <= S_TEST;
      end
      endcase // case (state)
   end // always @ (posedge clk)

endmodule
