module max7219_display
   #(
     parameter NUM_CASCADES = 1,
     parameter INTENSITY = 7
   )
   (
   input logic        clk, reset_sw,
   input logic [7:0]  frame[4 * NUM_CASCADES],
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
   logic [7:0] data[NUM_CASCADES];
   logic [7:0] sending_data[NUM_CASCADES];

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

   max7219_spi #(.NUM_CASCADES(NUM_CASCADES))
     spi (spi_clk, reset_n, addr, sending_data, dout, cs);

   // state register
   always@(posedge cs) begin
      if(~reset_n)
         state <= 0;
      else
         state <= next_state;
   end // always_ff@ (posedge cs)

   // decode 7 segment pattern
   wire [6:0] decoded[NUM_CASCADES];
   sseg_decoder decoder0(data[0][3:0], decoded[0]);
   if (1 < NUM_CASCADES)
     sseg_decoder decoder1(data[1][3:0], decoded[1]);
   if (2 < NUM_CASCADES)
     sseg_decoder decoder1(data[2][3:0], decoded[2]);
   if (3 < NUM_CASCADES)
     sseg_decoder decoder1(data[3][3:0], decoded[3]);
   always @(posedge spi_clk) begin
      if (`REG_DIGIT(0) <= addr && addr <= `REG_DIGIT(7)) begin
         sending_data[0][0] <= ~decoded[0][6];
         sending_data[0][1] <= ~decoded[0][5];
         sending_data[0][2] <= ~decoded[0][4];
         sending_data[0][3] <= ~decoded[0][3];
         sending_data[0][4] <= ~decoded[0][2];
         sending_data[0][5] <= ~decoded[0][1];
         sending_data[0][6] <= ~decoded[0][0];
         sending_data[0][7] <= 0;
         if (1 < NUM_CASCADES) begin
            sending_data[1][0] <= ~decoded[1][6];
            sending_data[1][1] <= ~decoded[1][5];
            sending_data[1][2] <= ~decoded[1][4];
            sending_data[1][3] <= ~decoded[1][3];
            sending_data[1][4] <= ~decoded[1][2];
            sending_data[1][5] <= ~decoded[1][1];
            sending_data[1][6] <= ~decoded[1][0];
            sending_data[1][7] <= 0;
         end
         if (2 < NUM_CASCADES) begin
            sending_data[2][0] <= ~decoded[2][6];
            sending_data[2][1] <= ~decoded[2][5];
            sending_data[2][2] <= ~decoded[2][4];
            sending_data[2][3] <= ~decoded[2][3];
            sending_data[2][4] <= ~decoded[2][2];
            sending_data[2][5] <= ~decoded[2][1];
            sending_data[2][6] <= ~decoded[2][0];
            sending_data[2][7] <= 0;
         end
         if (3 < NUM_CASCADES) begin
            sending_data[3][0] <= ~decoded[3][6];
            sending_data[3][1] <= ~decoded[3][5];
            sending_data[3][2] <= ~decoded[3][4];
            sending_data[3][3] <= ~decoded[3][3];
            sending_data[3][4] <= ~decoded[3][2];
            sending_data[3][5] <= ~decoded[3][1];
            sending_data[3][6] <= ~decoded[3][0];
            sending_data[3][7] <= 0;
         end
      end else begin
         sending_data[0] <= data[0];
         if (1 < NUM_CASCADES)
           sending_data[1] <= data[1];
         if (2 < NUM_CASCADES)
           sending_data[2] <= data[2];
         if (3 < NUM_CASCADES)
           sending_data[3] <= data[3];
      end
   end

   `define send_command(STATE, ADDR, DATA, NEXT_STATE) \
       STATE : begin \
          addr = ADDR; \
          data[0] = DATA; \
          if (1 < NUM_CASCADES) \
            data[1] = DATA; \
          if (2 < NUM_CASCADES) \
            data[2] = DATA; \
          if (3 < NUM_CASCADES) \
            data[3] = DATA; \
          stop = 0; \
          next_state = NEXT_STATE; \
       end

   `define send_data(STATE, INDEX, DIGIT, NEXT_STATE) \
       STATE : begin \
          addr = `REG_DIGIT(DIGIT); \
          data[0] = frame[INDEX][3:0]; \
          if (1 < NUM_CASCADES) \
            data[1] = frame[4 + INDEX][3:0]; \
          if (2 < NUM_CASCADES) \
            data[2] = frame[8 + INDEX][3:0]; \
          if (3 < NUM_CASCADES) \
            data[3] = frame[12 + INDEX][3:0]; \
          stop = 0; \
          next_state = STATE + 1; \
       end \
       STATE + 1: begin \
          addr = `REG_DIGIT(DIGIT + 1); \
          data[0] = frame[INDEX][7:4]; \
          if (1 < NUM_CASCADES) \
            data[1] = frame[4 + INDEX][7:4]; \
          if (2 < NUM_CASCADES) \
            data[2] = frame[8 + INDEX][7:4]; \
          if (3 < NUM_CASCADES) \
            data[3] = frame[12 + INDEX][7:4]; \
          stop = 0; \
          next_state = NEXT_STATE; \
       end

   // state machine
   always @(posedge spi_clk)
     case (state)
       `send_command(0, `REG_DISPLAY_TEST, 0, 1)
       `send_command(1, `REG_SHUTDOWN, 1, 2)
       `send_command(2, `REG_SCAN_LIMIT, 7, 3)
       `send_command(3, `REG_INTENSITY, INTENSITY, 4)
       `send_command(4, `REG_DECODE_MODE, 'h00, 5)
       `send_data(5, 3, 0, 7)
       `send_data(7, 2, 2, 9)
       `send_data(9, 1, 4, 11)
       `send_data(11, 0, 6, 5)
     endcase // case (state)

endmodule // max7219_frame


module max7219_spi
   #(
     parameter NUM_CASCADES = 1
   )
   (
   input logic  clk, reset_n, [7:0] addr, [7:0] data[NUM_CASCADES],
   output logic dout, cs
   );

   `define CASCADE0 ((0 < NUM_CASCADES) ? (NUM_CASCADES - 1) : 0)
   `define CASCADE1 ((1 < NUM_CASCADES) ? (NUM_CASCADES - 2) : 0)
   `define CASCADE2 ((2 < NUM_CASCADES) ? (NUM_CASCADES - 3) : 0)
   `define CASCADE3 ((3 < NUM_CASCADES) ? (NUM_CASCADES - 4) : 0)

   logic [6:0]  state, next_state;

   // state registor
   always_ff@(negedge clk)
     if (~reset_n)
       state <= 0;
     else
       state <= next_state;

   // state machine
   always @(posedge clk)
     case(state)
        0: begin dout = 0;       cs = 1; next_state = 10; end

        1: begin dout = 0;       cs = 1; next_state =  2; end
        2: begin dout = 0;       cs = 1; next_state =  3; end
        3: begin dout = 0;       cs = 1; next_state =  4; end
        4: begin dout = 0;       cs = 1; next_state =  5; end
        5: begin dout = 0;       cs = 1; next_state =  6; end
        6: begin dout = 0;       cs = 1; next_state =  7; end
        7: begin dout = 0;       cs = 1; next_state =  8; end
        8: begin dout = 0;       cs = 1; next_state =  0; end

       10: begin dout = addr[7]; cs = 0; next_state = 11; end
       11: begin dout = addr[6]; cs = 0; next_state = 12; end
       12: begin dout = addr[5]; cs = 0; next_state = 13; end
       13: begin dout = addr[4]; cs = 0; next_state = 14; end
       14: begin dout = addr[3]; cs = 0; next_state = 15; end
       15: begin dout = addr[2]; cs = 0; next_state = 16; end
       16: begin dout = addr[1]; cs = 0; next_state = 17; end
       17: begin dout = addr[0]; cs = 0; next_state = 18; end
       18: begin dout = data[`CASCADE0][7]; cs = 0; next_state = 19; end
       19: begin dout = data[`CASCADE0][6]; cs = 0; next_state = 20; end
       20: begin dout = data[`CASCADE0][5]; cs = 0; next_state = 21; end
       21: begin dout = data[`CASCADE0][4]; cs = 0; next_state = 22; end
       22: begin dout = data[`CASCADE0][3]; cs = 0; next_state = 23; end
       23: begin dout = data[`CASCADE0][2]; cs = 0; next_state = 24; end
       24: begin dout = data[`CASCADE0][1]; cs = 0; next_state = 25; end
       25: begin dout = data[`CASCADE0][0]; cs = 0; next_state = 30; end

       30: begin dout = addr[7]; cs = 0; next_state = 31; end
       31: begin dout = addr[6]; cs = 0; next_state = 32; end
       32: begin dout = addr[5]; cs = 0; next_state = 33; end
       33: begin dout = addr[4]; cs = 0; next_state = 34; end
       34: begin dout = addr[3]; cs = 0; next_state = 35; end
       35: begin dout = addr[2]; cs = 0; next_state = 36; end
       36: begin dout = addr[1]; cs = 0; next_state = 37; end
       37: begin dout = addr[0]; cs = 0; next_state = 38; end
       38: begin dout = data[`CASCADE1][7]; cs = 0; next_state = 39; end
       39: begin dout = data[`CASCADE1][6]; cs = 0; next_state = 40; end
       40: begin dout = data[`CASCADE1][5]; cs = 0; next_state = 41; end
       41: begin dout = data[`CASCADE1][4]; cs = 0; next_state = 42; end
       42: begin dout = data[`CASCADE1][3]; cs = 0; next_state = 43; end
       43: begin dout = data[`CASCADE1][2]; cs = 0; next_state = 44; end
       44: begin dout = data[`CASCADE1][1]; cs = 0; next_state = 45; end
       45: begin dout = data[`CASCADE1][0]; cs = 0; next_state = 50; end

       50: begin dout = addr[7]; cs = 0; next_state = 51; end
       51: begin dout = addr[6]; cs = 0; next_state = 52; end
       52: begin dout = addr[5]; cs = 0; next_state = 53; end
       53: begin dout = addr[4]; cs = 0; next_state = 54; end
       54: begin dout = addr[3]; cs = 0; next_state = 55; end
       55: begin dout = addr[2]; cs = 0; next_state = 56; end
       56: begin dout = addr[1]; cs = 0; next_state = 57; end
       57: begin dout = addr[0]; cs = 0; next_state = 58; end
       58: begin dout = data[`CASCADE2][7]; cs = 0; next_state = 59; end
       59: begin dout = data[`CASCADE2][6]; cs = 0; next_state = 60; end
       60: begin dout = data[`CASCADE2][5]; cs = 0; next_state = 61; end
       61: begin dout = data[`CASCADE2][4]; cs = 0; next_state = 62; end
       62: begin dout = data[`CASCADE2][3]; cs = 0; next_state = 63; end
       63: begin dout = data[`CASCADE2][2]; cs = 0; next_state = 64; end
       64: begin dout = data[`CASCADE2][1]; cs = 0; next_state = 65; end
       65: begin dout = data[`CASCADE2][0]; cs = 0; next_state = 70; end

       70: begin dout = addr[7]; cs = 0; next_state = 71; end
       71: begin dout = addr[6]; cs = 0; next_state = 72; end
       72: begin dout = addr[5]; cs = 0; next_state = 73; end
       73: begin dout = addr[4]; cs = 0; next_state = 74; end
       74: begin dout = addr[3]; cs = 0; next_state = 75; end
       75: begin dout = addr[2]; cs = 0; next_state = 76; end
       76: begin dout = addr[1]; cs = 0; next_state = 77; end
       77: begin dout = addr[0]; cs = 0; next_state = 78; end
       78: begin dout = data[`CASCADE3][7]; cs = 0; next_state = 79; end
       79: begin dout = data[`CASCADE3][6]; cs = 0; next_state = 80; end
       80: begin dout = data[`CASCADE3][5]; cs = 0; next_state = 81; end
       81: begin dout = data[`CASCADE3][4]; cs = 0; next_state = 82; end
       82: begin dout = data[`CASCADE3][3]; cs = 0; next_state = 83; end
       83: begin dout = data[`CASCADE3][2]; cs = 0; next_state = 84; end
       84: begin dout = data[`CASCADE3][1]; cs = 0; next_state = 85; end
       85: begin dout = data[`CASCADE3][0]; cs = 0; next_state = 1; end

     endcase
endmodule // max7219_spi
