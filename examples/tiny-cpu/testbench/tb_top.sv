module main();

   `include "tb.svh"
   `include "tb_h80cpu.svh"

   task tb_test00();
      bus_data_t data;

      tb_begin("test00");
      cpu_init();

      mem_write('h0000, I_LD_RL_I(0, 'h04));  // LD r0.l, 04h
      mem_write('h0002, I_LD_RH_I(0, 'h00));  // LD r0.h, 00h
      mem_write('h0004, I_LD_RL_I(1, 'h01));  // LD r1.l, 01h
      mem_write('h0006, I_LD_RH_I(1, 'h00));  // LD r1.h, 00h
      mem_write('h0008, I_LD_RL_I(2, 'h12));  // LD r2.l, 12h
      mem_write('h000a, I_LD_RH_I(2, 'h00));  // LD r2.h, 00h
      mem_write('h000c, I_LD_RL_I(3, 'h00));  // LD r3.l, 00h
      mem_write('h000e, I_LD_RH_I(3, 'h20));  // LD r3.h, 20h
      mem_write('h0010, I_HALT());            // HALT

      mem_write('h0012, I_SUB(0, 0, 1));      // SUB r0, r0, r1
      mem_write('h0014, I_LD_M_RW(3, 0));     // LD (r3), r0.w
      mem_write('h0016, I_LD_M_RB(3, 0));     // LD (r3), r0.b
      mem_write('h0018, I_LD_RL_I(0, 'hff));  // LD r0.l, FFh
      mem_write('h001a, I_LD_RW_M(0, 3));     // LD r0.w, (r3)
      mem_write('h001c, I_LD_RB_M(0, 3));     // LD r0.b, (r3)
      mem_write('h001e, I_JP_NZ(2));          // JP NZ, (r2)
      mem_write('h0020, I_HALT());            // HALT

      cpu_run();
      `tb_assert(regs[reg_pc] === 'h0012);
      `tb_assert(regs[0] === 'h0004);
      `tb_assert(regs[1] === 'h0001);
      `tb_assert(regs[2] === 'h0012);
      `tb_assert(regs[3] === 'h2000);

      cpu_cont();
      `tb_assert(regs[reg_pc] === 'h0022);
      `tb_assert(regs[0] === 'h0000);
      mem_read(bus_addr_t'('h2000), data);
      `tb_assert(data === 'h0000);

      tb_end();

   endtask // tb_test00

   task tb_test_LD_r_nnnn();
      bus_data_t data;

      tb_begin("test_LD_r_nnnn");
      cpu_init();

      mem_write('h0000, I_LD_RW_I(0));        // LD r0.w, 1234h
      mem_write('h0002, 'h1234);
      mem_write('h0004, I_LD_RW_I(1));        // LD r1.w, 2000h
      mem_write('h0006, 'h2000);
      mem_write('h0008, I_HALT());            // HALT

      mem_write('h000a, I_LD_M_RW(1, 0));     // LD (r1), r0.w
      mem_write('h000c, I_LD_RW_I(0));        // LD r0.w, 5678h
      mem_write('h000e, 'h5678);
      mem_write('h0010, I_HALT());            // HALT

      mem_write('h2000, 'h0000);

      cpu_run();
      `tb_assert(regs[reg_pc] === 'h000a);
      `tb_assert(regs[0] === 'h1234);
      `tb_assert(regs[1] === 'h2000);
      mem_read('h2000, data);
      `tb_assert(data === 'h0000);

      cpu_cont();
      `tb_assert(regs[reg_pc] === 'h0012);
      `tb_assert(regs[0] === 'h5678);
      mem_read('h2000, data);
      `tb_assert(data === 'h1234);

      tb_end();

   endtask // tb_test_LD_r_nnnn

   task tb_test_move();
      bus_addr_t addr;
      bus_data_t data;

      tb_begin("test_move");
      cpu_init();

      addr = 'h0000;
      mem_write(addr, I_LD_RW_I(5));          // LD r5.w, ba98h
      addr += 2;
      mem_write(addr, 'hba98);
      addr += 2;
      mem_write(addr, I_LD_RW_I(6));          // LD r6.w, fedch
      addr += 2;
      mem_write(addr, 'hfedc);
      addr += 2;
      mem_write(addr, I_LD_RW_I(10));         // LD r10.w, 0000h
      addr += 2;
      mem_write(addr, 'h0000);
      addr += 2;
      mem_write(addr, I_LD_RW_I(11));         // LD r11.w, 0000h
      addr += 2;
      mem_write(addr, 'h0000);
      addr += 2;
      mem_write(addr, I_HALT());              // HALT
      addr += 2;

      cpu_run();
      `tb_assert(regs[reg_pc] === addr);
      `tb_assert(regs[5] === 'hba98);
      `tb_assert(regs[6] === 'hfedc);
      `tb_assert(regs[10] === 'h0000);
      `tb_assert(regs[11] === 'h0000);

      mem_write(addr, I_LD_R_R(22, 5));       // LD r22, r5
      addr += 2;
      mem_write(addr, I_LD_R_R(23, 6));       // LD r23, r6
      addr += 2;
      mem_write(addr, I_LD_R_R(10, 22));      // LD r10, r22
      addr += 2;
      mem_write(addr, I_LD_R_R(11, 23));      // LD r11, r23
      addr += 2;
      mem_write(addr, I_HALT());              // HALT
      addr += 2;

      cpu_cont();
      `tb_assert(regs[reg_pc] === addr);
      `tb_assert(regs[22] === 'hba98);
      `tb_assert(regs[23] === 'hfedc);
      `tb_assert(regs[10] === 'hba98);
      `tb_assert(regs[11] === 'hfedc);

      reg_dump(0, reg_numregs - 1);
      tb_end();

   endtask // tb_test_stack

   task tb_test_stack();
      bus_addr_t addr;
      bus_data_t data;

      tb_begin("test_stack");
      cpu_init();

      /*
       * PUSH and POP
       */
      addr = 'h0000;
      mem_write(addr, I_LD_RW_I(8));          // LD r8.w, 89abh
      addr += 2;
      mem_write(addr, 'h89ab);
      addr += 2;
      mem_write(addr, I_LD_RW_I(9));          // LD r9.w, cdefh
      addr += 2;
      mem_write(addr, 'hcdef);
      addr += 2;
      mem_write(addr, I_LD_RW_I(0));          // LD a0.w, 2000h
      addr += 2;
      mem_write(addr, 'h2000);
      addr += 2;
      mem_write(addr, I_LD_R_R(reg_sp, 0));   // LD sp, a0
      addr += 2;
      mem_write(addr, I_HALT());              // HALT
      addr += 2;

      mem_write('h1ffa, 'h0000);
      mem_write('h1ffc, 'h0000);
      mem_write('h1ffe, 'h0000);
      
      cpu_run();
      mem_dump('h1ff0, 16);
      reg_dump(0, reg_numregs - 1);
      `tb_assert(regs[reg_pc] === addr);
      `tb_assert(regs[8] === 'h89ab);
      `tb_assert(regs[9] === 'hcdef);
      `tb_assert(regs[reg_sp] === 'h2000);

      mem_write(addr, I_PUSH_R(8));           // PUSH (r8)
      addr += 2;
      mem_write(addr, I_PUSH_R(9));           // PUSH (r9)
      addr += 2;
      mem_write(addr, I_HALT());              // HALT
      addr += 2;

      cpu_cont();
      `tb_assert(regs[reg_pc] === addr);
      `tb_assert(regs[8] === 'h89ab);
      `tb_assert(regs[9] === 'hcdef);
      `tb_assert(regs[reg_sp] === 'h1ffc);
      mem_read('h1ffa, data);
      `tb_assert(data === 'h0000);
      mem_read('h1ffc, data);
      `tb_assert(data === 'hcdef);
      mem_read('h1ffe, data);
      `tb_assert(data === 'h89ab);

      mem_write(addr, I_POP_R(8));            // POP (r8)
      addr += 2;
      mem_write(addr, I_POP_R(9));            // POP (r9)
      addr += 2;
      mem_write(addr, I_HALT());              // HALT
      addr += 2;

      cpu_cont();
      `tb_assert(regs[reg_pc] === addr);
      `tb_assert(regs[8] === 'hcdef);
      `tb_assert(regs[9] === 'h89ab);
      `tb_assert(regs[reg_sp] === 'h2000);
      mem_read('h1ffa, data);
      `tb_assert(data === 'h0000);
      mem_read('h1ffc, data);
      `tb_assert(data === 'hcdef);
      mem_read('h1ffe, data);
      `tb_assert(data === 'h89ab);

      /*
       * CALL and RET
       */
      mem_write(addr, I_LD_RW_I(0));          // LD r0.w, 1000h
      addr += 2;
      mem_write(addr, 'h1000);
      addr += 2;
      mem_write(addr, I_LD_RW_I(7));          // LD r7.w, ffffh
      addr += 2;
      mem_write(addr, 'hffff);
      addr += 2;
      mem_write(addr, I_HALT());              // HALT
      addr += 2;

      cpu_cont();
      `tb_assert(regs[0] === 'h1000);
      `tb_assert(regs[7] === 'hffff);

      mem_write(addr, I_CALL_R(0));           // CALL (r0)
      addr += 2;
      mem_write(addr, I_HALT());              // HALT
      addr += 2;

      addr = 'h1000;
      mem_write(addr, I_LD_RW_I(7));          // LD r7.w, cdefh
      addr += 2;
      mem_write(addr, 'hcdef);
      addr += 2;
      mem_write(addr, I_RET());               // RET
      addr += 2;

      cpu_cont();
      `tb_assert(regs[7] === 'hcdef);

      tb_end();

   endtask // tb_test_stack

   task tb_test_1reg_opr(ins_t ins, reg_num_t r, reg_t prev, reg_t result);
      bus_addr_t addr;
      int saved_assertion_failures;
      string opr_name;

      saved_assertion_failures = tb_assertion_failures;

      casez (ins)
      16'b0000_0001_0010_zzzz: opr_name = "EXTNW";
      16'b0000_0001_0011_zzzz: opr_name = "EXTNB";
      16'b0000_0001_0100_zzzz: opr_name = "  CPL";
      16'b0000_0001_0101_zzzz: opr_name = "  NEG";
      16'b0000_0001_1000_zzzz: opr_name = " INVF";
      16'b0000_0001_1001_zzzz: opr_name = " SETF";
      16'b0000_0001_1010_zzzz: opr_name = " CLRF";
      16'b0000_0001_1011_zzzz: opr_name = "TESTF";
      endcase // casez (ins)

      $display("tb_test_1reg_opr: %s(%1d): %h -> %h", opr_name, ins[3:0], prev, result);

      cpu_init();
      addr = 'h0000;
      mem_write(addr, I_LD_RW_I(0));          // LD r0, prev
      addr += 2;
      mem_write(addr, prev);
      addr += 2;
      mem_write(addr, I_LD_R_R(r, 0));        // LD r, r0
      addr += 2;
      mem_write(addr, I_HALT());              // HALT
      addr += 2;

      cpu_run();
      `tb_assert(regs[reg_pc] === addr);
      if (r == reg_flag)
        `tb_assert((regs[r] & 16'hfeff) === prev); // ignore halt flag
      else
        `tb_assert(regs[r] === prev);

      mem_write(addr, ins);                   // instruction under test
      addr += 2;
      mem_write(addr, I_HALT());              // HALT
      addr += 2;

      cpu_cont();
      `tb_assert(regs[reg_pc] === addr);
      if (r == reg_flag)
        `tb_assert((regs[r] & 16'hfeff) === result); // ignore halt flag
      else
        `tb_assert(regs[r] === result);

      if (saved_assertion_failures != tb_assertion_failures) begin
         $display("tb_test_1reg_opr: %s: r%0d = %h (%h expected)", opr_name, r, regs[r], result);
      end
   endtask // tb_test_1reg_opr

   task tb_test_1reg_oprs();
      tb_begin("test_1reg_oprs");
      //               instruction     reg num   before  after
      tb_test_1reg_opr(I_EXTN_RB(0),          0, 'h0074, 'h0074);
      tb_test_1reg_opr(I_EXTN_RB(0),          0, 'h8774, 'h0074);
      tb_test_1reg_opr(I_EXTN_RB(0),          0, 'h0098, 'hff98);
      tb_test_1reg_opr(I_EXTN_RB(0),          0, 'h1298, 'hff98);

      tb_test_1reg_opr(I_CPL_R(0),            0, 'h0000, 'hffff);
      tb_test_1reg_opr(I_CPL_R(0),            0, 'hffff, 'h0000);
      tb_test_1reg_opr(I_CPL_R(0),            0, 'h7171, 'h8e8e);

      tb_test_1reg_opr(I_NEG_R(0),            0,      1,     -1);
      tb_test_1reg_opr(I_NEG_R(0),            0,     -8,      8);
      tb_test_1reg_opr(I_NEG_R(0),            0, -12345,  12345);

      tb_test_1reg_opr(I_INVF(0),      reg_flag, 'h0000, 'h0001);
      tb_test_1reg_opr(I_INVF(1),      reg_flag, 'h0000, 'h0002);
      tb_test_1reg_opr(I_INVF(4),      reg_flag, 'h0000, 'h0010);
      tb_test_1reg_opr(I_INVF(7),      reg_flag, 'h0000, 'h0080);
      tb_test_1reg_opr(I_INVF(2),      reg_flag, 'h0004, 'h0000);
      tb_test_1reg_opr(I_INVF(3),      reg_flag, 'h0008, 'h0000);
      tb_test_1reg_opr(I_INVF(5),      reg_flag, 'h0020, 'h0000);
      tb_test_1reg_opr(I_INVF(6),      reg_flag, 'h0040, 'h0000);

      tb_test_1reg_opr(I_SETF(0),      reg_flag, 'h0000, 'h0001);
      tb_test_1reg_opr(I_SETF(1),      reg_flag, 'h0000, 'h0002);
      tb_test_1reg_opr(I_SETF(4),      reg_flag, 'h0000, 'h0010);
      tb_test_1reg_opr(I_SETF(7),      reg_flag, 'h0000, 'h0080);
      tb_test_1reg_opr(I_SETF(2),      reg_flag, 'h0004, 'h0004);
      tb_test_1reg_opr(I_SETF(3),      reg_flag, 'h0008, 'h0008);
      tb_test_1reg_opr(I_SETF(5),      reg_flag, 'h0020, 'h0020);
      tb_test_1reg_opr(I_SETF(6),      reg_flag, 'h0040, 'h0040);

      tb_test_1reg_opr(I_CLRF(0),      reg_flag, 'h000f, 'h000e);
      tb_test_1reg_opr(I_CLRF(1),      reg_flag, 'h000f, 'h000d);
      tb_test_1reg_opr(I_CLRF(4),      reg_flag, 'h00ff, 'h00ef);
      tb_test_1reg_opr(I_CLRF(7),      reg_flag, 'h00ff, 'h007f);
      tb_test_1reg_opr(I_CLRF(2),      reg_flag, 'h00f0, 'h00f0);
      tb_test_1reg_opr(I_CLRF(3),      reg_flag, 'h00f0, 'h00f0);
      tb_test_1reg_opr(I_CLRF(5),      reg_flag, 'h000f, 'h000f);
      tb_test_1reg_opr(I_CLRF(6),      reg_flag, 'h000f, 'h000f);

      tb_test_1reg_opr(I_TESTF(0),     reg_flag, 'h0001, 'h0000);
      tb_test_1reg_opr(I_TESTF(1),     reg_flag, 'h000f, 'h000e);
      tb_test_1reg_opr(I_TESTF(4),     reg_flag, 'h00ff, 'h00fe);
      tb_test_1reg_opr(I_TESTF(7),     reg_flag, 'h00ff, 'h00fe);
      tb_test_1reg_opr(I_TESTF(2),     reg_flag, 'h00f0, 'h00f1);
      tb_test_1reg_opr(I_TESTF(3),     reg_flag, 'h00f0, 'h00f1);
      tb_test_1reg_opr(I_TESTF(5),     reg_flag, 'h000f, 'h000f);
      tb_test_1reg_opr(I_TESTF(6),     reg_flag, 'h000f, 'h000f);

      tb_end();
   endtask // tb_test_1reg_oprs

   task tb_test_operation(ins_t ins, reg_t flags, dst, a, string opr, reg_t b, bit z, c, o, s);
      bus_addr_t addr;
      int saved_assertion_failures;
      string opr_name;

      saved_assertion_failures = tb_assertion_failures;

      casez (ins)
      'h8zzz: opr_name = "ADD";
      'h9zzz: opr_name = "SUB";
      'hazzz: opr_name = "ADC";
      'hbzzz: opr_name = "SBC";
      'hczzz: opr_name = "AND";
      'hdzzz: opr_name = " OR";
      'hezzz: opr_name = "XOR";
      'hfzzz: opr_name = " CP";
      endcase
      
      $display("tb_test_operation: %s %d:%h = %d:%h %s %d:%h %s%s%s%s",
               opr_name, ins[11:8], dst, ins[7:4], a, opr, ins[3:0], b,
               z ? "Z" : "_",  c ? "C" : "_", o ? "O" : "_",  s ? "S" : "_" );

      cpu_init();
      addr = 'h0000;
      mem_write(addr, I_LD_RW_I(0));          // LD r0, flags
      addr += 2;
      mem_write(addr, flags);
      addr += 2;
      mem_write(addr, I_LD_RW_I(ins[11:8]));  // LD dst, beefh
      addr += 2;
      mem_write(addr, 'hbeef);
      addr += 2;
      mem_write(addr, I_LD_R_R(reg_flag, 0)); // LD F, r0
      addr += 2;
      mem_write(addr, I_LD_RW_I(ins[7:4]));   // LD a
      addr += 2;
      mem_write(addr, a);
      addr += 2;
      mem_write(addr, I_LD_RW_I(ins[3:0]));   // LD b
      addr += 2;
      mem_write(addr, b);
      addr += 2;
      mem_write(addr, I_HALT());              // HALT
      addr += 2;

      cpu_run();
      `tb_assert(regs[reg_pc] === addr);
      `tb_assert(regs[ins[7:4]] === a);
      `tb_assert(regs[ins[3:0]] === b);

      mem_write(addr, ins);                   // three register operation
      addr += 2;
      mem_write(addr, I_HALT());              // HALT
      addr += 2;

      cpu_cont();
      `tb_assert(regs[reg_pc] === addr);
      if (ins[15:12] == 'hf) begin
         `tb_assert(regs[ins[11:8]] === 'hbeef);
      end else begin
         `tb_assert(regs[ins[11:8]] === dst);
      end
      `tb_assert(z == regs[reg_flag][reg_flag_zero]);   // equal zero
      `tb_assert(c == regs[reg_flag][reg_flag_carry]);  // carry / borrow
      `tb_assert(o == regs[reg_flag][reg_flag_parity]); // parity even / overflow
      `tb_assert(s == regs[reg_flag][reg_flag_sign]);   // negitive / positive

      if (saved_assertion_failures != tb_assertion_failures) begin
         reg_dump(0, reg_numregs - 1);
      end
      
   endtask // tb_tgest_operation
   
   task tb_test_oprations();
      tb_begin("test_operations");
      //                instruction     flags   result  a       opr  b       z  c  o  s
      tb_test_operation(I_ADD(0, 8, 9), 'hd000, 'hd000, 'hc000, "+", 'h1000, 0, 0, 0, 1);
      tb_test_operation(I_ADD(0, 8, 9), 'h0000, 'h1000, 'hc000, "+", 'h5000, 0, 1, 0, 0);
      tb_test_operation(I_ADD(0, 8, 9), 'h0000, 'h0000, 'hc000, "+", 'h4000, 1, 1, 0, 0);
      tb_test_operation(I_ADD(0, 8, 9), 'h0000, 'h9000, 'h5000, "+", 'h4000, 0, 0, 1, 1);

      tb_test_operation(I_SUB(1, 2, 3), 'h0000, 'h00f0, 'h0100, "-", 'h0010, 0, 0, 0, 0);
      tb_test_operation(I_SUB(1, 2, 3), 'h0000, 'h00e0, 'h0100, "-", 'h0020, 0, 0, 0, 0);
      tb_test_operation(I_SUB(3, 4, 5), 'h0000, 'hff00, 'h0100, "-", 'h0200, 0, 1, 0, 1);
      tb_test_operation(I_SUB(3, 4, 5), 'h0000, 'h0000, 'h0100, "-", 'h0100, 1, 0, 0, 0);
      tb_test_operation(I_SUB(3, 4, 5), 'h0000, 'hd000, 'h7000, "-", 'ha000, 0, 1, 1, 1);

      tb_test_operation(I_ADC(3, 4, 5), 'h0000, 'h2234, 'h1234, "+", 'h1000, 0, 0, 0, 0);
      tb_test_operation(I_ADC(3, 4, 5), 'h0002, 'h2235, 'h1234, "+", 'h1000, 0, 0, 0, 0);
      tb_test_operation(I_ADC(3, 4, 5), 'h0000, 'hffff, 'h7fff, "+", 'h8000, 0, 0, 0, 1);
      tb_test_operation(I_ADC(3, 4, 5), 'h0002, 'h0000, 'h7fff, "+", 'h8000, 1, 1, 0, 0);

      tb_test_operation(I_SBC(3, 4, 5), 'h0000, 'h0234, 'h1234, "-", 'h1000, 0, 0, 0, 0);
      tb_test_operation(I_SBC(3, 4, 5), 'h0002, 'h0233, 'h1234, "-", 'h1000, 0, 0, 0, 0);
      tb_test_operation(I_SBC(3, 4, 5), 'h0000, 'hffff, 'h7fff, "-", 'h8000, 0, 1, 1, 1);
      tb_test_operation(I_SBC(3, 4, 5), 'h0002, 'hffff, 'h7fff, "-", 'h7fff, 0, 1, 0, 1);

      tb_test_operation(I_CP (1, 2, 3), 'h0000, 'h00f0, 'h0100, "-", 'h0010, 0, 0, 0, 0);
      tb_test_operation(I_CP (1, 2, 3), 'h0000, 'h00e0, 'h0100, "-", 'h0020, 0, 0, 0, 0);
      tb_test_operation(I_CP (3, 4, 5), 'h0000, 'hff00, 'h0100, "-", 'h0200, 0, 1, 0, 1);
      tb_test_operation(I_CP (3, 4, 5), 'h0000, 'h0000, 'h0100, "-", 'h0100, 1, 0, 0, 0);
      tb_test_operation(I_CP (3, 4, 5), 'h0000, 'hd000, 'h7000, "-", 'ha000, 0, 1, 1, 1);

      //                instruction     flags   result  a       opr  b       z  c  p  s
      tb_test_operation(I_AND(6, 1, 3), 'h0000, 'h0000, 'ha5a5, "&", 'h5a5a, 1, 0, 1, 0);
      tb_test_operation(I_AND(6, 1, 3), 'h0000, 'ha500, 'ha5a5, "&", 'hff00, 0, 0, 1, 1);
      tb_test_operation(I_AND(6, 1, 3), 'h0000, 'h0808, 'ha8a8, "&", 'h5a5a, 0, 0, 1, 0);
      tb_test_operation(I_AND(6, 1, 3), 'h0000, 'ha800, 'ha8a8, "&", 'hff00, 0, 0, 0, 1);

      tb_test_operation(I_OR (6, 1, 3), 'h0000, 'hffff, 'ha5a5, "&", 'h5a5a, 0, 0, 1, 1);
      tb_test_operation(I_OR (6, 1, 3), 'h0000, 'hffa5, 'ha5a5, "&", 'hff00, 0, 0, 1, 1);
      tb_test_operation(I_OR (6, 1, 3), 'h0000, 'hfafa, 'ha8a8, "&", 'h5a5a, 0, 0, 1, 1);
      tb_test_operation(I_OR (6, 1, 3), 'h0000, 'hffa8, 'ha8a8, "&", 'hff00, 0, 0, 0, 1);

      tb_test_operation(I_XOR(6, 1, 3), 'h0000, 'hffff, 'ha5a5, "&", 'h5a5a, 0, 0, 1, 1);
      tb_test_operation(I_XOR(6, 1, 3), 'h0000, 'h5aa5, 'ha5a5, "&", 'hff00, 0, 0, 1, 0);
      tb_test_operation(I_XOR(6, 1, 3), 'h0000, 'hf2f2, 'ha8a8, "&", 'h5a5a, 0, 0, 1, 1);
      tb_test_operation(I_XOR(6, 1, 3), 'h0000, 'h57a8, 'ha8a8, "&", 'hff00, 0, 0, 1, 0);

      tb_end();

   endtask // tb_test_oprations

   task tb_test_jump(ins_t jump_flag_ins, jump_ins, bus_addr_t jump_addr, jump_result = -1,
                     ins_t ret_flag_ins = I_NOP(), ret_ins = I_NOP(), bit ret = 1);
      bus_addr_t addr, return_addr, not_return_addr;
      string ins_name;
      int saved_assertion_failures;

      casez (jump_ins)
      'h01cz: ins_name = "CALL";
      'h01dz: ins_name = " RST";
      'h01ez: ins_name = "  JP";
      'h01fz: ins_name = "  JR";
      endcase

      $display("test_jump: %s %h", ins_name, jump_addr);
      
      cpu_init();

      addr = 'h0000;                          // start address (reset address)
      mem_write(addr, I_LD_RW_I(0));          // set stack pointer
      addr += 2;
      mem_write(addr, 'h0000);
      addr += 2;
      mem_write(addr, I_LD_R_R(reg_sp, 0));
      addr += 2;
      mem_write(addr, I_LD_RW_I(0));          // LD r0, 8000h + 8h
      addr += 2;
      mem_write(addr, 'h8000 - 8);
      addr += 2;
      mem_write(addr, I_JP_R(0));             // jump to 8000h + 8h
      addr += 2;

      addr = 'h8000 - 8;
      mem_write(addr, I_HALT());              // HALT
      addr += 2;

      cpu_run();

      if (jump_result != -1) begin
         bus_addr_t addr;
         addr = jump_result;
         mem_write(addr, I_HALT());              // HALT
         addr += 2;
         mem_write(addr, ret_flag_ins);          // set / clear flag
         addr += 2;
         mem_write(addr, ret_ins);               // RETx
         addr += 2;
         mem_write(addr, I_HALT());              // HALT
         addr += 2;
         not_return_addr = addr;
      end

      mem_write(addr, I_LD_RW_I(jump_ins[3:0])); // load jump addr
      addr += 2;
      mem_write(addr, jump_addr);
      addr += 2;
      mem_write(addr, jump_flag_ins);         // set / clear flag
      addr += 2;
      mem_write(addr, jump_ins);              // jump
      addr += 2;
      mem_write(addr, I_HALT());              // HALT
      addr += 2;
      return_addr = addr;

      cpu_cont();
      saved_assertion_failures = tb_assertion_failures;
      if (jump_result != bus_addr_t'(-1))
         `tb_assert(regs[reg_pc] == jump_result + bus_addr_t'(2));
      else
         `tb_assert(regs[reg_pc] == return_addr);
      if (saved_assertion_failures != tb_assertion_failures)
         reg_dump(0, reg_numregs - 1);

      if (ret_ins == I_NOP())
        return;

      cpu_cont();
      saved_assertion_failures = tb_assertion_failures;
      if (ret)
         `tb_assert(regs[reg_pc] === return_addr);
      else
         `tb_assert(regs[reg_pc] === not_return_addr);
      if (saved_assertion_failures != tb_assertion_failures)
         reg_dump(0, reg_numregs - 1);

   endtask // tb_test_jump

   task tb_test_jumps();
      tb_begin("test_jumps");
      cpu_init();
      mem_fill('h0000, I_HALT(), 'h10000);

      //           flag    	jump		address	result  ret flag     ret ins    0=not ret
      // CALL (R)
      tb_test_jump(I_NOP(),     I_CALL_R(0),    'h3000, 'h3000);
      tb_test_jump(I_NOP(),     I_CALL_R(0),    'h3000, 'h3000, I_NOP(),     I_RET());
      tb_test_jump(I_CLRF(0),   I_CALL_Z(0),    'h3000);
      tb_test_jump(I_SETF(0),   I_CALL_Z(0),    'h3000, 'h3000);
      tb_test_jump(I_NOP(),     I_CALL_R(0),    'h3000, 'h3000, I_CLRF(0),   I_RET_Z(), 0);
      tb_test_jump(I_NOP(),     I_CALL_R(0),    'h3000, 'h3000, I_SETF(0),   I_RET_Z(), 1);

      // RST n
      tb_test_jump(I_NOP(),     I_RST_N('h00),  'h0000, 'h0000, I_NOP(),     I_RET());
      tb_test_jump(I_NOP(),     I_RST_N('h08),  'h0008, 'h0008, I_NOP(),     I_RET());
      tb_test_jump(I_NOP(),     I_RST_N('h10),  'h0010, 'h0010, I_NOP(),     I_RET());
      tb_test_jump(I_NOP(),     I_RST_N('h18),  'h0018, 'h0018, I_NOP(),     I_RET());
      tb_test_jump(I_NOP(),     I_RST_N('h20),  'h0020, 'h0020, I_NOP(),     I_RET());
      tb_test_jump(I_NOP(),     I_RST_N('h28),  'h0028, 'h0028, I_NOP(),     I_RET());
      tb_test_jump(I_NOP(),     I_RST_N('h30),  'h0030, 'h0030, I_NOP(),     I_RET());
      tb_test_jump(I_NOP(),     I_RST_N('h38),  'h0038, 'h0038, I_NOP(),     I_RET());
      tb_test_jump(I_NOP(),     I_RST_N('h78),  'h0078, 'h0078, I_NOP(),     I_RET());

      // JP (R)
      tb_test_jump(I_NOP(),     I_JP_R(0),      'h2000, 'h2000);
      tb_test_jump(I_NOP(),     I_JP_R(0),      'ha000, 'ha000);

      // JR (R)
      tb_test_jump(I_NOP(),     I_JR_R(0),      'h1000, 'h9000);
      tb_test_jump(I_NOP(),     I_JR_R(0),      'hf000, 'h7000);

      // JP cc, (R)
      tb_test_jump(I_CLRF(0),   I_JP_Z(0),      'h2000);
      tb_test_jump(I_SETF(0),   I_JP_Z(0),      'h2000, 'h2000);
      tb_test_jump(I_CLRF(0),   I_JP_Z(0),      'ha000);
      tb_test_jump(I_SETF(0),   I_JP_Z(0),      'ha000, 'ha000);

      // JR cc, (R)
      tb_test_jump(I_CLRF(0),   I_JR_Z(0),      'h1000);
      tb_test_jump(I_SETF(0),   I_JR_Z(0),      'h1000, 'h9000);
      tb_test_jump(I_CLRF(0),   I_JR_Z(0),      'hf000);
      tb_test_jump(I_SETF(0),   I_JR_Z(0),      'hf000, 'h7000);

      tb_test_jump(I_SETF(0),   I_JR_NZ(0),     'h1000);
      tb_test_jump(I_CLRF(0),   I_JR_NZ(0),     'h1000, 'h9000);
      tb_test_jump(I_SETF(0),   I_JR_NZ(0),     'hf000);
      tb_test_jump(I_CLRF(0),   I_JR_NZ(0),     'hf000, 'h7000);

      tb_end();
   endtask // tb_test_jumps

   initial begin
      tb_init();
      tb_test00();
      tb_test_LD_r_nnnn();
      tb_test_move();
      tb_test_stack();
      tb_test_1reg_oprs();
      tb_test_oprations();
      tb_test_jumps();
      tb_finish();
   end

endmodule
