module max7219_display(
   input logic        clk, reset_sw,
   output logic       spi_clk, dout, cs, stop,
   output logic [9:0] debug
   );

`define REG_NOP                 8'h00
`define REG_DIGIT(n)            ((n) + 1)
`define     REG_DIGIT_DP            8'h80
`define REG_DECODE_MODE         8'h09
`define REG_INTENSITY           8'h0a
`define REG_SCAN_LIMIT          8'h0b
`define REG_SHUTDOWN            8'h0c
`define REG_DISPLAY_TEST        8'h0f

   wire [7:0] addr;
   wire [7:0] data;

   // clock divider
   logic [15:0]  count = 0;
   always@(posedge clk) begin
      count <= count[14:0] + 1;
      
      if(count == 50)
        count <= 0;
      if(count <= 25)
        spi_clk <= 1;
      else
        spi_clk <= 0;
   end

   logic [5:0]  state = 0;
   wire [5:0]  next_state;
   logic        prev_cs = 1;
   wire         reset_n;

   assign reset_n = ~reset_sw;
   assign debug[4:0] = state[4:0];
   assign debug[8:5] = next_state[3:0];
   assign debug[9] = ~reset_n;

   max7219_spi spi(spi_clk, reset_n, addr, data, dout, cs);
   max7219_sm sm(spi_clk, state, next_state, addr, data, stop);

   // state register
   always@(posedge cs) begin
      if(~reset_n)
         state <= 0;
      else
         state <= next_state;
   end // always_ff@ (posedge cs)

endmodule // max7219_display

module max7219_sm(
   input logic clk,
   input logic [5:0] state,
   output logic [5:0] next_state,
   output logic [7:0] addr,
   output logic [7:0] data,
   output logic stop
   );

   // state machine
   always @(posedge clk)
     case (state)
       0: begin
          addr = `REG_DISPLAY_TEST;
          data = 0;
          stop = 0;
          next_state = 1;
       end
       1: begin
          addr = `REG_SHUTDOWN;
          data = 1;
          stop = 0;
          next_state = 2;
       end
       2: begin
          addr = `REG_SCAN_LIMIT;
          data = 7;
          stop = 0;
          next_state = 3;
       end
       3: begin
          addr = `REG_INTENSITY;
          data = 'h0f;
          stop = 0;
          next_state = 4;
       end
       4: begin
          addr = `REG_DECODE_MODE;
          data = 'hff;
          stop = 0;
          next_state = 5;
       end
       5: begin
          addr = `REG_DIGIT(0);
          data = 'h00;
          stop = 0;
          next_state = 6;
       end
       6: begin
          addr = `REG_DIGIT(1);
          data = 'h01;
          stop = 0;
          next_state = 7;
       end
       7: begin
          addr = `REG_DIGIT(2);
          data = 'h02;
          stop = 0;
          next_state = 8;
       end
       8: begin
          addr = `REG_DIGIT(3);
          data = 'h03;
          stop = 0;
          next_state = 9;
       end
       9: begin
          addr = `REG_DIGIT(4);
          data = 'h04;
          stop = 0;
          next_state = 10;
       end
       10: begin
          addr = `REG_DIGIT(5);
          data = 'h05;
          stop = 0;
          next_state = 11;
       end
       11: begin
          addr = `REG_DIGIT(6);
          data = 'h06;
          stop = 0;
          next_state = 12;
       end
       12: begin
          addr = `REG_DIGIT(7);
          data = 'h07;
          stop = 0;
          next_state = 13;
       end
       13: begin
          addr = `REG_NOP;
          data = 0;
          stop = 0;
          next_state = 14;
       end
       14: begin
          addr = `REG_NOP;
          data = 0;
          stop = 1;
          next_state = 14;
       end
     endcase // case (state)

endmodule // max7219_frame


module max7219_spi(
   input logic  clk, reset_n, [7:0] addr, [7:0] data,
   output logic dout, cs
   );

   logic [5:0]  state, next_state;

   // state registor
   always_ff@(negedge clk)
     if (~reset_n)
       state <= 0;
     else
       state <= next_state;

   // state machine
   always @(posedge clk)
     case(state)
        0: begin dout = 0;       cs = 1; next_state =  1; end
        1: begin dout = addr[7]; cs = 0; next_state =  2; end
        2: begin dout = addr[6]; cs = 0; next_state =  3; end
        3: begin dout = addr[5]; cs = 0; next_state =  4; end
        4: begin dout = addr[4]; cs = 0; next_state =  5; end
        5: begin dout = addr[3]; cs = 0; next_state =  6; end
        6: begin dout = addr[2]; cs = 0; next_state =  7; end
        7: begin dout = addr[1]; cs = 0; next_state =  8; end
        8: begin dout = addr[0]; cs = 0; next_state =  9; end
        9: begin dout = data[7]; cs = 0; next_state = 10; end
       10: begin dout = data[6]; cs = 0; next_state = 11; end
       11: begin dout = data[5]; cs = 0; next_state = 12; end
       12: begin dout = data[4]; cs = 0; next_state = 13; end
       13: begin dout = data[3]; cs = 0; next_state = 14; end
       14: begin dout = data[2]; cs = 0; next_state = 15; end
       15: begin dout = data[1]; cs = 0; next_state = 16; end
       16: begin dout = data[0]; cs = 0; next_state = 17; end
       17: begin dout = 0;       cs = 1; next_state = 18; end
       18: begin dout = 0;       cs = 1; next_state = 19; end
       19: begin dout = 0;       cs = 1; next_state = 20; end
       20: begin dout = 0;       cs = 1; next_state = 21; end
       21: begin dout = 0;       cs = 1; next_state = 22; end
       22: begin dout = 0;       cs = 1; next_state = 23; end
       23: begin dout = 0;       cs = 1; next_state = 24; end
       24: begin dout = 0;       cs = 1; next_state =  0; end
     endcase
endmodule // max7219_spi
