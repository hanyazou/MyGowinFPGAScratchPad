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
