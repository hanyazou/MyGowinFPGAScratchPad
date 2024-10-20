//localparam CPU_REG_WIDTH = 16;
localparam CPU_REG_WIDTH = 32;
localparam CPU_NUMREGS = 24;

typedef logic [CPU_REG_WIDTH-1:0] reg_t;
typedef logic [15:0] ins_t;
typedef bit [4:0] reg_num_t;
typedef bit [3:0] flag_num_t;
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

localparam BUS_MEM = 1'b0;
localparam BUS_IO = 1'b1;
