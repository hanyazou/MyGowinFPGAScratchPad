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
      mem_write(addr, I_LD_RW_I(7));          // LD r6.w, fedch
      addr += 2;
      mem_write(addr, 'h0000);
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
      `tb_assert(regs[7] === 'h0000);
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
      mem_write(addr, I_LD_R_R(7, 5));        // LD r7, r5
      addr += 2;
      mem_write(addr, I_HALT());              // HALT
      addr += 2;

      cpu_cont();
      `tb_assert(regs[reg_pc] === addr);
      `tb_assert(regs[22] === 'hba98);
      `tb_assert(regs[23] === 'hfedc);
      `tb_assert(regs[10] === 'hba98);
      `tb_assert(regs[11] === 'hfedc);
      `tb_assert(regs[7]  === 'hba98);

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

   initial begin
      tb_init();
      tb_test00();
      tb_test_LD_r_nnnn();
      tb_test_move();
      tb_test_stack();
      tb_finish();
   end

endmodule
