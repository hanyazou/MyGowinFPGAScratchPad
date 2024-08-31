module top(
   input logic clk, reset_sw,
   output logic spi_clk, dout, cs, stop,
   output logic [10:1] pin
   );

   parameter NUM_CASCADES = 4;

   logic [63:0] counter = 0;
   always @(posedge clk)
     counter <= counter + 1;
   
   wire [7:0] frame[4 * NUM_CASCADES];
   assign frame[0] = 'ha0;  // counter[51:44];
   assign frame[1] = counter[43:36];
   assign frame[2] = counter[35:28];
   assign frame[3] = counter[27:20];
   if (1 < NUM_CASCADES) begin
      assign frame[4] = 'hb1;  // counter[51:44];
      assign frame[5] = counter[43:36];
      assign frame[6] = counter[35:28];
      assign frame[7] = counter[27:20];
   end
   if (2 < NUM_CASCADES) begin
      assign frame[8] = 'hc2;  // counter[51:44];
      assign frame[9] = counter[43:36];
      assign frame[10] = counter[35:28];
      assign frame[11] = counter[27:20];
   end
   if (3 < NUM_CASCADES) begin
      assign frame[12] = 'hd3;  // counter[51:44];
      assign frame[13] = counter[43:36];
      assign frame[14] = counter[35:28];
      assign frame[15] = counter[27:20];
   end
   
   max7219_display #( .NUM_CASCADES(NUM_CASCADES), .INTENSITY(1) )
     disp(clk, reset_sw, frame, spi_clk, dout, cs, stop, pin);

endmodule
