module top(
   input wire logic sysclk, S1, S2,
   output wire logic spi_clk, dout, cs, stop,
   output wire logic [10:1] pin,
   output reg uart_txp
   );

   localparam BUS_ADDR_WIDTH = 16;
   localparam BUS_CMD_WIDTH = 3;
   localparam BUS_DATA_WIDTH = 16;

   `include "h80bus.svh"
   `include "h80cpu.svh"

   parameter SYSCLK_FREQ = 27000000;

   /*
    * clock
    */
   logic [63:0] counter = 0;
   always @(posedge sysclk)
     counter <= counter + 1;
   wire clk;
   reg clk_autorun = 1;
   enum { CLK_S_WAIT_MAKE, CLK_S_WAIT_BREAK } clk_state = CLK_S_WAIT_MAKE;
   localparam CLK_LONGPRESS = SYSCLK_FREQ/65536*2;  // 2 sec
   localparam CLK_DEBOUNCE = SYSCLK_FREQ/65536/10;  // 0.1 sec
   reg [15:0] clk_debounce = CLK_DEBOUNCE;  // This immediately disables autorun if S1 is true
                                            // at power on.
   always @(posedge counter[16]) begin
      case (clk_state)
      CLK_S_WAIT_MAKE: begin
         if (S1) begin
            if (clk_debounce == 0) begin
               clk_autorun <= ~clk_autorun;
               clk_debounce <= CLK_DEBOUNCE;
               clk_state <= CLK_S_WAIT_BREAK;
            end else begin
               clk_debounce <= clk_debounce - 1'b1;
            end
         end else begin
            clk_debounce <= CLK_LONGPRESS;
         end
      end
      CLK_S_WAIT_BREAK: begin
         if (~S1) begin
            if (clk_debounce == 0) begin
               clk_debounce <= CLK_LONGPRESS;
               clk_state <= CLK_S_WAIT_MAKE;
            end else begin
               clk_debounce <= clk_debounce - 1'b1;
            end
         end else begin
            clk_debounce <= CLK_DEBOUNCE;
         end
      end
      endcase // case (clk_state)
   end
   //assign clk = clk_autorun ? counter[21] : S1;
   assign clk = clk_autorun ? counter[1] : S1;

   /*
    * reset
    */
   wire reset;
   assign reset = S2;

   /*
    * bus
    */
   wire iorq_n, mreq_n;
   wire bus_addr_t bus_addr;
   wire bus_cmd_t bus_cmd;
   wire bus_data_t bus_data;
   wire bus_wait_n;

   wire mem_en_n, io_en_n;
   wire mem_wait_n, io_wait_n;

   assign mem_en_n = mreq_n;
   assign io_en_n = iorq_n;
   assign bus_wait_n = (mem_wait_n && io_wait_n) ? 1'b1 : 1'b0;

   /*
    * debug LED
    */
   parameter NUM_CASCADES = 2;
   wire reg_t regs[CPU_NUMREGS];
   wire [7:0] frame[4 * NUM_CASCADES];
   assign frame[0] = bus_addr[15:8];
   assign frame[1] = bus_addr[7:0];
   assign frame[2] = bus_data[15:8];
   assign frame[3] = bus_data[7:0];
   assign frame[4] = regs[0][15:8];
   assign frame[5] = regs[0][7:0];
   assign frame[6] = { clk, clk_autorun, {6{1'b0}} };
   assign frame[7] = regs[reg_flag][7:0];

   h80cpu  #(
      .BUS_ADDR_WIDTH(BUS_ADDR_WIDTH),
      .BUS_CMD_WIDTH(BUS_CMD_WIDTH),
      .BUS_DATA_WIDTH(BUS_DATA_WIDTH))
      cpu0(clk, reset, iorq_n, mreq_n, bus_addr, bus_cmd, bus_data, bus_wait_n);
   h80cpu_mem  #(
      .BUS_ADDR_WIDTH(BUS_ADDR_WIDTH),
      .BUS_CMD_WIDTH(BUS_CMD_WIDTH),
      .BUS_DATA_WIDTH(BUS_DATA_WIDTH))
      mem0(~clk, reset, mem_en_n, bus_addr, bus_cmd, bus_data, mem_wait_n);
   h80cpu_io  #(
      .BUS_ADDR_WIDTH(BUS_ADDR_WIDTH),
      .BUS_CMD_WIDTH(BUS_CMD_WIDTH),
      .BUS_DATA_WIDTH(BUS_DATA_WIDTH))
      io0(~clk, reset, io_en_n, bus_addr, bus_cmd, bus_data, io_wait_n, sysclk, uart_txp);

   max7219_display #( .NUM_CASCADES(NUM_CASCADES), .INTENSITY(1) )
     disp(sysclk, S2, frame, spi_clk, dout, cs, stop, pin);

endmodule
