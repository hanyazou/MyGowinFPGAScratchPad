/*
 * Count up on 7 segment LEDs PMOD
 */

module top(
   input logic        Clock,
   input logic        SW1,
   input logic        SW2,
   output logic [7:0] LED
   );

   reg [9:0]          sel_counter = 10'b0;
   reg [31:0]         counter = 32'b0;
   logic [6:0]        segdecoded;
   logic [6:0]        segdecoded_high;
   logic [6:0]        segdecoded_low;
   logic              sel;
   
   sseg_decoder U1 (counter[30:27], segdecoded_high);
   sseg_decoder U2 (counter[26:23], segdecoded_low);

   always @(posedge Clock) begin
      if ( SW1 ) begin
         counter  <= 32'b0;  // clear
      end
      else
      if ( SW2 ) begin
         counter  <= counter - 1'b1;  // count down
      end
      else begin
         counter  <= counter + 1'b1;  // count up
      end

      sel_counter <= sel_counter + 1;
      sel = sel_counter[9];

      if ( sel == 0 ) begin
         segdecoded <= segdecoded_high;
      end
      else begin
         segdecoded <= segdecoded_low;
      end
   end

   assign LED[0] = segdecoded[5];  // F
   assign LED[1] = segdecoded[4];  // E
   assign LED[2] = segdecoded[1];  // B
   assign LED[3] = segdecoded[2];  // C
   assign LED[4] = segdecoded[6];  // G
   assign LED[5] = segdecoded[3];  // D
   assign LED[6] = segdecoded[0];  // A
   assign LED[7] = sel;  // SEL

endmodule  // top

module sseg_decoder(
   input logic [3:0]  num,
   output logic [6:0] y
   );

   /*
    *           A
    *         -----
    *      F/  G  /B
    *       -----
    *    E/     /C
    *     -----
    *       D
    */

   always_comb begin
      case (num)     // GFE DCBA
        4'b0000  : y = 7'b100_0000;  // 0
        4'b0001  : y = 7'b111_1001;  // 1
        4'b0010  : y = 7'b010_0100;  // 2
        4'b0011  : y = 7'b011_0000;  // 3
        4'b0100  : y = 7'b001_1001;  // 4
        4'b0101  : y = 7'b001_0010;  // 5
        4'b0110  : y = 7'b000_0010;  // 6
        4'b0111  : y = 7'b101_1000;  // 7
        4'b1000  : y = 7'b000_0000;  // 8
        4'b1001  : y = 7'b001_0000;  // 9
        4'b1010  : y = 7'b000_1000;  // A
        4'b1011  : y = 7'b000_0011;  // b
        4'b1100  : y = 7'b100_0110;  // C
        4'b1101  : y = 7'b010_0001;  // d
        4'b1110  : y = 7'b000_0110;  // E
        4'b1111  : y = 7'b000_1110;  // F
      endcase
   end

endmodule  // sseg_decoder
