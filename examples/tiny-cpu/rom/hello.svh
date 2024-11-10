   `include "h80cpu.svh"
   `include "h80cpu_instmacros.svh"
   initial begin
      mem['h0000] = I_LD_RB_I(0, 'h04);  // LD r0, 04h
      mem['h0001] = I_LD_RB_I(1, 'h01);  // LD r1, 01h
      mem['h0002] = I_LD_RB_I(2, 'h0a);  // LD r2, 0ah  LOOP0
      mem['h0003] = I_LD_RW_I(3);        // LD r, 2000h  work area
      mem['h0004] = 'h2000;

      // LOOP0
      mem['h0005] = I_SUB(0, 0, 1);      // SUB r0, r0, r1
      mem['h0006] = I_LD_M_RW(3, 0);     // LD (r3), r0.w
      mem['h0007] = I_LD_M_RB(3, 0);     // LD (r3), r0.b
      mem['h0008] = I_LD_RB_I(0, 'hff);  // LD r0, FFh
      mem['h0009] = I_LD_RW_M(0, 3);     // LD.W r0, (r3)
      mem['h000a] = I_LD_RB_M(0, 3);     // LD r0, (r3)
      mem['h000b] = I_JP_NZ(2);          // JP NZ, (r2)
      mem['h000c] = I_NOP();             // NOP

      mem['h000d] = I_LD_RB_I(2, 'h22);  // LD r2, 2ch  LOOP1
      mem['h000e] = I_LD_RW_I(3);        // LD r3, 2020h  message
      mem['h000f] = 'h2020;
      mem['h0010] = I_LD_RB_I(4, 'h00);  // LD r4, 0000h  UART TX

      // LOOP1
      mem['h0011] = I_LD_RB_M(0, 3);     // LD r0.l, (r3)
      mem['h0012] = I_OUTB(4, 0);        // OUTB (r4), r0
      mem['h0013] = I_ADD(3, 3, 1);      // ADD r3, r3, r1  r3 = r3 + 1
      mem['h0014] = I_ADD(0, 0, 0);      // ADD r0, r0, r0  r0 == 0 ?
      mem['h0015] = I_JP_NZ(2);          // JP NZ, (r2)

      mem['h0016] = I_HALT();            // HALT

      mem['h1000] = 'h0000;              // work area
      mem['h1010] = { "e", "H" };        // message
      mem['h1011] = { "l", "l" };
      mem['h1012] = { ",", "o" };
      mem['h1013] = { "w", " " };
      mem['h1014] = { "r", "o" };
      mem['h1015] = { "d", "l" };
      mem['h1016] = { 8'h0d, "!" };
      mem['h1017] = { 8'h00, 8'h0a };
   end
