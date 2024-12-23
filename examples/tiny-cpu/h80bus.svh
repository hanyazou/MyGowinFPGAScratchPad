typedef logic [BUS_DATA_WIDTH-1:0] bus_data_t;
typedef logic [BUS_ADDR_WIDTH-1:0] bus_addr_t;
typedef logic [BUS_CMD_WIDTH-1:0] bus_cmd_t;
localparam bus_cmd_write =   3'b000;
localparam bus_cmd_read =    3'b001;
localparam bus_cmd_write_w = 3'b010;
localparam bus_cmd_read_w =  3'b011;
localparam bus_cmd_write_b = 3'b100;
localparam bus_cmd_read_b =  3'b101;
localparam bus_cmd_none =    3'b111;
function bit bus_cmd_is_read(bus_cmd_t cmd);
   return cmd[0];
endfunction
