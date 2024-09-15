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
localparam reg_flag_zero = 0;
localparam reg_pc = 17;
localparam reg_sp = 18;
localparam reg_bp = 19;
localparam reg_numregs = 20;

localparam bus_cmd_write =   3'b000;
localparam bus_cmd_read =    3'b001;
localparam bus_cmd_write_w = 3'b010;
localparam bus_cmd_read_w =  3'b011;
localparam bus_cmd_write_b = 3'b100;
localparam bus_cmd_read_b =  3'b101;

localparam BUS_MEM = 1'b0;
localparam BUS_IO = 1'b1;

//  0 0000_0000_0000  NOP
function [15:0] I_NOP;
   return { 4'h0, 12'b0000_0000_0000 };
endfunction

//  0 0000_0000_0001  HALT
function [15:0] I_HALT;
   return { 4'h0, 12'b0000_0000_0001 };
endfunction

//  0 0100_00ff_rrrr JPN f, (R) (jump to R if F is false)
function [15:0] I_JPN_(flag_num_t f, reg_num_t r);
   return { 4'h0, 6'b0100_00, f[1:0], r[3:0] };
endfunction
function [15:0] I_JPNZ(reg_num_t r);
   return I_JPN_(reg_flag_zero, r);
endfunction

//  1 dddd_nnnn_nnnn  reg[D][7:0] = n
function [15:0] I_LD_IL(reg_num_t r, int i);
   return { 4'h1, r[3:0], i[7:0]};
endfunction

//  2 dddd_nnnn_nnnn  reg[D][15:8] = 8'hzz
function [15:0] I_LD_IH(reg_num_t r, int i);
   return { 4'h2, r[3:0], i[7:0]};
endfunction

//
//  memory load/store
//
//  3 ttt0_aaaa_abbb R/W reg[A] from/to memory address reg[B]
function [15:0] I_ST   (reg_num_t ra, reg_num_t rb);
   return { 4'h3, bus_cmd_write,   BUS_MEM, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_LD_M (reg_num_t ra, reg_num_t rb);
   return { 4'h3, bus_cmd_read,    BUS_MEM, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_STW  (reg_num_t ra, reg_num_t rb);
   return { 4'h3, bus_cmd_write_w, BUS_MEM, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_LD_MW(reg_num_t ra, reg_num_t rb);
   return { 4'h3, bus_cmd_read_w,  BUS_MEM, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_STB  (reg_num_t ra, reg_num_t rb);
   return { 4'h3, bus_cmd_write_b, BUS_MEM, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_LD_MB(reg_num_t ra, reg_num_t rb);
   return { 4'h3, bus_cmd_read_b,  BUS_MEM, ra[3:0], rb[3:0] };
endfunction

//
//  I/O read/write
//
//  3 ttt1_aaaa_abbb R/W reg[A] from/to I/O address reg[B]
function [15:0] I_OUT (reg_num_t ra, reg_num_t rb);
   return { 4'h3, bus_cmd_write,   BUS_IO, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_IN  (reg_num_t ra, reg_num_t rb);
   return { 4'h3, bus_cmd_read,    BUS_IO, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_OUTW(reg_num_t ra, reg_num_t rb);
   return { 4'h3, bus_cmd_write_w, BUS_IO, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_INW (reg_num_t ra, reg_num_t rb);
   return { 4'h3, bus_cmd_read_w,  BUS_IO, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_OUTB(reg_num_t ra, reg_num_t rb);
   return { 4'h3, bus_cmd_write_b, BUS_IO, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_INB (reg_num_t ra, reg_num_t rb);
   return { 4'h3, bus_cmd_read_b,  BUS_IO, ra[3:0], rb[3:0] };
endfunction

//
//  move
//
function [15:0] I_MOV(reg_num_t ra, reg_num_t rb);
   if (ra[4] && ~rb[4])
     //  3 110a_aaaa_bbbb  move reg[A] to reg[B]
     return { 4'h3, 3'b110, ra[4:0], rb[3:0] };
   else
   if (~ra[4] && rb[4])
     //  3 111a_aaaa_bbbb  move reg[B] to reg[A]
     return { 4'h3, 3'b111, rb[4:0], ra[3:0] };
   else
     return { 4'h0, 4'h0, 8'hff };  // invalid instruction
endfunction

//
//  three register operations
//
//  8 dddd_aaaa_bbbb  reg[D] = reg[A] + reg[B]
function [15:0] I_ADD(reg_num_t dst, reg_num_t ra, reg_num_t rb);
   return { 4'h8, dst[3:0], ra[3:0], rb[3:0] };
endfunction

//  9 001d_ddaa_abbb  reg[D] = reg[A] - reg[B]
function [15:0] I_SUB(reg_num_t dst, reg_num_t ra, reg_num_t rb);
   return { 4'h9, dst[3:0], ra[3:0], rb[3:0] };
endfunction

module top(
   input logic sysclk, S1, S2,
   output logic spi_clk, dout, cs, stop,
   output logic [10:1] pin,
   output wire uart_txp
   );

   parameter SYSCLK_FREQ = 27000000;

   reg halt;
   reg_t regs[reg_numregs];
   enum { S_FETCH_EXEC, S_BUS_RW } state;
   bus_addr_t bus_addr;
   bus_cmd_t bus_cmd;
   bus_num_t bus_num;
   reg bus_run[bus_numbuses];
   bus_data_t bus_wr_data;
   bus_data_t bus_rd_data[bus_numbuses];
   reg_num_t bus_rd_reg;

   wire reg_t pc;
   wire reg_t flag;
   wire bus_done[bus_numbuses];
   wire ins_t ins;
   wire bus_busy;
   assign bus_busy = ((bus_run[BUS_MEM] != bus_done[BUS_MEM]) ||
                      (bus_run[BUS_IO] != bus_done[BUS_IO]));
   assign ins = ins_t'(bus_rd_data[BUS_MEM]);
   int next_ins_addr;

   /*
    * clock
    */
   logic [63:0] counter = 0;
   always @(posedge sysclk)
     counter <= counter + 1;
   wire clk;
   reg clk_autorun = 1;
   enum { CLK_S_WAIT_MAKE, CLK_S_WAIT_BREAK } clk_state = CLK_S_WAIT_MAKE;
   localparam CLK_LONGPRESS = SYSCLK_FREQ/65536*2;  // 2 sec
   localparam CLK_DEBOUNCE = SYSCLK_FREQ/65536/10;  // 0.1 sec
   reg [15:0] clk_debounce = CLK_DEBOUNCE;  // This immediately disables autorun if S1 is true
                                            // at power on.
   always @(posedge counter[16]) begin
      case (clk_state)
      CLK_S_WAIT_MAKE: begin
         if (S1) begin
            if (clk_debounce == 0) begin
               clk_autorun <= ~clk_autorun;
               clk_debounce <= CLK_DEBOUNCE;
               clk_state <= CLK_S_WAIT_BREAK;
            end else begin
               clk_debounce <= clk_debounce - 1'b1;
            end
         end else begin
            clk_debounce <= CLK_LONGPRESS;
         end
      end
      CLK_S_WAIT_BREAK: begin
         if (~S1) begin
            if (clk_debounce == 0) begin
               clk_debounce <= CLK_LONGPRESS;
               clk_state <= CLK_S_WAIT_MAKE;
            end else begin
               clk_debounce <= clk_debounce - 1'b1;
            end
         end else begin
            clk_debounce <= CLK_DEBOUNCE;
         end
      end
      endcase // case (clk_state)
   end
   assign clk = clk_autorun ? counter[21] : S1;

   /*
    * reset
    */
   reg [1:0] reset_pon = 2'b10;
   wire reset;
   assign reset = (S2 || reset_pon) ? 1'b1 : 1'b0;
   always @(negedge clk) begin
      if (reset_pon) begin
         reset_pon <= reset_pon - 1'b1;
      end
   end

   /*
    * debug LED
    */
   parameter NUM_CASCADES = 2;
   wire [7:0] frame[4 * NUM_CASCADES];
   assign frame[0] = bus_addr[15:8];
   assign frame[1] = bus_addr[7:0];
   assign frame[2] = ins[15:8];
   assign frame[3] = ins[7:0];
   assign frame[4] = regs[0][15:8];
   assign frame[5] = regs[0][7:0];
   assign frame[6] = { clk, clk_autorun, bus_run[BUS_MEM], bus_done[BUS_MEM], state[0:0],
                       bus_cmd[2:0] };
   assign frame[7] = regs[reg_flag][7:0];

   memory mem(clk, reset, bus_addr, bus_cmd, bus_run[BUS_MEM], bus_wr_data,
              bus_rd_data[BUS_MEM], bus_done[BUS_MEM]);
   io io_i(clk, reset, bus_addr, bus_cmd, bus_run[BUS_IO], bus_wr_data,
              bus_rd_data[BUS_IO], bus_done[BUS_IO], sysclk, uart_txp);

   task start_instruction_fetch(bus_addr_t addr);
      bus_run_cmd(BUS_MEM, bus_cmd_read_w, addr);
      state <= S_FETCH_EXEC;
   endtask // start_instruction_fetch

   task bus_run_cmd(bus_num_t bus, bus_cmd_t cmd, bus_addr_t addr);
      bus_cmd <= cmd;
      bus_addr <= addr;
      bus_num <= bus;
      bus_run[bus] <= ~bus_run[bus];
   endtask

   task register_(reg_num_t regnum, reg_t value);
      if ((regnum) == reg_pc)
         next_ins_addr = value;
      regs[regnum] <= value;
   endtask
   `define register(regnum, value) register_(regnum, value)

   function bus(input bus_sel);
      return bus_sel ? BUS_IO : BUS_MEM;
   endfunction

   always @(negedge clk) begin
      automatic int tmp;
      if (reset) begin
         regs[reg_pc] <= 'h0000;
         regs[reg_flag] <= 'h0000;
         halt <= 0;
         bus_run[BUS_IO] <= 0;
         state <= S_FETCH_EXEC;

         // fetch first instruction
         bus_addr <= 'h0000;
         bus_cmd <= bus_cmd_read_w;
         bus_run[BUS_MEM] <= 1;
      end else
      if (halt) begin
         // halted with no execution
      end else
      if (bus_busy) begin
         // wait for memory access completion
      end else
      case (state)
      S_FETCH_EXEC: begin  // fetch and execution
         automatic int do_memory_access = 0;
         next_ins_addr = regs[reg_pc] + 2;
         casez (ins)
         16'b0000_0000_0000_0000: begin  //  0 0000_0000_0000  NOP
            // no operation
         end
         16'b0000_0000_0000_0001: begin  //  0 0000_0000_0001  HALT
            halt <= 1;
         end
         16'b0000_0100_00zz_zzzz: begin  //  0 0100_00ff_rrrr JPN f, (R) (jump to R if F is false)
            if (!regs[reg_flag][ins[5:4]])
               `register(reg_pc, regs[ins[3:0]]);
         end
         16'b0000_0100_01zz_zzzz: begin  //  0 0100_01ff_rrrr JP  f, (R) (jump to R if F is true)
            if (regs[reg_flag][ins[5:4]])
               `register(reg_pc, regs[ins[3:0]]);
         end
         16'b0001_zzzz_zzzz_zzzz: begin  //  1 dddd_nnnn_nnnn  reg[D][7:0] = n
            `register(ins[11:8], regs[ins[11:8]] & 'hff00 | (ins & 'hff));
         end
         16'b0010_zzzz_zzzz_zzzz: begin  //  1 dddd_nnnn_nnnn  reg[D][7:0] = n
            `register(ins[11:8], regs[ins[11:8]] & 'h00ff | (ins & 'hff) << 8);
         end

         //
         // bus read/write 
         //
         //  3 tttn_aaaa_bbbb R/W reg[A] from/to address reg[B]
         16'b0011_zzzz_zzzz_zzzz:  begin
            bus_wr_data <= regs[ins[7:4]];
            bus_rd_reg <= ins[7:4];
            bus_run_cmd(bus(ins[8]), ins[11:9], regs[ins[3:0]]);
            do_memory_access = 1;
         end

         //
         // move
         //
         16'b0011_110z_zzzz_zzzz:  begin
            //  3 110a_aaaa_bbbb  move reg[A] to reg[B]
           `register(ins[3:0], regs[ins[8:4]]);
         end
         16'b0011_111z_zzzz_zzzz:  begin
            //  3 111a_aaaa_bbbb  move reg[B] to reg[A]
            `register(ins[8:4], regs[ins[3:0]]);
         end

         //
         //  three register operations
         //
         'h8zzz: begin  //  8 dddd_aaaa_bbbb  reg[D] = reg[A] + reg[B]
            tmp = regs[ins[7:4]] + regs[ins[3:0]];
            `register(ins[11:8], tmp);
            regs[reg_flag][reg_flag_zero] <= (tmp[15:0] == 0) ? 1 : 0;
         end
         'h9zzz: begin  //  9 001d_ddaa_abbb  reg[D] = reg[A] - reg[B]
            tmp = regs[ins[7:4]] - regs[ins[3:0]];
            `register(ins[11:8], tmp);
            regs[reg_flag][reg_flag_zero] <= (tmp[15:0] == 0) ? 1 : 0;
         end
         endcase // casez (ins)
         regs[reg_pc] <= next_ins_addr[15:0];
         if (do_memory_access)
            state <= S_BUS_RW;
         else
            start_instruction_fetch(next_ins_addr);
      end
      S_BUS_RW: begin  // memory access completion
         if (bus_cmd == bus_cmd_read_w)
            regs[bus_rd_reg] <= bus_rd_data[bus_num];
         if (bus_cmd == bus_cmd_read_b)
            regs[bus_rd_reg] <= { regs[bus_rd_reg][15:8], bus_rd_data[bus_num][7:0] };
         if (bus_rd_reg == reg_pc)
            start_instruction_fetch(bus_rd_data[BUS_MEM]);
         else
            start_instruction_fetch(regs[reg_pc]);
      end
      endcase // case (state)
   end // always @ (negedge clk)

   max7219_display #( .NUM_CASCADES(NUM_CASCADES), .INTENSITY(1) )
     disp(sysclk, reset, frame, spi_clk, dout, cs, stop, pin);

endmodule


module memory(
   input wire clk,
   input wire reset,
   input wire bus_addr_t addr,
   input wire bus_cmd_t cmd,
   input wire run,
   input wire bus_data_t wr_data,
   ref bus_data_t rd_data,
   output logic done
   );

   reg [15:0] mem[1024*32];  // 32K words
   int state = 0;

   initial begin
      done <= 0;
      mem['h0000] = I_LD_IL(0, 'h04);  // LD r0.l, 04h
      mem['h0001] = I_LD_IH(0, 'h00);  // LD r0.h, 00h
      mem['h0002] = I_LD_IL(1, 'h01);  // LD r1.l, 01h
      mem['h0003] = I_LD_IH(1, 'h00);  // LD r1.h, 00h
      mem['h0004] = I_LD_IL(2, 'h10);  // LD r2.l, 10h  LOOP0
      mem['h0005] = I_LD_IH(2, 'h00);  // LD r2.h, 00h
      mem['h0006] = I_LD_IL(3, 'h00);  // LD r3.l, 00h  work area
      mem['h0007] = I_LD_IH(3, 'h20);  // LD r3.h, 20h

      // LOOP0
      mem['h0008] = I_SUB(0, 0, 1);    // SUB r0, r0, r1
      mem['h0009] = I_STW(0, 3);       // ST r0.w, (r3)
      mem['h000a] = I_STB(0, 3);       // ST r0.b, (r3)
      mem['h000b] = I_LD_IL(0, 'hff);  // LD r0.l, FFh
      mem['h000c] = I_LD_MW(0, 3);     // LD r0.w, (r3)
      mem['h000d] = I_LD_MB(0, 3);     // LD r0.b, (r3)
      mem['h000e] = I_JPNZ(2);         // JPNZ (r2)
      mem['h000f] = I_NOP();           // NOP

      mem['h0010] = I_LD_IL(2, 'h2c);  // LD r2.l, 2ch  LOOP1
      mem['h0011] = I_LD_IH(2, 'h00);  // LD r2.h, 00h
      mem['h0012] = I_LD_IL(3, 'h20);  // LD r3.l, 20h  message
      mem['h0013] = I_LD_IH(3, 'h20);  // LD r3.h, 20h
      mem['h0014] = I_LD_IL(4, 'h00);  // LD r4.l, 00h  UART TX
      mem['h0015] = I_LD_IH(4, 'h00);  // LD r4.h, 00h

      // LOOP1
      mem['h0016] = I_LD_MB(0, 3);     // LD r0.l, (r3)
      mem['h0017] = I_OUTB(0, 4);      // OUTB r0, (r4)
      mem['h0018] = I_ADD(3, 3, 1);    // ADD r3, r3, r1  r3 = r3 + 1
      mem['h0019] = I_ADD(0, 0, 0);    // ADD r0, r0, r0  r0 == 0 ?
      mem['h001a] = I_JPNZ(2);         // JPNZ (r2)

      mem['h001b] = I_HALT();          // HALT

      mem['h1000] = 'h0000;            // work area
      mem['h1010] = { "e", "H" };      // message
      mem['h1011] = { "l", "l" };
      mem['h1012] = { ",", "o" };
      mem['h1013] = { "w", " " };
      mem['h1014] = { "r", "o" };
      mem['h1015] = { "d", "l" };
      mem['h1016] = { 8'h0d, "!" };
      mem['h1017] = { 8'h00, 8'h0a };
   end

   always @(posedge clk) begin
      if (reset) begin
         state <= 0;
         done <= 0;
      end else begin
         case (state)
         0: begin
            if (run != done) begin
               case (cmd)
               bus_cmd_read_w:
                  rd_data <= mem[addr[15:1]];
               bus_cmd_write_w:
                  mem[addr[15:1]] <= wr_data;
               bus_cmd_read_b:
                 if (addr[0])
                   rd_data <= { 8'h00, mem[addr[15:1]][15:8] };
                 else
                   rd_data <= { 8'h00, mem[addr[15:1]][7:0] };
               bus_cmd_write_b:
                 if (addr[0])
                   mem[addr[15:1]] <= { wr_data[7:0], mem[addr[15:1]][7:0] };
                 else
                   mem[addr[15:1]] <= { mem[addr[15:1]][15:8], wr_data[7:0] };
               endcase
               done <= ~done;
               state <= 0;  // there is only one state, no transition
            end
         end
         endcase
      end // else: !if(reset)
   end // always @ (posedge clk)

endmodule


module io(
   input wire clk,
   input wire reset,
   input wire bus_addr_t addr,
   input wire bus_cmd_t cmd,
   input wire run,
   input wire bus_data_t wr_data,
   ref bus_data_t rd_data,
   output logic done,
   input wire sysclk,
   output wire uart_txp
   );

   reg prev_clk;
   reg uart_en = 0;
   reg [7:0] uart_tx = 0;
   wire uart_busy;
   uart_tx_V2 #( .clk_freq(50000000), .uart_freq(115200))
       tx(sysclk, uart_tx, uart_en, uart_busy, uart_txp);
   
   localparam S_IDLE = 'h0;
   localparam S_WAIT_UART = 'h1;
   reg [1:0] state = S_IDLE;

   initial begin
      done <= 0;
   end

   always @(posedge sysclk) begin
      prev_clk <= clk;
      if (reset) begin
         state <= 0;
         done <= 0;
         uart_en <= 0;
      end else begin
         if (~uart_busy) begin
            uart_en <= 0;
         end

         // posedge clk
         if (~prev_clk && clk)  begin
            case (state)
            S_IDLE: begin
               if (run != done) begin
                  case (addr)
                  'h0000: begin
                     if (cmd == bus_cmd_write_b) begin
                        if (!uart_busy) begin
                           uart_tx <= wr_data[7:0];
                              uart_en <= 1;
                           done <= ~done;
                        end else begin
                          state <= S_WAIT_UART;
                        end
                     end
                  end
                  endcase
               end
            end
            S_WAIT_UART: begin
               if (!uart_en && !uart_busy) begin
                  uart_tx <= wr_data[7:0];
                  uart_en <= 1;
                  done <= ~done;
                  state <= S_IDLE;
               end
            end
            endcase
         end
      end // else: !if(reset)
   end // always @ (posedge sysclk)

endmodule
