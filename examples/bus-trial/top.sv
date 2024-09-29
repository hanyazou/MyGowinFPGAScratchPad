module top(
   input wire logic sysclk, S1, S2,
   output wire logic spi_clk, dout, cs, stop,
   output wire logic [10:1] pin,
   output reg uart_txp
   );

   parameter SYSCLK_FREQ = 27000000;
   parameter DATA_WIDTH = 8;
   parameter ADDR_WIDTH = 16;

   typedef logic [DATA_WIDTH-1:0] bus_data_t;
   typedef logic [ADDR_WIDTH-1:0] bus_addr_t;

   reg [63:0] counter = 0;
   reg [1:0] pon_reset_count = 1;
   reg pon_reset = 1;

   wire clk, reset_n;
   wire mem0_en_n, mem1_en_n, io0_en_n;
   wire mem0_wait_n, mem1_wait_n, io0_wait_n;
   wire iorq_n, mreq_n;
   wire bus_addr_t addr;
   wire rd_n, wr_n, buswait_n, busrq_n;
   wire bus_data_t data;
   wire buack_n;

   assign clk = counter[20];
   //assign clk = S1;
   assign reset_n = !(S2 || pon_reset);
   assign mem0_en_n = !(addr[ADDR_WIDTH-1] == 0 && ~mreq_n);
   assign mem1_en_n = !(addr[ADDR_WIDTH-1] == 1 && ~mreq_n);
   assign io0_en_n = !(addr[ADDR_WIDTH-1:4] == 0 && ~iorq_n);
   assign buswait_n = (mem0_wait_n && mem1_wait_n && io0_wait_n) ? 1'b1 : 1'b0;

   cpu #( .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH) ) 
      cpu0(clk, reset_n, iorq_n, mreq_n, addr, rd_n, wr_n, data, buswait_n, busrq_n, buack_n);
   memory #(.ID('h0), .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH-1) ) 
   mem0(~clk, reset_n, mem0_en_n, addr[ADDR_WIDTH-2:0], rd_n, wr_n, data, mem0_wait_n, busrq_n, buack_n);
   memory #(.ID('h1), .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH-1) ) 
      mem1(~clk, reset_n, mem1_en_n, addr[ADDR_WIDTH-2:0], rd_n, wr_n, data, mem1_wait_n, busrq_n, buack_n);
   h80cpu_io #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH) )
      io0(~clk, reset_n, io0_en_n, addr, rd_n, wr_n, data, io0_wait_n, sysclk, uart_txp);

   always @(posedge sysclk)
     counter <= counter + 1;

   always @(posedge clk) begin
      if (0 < pon_reset_count) begin
        pon_reset_count <= 2'(pon_reset_count - 1);
      end else begin
        pon_reset <= 0;
      end
   end

   /*
    * debug LED
    */
   parameter NUM_CASCADES = 2;
   wire [7:0] frame[4 * NUM_CASCADES];
   assign frame[0] = addr[7:0];
   assign frame[1] = data[7:0];
   assign frame[2] = { reset_n, mem0_en_n, mem1_en_n, io0_en_n, iorq_n, mreq_n, rd_n, wr_n };
   assign frame[3] = { {4{1'b1}}, mem0_wait_n, mem1_wait_n, io0_wait_n, buswait_n };
   assign frame[4] = { cpu0.clk, 2'b0, cpu0.state };
   assign frame[5] = { cpu0.reset_n, cpu0.busack_n, cpu0.buswait_n, cpu0.iorq_n, cpu0.mreq_n, cpu0.rd_n, cpu0.wr_n  };
   assign frame[6] = { 6'b0, io0.state };
   assign frame[7] = { io0.reset_n, io0.clk, io0.rd_n, io0.wr_n,
                       io0.ce_n, io0.uart_en, io0.uart_busy, io0.buswait_n };

   max7219_display #( .NUM_CASCADES(NUM_CASCADES), .INTENSITY(1) )
     disp(sysclk, S2, frame, spi_clk, dout, cs, stop, pin);

endmodule
