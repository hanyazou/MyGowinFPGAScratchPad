typedef logic [15:0] reg_t;
typedef logic [15:0] ins_t;
typedef bit [4:0] reg_num_t;
typedef bit [3:0] flag_num_t;
typedef logic [15:0] bus_data_t;
typedef logic [15:0] bus_addr_t;
typedef logic [2:0] bus_cmd_t;
typedef bit [0:0] bus_num_t;
localparam bus_numbuses = 2;

localparam reg_flag = 16;
localparam     reg_flag_zero            = 0;  // equal zero
localparam     reg_flag_carry           = 1;  // carry / borrow
localparam     reg_flag_parity          = 2;  // 1: even / 0: odd
localparam     reg_flag_overflow        = 2;  // overflow flag and parity flag share the same field
localparam     reg_flag_sign            = 3;  // 1: negitive / 0: positive
localparam     reg_flag_halt            = 8;  // CPU is halted
localparam reg_pc = 17;
localparam reg_sp = 18;
localparam reg_bp = 19;
localparam reg_numregs = 24;

localparam bus_cmd_write =   3'b000;
localparam bus_cmd_read =    3'b001;
localparam bus_cmd_write_w = 3'b010;
localparam bus_cmd_read_w =  3'b011;
localparam bus_cmd_write_b = 3'b100;
localparam bus_cmd_read_b =  3'b101;
localparam bus_cmd_none =    3'b111;

localparam BUS_MEM = 1'b0;
localparam BUS_IO = 1'b1;
