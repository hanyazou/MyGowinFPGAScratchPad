module max7219_display(
   input logic        clk, reset_sw,
   input logic [7:0]  frame[4],
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

   logic [7:0] addr;
   logic [7:0] data;
   logic [7:0] sending_data;

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
   logic [5:0]  next_state;
   logic        prev_cs = 1;
   wire         reset_n;

   assign reset_n = ~reset_sw;
   assign debug[4:0] = state[4:0];
   assign debug[8:5] = next_state[3:0];
   assign debug[9] = ~reset_n;

   max7219_spi spi(spi_clk, reset_n, addr, sending_data, dout, cs);

   // state register
   always@(posedge cs) begin
      if(~reset_n)
         state <= 0;
      else
         state <= next_state;
   end // always_ff@ (posedge cs)

   // decode 7 segment pattern
   wire [6:0] decoded;
   sseg_decoder decoder(data[3:0], decoded);
   always @(posedge spi_clk) begin
      if (`REG_DIGIT(0) <= addr && addr <= `REG_DIGIT(7)) begin
        sending_data[0] <= ~decoded[6];
        sending_data[1] <= ~decoded[5];
        sending_data[2] <= ~decoded[4];
        sending_data[3] <= ~decoded[3];
        sending_data[4] <= ~decoded[2];
        sending_data[5] <= ~decoded[1];
        sending_data[6] <= ~decoded[0];
        sending_data[7] <= 0;
      end else begin
        sending_data <= data;
      end
   end

   // state machine
   always @(posedge spi_clk)
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
          data = 'h00;
          stop = 0;
          next_state = 5;
       end
       5: begin
          addr = `REG_DIGIT(0);
          data = frame[3][3:0];
          stop = 0;
          next_state = 6;
       end
       6: begin
          addr = `REG_DIGIT(1);
          data = frame[3][7:4];
          stop = 0;
          next_state = 7;
       end
       7: begin
          addr = `REG_DIGIT(2);
          data = frame[2][3:0];
          stop = 0;
          next_state = 8;
       end
       8: begin
          addr = `REG_DIGIT(3);
          data = frame[2][7:4];
          stop = 0;
          next_state = 9;
       end
       9: begin
          addr = `REG_DIGIT(4);
          data = frame[1][3:0];
          stop = 0;
          next_state = 10;
       end
       10: begin
          addr = `REG_DIGIT(5);
          data = frame[1][7:4];
          stop = 0;
          next_state = 11;
       end
       11: begin
          addr = `REG_DIGIT(6);
          data = frame[0][3:0];
          stop = 0;
          next_state = 12;
       end
       12: begin
          addr = `REG_DIGIT(7);
          data = frame[0][7:4];
          stop = 0;
          next_state = 5;
       end
       13: begin
          addr = `REG_NOP;
          data = 0;
          stop = 1;
          next_state = 13;
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
