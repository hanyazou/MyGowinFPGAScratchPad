module h80cpu_io(
   input wire clk,
   input wire reset,
   input wire bus_addr_t addr,
   input wire bus_cmd_t cmd,
   input wire run,
   input wire bus_data_t wr_data,
   output bus_data_t rd_data,
   output logic done,
   input wire sysclk,
   output wire uart_txp
   );

endmodule
