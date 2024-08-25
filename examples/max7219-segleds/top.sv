module top(
   input logic clk, reset_sw,
   output logic spi_clk, dout, cs, stop,
   output logic [10:1] pin
   );

   logic [63:0] counter = 0;
   always @(posedge clk)
     counter <= counter + 1;
   
   wire [7:0] frame[4];
   assign frame[0] = counter[51:44];
   assign frame[1] = counter[43:36];
   assign frame[2] = counter[35:28];
   assign frame[3] = counter[27:20];
   
   max7219_display disp(clk, reset_sw, frame, spi_clk, dout, cs, stop, pin);

endmodule
