module top(
   input wire logic sysclk, S1, S2,
   output wire logic spi_clk, dout, cs, stop,
   output wire logic [10:1] pin,
   output reg uart_txp
   );

   h80cpu(sysclk, S1, S2, spi_clk, dout, cs, stop, pin, uart_txp);

endmodule
