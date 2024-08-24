module top(
   input logic clk, reset,
   output logic spi_clk, dout, cs, stop,
   output logic [10:1] pin
   );

   // assign pin = 10'b0;
   max7219_display disp(clk, reset, spi_clk, dout, cs, stop, pin);

endmodule
