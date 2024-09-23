`default_nettype none

`include "h80cpu.svh"
`include "h80cpu_instmacros.svh"

module h80cpu(
   input wire logic sysclk, clk, reset_,
   output wire bus_addr_t bus_addr_,
   output wire ins_t ins_,
   output wire reg_t regs_[reg_numregs],
   output reg  uart_txp
   );

   parameter SYSCLK_FREQ = 27000000;

   reg_t regs[reg_numregs];
   assign regs_ = regs;
   enum { S_FETCH_EXEC, S_BUS_RW } state;
   bus_addr_t bus_addr;
   assign bus_addr_ = bus_addr;
   bus_cmd_t bus_cmd;
   bus_num_t bus_num;
   reg bus_run[bus_numbuses];
   bus_data_t bus_wr_data;
   wire bus_data_t bus_rd_data[bus_numbuses];
   reg_num_t bus_rd_reg;

   wire reg_t pc;
   wire reg_t flag;
   wire bus_done[bus_numbuses];
   wire ins_t ins;
   wire bus_busy;
   assign bus_busy = ((bus_run[BUS_MEM] != bus_done[BUS_MEM]) ||
                      (bus_run[BUS_IO] != bus_done[BUS_IO]));
   assign ins = ins_t'(bus_rd_data[BUS_MEM]);
   assign ins_ = ins;
   int next_ins_addr;
   int do_memory_access;

   /*
    * reset
    */
   reg [1:0] reset_pon = 2'b10;
   wire reset;
   assign reset = (reset_ || reset_pon) ? 1'b1 : 1'b0;
   always @(negedge clk) begin
      if (reset_pon) begin
         reset_pon <= reset_pon - 1'b1;
      end
   end

   h80cpu_mem mem0(clk, reset, bus_addr, bus_cmd, bus_run[BUS_MEM], bus_wr_data,
                   bus_rd_data[BUS_MEM], bus_done[BUS_MEM]);
   h80cpu_io io0(clk, reset, bus_addr, bus_cmd, bus_run[BUS_IO], bus_wr_data,
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

   task bus_rw(bus_num_t bus, bus_cmd_t cmd, bus_addr_t addr, bus_data_t wr_data = 0);
      bus_cmd = cmd;
      bus_addr = addr;
      bus_num = bus;
      bus_wr_data = wr_data;
      bus_run[bus] = ~bus_run[bus];
   endtask

   task bus_wait(bus_num_t bus, output busy, output bus_data_t rd_data);
      rd_data = bus_rd_data[bus];
      busy = (bus_run[bus] != bus_done[bus]);
   endtask

   task set_halt(bit halt_);
      regs[reg_flag][reg_flag_halt] = halt_;
   endtask

   always @(negedge clk) begin
      if (reset) begin
         regs[reg_pc] <= 'h0000;
         regs[reg_flag] <= 'h0000;
         bus_run[BUS_IO] <= 0;
         state <= S_FETCH_EXEC;

         // fetch first instruction
         bus_addr <= 'h0000;
         bus_cmd <= bus_cmd_read_w;
         bus_run[BUS_MEM] <= 1;
      end else
      if (regs[reg_flag][reg_flag_halt]) begin
         // halted with no execution
      end else
      if (bus_busy) begin
         // wait for memory access completion
      end else
      case (state)
      S_FETCH_EXEC: begin  // fetch and execution
         do_memory_access = 0;
         next_ins_addr = regs[reg_pc] + 2;
         casez (ins)
         16'b0000_0000_0000_0000: begin  //  0 0000_0000_0000  NOP
            // no operation
         end
         16'b0000_0000_0000_0001: begin  //  0 0000_0000_0001  HALT
            regs[reg_flag][reg_flag_halt] <= 1;
         end
         16'b0000_0000_0000_0010: begin  //  0 0000_0000_0010 RET
            bus_rd_reg <= reg_pc;
            bus_run_cmd(BUS_MEM, bus_cmd_read_w, regs[reg_sp]);
            regs[reg_sp] <= regs[reg_sp] + 2;
            do_memory_access = 1;
         end
         // 0000_0000_0000_0011 to 0111_1110 reserved
         16'b0000_0000_0111_1111: begin  //  0 0000_0111_1111 INV 無効な命令
            // TODO (exception)
         end
         16'b0000_0000_1000_00zz,        //  0 0000_1000_00ff RET_N f
         16'b0000_0000_1000_01zz: begin  //  0 0000_1000_01ff RET f
            if ((ins[2] == 1'b0 && !regs[reg_flag][ins[1:0]]) ||
                (ins[2] == 1'b1 && regs[reg_flag][ins[1:0]])) begin
               bus_rd_reg <= reg_pc;
               bus_run_cmd(BUS_MEM, bus_cmd_read_w, regs[reg_sp]);
               regs[reg_sp] <= regs[reg_sp] + 2;
               do_memory_access = 1;
            end
         end
         16'b0000_0001_0000_zzzz: begin  //  0 0001_0000_rrrr PUSH R
            bus_wr_data <= regs[ins[3:0]];
            bus_run_cmd(BUS_MEM, bus_cmd_write_w, regs[reg_sp] - 2);
            regs[reg_sp] <= regs[reg_sp] - 2;
            do_memory_access = 1;
         end
         16'b0000_0001_0001_zzzz: begin  //  0 0001_0001_rrrr POP R
            bus_rd_reg <= ins[3:0];
            bus_run_cmd(BUS_MEM, bus_cmd_read_w, regs[reg_sp]);
            regs[reg_sp] <= regs[reg_sp] + 2;
            do_memory_access = 1;
         end
         16'b0000_0001_0010_zzzz: begin  //  0 0001_0010_rrrr EXTN R.w
                                         //  (copy R[15] for sign extension)
            // TODO (32bit)
         end
         16'b0000_0001_0011_zzzz: begin  //  0 0001_0011_rrrr EXTN R.b
                                         //  (copy R[7] for sign extension)
            reg_num_t r;
            r = ins[3:0];
            regs[r] <= regs[r][7] == 0 ? (regs[r] & 'h00ff) : (regs[r] | 'hff00);
         end
         16'b0000_0001_0100_zzzz: begin  //  0 0001_0100_rrrr CPL R (invert R, one's complement)
            regs[ins[3:0]] <= ~regs[ins[3:0]];
         end
         16'b0000_0001_0101_zzzz: begin  //  0 0001_0101_rrrr NEG R (negate R, two's complement)
            regs[ins[3:0]] <= ~regs[ins[3:0]] + 1;
         end
         16'b0000_0001_0110_zzzz: begin  //  0 0001_0110_rrrr LD R, nnnnnnnn
            // TODO (32bit)
         end
         16'b0000_0001_0111_zzzz: begin  //  0 0001_0111_rrrr LD R, nnnn
            bus_rd_reg <= ins[3:0];
            bus_run_cmd(BUS_MEM, bus_cmd_read_w, regs[reg_pc] + 2);
            next_ins_addr = regs[reg_pc] + 4;
            do_memory_access = 1;
         end
         16'b0000_0001_1000_zzzz: begin  //  0 0001_1000_ffff INVF (invert flag F)
            regs[reg_flag] <= regs[reg_flag] ^ (16'b1 << ins[3:0]);
         end
         16'b0000_0001_1001_zzzz: begin  //  0 0001_1001_ffff SETF (set flag F)
            regs[reg_flag] <= regs[reg_flag] | (16'b1 << ins[3:0]);
         end
         16'b0000_0001_1010_zzzz: begin  //  0 0001_1010_ffff CLRF (clear flag F)
            regs[reg_flag] <= regs[reg_flag]& ~(16'b1 << ins[3:0]);
         end
         16'b0000_0001_1011_zzzz: begin  //  0 0001_1011_ffff TESTF (test flag F is zero)
            regs[reg_flag][reg_flag_zero] <= regs[reg_flag][ins[3:0]] ? 1'b0: 1'b1;
         end
         16'b0000_0001_1100_zzzz: begin  //  0 0001_1100_zzzz CALL R
            bus_wr_data <= regs[reg_pc] + 2;
            bus_run_cmd(BUS_MEM, bus_cmd_write_w, regs[reg_sp] - 2);
            regs[reg_sp] <= regs[reg_sp] - 2;
            next_ins_addr = regs[ins[3:0]];
            do_memory_access = 1;
         end
         16'b0000_0001_1101_zzzz: begin  //  0 0001_1101_nnnn RST n (call address n * 8)
            bus_wr_data <= regs[reg_pc] + 2;
            bus_run_cmd(BUS_MEM, bus_cmd_write_w, regs[reg_sp] - 2);
            regs[reg_sp] <= regs[reg_sp] - 2;
            next_ins_addr = bus_addr_t'(ins[3:0] * 8);
            do_memory_access = 1;
         end
         16'b0000_0001_1110_zzzz: begin  //  0 0001_1110_rrrr JP R
            `register(reg_pc, regs[ins[3:0]]);
         end
         16'b0000_0001_1111_zzzz: begin  //  0 0001_1111_rrrr JR R
            `register(reg_pc, regs[reg_pc] + regs[ins[3:0]]);
         end
         16'b0000_0010_00zz_zzzz,        //  0 0010_00ff_rrrr CALLN f, (R) (call R if f is false)
         16'b0000_0010_01zz_zzzz: begin  //  0 0010_01ff_rrrr CALL  f, (R) (call R if f is true)
            if ((ins[6] == 1'b0 && !regs[reg_flag][ins[5:4]]) ||
                (ins[6] == 1'b1 && regs[reg_flag][ins[5:4]])) begin
               bus_wr_data <= regs[reg_pc] + 2;
               bus_run_cmd(BUS_MEM, bus_cmd_write_w, regs[reg_sp] - 2);
               regs[reg_sp] <= regs[reg_sp] - 2;
               next_ins_addr = regs[ins[3:0]];
               do_memory_access = 1;
            end
         end
         //  0 0010_10ff_rrrr reserved 空き
         //  0 0010_11ff_rrrr reserved 空き
         16'b0000_0011_00zz_zzzz: begin  //  0 0011_00ff_rrrr JPN f, (R) (jump to R if F is false)
            if (!regs[reg_flag][ins[5:4]])
               `register(reg_pc, regs[ins[3:0]]);
         end
         16'b0000_0011_01zz_zzzz: begin  //  0 0011_01ff_rrrr JP  f, (R) (jump to R if F is true)
            if (regs[reg_flag][ins[5:4]])
               `register(reg_pc, regs[ins[3:0]]);
         end
         16'b0000_0011_10zz_zzzz: begin  //  0 0011_10ff_rrrr JRN f, (R) (jump to R if F is false)
            if (!regs[reg_flag][ins[5:4]])
               `register(reg_pc, regs[reg_pc] + regs[ins[3:0]]);
         end
         16'b0000_0011_11zz_zzzz: begin  //  0 0011_11ff_rrrr JR  f, (R) (jump to R if F is true)
            if (regs[reg_flag][ins[5:4]])
               `register(reg_pc, regs[reg_pc] + regs[ins[3:0]]);
         end
         16'b0000_0100_zzzz_zzzz: begin  //  0 0100_rrrr_nnnn SRA R, n (shift right arithmetic)
            `register(ins[7:4], signed'(regs[ins[7:4]]) >>>  ins[3:0]);
         end
         16'b0000_0101_zzzz_zzzz: begin  //  0 0101_rrrr_nnnn SRL R, n (shift right logical)
            `register(ins[7:4], regs[ins[7:4]] >> ins[3:0]);
         end
         16'b0000_0110_zzzz_zzzz: begin  //  0 0110_rrrr_nnnn SL  R, n (shift left)
            `register(ins[7:4], regs[ins[7:4]] << ins[3:0]);
         end
         16'b0000_0111_zzzz_zzzz: begin  //  0 0111_rrrr_nnnn RLC R, n (rotate left circular)
            `register(ins[7:4], (regs[ins[7:4]] << ins[3:0]) | (regs[ins[7:4]] >> (16-ins[3:0])));
         end
         16'b0000_1000_zzzz_zzzz: begin  //  0 1000_rrrr_nnnn ADD R, n
            bit [16:0] res;
            bit [16:0] a;
            a = { 1'b0, regs[ins[7:4]] };
            res = a + ins[3:0];
            regs[reg_flag][reg_flag_sign] <= res[15];
            regs[reg_flag][reg_flag_zero] <= (res[15:0] == 0) ? 1 : 0;
            regs[reg_flag][reg_flag_overflow] <= (a[15] == 1'b0 && res[15] == 1'b1) ? 1 : 0;
            regs[reg_flag][reg_flag_carry] <= res[16];
            `register(ins[7:4], regs[ins[7:4]] + ins[3:0]);
         end
         16'b0000_1001_zzzz_zzzz: begin  //  0 1001_rrrr_nnnn SUB R, n
            bit [16:0] res;
            bit [16:0] a;
            a = { 1'b0, regs[ins[7:4]] };
            res = a - ins[3:0];
            regs[reg_flag][reg_flag_sign] <= res[15];
            regs[reg_flag][reg_flag_zero] <= (res[15:0] == 0) ? 1 : 0;
            regs[reg_flag][reg_flag_overflow] <= (a[15] == 1'b1 && res[15] == 1'b0) ? 1 : 0;
            regs[reg_flag][reg_flag_carry] <= res[16];
            `register(ins[7:4], regs[ins[7:4]] - ins[3:0]);
         end
         16'b0000_1010_zzzz_zzzz: begin  //  0 1010_aaaa_bbbb DJNZ A, (B)
                                         //  (decrement A and jump to B if A is not zero)
            // TODO
         end
         16'b0000_110z_zzzz_zzzz: begin  //  0 110a_aaaa_bbbb EX A, B
            // TODO
         end
         //  0 1110_aaaa_bbbb reserved 空き
         //  0 1111_aaaa_bbbb reserved 空き

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
         16'b0011_00zz_zzzz_zzzz,
         16'b0011_01zz_zzzz_zzzz,
         16'b0011_10zz_zzzz_zzzz:  begin
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
         //  1zzzz dddd_aaaa_bbbb  reg[D] = reg[A] op reg[B]
         'b1zzz_zzzz_zzzz_zzzz: begin
            reg_num_t dst;
            bit [16:0] a;
            bit [16:0] b;
            bit C;
            bit [16:0] res;

            dst = ins[11:8];
            a = { 1'b0, regs[ins[7:4]] };
            b = { 1'b0, regs[ins[3:0]] };
            C = regs[reg_flag][reg_flag_carry];

            casez (ins)
            'h8zzz: begin res = a + b;     end  // ADD
            'h9zzz: begin res = a - b;     end  // SUB
            'hazzz: begin res = a * b;     end  // MUL
            'hbzzz: begin res = a / b;     end  // DIV
            'hczzz: begin res = a & b;     end  // AND
            'hdzzz: begin res = a | b;     end  // OR 
            'hezzz: begin res = a ^ b;     end  // XOR
            'hfzzz: begin res = a - b;     end  // CP 
            endcase // casez (ins)

            if (ins[15:12] != 'hf) begin
               `register(dst, res);
            end

            casez (ins)
            'h8zzz,
            'h9zzz,
            'hfzzz: begin  //  ADD, SUB and CP
               regs[reg_flag][reg_flag_sign] <= res[15];
               regs[reg_flag][reg_flag_zero] <= (res[15:0] == 0) ? 1 : 0;
               if (ins[15:12] == 'h8 || ins[15:12] == 'ha)
                 regs[reg_flag][reg_flag_overflow] <= (a[15] == b[15] && a[15] != res[15]) ? 1 : 0;
               else
                 regs[reg_flag][reg_flag_overflow] <= (a[15] != b[15] && a[15] != res[15]) ? 1 : 0;
               regs[reg_flag][reg_flag_carry] <= res[16];
            end
            'hazzz,
            'hbzzz: begin  //  MUL and DIV
               regs[reg_flag][reg_flag_sign] <= res[15];
               regs[reg_flag][reg_flag_zero] <= (res[15:0] == 0) ? 1 : 0;
               regs[reg_flag][reg_flag_overflow] <= 0;
               regs[reg_flag][reg_flag_carry] <= 0;
            end
            'hczzz,
            'hdzzz,
            'hezzz: begin  //  AND, OR and XOR
               regs[reg_flag][reg_flag_sign] <= res[15];
               regs[reg_flag][reg_flag_zero] <= (res[15:0] == 0) ? 1 : 0;
               regs[reg_flag][reg_flag_overflow] <= ~^res[15:0];
               regs[reg_flag][reg_flag_carry] <= 0;
            end
            endcase // casez (ins)
         end // case: 'b1zzz_zzzz_zzzz_zzzz
         endcase // casez (ins)

         regs[reg_pc] <= next_ins_addr[15:0];
         if (do_memory_access)
            state <= S_BUS_RW;
         else
            start_instruction_fetch(next_ins_addr);

      end // case: S_FETCH_EXEC
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

endmodule


module h80cpu_mem(
   input wire clk,
   input wire reset,
   input wire bus_addr_t addr,
   input wire bus_cmd_t cmd,
   input wire run,
   input wire bus_data_t wr_data,
   output bus_data_t rd_data,
   output logic done
   );

   reg [15:0] mem[1024*32];  // 32K words
   int state = 0;

   initial begin
      done <= 0;
      /*
      mem['h0000] = I_LD_RL_I(0, 'h04);  // LD r0.l, 04h
      mem['h0001] = I_LD_RH_I(0, 'h00);  // LD r0.h, 00h
      mem['h0002] = I_LD_RL_I(1, 'h01);  // LD r1.l, 01h
      mem['h0003] = I_LD_RH_I(1, 'h00);  // LD r1.h, 00h
      mem['h0004] = I_LD_RL_I(2, 'h10);  // LD r2.l, 10h  LOOP0
      mem['h0005] = I_LD_RH_I(2, 'h00);  // LD r2.h, 00h
      mem['h0006] = I_LD_RL_I(3, 'h00);  // LD r3.l, 00h  work area
      mem['h0007] = I_LD_RH_I(3, 'h20);  // LD r3.h, 20h

      // LOOP0
      mem['h0008] = I_SUB(0, 0, 1);      // SUB r0, r0, r1
      mem['h0009] = I_LD_M_RW(3, 0);     // LD (r3), r0.w
      mem['h000a] = I_LD_M_RB(3, 0);     // LD (r3), r0.b
      mem['h000b] = I_LD_RL_I(0, 'hff);  // LD r0.l, FFh
      mem['h000c] = I_LD_RW_M(0, 3);     // LD r0.w, (r3)
      mem['h000d] = I_LD_RB_M(0, 3);     // LD r0.b, (r3)
      mem['h000e] = I_JP_NZ(2);          // JP NZ, (r2)
      mem['h000f] = I_NOP();             // NOP

      mem['h0010] = I_LD_RL_I(2, 'h2c);  // LD r2.l, 2ch  LOOP1
      mem['h0011] = I_LD_RH_I(2, 'h00);  // LD r2.h, 00h
      mem['h0012] = I_LD_RL_I(3, 'h20);  // LD r3.l, 20h  message
      mem['h0013] = I_LD_RH_I(3, 'h20);  // LD r3.h, 20h
      mem['h0014] = I_LD_RL_I(4, 'h00);  // LD r4.l, 00h  UART TX
      mem['h0015] = I_LD_RH_I(4, 'h00);  // LD r4.h, 00h

      // LOOP1
      mem['h0016] = I_LD_RB_M(0, 3);     // LD r0.l, (r3)
      mem['h0017] = I_OUTB(4, 0);        // OUTB (r4), r0
      mem['h0018] = I_ADD(3, 3, 1);      // ADD r3, r3, r1  r3 = r3 + 1
      mem['h0019] = I_ADD(0, 0, 0);      // ADD r0, r0, r0  r0 == 0 ?
      mem['h001a] = I_JP_NZ(2);          // JP NZ, (r2)

      mem['h001b] = I_HALT();            // HALT

      mem['h1000] = 'h0000;              // work area
      mem['h1010] = { "e", "H" };        // message
      mem['h1011] = { "l", "l" };
      mem['h1012] = { ",", "o" };
      mem['h1013] = { "w", " " };
      mem['h1014] = { "r", "o" };
      mem['h1015] = { "d", "l" };
      mem['h1016] = { 8'h0d, "!" };
      mem['h1017] = { 8'h00, 8'h0a };
       */

      mem['h0800] = 'h0444;  // I_SRA_R_I(4, 4)
      mem['h0801] = 'h0455;  // I_SRA_R_I(5, FRACBITS - 4)
      mem['h0802] = 'ha245;  // I_MUL(2, 4, 5)
      mem['h0803] = 'h0002;  // I_RET()
      mem['h0804] = 'h0178;  // I_LD_RW_I(8)
      mem['h0805] = 'h000a;  // 10
      mem['h0806] = 'hf448;  // I_CP(4, 4, 8)
      mem['h0807] = 'h0178;  // I_LD_RW_I(8)
      mem['h0808] = 'h0004;  // 4
      mem['h0809] = 'h03d8;  // I_JR_C(8)
      mem['h080a] = 'h0847;  // I_ADD_R_I(4, 7)
      mem['h080b] = 'h0178;  // I_LD_RW_I(8)
      mem['h080c] = 'h0030;  // 48
      mem['h080d] = 'h8448;  // I_ADD(4, 4, 8)
      mem['h080e] = 'h0178;  // I_LD_RW_I(8)
      mem['h080f] = 'h0000;  // 'h0000
      mem['h0810] = 'h3948;  // I_OUTB(8, 4)
      mem['h0811] = 'h0002;  // I_RET()
      mem['h0000] = 'h0170;  // I_LD_RW_I(0)
      mem['h0001] = 'h0000;  // 'h0000
      mem['h0002] = 'h3f20;  // I_LD_R_R(reg_sp, 0)
      mem['h0003] = 'h017e;  // I_LD_RW_I(CA)
      mem['h0004] = 'hfc7f;  // CA0
      mem['h0005] = 'h017f;  // I_LD_RW_I(CB)
      mem['h0006] = 'hfe08;  // CB0
      mem['h0007] = 'h0177;  // I_LD_RW_I(Y)
      mem['h0008] = 'h0018;  // HEIGHT
      mem['h0009] = 'h0871;  // I_ADD_R_I(Y, 1)
      mem['h000a] = 'h017e;  // I_LD_RW_I(CA)
      mem['h000b] = 'hfc7f;  // CA0
      mem['h000c] = 'h0176;  // I_LD_RW_I(X)
      mem['h000d] = 'h004e;  // WIDTH
      mem['h000e] = 'h0861;  // I_ADD_R_I(X, 1)
      mem['h000f] = 'h3cec;  // I_LD_R_R(A, CA)
      mem['h0010] = 'h3cfd;  // I_LD_R_R(B, CB)
      mem['h0011] = 'hebbb;  // I_XOR(I, I, I)
      mem['h0012] = 'h3cc4;  // I_LD_R_R(4, A)
      mem['h0013] = 'h3cc5;  // I_LD_R_R(5, A)
      mem['h0014] = 'h0170;  // I_LD_RW_I(0)
      mem['h0015] = 'h1000;  // label_fp_mul
      mem['h0016] = 'h01c0;  // I_CALL_R(0)
      mem['h0017] = 'h3c23;  // I_LD_R_R(T, 2)
      mem['h0018] = 'h3cd4;  // I_LD_R_R(4, B)
      mem['h0019] = 'h3cd5;  // I_LD_R_R(5, B)
      mem['h001a] = 'h0170;  // I_LD_RW_I(0)
      mem['h001b] = 'h1000;  // label_fp_mul
      mem['h001c] = 'h01c0;  // I_CALL_R(0)
      mem['h001d] = 'h9332;  // I_SUB(T, T, 2)
      mem['h001e] = 'h833e;  // I_ADD(T, T, CA)
      mem['h001f] = 'h3cc4;  // I_LD_R_R(4, A)
      mem['h0020] = 'h3cd5;  // I_LD_R_R(5, B)
      mem['h0021] = 'h0170;  // I_LD_RW_I(0)
      mem['h0022] = 'h1000;  // label_fp_mul
      mem['h0023] = 'h01c0;  // I_CALL_R(0)
      mem['h0024] = 'h0621;  // I_SL_R_I(2, 1)
      mem['h0025] = 'h8d2f;  // I_ADD(B, 2, CB)
      mem['h0026] = 'h3c3c;  // I_LD_R_R(A, T)
      mem['h0027] = 'h3cc4;  // I_LD_R_R(4, A)
      mem['h0028] = 'h3cc5;  // I_LD_R_R(5, A)
      mem['h0029] = 'h0170;  // I_LD_RW_I(0)
      mem['h002a] = 'h1000;  // label_fp_mul
      mem['h002b] = 'h01c0;  // I_CALL_R(0)
      mem['h002c] = 'h3c23;  // I_LD_R_R(T, 2)
      mem['h002d] = 'h3cd4;  // I_LD_R_R(4, B)
      mem['h002e] = 'h3cd5;  // I_LD_R_R(5, B)
      mem['h002f] = 'h0170;  // I_LD_RW_I(0)
      mem['h0030] = 'h1000;  // label_fp_mul
      mem['h0031] = 'h01c0;  // I_CALL_R(0)
      mem['h0032] = 'h8332;  // I_ADD(T, T, 2)
      mem['h0033] = 'h0170;  // I_LD_RW_I(0)
      mem['h0034] = 'h0800;  // FP4_0
      mem['h0035] = 'hf303;  // I_CP(T, 0, T)
      mem['h0036] = 'h0170;  // I_LD_RW_I(0)
      mem['h0037] = 'h0010;  // 16
      mem['h0038] = 'h0390;  // I_JR_NC(0)
      mem['h0039] = 'h3cb4;  // I_LD_R_R(4, I)
      mem['h003a] = 'h0170;  // I_LD_RW_I(0)
      mem['h003b] = 'h1008;  // label_put_pixel
      mem['h003c] = 'h01c0;  // I_CALL_R(0)
      mem['h003d] = 'h0170;  // I_LD_RW_I(0)
      mem['h003f] = 'h01e0;  // I_JP_R(0)
      mem['h0040] = 'h08b1;  // I_ADD_R_I(I, 1)
      mem['h0041] = 'h0170;  // I_LD_RW_I(0)
      mem['h0042] = 'h0010;  // 16
      mem['h0043] = 'hfbb0;  // I_CP(I, I, 0)
      mem['h0044] = 'h0170;  // I_LD_RW_I(0)
      mem['h0045] = 'h0024;  // label_loop_i
      mem['h0046] = 'h0350;  // I_JP_C(0)
      mem['h0047] = 'h0171;  // I_LD_RW_I(1)
      mem['h0048] = 'h0000;  // 'h0000
      mem['h0049] = 'h1020;  // I_LD_RL_I(0, 'h20)
      mem['h004a] = 'h3901;  // I_OUTB(1, 0)
      mem['h003e] = 'h0096;  // addr
      mem['h004b] = 'h0170;  // I_LD_RW_I(0)
      mem['h004c] = 'h0017;  // FP0_0458
      mem['h004d] = 'h8ee0;  // I_ADD(CA, CA, 0)
      mem['h004e] = 'h0961;  // I_SUB_R_I(X, 1)
      mem['h004f] = 'h0170;  // I_LD_RW_I(0)
      mem['h0050] = 'h001e;  // label_loop_x
      mem['h0051] = 'h0300;  // I_JP_NZ(0)
      mem['h0052] = 'h0170;  // I_LD_RW_I(0)
      mem['h0053] = 'h002a;  // FP0_0833
      mem['h0054] = 'h8ff0;  // I_ADD(CB, CB, 0)
      mem['h0055] = 'h0171;  // I_LD_RW_I(1)
      mem['h0056] = 'h0000;  // 'h0000
      mem['h0057] = 'h100d;  // I_LD_RL_I(0, 'h0d)
      mem['h0058] = 'h3901;  // I_OUTB(1, 0)
      mem['h0059] = 'h100a;  // I_LD_RL_I(0, 'h0a)
      mem['h005a] = 'h3901;  // I_OUTB(1, 0)
      mem['h005b] = 'h0971;  // I_SUB_R_I(Y, 1)
      mem['h005c] = 'h0170;  // I_LD_RW_I(0)
      mem['h005d] = 'h0014;  // label_loop_y
      mem['h005e] = 'h0300;  // I_JP_NZ(0)
      mem['h005f] = 'h0001;  // I_HALT()
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
