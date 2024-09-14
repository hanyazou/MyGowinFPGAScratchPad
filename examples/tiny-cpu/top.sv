const int reg_pc = 6;
const int reg_flag = 7;
const int reg_flag_zero = 0;

//  0 zzzz_zzzz_zzzz  nop
function [15:0] I_NOP;
   return { 4'h0, 12'bzzzz_zzzz_zzzz };
endfunction

//  1 0ddd_nnnn_nnnn  reg[0][7:0] = 8'hzz
function [15:0] I_LD_IL(input [2:0] r, input [7:0] i);
   return { 4'h1, 1'b0, r, i};
endfunction

//  1 1ddd_nnnn_nnnn  reg[0][15:8] = 8'hzz
function [15:0] I_LD_IH(input [2:0] r, input [7:0] i);
   return { 4'h1, 1'b1, r, i};
endfunction

//  2 001d_ddaa_abbb  reg[dst] = reg[ra] - reg[rb]
function [15:0] I_SUB(input [2:0] dst, input [2:0] ra, input [2:0] rb);
   return { 4'h2, 3'b001, dst, ra, rb };
endfunction

//  3 0000_00aa_abbb  store reg[ra] to mem[reg[rb]]
function [15:0] I_ST(input [2:0] ra, input [2:0] rb);
   return { 4'h3, 6'b0000_00, ra, rb };
endfunction

//  3 0000_01aa_abbb  load reg[ra] from mem[reg[rb]]
function [15:0] I_LD_M(input [2:0] ra, input [2:0] rb);
   return { 4'h3, 6'b0000_01, ra, rb };
endfunction

//  3 0000_00aa_abbb  store reg[ra] to mem[reg[rb]]
function [15:0] I_STB(input [2:0] ra, input [2:0] rb);
   return { 4'h3, 6'b0001_00, ra, rb };
endfunction

// 3 0001_01aa_abbb  load reg[A][7:0] from mem[reg[B]]
function [15:0] I_LD_MB(input [2:0] ra, input [2:0] rb);
   return { 4'h3, 6'b0001_01, ra, rb };
endfunction

//  3 01ff_ffaa_abbb  move reg[ra] to reg[rb] if flag[F]
function [15:0] I_MVNF(input [2:0] ra, input [2:0] rb, input [3:0] flag);
   return { 4'h3, 2'b01, flag, ra, rb };
endfunction
function [15:0] I_JPNZ(input [2:0] r);
   return I_MVNF(reg_pc, r, reg_flag_zero);
endfunction

//  f 0000_0000_0000  halt
function [15:0] I_HALT;
   return { 4'hf, 12'b0000_0000_0000 };
endfunction

const int bus_cmd_read = 2'b00;
const int bus_cmd_write = 2'b01;
const int bus_cmd_read_b = 2'b10;
const int bus_cmd_write_b = 2'b11;

module top(
   input logic sysclk, S1, S2,
   output logic spi_clk, dout, cs, stop,
   output logic [10:1] pin
   );

   parameter SYSCLK_FREQ = 27000000;
   parameter int BUS_NIPS = 1;
   parameter int BUS_MEM = 0;

   wire [15:0] pc;
   wire [15:0] flag;
   wire [15:0] ins;
   reg halt;
   reg [15:0] regs[8];
   reg [3:0] state;

   reg [15:0] bus_addr;
   reg [1:0] bus_cmd;
   reg bus_run[BUS_NIPS];
   reg [15:0] bus_wr_data;
   reg [15:0] bus_rd_data[BUS_NIPS];
   wire bus_done[BUS_NIPS];
   reg [2:0] bus_rd_reg;
   wire bus_busy;
   assign bus_busy = (bus_run[BUS_MEM] != bus_done[BUS_MEM]);

   assign ins = bus_rd_data[BUS_MEM];
   int  next_ins_addr;

   /*
    * clock
    */
   logic [63:0] counter = 0;
   always @(posedge sysclk)
     counter <= counter + 1;
   wire clk;
   reg clk_autorun = 1;
   localparam CLK_S_WAIT_MAKE = 1;
   localparam CLK_S_WAIT_BREAK = 2;
   localparam CLK_LONGPRESS = SYSCLK_FREQ/65536*2;  // 2 sec
   localparam CLK_DEBOUNCE = SYSCLK_FREQ/65536/10;  // 0.1 sec
   reg [2:0] clk_state = CLK_S_WAIT_MAKE;
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
   assign clk = clk_autorun ? counter[24] : S1;

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
   assign frame[6] = { clk, clk_autorun, state[1:0], bus_cmd[1:0], bus_run[BUS_MEM],
                       bus_done[BUS_MEM] };
   assign frame[7] = regs[reg_flag][7:0];

   memory mem(clk, reset, bus_addr, bus_cmd, bus_run[BUS_MEM], bus_wr_data,
              bus_rd_data[BUS_MEM], bus_done[BUS_MEM]);

   task start_instruction_fetch(input [15:0] addr);
      bus_run_cmd(BUS_MEM, bus_cmd_read, addr);
      state <= 0;
   endtask // start_instruction_fetch

   task bus_run_cmd(input int ip, input int cmd, input [15:0] addr);
      bus_cmd <= cmd;
      bus_addr <= addr;
      bus_run[ip] <= ~bus_run[ip];
   endtask

   task register_(input int regnum, input [15:0] value);
      if ((regnum) == reg_pc)
         next_ins_addr = value;
      regs[regnum] <= value;
   endtask
   `define register(regnum, value) register_(regnum, value)

   always @(negedge clk) begin
      automatic int tmp;
      if (reset) begin
         regs[0] <= 'hffff;
         regs[1] <= 'hffff;
         regs[2] <= 'hffff;
         regs[3] <= 'hffff;
         regs[4] <= 'hffff;
         regs[5] <= 'hffff;
         regs[reg_pc] <= 'h0000;
         regs[reg_flag] <= 'h0000;
         halt <= 0;
         bus_addr <= 'h0000;
         bus_cmd <= bus_cmd_read;
         bus_run[BUS_MEM] <= 1;
         state <= 0;
      end else
      if (halt) begin
         // halted with no execution
      end else
      if (bus_busy) begin
         // wait for memory access completion
      end else
      case (state)
      0: begin  // fetch and execution
         automatic int do_memory_access = 0;
         next_ins_addr = regs[reg_pc] + 2;
         casez (ins)
         'h0zzz: begin  // 0 zzzz_zzz_zzzz  no operation
            end
         'h1zzz:
            case (ins[11])
            0:  // 1 0ddd_nnnn_nnnn  load immediate lower half of reg[D]
              `register(ins[10:8], regs[ins[10:8]] & 'hff00 | (ins & 'hff));
            1:  // 1 1ddd_nnnn_nnnn  load immediate upper half of reg[D]
              `register(ins[10:8], regs[ins[10:8]] & 'h00ff | (ins & 'hff) << 8);
            endcase
         'h2zzz:
            case (ins[11:9])
            0: begin  // 2 000d_ddaa_abbb  reg[D] = reg[A] + reg[B]
               tmp = regs[ins[5:3]] + regs[ins[2:0]];
               `register(ins[8:6], tmp);
               regs[reg_flag][reg_flag_zero] <= (tmp[15:0] == 0) ? 1 : 0;
            end
            1: begin  // 2 000d_ddaa_abbb  reg[D] = reg[A] - reg[B]
               tmp = regs[ins[5:3]] - regs[ins[2:0]];
               `register(ins[8:6], tmp);
               regs[reg_flag][reg_flag_zero] <= (tmp[15:0] == 0) ? 1 : 0;
            end
            endcase
         'h3zzz:
            //
            // memory read/write (word)
            //
            casez (ins[11:6])
            'b000000: begin  // 3 0000_00aa_abbb  store reg[A] to mem[reg[B]]
               bus_wr_data <= regs[ins[5:3]];
               bus_run_cmd(BUS_MEM, bus_cmd_write, regs[ins[2:0]]);
               do_memory_access = 1;
               end
            'b000001: begin  // 3 0000_01aa_abbb  load reg[A] from mem[reg[B]]
               bus_rd_reg <= ins[5:3];
               bus_run_cmd(BUS_MEM, bus_cmd_read, regs[ins[2:0]]);
               do_memory_access = 1;
            end
            //
            // memory read/write (byte)
            //
            'b000100: begin  // 3 0001_00aa_abbb  store reg[A][7:0] to mem[reg[B]]
               bus_wr_data <= regs[ins[5:3]];
               bus_run_cmd(BUS_MEM, bus_cmd_write_b, regs[ins[2:0]]);
               do_memory_access = 1;
               end
            'b000101: begin  // 3 0001_01aa_abbb  load reg[A][7:0] from mem[reg[B]]
               bus_rd_reg <= ins[5:3];
               bus_run_cmd(BUS_MEM, bus_cmd_read_b, regs[ins[2:0]]);
               do_memory_access = 1;
               end
            'b001000:  // 3 0010_10aa_abbb  move reg[B] to reg[A]
               `register(ins[5:3], regs[ins[2:0]]);
            'b01zzzz:  // 3 0100_00aa_abbb  move reg[B] to reg[A] if not flag[F]
               if (!regs[reg_flag][ins[9:6]])
                  `register(ins[5:3], regs[ins[2:0]]);
            'b10zzzz:  // 3 10ff_ffaa_abbb  move reg[B] to reg[A] if flag[F]
               if (regs[reg_flag][ins[9:6]])
                  `register(ins[5:3], regs[ins[2:0]]);
            endcase
         'hfzzz:
            case (ins[11:0])
            0: begin  // f 0000_0000_0000  halt
               halt <= 1;
               end
            endcase
         endcase // casez (ins)
         regs[reg_pc] <= next_ins_addr[15:0];
         if (do_memory_access)
            state <= 1;
         else
            start_instruction_fetch(next_ins_addr);
      end
      1: begin  // memory access completion
         if (bus_cmd == bus_cmd_read)
            regs[bus_rd_reg] <= bus_rd_data[BUS_MEM];
         if (bus_cmd == bus_cmd_read_b)
            regs[bus_rd_reg] <= { regs[bus_rd_reg][15:8], bus_rd_data[BUS_MEM][7:0] };
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
   input wire [15:0] addr,
   input wire [1:0] cmd,
   input wire run,
   input wire [15:0] wr_data,
   ref [15:0] rd_data,
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
      mem['h0004] = I_LD_IL(2, 'h10);  // LD r2.l, 10h
      mem['h0005] = I_LD_IH(2, 'h00);  // LD r2.h, 00h
      mem['h0006] = I_LD_IL(3, 'h41);  // LD r3.l, 41h
      mem['h0007] = I_LD_IH(3, 'h00);  // LD r3.h, 00h

      mem['h0008] = I_SUB(0, 0, 1);    // SUB r0, r0, r1
      //mem['h0009] = I_ST(0, 3);      // ST r0, (r3)
      mem['h0009] = I_NOP();
      mem['h000a] = I_STB(0, 3);       // ST r0.l, (r3)
      mem['h000b] = I_LD_IL(0, 'hff);  // LD r0.l, FFh
      //mem['h000c] = I_LD_M(0, 3);    // LD r0, (r3)
      mem['h000c] = I_NOP();
      mem['h000d] = I_LD_MB(0, 3);     // LD r0.l, (r3)
      mem['h000e] = I_JPNZ(2);         // JPNZ (r2)
      mem['h000f] = I_NOP();           // NOP
      mem['h0010] = I_HALT();          // HALT

      mem['h0020] = 'h0000;            // work area
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
               bus_cmd_read:
                  rd_data <= mem[addr[15:1]];
               bus_cmd_write:
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
