module main();

   `include "tb.svh"
   `include "tb_h80cpu.svh"
   `include "h80cpu_instmacros.svh"

   task tb_test_rom();

      tb_begin("test_rom");
      cpu_init();
      cpu_run();
      tb_end();

   endtask // tb_test_rom

   task tb_test00();
      bus_data_t data;

      tb_begin("test00");
      cpu_init();

      mem_write('h0000, I_LD_RB_I(0, 'h04));  // LD r0, 04h
      mem_write('h0002, I_LD_RB_I(1, 'h01));  // LD r1, 01h
      mem_write('h0004, I_LD_RB_I(2, 'h0c));  // LD r2, 0ch
      mem_write('h0006, I_LD_RW_I(3));        // LD r3, 2000h
      mem_write('h0008, 16'h2000);
      mem_write('h000a, I_HALT());            // HALT

      cpu_run();
      `tb_assert(regs(reg_pc) === 'h000c);
      `tb_assert(regs(0) === 'h0004);
      `tb_assert(regs(1) === 'h0001);
      `tb_assert(regs(2) === 'h000c);
      `tb_assert(regs(3) === 'h2000);

      mem_write('h000c, I_SUB(0, 0, 1));      // SUB r0, r0, r1
      mem_write('h000e, I_LD_M_RW(3, 0));     // LD (r3), r0.w
      mem_write('h0010, I_LD_M_RB(3, 0));     // LD (r3), r0.b
      mem_write('h0012, I_LD_RB_I(0, 'hff));  // LD r0, 00FFh
      mem_write('h0014, I_LD_RW_M(0, 3));     // LD r0.w, (r3)
      mem_write('h0016, I_LD_RB_M(0, 3));     // LD r0.b, (r3)
      mem_write('h0018, I_JP_NZ(2));          // JP NZ, (r2)
      mem_write('h001a, I_HALT());            // HALT

      cpu_cont();
      `tb_assert(regs(reg_pc) === 'h001c);
      `tb_assert(regs(0) === 'h0000);
      mem_read(bus_addr_t'('h2000), data);
      `tb_assert(data === 'h0000);

      tb_end();

   endtask // tb_test00

   task tb_test_dump_inst();
      bus_addr_t addr;

      tb_begin("test_dump_inst");

      cpu_init();

      addr = 'h0000;
      `cpu_mem(addr, I_NOP());
      `cpu_mem(addr, I_HALT());
      `cpu_mem(addr, I_RET());
      // 0000_0000_0000_0011 to 0111_1110 reserved
      `cpu_mem(addr, I_INV());
      `cpu_mem(addr, I_RET_N_(reg_flag_zero));
      `cpu_mem(addr, I_RET_N_(reg_flag_carry));
      `cpu_mem(addr, I_RET_N_(reg_flag_overflow));
      `cpu_mem(addr, I_RET_N_(reg_flag_parity));
      `cpu_mem(addr, I_RET_N_(reg_flag_sign));
      `cpu_mem(addr, I_RET_(reg_flag_zero));
      `cpu_mem(addr, I_RET_(reg_flag_carry));
      `cpu_mem(addr, I_RET_(reg_flag_overflow));
      `cpu_mem(addr, I_RET_(reg_flag_parity));
      `cpu_mem(addr, I_RET_(reg_flag_sign));
      // 0000_0000_1000_1000 to 1110_1111 reserved
      `cpu_mem(addr, I_LD_R_I(0));
      `cpu_mem(addr, 16'h3210);
      `cpu_mem(addr, 16'h7654);
      `cpu_mem(addr, I_LD_R_I(5));
      `cpu_mem(addr, 16'hba98);
      `cpu_mem(addr, 16'hfedc);
      `cpu_mem(addr, I_LD_R_I(10));
      `cpu_mem(addr, 16'h1032);
      `cpu_mem(addr, 16'h5476);
      `cpu_mem(addr, I_LD_R_I(15));
      `cpu_mem(addr, 16'h98ba);
      `cpu_mem(addr, 16'hdcfe);
      `cpu_mem(addr, I_PUSH_R(0));
      `cpu_mem(addr, I_PUSH_R(5));
      `cpu_mem(addr, I_PUSH_R(10));
      `cpu_mem(addr, I_PUSH_R(15));
      `cpu_mem(addr, I_POP_R(0));
      `cpu_mem(addr, I_POP_R(5));
      `cpu_mem(addr, I_POP_R(10));
      `cpu_mem(addr, I_POP_R(15));
      `cpu_mem(addr, I_EXTN_RW(0));
      `cpu_mem(addr, I_EXTN_RW(5));
      `cpu_mem(addr, I_EXTN_RW(10));
      `cpu_mem(addr, I_EXTN_RW(15));
      `cpu_mem(addr, I_EXTN_RB(0));
      `cpu_mem(addr, I_EXTN_RB(5));
      `cpu_mem(addr, I_EXTN_RB(10));
      `cpu_mem(addr, I_EXTN_RB(15));
      `cpu_mem(addr, I_CPL_R(0));
      `cpu_mem(addr, I_CPL_R(5));
      `cpu_mem(addr, I_CPL_R(10));
      `cpu_mem(addr, I_CPL_R(15));
      `cpu_mem(addr, I_NEG_R(0));
      `cpu_mem(addr, I_NEG_R(5));
      `cpu_mem(addr, I_NEG_R(10));
      `cpu_mem(addr, I_NEG_R(15));
      `cpu_mem(addr, I_LD_RW_I(0));
      `cpu_mem(addr, 16'h3210);
      `cpu_mem(addr, I_LD_RW_I(5));
      `cpu_mem(addr, 16'h7654);
      `cpu_mem(addr, I_LD_RW_I(10));
      `cpu_mem(addr, 16'h1032);
      `cpu_mem(addr, I_LD_RW_I(15));
      `cpu_mem(addr, 16'h5476);
      `cpu_mem(addr, I_LD_RW_SI(0));
      `cpu_mem(addr, 16'h3210);
      `cpu_mem(addr, I_LD_RW_SI(5));
      `cpu_mem(addr, 16'h7654);
      `cpu_mem(addr, I_LD_RW_SI(10));
      `cpu_mem(addr, 16'h1032);
      `cpu_mem(addr, I_LD_RW_SI(15));
      `cpu_mem(addr, 16'h5476);
      `cpu_mem(addr, I_INVF(0));
      `cpu_mem(addr, I_INVF(5));
      `cpu_mem(addr, I_INVF(10));
      `cpu_mem(addr, I_INVF(15));
      `cpu_mem(addr, I_SETF(0));
      `cpu_mem(addr, I_SETF(5));
      `cpu_mem(addr, I_SETF(10));
      `cpu_mem(addr, I_SETF(15));
      `cpu_mem(addr, I_CLRF(0));
      `cpu_mem(addr, I_CLRF(5));
      `cpu_mem(addr, I_CLRF(10));
      `cpu_mem(addr, I_CLRF(15));
      `cpu_mem(addr, I_TESTF(0));
      `cpu_mem(addr, I_TESTF(5));
      `cpu_mem(addr, I_TESTF(10));
      `cpu_mem(addr, I_TESTF(15));
      `cpu_mem(addr, I_CALL_R(0));
      `cpu_mem(addr, I_CALL_R(5));
      `cpu_mem(addr, I_CALL_R(10));
      `cpu_mem(addr, I_CALL_R(15));
      `cpu_mem(addr, I_RST_N(8'h00));
      `cpu_mem(addr, I_RST_N(8'h08));
      `cpu_mem(addr, I_RST_N(8'h20));
      `cpu_mem(addr, I_RST_N(8'h38));
      `cpu_mem(addr, I_JP_R(0));
      `cpu_mem(addr, I_JP_R(5));
      `cpu_mem(addr, I_JP_R(10));
      `cpu_mem(addr, I_JP_R(15));
      `cpu_mem(addr, I_JR_R(0));
      `cpu_mem(addr, I_JR_R(5));
      `cpu_mem(addr, I_JR_R(10));
      `cpu_mem(addr, I_JR_R(15));
      `cpu_mem(addr, I_CALL_N_(reg_flag_zero, 0));
      `cpu_mem(addr, I_CALL_N_(reg_flag_carry, 5));
      `cpu_mem(addr, I_CALL_N_(reg_flag_overflow, 10));
      `cpu_mem(addr, I_CALL_N_(reg_flag_parity, 15));
      `cpu_mem(addr, I_CALL_N_(reg_flag_sign, 0));
      `cpu_mem(addr, I_CALL_(reg_flag_zero, 0));
      `cpu_mem(addr, I_CALL_(reg_flag_carry, 5));
      `cpu_mem(addr, I_CALL_(reg_flag_overflow, 10));
      `cpu_mem(addr, I_CALL_(reg_flag_parity, 15));
      `cpu_mem(addr, I_CALL_(reg_flag_sign, 0));
      //  0 0010_10ff_rrrr reserved
      //  0 0010_11ff_rrrr reserved
      `cpu_mem(addr, I_JP_NZ(0));
      `cpu_mem(addr, I_JP_NC(5));
      `cpu_mem(addr, I_JP_NV(10));
      `cpu_mem(addr, I_JP_NP(15));
      `cpu_mem(addr, I_JP_NS(0));

      `cpu_mem(addr, I_JP_Z (0));
      `cpu_mem(addr, I_JP_C (5));
      `cpu_mem(addr, I_JP_V (10));
      `cpu_mem(addr, I_JP_P (15));
      `cpu_mem(addr, I_JP_S (0));

      `cpu_mem(addr, I_JR_NZ(0));
      `cpu_mem(addr, I_JR_NC(5));
      `cpu_mem(addr, I_JR_NV(10));
      `cpu_mem(addr, I_JR_NP(15));
      `cpu_mem(addr, I_JR_NS(0));

      `cpu_mem(addr, I_JR_Z (0));
      `cpu_mem(addr, I_JR_C (5));
      `cpu_mem(addr, I_JR_V (10));
      `cpu_mem(addr, I_JR_P (15));
      `cpu_mem(addr, I_JR_S (0));

      `cpu_mem(addr, I_SRA_R_I(0, 15));
      `cpu_mem(addr, I_SRA_R_I(5, 10));
      `cpu_mem(addr, I_SRA_R_I(10, 5));
      `cpu_mem(addr, I_SRA_R_I(15, 0));
      `cpu_mem(addr, I_SRL_R_I(0, 15));
      `cpu_mem(addr, I_SRL_R_I(5, 10));
      `cpu_mem(addr, I_SRL_R_I(10, 5));
      `cpu_mem(addr, I_SRL_R_I(15, 0));
      `cpu_mem(addr, I_SL_R_I (0, 15));
      `cpu_mem(addr, I_SL_R_I (5, 10));
      `cpu_mem(addr, I_SL_R_I (10, 5));
      `cpu_mem(addr, I_SL_R_I (15, 0));
      `cpu_mem(addr, I_RLC_R_I(0, 15));
      `cpu_mem(addr, I_RLC_R_I(5, 10));
      `cpu_mem(addr, I_RLC_R_I(10, 5));
      `cpu_mem(addr, I_RLC_R_I(15, 0));

      `cpu_mem(addr, I_ADD_R_I(0, 15));
      `cpu_mem(addr, I_ADD_R_I(5, 10));
      `cpu_mem(addr, I_ADD_R_I(10, 5));
      `cpu_mem(addr, I_ADD_R_I(15, 0));
      `cpu_mem(addr, I_SUB_R_I(0, 15));
      `cpu_mem(addr, I_SUB_R_I(5, 10));
      `cpu_mem(addr, I_SUB_R_I(10, 5));
      `cpu_mem(addr, I_SUB_R_I(15, 0));

      `cpu_mem(addr, I_DJNZ(0, 15));
      `cpu_mem(addr, I_DJNZ(5, 10));
      `cpu_mem(addr, I_DJNZ(10, 5));
      `cpu_mem(addr, I_DJNZ(15, 0));
      `cpu_mem(addr, I_EX_R_R(0,  31));
      `cpu_mem(addr, I_EX_R_R(5,  30));
      `cpu_mem(addr, I_EX_R_R(10, 25));
      `cpu_mem(addr, I_EX_R_R(15, 20));
      `cpu_mem(addr, I_EX_R_R(20, 15));
      `cpu_mem(addr, I_EX_R_R(25, 10));
      `cpu_mem(addr, I_EX_R_R(30, 5));
      `cpu_mem(addr, I_EX_R_R(31, 0));
      //  0 1110_aaaa_bbbb reserved
      //  0 1111_aaaa_bbbb reserved

      `cpu_mem(addr, I_LD_RB_I(0,  8'hff));
      `cpu_mem(addr, I_LD_RB_I(5,  8'ha5));
      `cpu_mem(addr, I_LD_RB_I(10, 8'h5a));
      `cpu_mem(addr, I_LD_RB_I(15, 8'h00));
      `cpu_mem(addr, I_LD_RB_SI(0,  8'hff));
      `cpu_mem(addr, I_LD_RB_SI(5,  8'ha5));
      `cpu_mem(addr, I_LD_RB_SI(10, 8'h5a));
      `cpu_mem(addr, I_LD_RB_SI(15, 8'h00));
      
      `cpu_mem(addr, I_LD_M_R (0, 15));
      `cpu_mem(addr, I_LD_M_R (5, 10));
      `cpu_mem(addr, I_LD_M_R (10, 5));
      `cpu_mem(addr, I_LD_M_R (15, 0));
      `cpu_mem(addr, I_LD_R_M (0, 15));
      `cpu_mem(addr, I_LD_R_M (5, 10));
      `cpu_mem(addr, I_LD_R_M (10, 5));
      `cpu_mem(addr, I_LD_R_M (15, 0));
      `cpu_mem(addr, I_LD_M_RW(0, 15));
      `cpu_mem(addr, I_LD_M_RW(5, 10));
      `cpu_mem(addr, I_LD_M_RW(10, 5));
      `cpu_mem(addr, I_LD_M_RW(15, 0));
      `cpu_mem(addr, I_LD_RW_M(0, 15));
      `cpu_mem(addr, I_LD_RW_M(5, 10));
      `cpu_mem(addr, I_LD_RW_M(10, 5));
      `cpu_mem(addr, I_LD_RW_M(15, 0));
      `cpu_mem(addr, I_LD_M_RB(0, 15));
      `cpu_mem(addr, I_LD_M_RB(5, 10));
      `cpu_mem(addr, I_LD_M_RB(10, 5));
      `cpu_mem(addr, I_LD_M_RB(15, 0));
      `cpu_mem(addr, I_LD_RB_M(0, 15));
      `cpu_mem(addr, I_LD_RB_M(5, 10));
      `cpu_mem(addr, I_LD_RB_M(10, 5));
      `cpu_mem(addr, I_LD_RB_M(15, 0));
      
      `cpu_mem(addr, I_OUT (0, 15));
      `cpu_mem(addr, I_OUT (5, 10));
      `cpu_mem(addr, I_OUT (10, 5));
      `cpu_mem(addr, I_OUT (15, 0));
      `cpu_mem(addr, I_IN  (0, 15));
      `cpu_mem(addr, I_IN  (5, 10));
      `cpu_mem(addr, I_IN  (10, 5));
      `cpu_mem(addr, I_IN  (15, 0));
      `cpu_mem(addr, I_OUTW(0, 15));
      `cpu_mem(addr, I_OUTW(5, 10));
      `cpu_mem(addr, I_OUTW(10, 5));
      `cpu_mem(addr, I_OUTW(15, 0));
      `cpu_mem(addr, I_INW (0, 15));
      `cpu_mem(addr, I_INW (5, 10));
      `cpu_mem(addr, I_INW (10, 5));
      `cpu_mem(addr, I_INW (15, 0));
      `cpu_mem(addr, I_OUTB(0, 15));
      `cpu_mem(addr, I_OUTB(5, 10));
      `cpu_mem(addr, I_OUTB(10, 5));
      `cpu_mem(addr, I_OUTB(15, 0));
      `cpu_mem(addr, I_INB (0, 15));
      `cpu_mem(addr, I_INB (5, 10));
      `cpu_mem(addr, I_INB (10, 5));
      `cpu_mem(addr, I_INB (15, 0));
      
      `cpu_mem(addr, I_LD_R_R(0,  31));
      `cpu_mem(addr, I_LD_R_R(5,  30));
      `cpu_mem(addr, I_LD_R_R(10, 25));
      `cpu_mem(addr, I_LD_R_R(15, 20));
      `cpu_mem(addr, I_LD_R_R(20, 15));
      `cpu_mem(addr, I_LD_R_R(25, 10));
      `cpu_mem(addr, I_LD_R_R(30,  5));
      `cpu_mem(addr, I_LD_R_R(31,  0));
      
      `cpu_mem(addr, I_ADD(0,  1,  2));
      `cpu_mem(addr, I_ADD(12, 13, 15));
      `cpu_mem(addr, I_SUB(0,  1,  2));
      `cpu_mem(addr, I_SUB(12, 13, 15));
      `cpu_mem(addr, I_MUL(0,  1,  2));
      `cpu_mem(addr, I_MUL(12, 13, 15));
      `cpu_mem(addr, I_DIV(0,  1,  2));
      `cpu_mem(addr, I_DIV(12, 13, 15));
      `cpu_mem(addr, I_AND(0,  1,  2));
      `cpu_mem(addr, I_AND(12, 13, 15));
      `cpu_mem(addr, I_OR (0,  1,  2));
      `cpu_mem(addr, I_OR (12, 13, 15));
      `cpu_mem(addr, I_XOR(0,  1,  2));
      `cpu_mem(addr, I_XOR(12, 13, 15));
      `cpu_mem(addr, I_CP (0,  1,  2));
      `cpu_mem(addr, I_CP (12, 13, 15));

      `cpu_mem(addr, 16'h0000);
      `cpu_mem(addr, 16'h0000);
      `cpu_mem(addr, 16'h0000);
      `cpu_mem(addr, 16'h0000);
      `cpu_mem(addr, 16'h0000);
      `cpu_mem(addr, 16'h0000);
      `cpu_mem(addr, 16'h0000);
      `cpu_mem(addr, 16'h0000);

      mem_dump('h0000, addr - 16);

      tb_end();

   endtask // tb_test_dump_inst

   task tb_test_LD_r_nnnn();
      bus_addr_t addr;
      bus_data_t data;

      tb_begin("test_LD_r_nnnn");
      cpu_init();

      mem_write('h2000, 'h0000);

      addr = 'h0000;
      `cpu_mem(addr, I_LD_RW_I(0));        // LD r0.w, 1234h
      `cpu_mem(addr, 'h1234);
      `cpu_mem(addr, I_LD_RW_I(1));        // LD r1.w, 2000h
      `cpu_mem(addr, 'h2000);
      `cpu_mem(addr, I_HALT());            // HALT

      cpu_run();
      `tb_assert(regs(reg_pc) === addr);
      `tb_assert(regs(0) === 'h1234);
      `tb_assert(regs(1) === 'h2000);
      mem_read('h2000, data);
      `tb_assert(data === 'h0000);

      `cpu_mem(addr, I_LD_M_RW(1, 0));     // LD (r1), r0.w
      `cpu_mem(addr, I_LD_RW_I(0));        // LD r0.w, 5678h
      `cpu_mem(addr, 'h5678);
      `cpu_mem(addr, I_HALT());            // HALT

      cpu_cont();
      `tb_assert(regs(reg_pc) === addr);
      `tb_assert(regs(0) === 'h5678);
      mem_read('h2000, data);
      `tb_assert(data === 'h1234);

      tb_end();

   endtask // tb_test_LD_r_nnnn

   task tb_test_LD_r_nnnnnnnn();
      bus_addr_t addr;
      bus_data_t data;
      int saved_assertion_failures;

      tb_begin("test_LD_r_nnnnnnnn");
      cpu_init();

      mem_write('h2000, 'h0000);
      mem_write('h2002, 'h0000);

      addr = 'h0000;
      `cpu_mem(addr, I_LD_R_I(0));         // LD r0, 12345678h
      `cpu_mem(addr, 'h5678);
      `cpu_mem(addr, 'h1234);
      `cpu_mem(addr, I_LD_R_I(1));         // LD r1, 00002000h
      `cpu_mem(addr, 'h2000);
      `cpu_mem(addr, 'h0000);
      `cpu_mem(addr, I_HALT());            // HALT

      saved_assertion_failures = tb_assertion_failures;

      cpu_run();
      `tb_assert(regs(reg_pc) === addr);
      `tb_assert(regs(0) === 'h12345678);
      `tb_assert(regs(1) === 'h00002000);
      mem_read('h2000, data);
      `tb_assert(data === 'h0000);
      mem_read('h2002, data);
      `tb_assert(data === 'h0000);

      if (saved_assertion_failures != tb_assertion_failures) begin
         reg_dump(0, CPU_NUMREGS - 1);
      end

      `cpu_mem(addr, I_LD_M_R(1, 0));      // LD (r1), r0
      `cpu_mem(addr, I_LD_R_I(0));         // LD r0, 9abcdef0h
      `cpu_mem(addr, 'hdef0);
      `cpu_mem(addr, 'h9abc);
      `cpu_mem(addr, I_HALT());            // HALT

      saved_assertion_failures = tb_assertion_failures;

      cpu_cont();
      `tb_assert(regs(reg_pc) === addr);
      `tb_assert(regs(0) === 'h9abcdef0);
      mem_read('h2000, data);
      `tb_assert(data === 'h5678);
      mem_read('h2002, data);
      `tb_assert(data === 'h1234);

      if (saved_assertion_failures != tb_assertion_failures) begin
         reg_dump(0, CPU_NUMREGS - 1);
      end

      tb_end();

   endtask // tb_test_LD_r_nnnnnnnn

   task tb_test_move();
      bus_addr_t addr;
      bus_data_t data;
      int saved_assertion_failures;

      saved_assertion_failures = tb_assertion_failures;

      tb_begin("test_move");
      cpu_init();

      addr = 'h0000;
      `cpu_mem(addr, I_LD_RW_I(5));          // LD r5.w, ba98h
      `cpu_mem(addr, 'hba98);
      `cpu_mem(addr, I_LD_RW_I(6));          // LD r6.w, fedch
      `cpu_mem(addr, 'hfedc);
      `cpu_mem(addr, I_LD_RW_I(7));          // LD r6.w, fedch
      `cpu_mem(addr, 'h0000);
      `cpu_mem(addr, I_LD_RW_I(10));         // LD r10.w, 0000h
      `cpu_mem(addr, 'h0000);
      `cpu_mem(addr, I_LD_RW_I(11));         // LD r11.w, 0000h
      `cpu_mem(addr, 'h0000);
      `cpu_mem(addr, I_HALT());              // HALT

      cpu_run();
      `tb_assert(regs(reg_pc) === addr);
      `tb_assert(regs(5) === 'hba98);
      `tb_assert(regs(6) === 'hfedc);
      `tb_assert(regs(7) === 'h0000);
      `tb_assert(regs(10) === 'h0000);
      `tb_assert(regs(11) === 'h0000);

      `cpu_mem(addr, I_LD_R_R(22, 5));       // LD r22, r5
      `cpu_mem(addr, I_LD_R_R(23, 6));       // LD r23, r6
      `cpu_mem(addr, I_LD_R_R(10, 22));      // LD r10, r22
      `cpu_mem(addr, I_LD_R_R(11, 23));      // LD r11, r23
      `cpu_mem(addr, I_LD_R_R(7, 5));        // LD r7, r5
      `cpu_mem(addr, I_HALT());              // HALT

      cpu_cont();
      `tb_assert(regs(reg_pc) === addr);
      `tb_assert(regs(22) === 'hba98);
      `tb_assert(regs(23) === 'hfedc);
      `tb_assert(regs(10) === 'hba98);
      `tb_assert(regs(11) === 'hfedc);
      `tb_assert(regs(7)  === 'hba98);

      if (saved_assertion_failures != tb_assertion_failures) begin
         reg_dump(0, CPU_NUMREGS - 1);
      end
      tb_end();

   endtask // tb_test_move

   task tb_test_stack();
      bus_addr_t addr;
      bus_data_t data;
      int saved_assertion_failures;

      tb_begin("test_stack");
      cpu_init();

      /*
       * PUSH and POP
       */
      addr = 'h0000;
      `cpu_mem(addr, I_LD_RW_I(8));          // LD r8.w, 89abh
      `cpu_mem(addr, 'h89ab);
      `cpu_mem(addr, I_LD_RW_I(9));          // LD r9.w, cdefh
      `cpu_mem(addr, 'hcdef);
      `cpu_mem(addr, I_LD_RW_I(0));          // LD a0.w, 2000h
      `cpu_mem(addr, 'h2000);
      `cpu_mem(addr, I_LD_R_R(reg_sp, 0));   // LD sp, a0
      `cpu_mem(addr, I_HALT());              // HALT

      mem_write('h1ffa, 'h0000);
      mem_write('h1ffc, 'h0000);
      mem_write('h1ffe, 'h0000);
      
      cpu_run();
      saved_assertion_failures = tb_assertion_failures;
      `tb_assert(regs(reg_pc) === addr);
      `tb_assert(regs(8) === 'h89ab);
      `tb_assert(regs(9) === 'hcdef);
      `tb_assert(regs(reg_sp) === 'h2000);
      if (saved_assertion_failures != tb_assertion_failures) begin
         reg_dump(0, CPU_NUMREGS - 1);
      end

      `cpu_mem(addr, I_PUSH_R(8));           // PUSH (r8)
      `cpu_mem(addr, I_PUSH_R(9));           // PUSH (r9)
      `cpu_mem(addr, I_HALT());              // HALT

      cpu_cont();
      saved_assertion_failures = tb_assertion_failures;
      `tb_assert(regs(reg_pc) === addr);
      `tb_assert(regs(8) === 'h89ab);
      `tb_assert(regs(9) === 'hcdef);
      `tb_assert(regs(reg_sp) === 'h1ffc);
      if (saved_assertion_failures != tb_assertion_failures) begin
         reg_dump(0, CPU_NUMREGS - 1);
      end
      mem_read('h1ffa, data);
      `tb_assert(data === 'h0000);
      mem_read('h1ffc, data);
      `tb_assert(data === 'hcdef);
      mem_read('h1ffe, data);
      `tb_assert(data === 'h89ab);

      `cpu_mem(addr, I_POP_R(8));            // POP (r8)
      `cpu_mem(addr, I_POP_R(9));            // POP (r9)
      `cpu_mem(addr, I_HALT());              // HALT

      cpu_cont();
      saved_assertion_failures = tb_assertion_failures;
      `tb_assert(regs(reg_pc) === addr);
      `tb_assert(regs(8) === 'hcdef);
      `tb_assert(regs(9) === 'h89ab);
      `tb_assert(regs(reg_sp) === 'h2000);
      if (saved_assertion_failures != tb_assertion_failures) begin
         reg_dump(0, CPU_NUMREGS - 1);
      end
      mem_read('h1ffa, data);
      `tb_assert(data === 'h0000);
      mem_read('h1ffc, data);
      `tb_assert(data === 'hcdef);
      mem_read('h1ffe, data);
      `tb_assert(data === 'h89ab);

      /*
       * CALL and RET
       */
      `cpu_mem(addr, I_LD_RW_I(0));          // LD r0.w, 1000h
      `cpu_mem(addr, 'h1000);
      `cpu_mem(addr, I_LD_RW_I(7));          // LD r7.w, ffffh
      `cpu_mem(addr, 'hffff);
      `cpu_mem(addr, I_HALT());              // HALT

      cpu_cont();
      saved_assertion_failures = tb_assertion_failures;
      `tb_assert(regs(0) === 'h1000);
      `tb_assert(regs(7) === 'hffff);
      if (saved_assertion_failures != tb_assertion_failures) begin
         reg_dump(0, CPU_NUMREGS - 1);
      end

      `cpu_mem(addr, I_CALL_R(0));           // CALL (r0)
      `cpu_mem(addr, I_HALT());              // HALT

      addr = 'h1000;
      `cpu_mem(addr, I_LD_RW_I(7));          // LD r7.w, cdefh
      `cpu_mem(addr, 'hcdef);
      `cpu_mem(addr, I_RET());               // RET

      cpu_cont();
      saved_assertion_failures = tb_assertion_failures;
      `tb_assert(regs(7) === 'hcdef);
      if (saved_assertion_failures != tb_assertion_failures) begin
         reg_dump(0, CPU_NUMREGS - 1);
      end

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
      16'b0000_0100_zzzz_zzzz: opr_name = "  SRA";
      16'b0000_0101_zzzz_zzzz: opr_name = "  SRL";
      16'b0000_0110_zzzz_zzzz: opr_name = "   SL";
      16'b0000_0111_zzzz_zzzz: opr_name = "  RLC";
      16'b0000_1000_zzzz_zzzz: opr_name = " ADDI";
      16'b0000_1001_zzzz_zzzz: opr_name = " SUBI";
      endcase // casez (ins)

      $display("tb_test_1reg_opr: %s(%d): %h -> %h", opr_name, ins[3:0], prev, result);

      cpu_init();
      addr = 'h0000;
      if (16 < CPU_REG_WIDTH) begin
         `cpu_mem(addr, I_LD_R_I(0));           // LD r0, prev
         `cpu_mem(addr, prev[15:0]);
         `cpu_mem(addr, prev[CPU_REG_WIDTH-1:16]);
      end else begin
         `cpu_mem(addr, I_LD_RW_I(0));          // LD r0, prev
         `cpu_mem(addr, prev);
      end
      `cpu_mem(addr, I_LD_R_R(r, 0));        // LD r, r0
      `cpu_mem(addr, I_HALT());              // HALT

      cpu_run();
      `tb_assert(regs(reg_pc) === addr);
      if (r == reg_flag)
        `tb_assert((regs(r) & 16'hfeff) === prev); // ignore halt flag
      else
        `tb_assert(regs(r) === prev);

      `cpu_mem(addr, ins);                   // instruction under test
      `cpu_mem(addr, I_HALT());              // HALT

      cpu_cont();
      `tb_assert(regs(reg_pc) === addr);
      if (r == reg_flag)
        `tb_assert((regs(r) & 16'hfeff) === result); // ignore halt flag
      else
        `tb_assert(regs(r) === result);

      if (saved_assertion_failures != tb_assertion_failures) begin
         $display("tb_test_1reg_opr: %s: r%0d = %h (%h expected)", opr_name, r, regs(r), result);
      end
   endtask // tb_test_1reg_opr

   task tb_test_1reg_oprs();
      tb_begin("test_1reg_oprs");
      //               instruction     reg num   before  after
      tb_test_1reg_opr(I_EXTN_RB(0),          0, 'h00000074, 'h00000074);
      tb_test_1reg_opr(I_EXTN_RB(0),          0, 'h00008774, 'h00000074);
      tb_test_1reg_opr(I_EXTN_RB(0),          0, 'h00000098, 'hffffff98);
      tb_test_1reg_opr(I_EXTN_RB(0),          0, 'h00001298, 'hffffff98);

      tb_test_1reg_opr(I_CPL_R(0),            0, 'h00000000, 'hffffffff);
      tb_test_1reg_opr(I_CPL_R(0),            0, 'hffffffff, 'h00000000);
      tb_test_1reg_opr(I_CPL_R(0),            0, 'h71717171, 'h8e8e8e8e);

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

      tb_test_1reg_opr(I_ADD_R_I(0, 1),       0, 'h0000, 'h0001);
      tb_test_1reg_opr(I_ADD_R_I(0, 15),      0, 'h0000, 'h000f);
      tb_test_1reg_opr(I_SUB_R_I(0, 1),       0, 'h0100, 'h00ff);
      tb_test_1reg_opr(I_SUB_R_I(0, 15),      0, 'h0100, 'h00f1);

      if (CPU_REG_WIDTH == 16) begin
         tb_test_1reg_opr(I_SRA_R_I(0, 1),       0, 'h8001, 'hc000);
         tb_test_1reg_opr(I_SRA_R_I(0, 8),       0, 'h8001, 'hff80);
         tb_test_1reg_opr(I_SRA_R_I(0, 15),      0, 'h8001, 'hffff);

         tb_test_1reg_opr(I_SRL_R_I(0, 1),       0, 'h8001, 'h4000);
         tb_test_1reg_opr(I_SRL_R_I(0, 8),       0, 'h8001, 'h0080);
         tb_test_1reg_opr(I_SRL_R_I(0, 15),      0, 'h8001, 'h0001);

         tb_test_1reg_opr(I_SL_R_I(0, 1),        0, 'h8001, 'h0002);
         tb_test_1reg_opr(I_SL_R_I(0, 8),        0, 'h8001, 'h0100);
         tb_test_1reg_opr(I_SL_R_I(0, 15),       0, 'h8001, 'h8000);

         tb_test_1reg_opr(I_RLC_R_I(0, 1),       0, 'h8001, 'h0003);
         tb_test_1reg_opr(I_RLC_R_I(0, 8),       0, 'h8001, 'h0180);
         tb_test_1reg_opr(I_RLC_R_I(0, 15),      0, 'h8001, 'hc000);
      end else
      if (CPU_REG_WIDTH == 32) begin
         tb_test_1reg_opr(I_SRA_R_I(0, 1),       0, 'h80000001, 'hc0000000);
         tb_test_1reg_opr(I_SRA_R_I(0, 8),       0, 'h80000001, 'hff800000);
         tb_test_1reg_opr(I_SRA_R_I(0, 15),      0, 'h80000001, 'hffff0000);

         tb_test_1reg_opr(I_SRL_R_I(0, 1),       0, 'h80000001, 'h40000000);
         tb_test_1reg_opr(I_SRL_R_I(0, 8),       0, 'h80000001, 'h00800000);
         tb_test_1reg_opr(I_SRL_R_I(0, 15),      0, 'h80000001, 'h00010000);

         tb_test_1reg_opr(I_SL_R_I(0, 1),        0, 'h80000001, 'h00000002);
         tb_test_1reg_opr(I_SL_R_I(0, 8),        0, 'h80000001, 'h00000100);
         tb_test_1reg_opr(I_SL_R_I(0, 15),       0, 'h80000001, 'h00008000);

         tb_test_1reg_opr(I_RLC_R_I(0, 1),       0, 'h80000001, 'h00000003);
         tb_test_1reg_opr(I_RLC_R_I(0, 8),       0, 'h80000001, 'h00000180);
         tb_test_1reg_opr(I_RLC_R_I(0, 15),      0, 'h80000001, 'h0000c000);
      end else begin
         // fail
         `tb_assert(0);
      end

      tb_end();
   endtask // tb_test_1reg_oprs

   task tb_test_operation(ins_t ins, reg_t flags, dst, a, string opr, reg_t b, bit z, c, o, s);
      bus_addr_t addr;
      int saved_assertion_failures;
      string opr_name;
      reg_num_t rd, ra, rb;

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
      
      rd = ins[11:8];
      ra = ins[7:4];
      rb = ins[3:0];

      $display("tb_test_operation: %s %d:%h = %d:%h %s %d:%h %s%s%s%s",
               opr_name, rd, dst, ra, a, opr, rb, b,
               z ? "Z" : "_",  c ? "C" : "_", o ? "O" : "_",  s ? "S" : "_" );

      cpu_init();
      addr = 'h0000;
      `cpu_mem(addr, I_LD_RW_I(0));          // LD r0, flags
      `cpu_mem(addr, flags);
      `cpu_mem(addr, I_LD_R_R(reg_flag, 0)); // LD F, r0
      if (16 < CPU_REG_WIDTH) begin
         `cpu_mem(addr, I_LD_R_I(rd));       // LD dst, deadbeefh
         `cpu_mem(addr, 'hbeef);
         `cpu_mem(addr, 'hdead);
         `cpu_mem(addr, I_LD_R_I(ra));       // LD a
         `cpu_mem(addr, a[15:0]);
         `cpu_mem(addr, a[CPU_REG_WIDTH-1:16]);
         `cpu_mem(addr, I_LD_R_I(rb));       // LD b
         `cpu_mem(addr, b[15:0]);
         `cpu_mem(addr, b[CPU_REG_WIDTH-1:16]);
      end else begin
         `cpu_mem(addr, I_LD_RW_I(rd));      // LD dst, beefh
         `cpu_mem(addr, 'hbeef);
         `cpu_mem(addr, I_LD_RW_I(ra));      // LD a
         `cpu_mem(addr, a);
         `cpu_mem(addr, I_LD_RW_I(rb));      // LD b
         `cpu_mem(addr, b);
      end
      `cpu_mem(addr, I_HALT());              // HALT

      cpu_run();
      `tb_assert(regs(reg_pc) === addr);
      `tb_assert(regs(ra) === a);
      `tb_assert(regs(rb) === b);

      `cpu_mem(addr, ins);                   // three register operation
      `cpu_mem(addr, I_HALT());              // HALT

      cpu_cont();
      `tb_assert(regs(reg_pc) === addr);
      if (ins[15:12] == 'hf) begin
         if (16 < CPU_REG_WIDTH) begin
            `tb_assert(regs(rd) === 'hdeadbeef);
         end else begin
            `tb_assert(regs(rd) === 'hbeef);
         end
      end else begin
         `tb_assert(regs(rd) === dst);
      end
      `tb_assert(z == ((regs(reg_flag) & (1<<reg_flag_zero)) ? 1 : 0));   // equal zero
      `tb_assert(c == ((regs(reg_flag) & (1<<reg_flag_carry)) ? 1 : 0));  // carry / borrow
      `tb_assert(o == ((regs(reg_flag) & (1<<reg_flag_parity)) ? 1 : 0)); // parity even / overflow
      `tb_assert(s == ((regs(reg_flag) & (1<<reg_flag_sign)) ? 1 : 0));   // negitive / positive

      if (saved_assertion_failures != tb_assertion_failures) begin
         reg_dump(0, CPU_NUMREGS - 1);
      end
      
   endtask // tb_tgest_operation
   
   task tb_test_oprations();
      tb_begin("test_operations");
      if (CPU_REG_WIDTH == 16) begin
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

         tb_test_operation(I_MUL(3, 4, 5), 'h0000,     12,      3, "*",      4, 0, 0, 0, 0);
         tb_test_operation(I_DIV(3, 4, 5), 'h0000,      8,     48, "/",      6, 0, 0, 0, 0);

         /*
         tb_test_operation(I_ADC(3, 4, 5), 'h0000, 'h2234, 'h1234, "+", 'h1000, 0, 0, 0, 0);
         tb_test_operation(I_ADC(3, 4, 5), 'h0002, 'h2235, 'h1234, "+", 'h1000, 0, 0, 0, 0);
         tb_test_operation(I_ADC(3, 4, 5), 'h0000, 'hffff, 'h7fff, "+", 'h8000, 0, 0, 0, 1);
         tb_test_operation(I_ADC(3, 4, 5), 'h0002, 'h0000, 'h7fff, "+", 'h8000, 1, 1, 0, 0);

         tb_test_operation(I_SBC(3, 4, 5), 'h0000, 'h0234, 'h1234, "-", 'h1000, 0, 0, 0, 0);
         tb_test_operation(I_SBC(3, 4, 5), 'h0002, 'h0233, 'h1234, "-", 'h1000, 0, 0, 0, 0);
         tb_test_operation(I_SBC(3, 4, 5), 'h0000, 'hffff, 'h7fff, "-", 'h8000, 0, 1, 1, 1);
         tb_test_operation(I_SBC(3, 4, 5), 'h0002, 'hffff, 'h7fff, "-", 'h7fff, 0, 1, 0, 1);
          */

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

         tb_test_operation(I_OR (6, 1, 3), 'h0000, 'hffff, 'ha5a5, "|", 'h5a5a, 0, 0, 1, 1);
         tb_test_operation(I_OR (6, 1, 3), 'h0000, 'hffa5, 'ha5a5, "|", 'hff00, 0, 0, 1, 1);
         tb_test_operation(I_OR (6, 1, 3), 'h0000, 'hfafa, 'ha8a8, "|", 'h5a5a, 0, 0, 1, 1);
         tb_test_operation(I_OR (6, 1, 3), 'h0000, 'hffa8, 'ha8a8, "|", 'hff00, 0, 0, 0, 1);

         tb_test_operation(I_XOR(6, 1, 3), 'h0000, 'hffff, 'ha5a5, "^", 'h5a5a, 0, 0, 1, 1);
         tb_test_operation(I_XOR(6, 1, 3), 'h0000, 'h5aa5, 'ha5a5, "^", 'hff00, 0, 0, 1, 0);
         tb_test_operation(I_XOR(6, 1, 3), 'h0000, 'hf2f2, 'ha8a8, "^", 'h5a5a, 0, 0, 1, 1);
         tb_test_operation(I_XOR(6, 1, 3), 'h0000, 'h57a8, 'ha8a8, "^", 'hff00, 0, 0, 1, 0);
      end else
      if (CPU_REG_WIDTH == 32) begin
         //                instruction     flags   result      a           opr  b           z  c  o  s
         tb_test_operation(I_ADD(0, 8, 9), 'h0000, 'h0000d000, 'h0000c000, "+", 'h00001000, 0, 0, 0, 0);
         tb_test_operation(I_ADD(0, 8, 9), 'h0000, 'hd0000000, 'hc0000000, "+", 'h10000000, 0, 0, 0, 1);
         tb_test_operation(I_ADD(0, 8, 9), 'h0000, 'h00011000, 'h0000c000, "+", 'h00005000, 0, 0, 0, 0);
         tb_test_operation(I_ADD(0, 8, 9), 'h0000, 'h10000000, 'hc0000000, "+", 'h50000000, 0, 1, 0, 0);
         tb_test_operation(I_ADD(0, 8, 9), 'h0000, 'h00010000, 'h0000c000, "+", 'h00004000, 0, 0, 0, 0);
         tb_test_operation(I_ADD(0, 8, 9), 'h0000, 'h00000000, 'hc0000000, "+", 'h40000000, 1, 1, 0, 0);
         tb_test_operation(I_ADD(0, 8, 9), 'h0000, 'h00009000, 'h00005000, "+", 'h00004000, 0, 0, 0, 0);
         tb_test_operation(I_ADD(0, 8, 9), 'h0000, 'h90000000, 'h50000000, "+", 'h40000000, 0, 0, 1, 1);

         tb_test_operation(I_SUB(1, 2, 3), 'h0000, 'h000000f0, 'h00000100, "-", 'h00000010, 0, 0, 0, 0);
         tb_test_operation(I_SUB(1, 2, 3), 'h0000, 'h000000e0, 'h00000100, "-", 'h00000020, 0, 0, 0, 0);
         tb_test_operation(I_SUB(3, 4, 5), 'h0000, 'hffffff00, 'h00000100, "-", 'h00000200, 0, 1, 0, 1);
         tb_test_operation(I_SUB(3, 4, 5), 'h0000, 'h00000000, 'h00000100, "-", 'h00000100, 1, 0, 0, 0);
         tb_test_operation(I_SUB(3, 4, 5), 'h0000, 'hffffd000, 'h00007000, "-", 'h0000a000, 0, 1, 0, 1);
         tb_test_operation(I_SUB(3, 4, 5), 'h0000, 'hd0000000, 'h70000000, "-", 'ha0000000, 0, 1, 1, 1);

         tb_test_operation(I_MUL(3, 4, 5), 'h0000,         12,          3, "*",          4, 0, 0, 0, 0);
         tb_test_operation(I_DIV(3, 4, 5), 'h0000,          8,         48, "/",          6, 0, 0, 0, 0);

         tb_test_operation(I_CP (1, 2, 3), 'h0000, 'h000000f0, 'h00000100, "-", 'h00000010, 0, 0, 0, 0);
         tb_test_operation(I_CP (1, 2, 3), 'h0000, 'h000000e0, 'h00000100, "-", 'h00000020, 0, 0, 0, 0);
         tb_test_operation(I_CP (3, 4, 5), 'h0000, 'hffffff00, 'h00000100, "-", 'h00000200, 0, 1, 0, 1);
         tb_test_operation(I_CP (3, 4, 5), 'h0000, 'h00000000, 'h00000100, "-", 'h00000100, 1, 0, 0, 0);
         tb_test_operation(I_CP (3, 4, 5), 'h0000, 'hffffd000, 'h00007000, "-", 'h0000a000, 0, 1, 0, 1);
         tb_test_operation(I_CP (3, 4, 5), 'h0000, 'hd0000000, 'h70000000, "-", 'ha0000000, 0, 1, 1, 1);

         //                instruction     flags   result      a           opr  b           z  c  p  s
         tb_test_operation(I_AND(6, 1, 3), 'h0000, 'h00000000, 'h0000a5a5, "&", 'h00005a5a, 1, 0, 1, 0);
         tb_test_operation(I_AND(6, 1, 3), 'h0000, 'h0000a500, 'h0000a5a5, "&", 'h0000ff00, 0, 0, 1, 0);
         tb_test_operation(I_AND(6, 1, 3), 'h0000, 'ha500a500, 'ha5a5a5a5, "&", 'hff00ff00, 0, 0, 1, 1);
         tb_test_operation(I_AND(6, 1, 3), 'h0000, 'h00000808, 'h0000a8a8, "&", 'h00005a5a, 0, 0, 1, 0);
         tb_test_operation(I_AND(6, 1, 3), 'h0000, 'h0000a800, 'h0000a8a8, "&", 'h0000ff00, 0, 0, 0, 0);
         tb_test_operation(I_AND(6, 1, 3), 'h0000, 'ha500a800, 'ha5a8a8a8, "&", 'hff00ff00, 0, 0, 0, 1);

         tb_test_operation(I_OR (6, 1, 3), 'h0000, 'h0000ffff, 'h0000a5a5, "|", 'h00005a5a, 0, 0, 1, 0);
         tb_test_operation(I_OR (6, 1, 3), 'h0000, 'hffffffff, 'ha5a5a5a5, "|", 'h5a5a5a5a, 0, 0, 1, 1);
         tb_test_operation(I_OR (6, 1, 3), 'h0000, 'h0000ffa5, 'h0000a5a5, "|", 'h0000ff00, 0, 0, 1, 0);
         tb_test_operation(I_OR (6, 1, 3), 'h0000, 'ha5ffffa5, 'ha5a5a5a5, "|", 'h00ffff00, 0, 0, 1, 1);
         tb_test_operation(I_OR (6, 1, 3), 'h0000, 'h0000fafa, 'h0000a8a8, "|", 'h00005a5a, 0, 0, 1, 0);
         tb_test_operation(I_OR (6, 1, 3), 'h0000, 'hfafafafa, 'ha8a8a8a8, "|", 'h5a5a5a5a, 0, 0, 1, 1);
         tb_test_operation(I_OR (6, 1, 3), 'h0000, 'h0000ffa8, 'h0000a8a8, "|", 'h0000ff00, 0, 0, 0, 0);
         tb_test_operation(I_OR (6, 1, 3), 'h0000, 'ha5ffffa8, 'ha5a5a8a8, "|", 'h00ffff00, 0, 0, 0, 1);

         tb_test_operation(I_XOR(6, 1, 3), 'h0000, 'h0000ffff, 'h0000a5a5, "^", 'h00005a5a, 0, 0, 1, 0);
         tb_test_operation(I_XOR(6, 1, 3), 'h0000, 'hffffffff, 'ha5a5a5a5, "^", 'h5a5a5a5a, 0, 0, 1, 1);
         tb_test_operation(I_XOR(6, 1, 3), 'h0000, 'h00005aa5, 'h0000a5a5, "^", 'h0000ff00, 0, 0, 1, 0);
         tb_test_operation(I_XOR(6, 1, 3), 'h0000, 'h0000f2f2, 'h0000a8a8, "^", 'h00005a5a, 0, 0, 1, 0);
         tb_test_operation(I_XOR(6, 1, 3), 'h0000, 'hf2f2f2f2, 'ha8a8a8a8, "^", 'h5a5a5a5a, 0, 0, 1, 1);
         tb_test_operation(I_XOR(6, 1, 3), 'h0000, 'h000057a8, 'h0000a8a8, "^", 'h0000ff00, 0, 0, 1, 0);
      end else begin
         // fail
         `tb_assert(0);
      end

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
      'h034z: ins_name = " JPZ";
      'h038z: ins_name = "JRNZ";
      'h03cz: ins_name = " JRZ";
      endcase

      if (jump_result != -1) begin
         $display("test_jump: %s %h %h", ins_name, jump_addr, jump_result);
      end else begin
         $display("test_jump: %s %h", ins_name, jump_addr);
      end

      cpu_init();

      addr = 'h0000;                         // start address (reset address)
      `cpu_mem(addr, I_LD_RW_I(0));          // set stack pointer
      `cpu_mem(addr, 'h4000);
      `cpu_mem(addr, I_LD_R_R(reg_sp, 0));
      `cpu_mem(addr, I_LD_RW_I(0));          // LD r0, 1000h - 10
      `cpu_mem(addr, 'h1000 - 10);
      `cpu_mem(addr, I_JP_R(0));             // jump to 1000h - 10

      addr = 'h1000 - 10;
      `cpu_mem(addr, I_HALT());              // HALT

      cpu_run();

      if (jump_result != -1) begin
         bus_addr_t addr;
         addr = jump_result;
         `cpu_mem(addr, I_HALT());              // HALT
         `cpu_mem(addr, ret_flag_ins);          // set / clear flag
         `cpu_mem(addr, ret_ins);               // RETx
         `cpu_mem(addr, I_HALT());              // HALT
         not_return_addr = addr;
      end

      `cpu_mem(addr, I_LD_RW_SI(jump_ins[3:0]));// load jump addr
      `cpu_mem(addr, jump_addr);
      `cpu_mem(addr, I_NOP());
      `cpu_mem(addr, jump_flag_ins);         // set / clear flag
      `cpu_mem(addr, jump_ins);              // jump
      `cpu_mem(addr, I_HALT());              // HALT
      return_addr = addr;

      cpu_cont();
      saved_assertion_failures = tb_assertion_failures;
      if (jump_result != bus_addr_t'(-1))
         `tb_assert(regs(reg_pc) == jump_result + bus_addr_t'(2));
      else
         `tb_assert(regs(reg_pc) == return_addr);
      if (saved_assertion_failures != tb_assertion_failures)
         reg_dump(0, CPU_NUMREGS - 1);

      if (ret_ins == I_NOP())
        return;

      cpu_cont();
      saved_assertion_failures = tb_assertion_failures;
      if (ret)
         `tb_assert(regs(reg_pc) === return_addr);
      else
         `tb_assert(regs(reg_pc) === not_return_addr);
      if (saved_assertion_failures != tb_assertion_failures)
         reg_dump(0, CPU_NUMREGS - 1);

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
      tb_test_jump(I_NOP(),     I_JP_R(0),      'h3000, 'h3000);

      // JR (R)
      tb_test_jump(I_NOP(),     I_JR_R(0),      'h1000, 'h2000);
      tb_test_jump(I_NOP(),     I_JR_R(0),      'hff00, 'h0f00);

      // JP cc, (R)
      tb_test_jump(I_CLRF(0),   I_JP_Z(0),      'h2000);
      tb_test_jump(I_SETF(0),   I_JP_Z(0),      'h2000, 'h2000);
      tb_test_jump(I_CLRF(0),   I_JP_Z(0),      'h3000);
      tb_test_jump(I_SETF(0),   I_JP_Z(0),      'h3000, 'h3000);

      // JR cc, (R)
      tb_test_jump(I_CLRF(0),   I_JR_Z(0),      'h1000);
      tb_test_jump(I_SETF(0),   I_JR_Z(0),      'h1000, 'h2000);
      tb_test_jump(I_CLRF(0),   I_JR_Z(0),      'hff00);
      tb_test_jump(I_SETF(0),   I_JR_Z(0),      'hff00, 'h0f00);

      tb_test_jump(I_SETF(0),   I_JR_NZ(0),     'h1000);
      tb_test_jump(I_CLRF(0),   I_JR_NZ(0),     'h1000, 'h2000);
      tb_test_jump(I_SETF(0),   I_JR_NZ(0),     'hff00);
      tb_test_jump(I_CLRF(0),   I_JR_NZ(0),     'hff00, 'h0f00);

      tb_end();
   endtask // tb_test_jumps

   task tb_test_hello();
      bus_addr_t addr;
      int saved_assertion_failures;

      tb_begin("test_hello");

      cpu_init();

      addr = 'h1000;                         // message
      mem_write(addr, { "e", "H" }); addr += 2;
      mem_write(addr, { "l", "l" }); addr += 2;
      mem_write(addr, { ",", "o" }); addr += 2;
      mem_write(addr, { "w", " " }); addr += 2;
      mem_write(addr, { "r", "o" }); addr += 2;
      mem_write(addr, { "d", "l" }); addr += 2;
      mem_write(addr, { 8'h0d, "!" }); addr += 2;
      mem_write(addr, { 8'h00, 8'h0a }); addr += 2;

      addr = 'h0000;                         // start address (reset address)
      `cpu_mem(addr, I_LD_RW_I(1));          // LD r1, message
      `cpu_mem(addr, 'h1000);
      `cpu_mem(addr, I_LD_RW_I(2));          // UART TX
      `cpu_mem(addr, 'h0000);
      `cpu_mem(addr, I_LD_RW_I(3));          // LD r3, 6
      `cpu_mem(addr, 6);
      `cpu_mem(addr, I_LD_RW_SI(4));         // LD r4, -10
      `cpu_mem(addr, -10);

      // LOOP:
      `cpu_mem(addr, I_LD_RB_M(0, 1));       // LD r0.b, (r1)
      `cpu_mem(addr, I_ADD_R_I(1, 1));       // ADD r1, 1 
      `cpu_mem(addr, I_ADD(8, 0, 0));        // ADD r8, r0, r0  r0 == 0 ?
      `cpu_mem(addr, I_JR_Z(3));             // JR Z, (r3)
      `cpu_mem(addr, I_OUTB(2, 0));          // OUTB (r2), r0.b
      `cpu_mem(addr, I_JR_R(4));             // JR (r4)
      `cpu_mem(addr, I_HALT());              // HALT

      saved_assertion_failures = tb_assertion_failures;

      cpu_run();
      `tb_assert(regs(reg_pc) === addr);
      `tb_assert(regs(0) === 'h0000);
      `tb_assert(regs(1) === 'h1010);

      // mem_dump('h0000, 'h20);
      // mem_dump('h1000, 'h10);

      if (saved_assertion_failures != tb_assertion_failures)
         reg_dump(0, CPU_NUMREGS - 1);

      tb_end();
   endtask // tb_test_hello

   task tb_test_mandelbrot();
      localparam [7:0] FRACBITS = 9;
      localparam [15:0] WIDTH = 78;
      localparam [15:0] HEIGHT = 24;
      localparam [15:0] FP0_0458 = 16'h0017;
      localparam [15:0] FP0_0833 = 16'h002a;
      localparam [15:0] FP4_0 = 16'h0800;
      localparam [15:0] CA0 = 16'hfc7f;
      localparam [15:0] CB0 = 16'hfe08;

      localparam X = 6;
      localparam Y = 7;
      localparam I = 11;
      localparam A = 12;
      localparam B = 13;
      localparam CA = 14;
      localparam CB = 15;
      localparam T = 3;

      bus_addr_t addr;
      bus_addr_t label_fp_mul;
      bus_addr_t label_put_pixel;
      bus_addr_t label_loop_y;
      bus_addr_t label_loop_x;
      bus_addr_t label_loop_i;
      bus_addr_t label_exit_loop_i;

      tb_begin("test_mandelbrot");

      cpu_init();

      addr = 'h1000;

      // fp_mul(A, B)
      label_fp_mul = addr;
      `cpu_mem(addr, I_SRA_R_I(4, 4));       // r2 = (A >> 4)
      `cpu_mem(addr, I_SRA_R_I(5, FRACBITS - 4));       // r5 = (A >> (FRACBITS - 4))
      `cpu_mem(addr, I_MUL(2, 4, 5));        // r2 = (A * B) >> FRACBITS
      `cpu_mem(addr, I_RET());               // return

      // put_pixel(I)
      label_put_pixel = addr;
      `cpu_mem(addr, I_LD_RW_I(8));          // LD r8, 10
      `cpu_mem(addr, 10);
      `cpu_mem(addr, I_CP(4, 4, 8));         // r4(I) - r8(9)
      `cpu_mem(addr, I_LD_RW_I(8));          // LD r8, 4
      `cpu_mem(addr, 4);
      `cpu_mem(addr, I_JR_C(8));             // JR r8(+4) if I < 10
      `cpu_mem(addr, I_ADD_R_I(4, 7));       // r4(I) = r4(I) + 7
      `cpu_mem(addr, I_LD_RW_I(8));          // LD r8, 48
      `cpu_mem(addr, 48);
      `cpu_mem(addr, I_ADD(4, 4, 8));        // r4(I) = r4(I) + 48
      `cpu_mem(addr, I_LD_RW_I(8));          // LD r8, 'h0000
      `cpu_mem(addr, 'h0000);
      `cpu_mem(addr, I_OUTB(8, 4));          // OUT r8('h0000), r4(I)
      `cpu_mem(addr, I_RET());               // RET

      // mem_dump_sv('h1000, addr - 'h1000);

      //
      // main routine
      //
      addr = 'h0000;
      `cpu_mem(addr, I_LD_RW_I(0));          // LD r0, 4000h
      `cpu_mem(addr, 'h4000);
      `cpu_mem(addr, I_LD_R_R(reg_sp, 0));   // LD sp, r0
      `cpu_mem(addr, I_LD_RW_SI(CB));        // CB = CB0
      `cpu_mem(addr, CB0);

      `cpu_mem(addr, I_LD_RW_SI(Y));        // Y = HEIGHT + 1
      `cpu_mem(addr, HEIGHT);
      `cpu_mem(addr, I_ADD_R_I(Y, 1));

      label_loop_y = addr;

      `cpu_mem(addr, I_LD_RW_SI(CA));        // CA = CA0
      `cpu_mem(addr, CA0);

      `cpu_mem(addr, I_LD_RW_SI(X));          // X = WIDTH + 1
      `cpu_mem(addr, WIDTH);
      `cpu_mem(addr, I_ADD_R_I(X, 1));

      label_loop_x = addr;

      `cpu_mem(addr, I_LD_R_R(A, CA));       // A = CA
      `cpu_mem(addr, I_LD_R_R(B, CB));       // B = CB

      `cpu_mem(addr, I_XOR(I, I, I));        // I = 0

      label_loop_i = addr;
      `cpu_mem(addr, I_LD_R_R(4, A));        // arg0 = A
      `cpu_mem(addr, I_LD_R_R(5, A));        // arg1 = A
      `cpu_mem(addr, I_LD_RW_I(0));          // LD r0, label_fp_mul
      `cpu_mem(addr, label_fp_mul);
      `cpu_mem(addr, I_CALL_R(0));           // r2 = A * A
      `cpu_mem(addr, I_LD_R_R(T, 2));        // T = A * A
      `cpu_mem(addr, I_LD_R_R(4, B));        // arg0 = B
      `cpu_mem(addr, I_LD_R_R(5, B));        // arg1 = B
      `cpu_mem(addr, I_LD_RW_I(0));          // LD r0, label_fp_mul
      `cpu_mem(addr, label_fp_mul);
      `cpu_mem(addr, I_CALL_R(0));           // r2 = B * B
      `cpu_mem(addr, I_SUB(T, T, 2));        // T = A * A - B * B
      `cpu_mem(addr, I_ADD(T, T, CA));       // T = A * A - B * B + CA

      `cpu_mem(addr, I_LD_R_R(4, A));        // arg0 = A
      `cpu_mem(addr, I_LD_R_R(5, B));        // arg1 = B
      `cpu_mem(addr, I_LD_RW_I(0));          // LD r0, label_fp_mul
      `cpu_mem(addr, label_fp_mul);
      `cpu_mem(addr, I_CALL_R(0));           // r2 = A * B
      `cpu_mem(addr, I_SL_R_I(2, 1));        // r2 = A * B * 2
      `cpu_mem(addr, I_ADD(B, 2, CB));       // B = A * B * 2 + CB
      `cpu_mem(addr, I_LD_R_R(A, T));        // A = T

      `cpu_mem(addr, I_LD_R_R(4, A));        // arg0 = A
      `cpu_mem(addr, I_LD_R_R(5, A));        // arg1 = A
      `cpu_mem(addr, I_LD_RW_I(0));          // LD r0, label_fp_mul
      `cpu_mem(addr, label_fp_mul);
      `cpu_mem(addr, I_CALL_R(0));           // r2 = A * A
      `cpu_mem(addr, I_LD_R_R(T, 2));        // T = A * A
      `cpu_mem(addr, I_LD_R_R(4, B));        // arg0 = B
      `cpu_mem(addr, I_LD_R_R(5, B));        // arg1 = B
      `cpu_mem(addr, I_LD_RW_I(0));          // LD r0, label_fp_mul
      `cpu_mem(addr, label_fp_mul);
      `cpu_mem(addr, I_CALL_R(0));           // r2 = B * B
      `cpu_mem(addr, I_ADD(T, T, 2));        // T = A * A + B * B

      `cpu_mem(addr, I_LD_RW_I(0));          // r0 = 4.0
      `cpu_mem(addr, FP4_0);

      `cpu_mem(addr, I_LD_RW_I(1));          // r1 = 16
      `cpu_mem(addr, 16);

      `cpu_mem(addr, I_CP(T, 0, T));         // 4.0 - (A * A + B * B)
      `cpu_mem(addr, I_JR_NC(1));            // jump +20 if A * A + B * B <= 4.0

      `cpu_mem(addr, I_LD_R_R(4, I));        // arg0 = I
      `cpu_mem(addr, I_LD_RW_I(0));          // LD r0, label_put_pixel
      `cpu_mem(addr, label_put_pixel);
      `cpu_mem(addr, I_CALL_R(0));           // CALL label_put_pixel

      `cpu_mem(addr, I_LD_RW_I(0));          // r0 = address to exit from variable I loop
      label_exit_loop_i = addr;              // this word will be set later
      addr += 2;
      `cpu_mem(addr, I_JP_R(0));             // break variable I loop

      `cpu_mem(addr, I_ADD_R_I(I, 1));       // I++
      `cpu_mem(addr, I_LD_RW_I(0));          // r0 = 16
      `cpu_mem(addr, 16);
      `cpu_mem(addr, I_LD_RW_I(1));          // LD r1, label_loop_i
      `cpu_mem(addr, label_loop_i);

      `cpu_mem(addr, I_CP(I, I, 0));         // I - 16
      `cpu_mem(addr, I_JP_C(1));             // JP C, label_loop_i if I < 16
      `cpu_mem(addr, I_LD_RW_I(1));          // LD r1, 'h0000  output port
      `cpu_mem(addr, 'h0000);
      `cpu_mem(addr, I_LD_RB_I(0, 'h20));    // LD r0, 'h20
      `cpu_mem(addr, I_OUTB(1, 0));          // OUT ('h0000), 'h20

      // break from var I loop
      `cpu_mem(label_exit_loop_i, addr);

      `cpu_mem(addr, I_LD_RW_I(0));          // LD r0, FP0_0458
      `cpu_mem(addr, FP0_0458);
      `cpu_mem(addr, I_ADD(CA, CA, 0));      // CA += 0.0458

      `cpu_mem(addr, I_LD_RW_I(0));          // LD r0, label_loop_x
      `cpu_mem(addr, label_loop_x);
      `cpu_mem(addr, I_SUB_R_I(X, 1));       // X--
      `cpu_mem(addr, I_JP_NZ(0));            // jump to label_loop_x if 0 < X

      `cpu_mem(addr, I_LD_RW_SI(0));         // LD r0, FP0_0833
      `cpu_mem(addr, FP0_0833);
      `cpu_mem(addr, I_ADD(CB, CB, 0));      // CB += 0.0833

      `cpu_mem(addr, I_LD_RW_I(1));          // LD r1, 'h0000  output port
      `cpu_mem(addr, 'h0000);
      `cpu_mem(addr, I_LD_RB_I(0, 'h0d));    // LD r0, 'h0d
      `cpu_mem(addr, I_OUTB(1, 0));          // OUT ('h0000), 'h0d
      `cpu_mem(addr, I_LD_RB_I(0, 'h0a));    // LD r0, 'h0a
      `cpu_mem(addr, I_OUTB(1, 0));          // OUT ('h0000), 'h0d

      `cpu_mem(addr, I_LD_RW_I(0));          // LD r0, label_loop_y
      `cpu_mem(addr, label_loop_y);
      `cpu_mem(addr, I_SUB_R_I(Y, 1));       // Y--
      `cpu_mem(addr, I_JP_NZ(0));            // jump to label_loop_y if 0 < Y

      `cpu_mem(addr, I_HALT());              // HALT

      // mem_dump_sv('h0000, addr - 'h0000);

      cpu_run();
      while (regs(reg_pc) != addr) begin
         $display("  %h: %h X=%h Y=%h A=%h B=%h CA=%h CB=%h T=%h I=%h",
                  regs(reg_pc), 4'(regs(reg_flag)),
                  regs(X), regs(Y), regs(A), regs(B), regs(CA), regs(CB), regs(T), regs(I));
         cpu_cont();
      end
      
      `tb_assert(regs(reg_pc) === addr);

      tb_end();
   endtask // tb_test_mandelbrot

   initial begin
      tb_init();
      tb_test_rom();
      tb_test00();
      tb_test_dump_inst();
      tb_test_LD_r_nnnn();
      if (CPU_REG_WIDTH == 32) begin
         tb_test_LD_r_nnnnnnnn();
      end
      tb_test_move();
      tb_test_stack();
      tb_test_1reg_oprs();
      tb_test_oprations();
      tb_test_jumps();
      tb_test_hello();
      tb_test_mandelbrot();
      tb_finish();
   end

endmodule
