module top(
   input logic sysclk, S1, S2,
   output logic spi_clk, dout, cs, stop,
   output logic [10:1] pin
   );

   reg reset;
   wire [15:0] pc;
   wire [15:0] flag;
   reg [15:0] ins;
   reg [15:0] regs[8];
   reg halt;
   reg [15:0] mem[16];

   logic [63:0] counter = 0;
   always @(posedge sysclk)
     counter <= counter + 1;

   wire clk;
   //assign clk = S1;
   assign clk = counter[24];
   wire reset_sw;
   assign reset_sw = S2;

   `define reg_pc regs[6]
   `define reg_flag regs[7]
   `define reg_flag_zero `reg_flag[0]

   parameter NUM_CASCADES = 2;
   wire [7:0] frame[4 * NUM_CASCADES];
   assign frame[0] = `reg_pc[15:8];
   assign frame[1] = `reg_pc[7:0];
   assign frame[2] = ins[15:8];
   assign frame[3] = ins[7:0];
   assign frame[4] = regs[0][15:8];
   assign frame[5] = regs[0][7:0];
   assign frame[6] = `reg_flag[15:8];
   assign frame[7] = `reg_flag[7:0];

   initial begin
      reset = 1;
      mem['h0000] = 'h0004;  // LD r0.l, 04h    0000_0ddd_nnnn_nnnn  reg[0][7:0] = 'h04
      mem['h0001] = 'h0800;  // LD r0.h, 00h    0000_1ddd_nnnn_nnnn  reg[0][15:9] = 'h00
      mem['h0002] = 'h0101;  // LD r1.l, 01h    0000_0ddd_nnnn_nnnn  reg[1][7:0] = 'h01
      mem['h0003] = 'h0900;  // LD r1.h, 00h    0000_1ddd_nnnn_nnnn  reg[1][15:9] = 'h00
      mem['h0004] = 'h0206;  // LD r2.l, 06h    0000_0ddd_nnnn_nnnn  reg[2][7:0] = 'h06
      mem['h0005] = 'h0a00;  // LD r2.h, 00h    0000_1ddd_nnnn_nnnn  reg[2][15:9] = 'h00

      mem['h0006] = 'h1201;  // ADD r0, r0, r1  0001_001d_ddaa_abbb  reg[0] = reg[0] - reg[1]
      mem['h0007] = 'h2001;  // ST r0, (r1)     0010_0000_00aa_abbb  store reg[0] to mem[reg[1]]
      mem['h0008] = 'h00ff;  // LD r0.l, FFh    0000_0ddd_nnnn_nnnn  reg[0][7:0] = 'hff
      mem['h0009] = 'h2041;  // LD r0, (r1)     0010_0000_01aa_abbb  load reg[0] from mem[reg[1]]
      mem['h000a] = 'h2432;  // JPNZ (r2)       0010_01ff_ffaa_abbb  move reg[2] to reg[6] if flag[F] is asserted
      mem['h000b] = 'hf000;  // HALT            1111_0000_0000_0000  halt
   end

   always @(posedge clk) begin
      if (reset || reset_sw) begin
      end else begin
         ins <= mem[`reg_pc];
      end
   end

   always @(negedge clk) begin
      if (reset || reset_sw) begin
         reset <= 0;
         regs[0] <= 'hffff;
         regs[1] <= 'hffff;
         regs[2] <= 'hffff;
         regs[3] <= 'hffff;
         regs[4] <= 'hffff;
         regs[5] <= 'hffff;
         `reg_pc <= 'h0000;
         `reg_flag <= 'h0000;
         halt <= 0;
      end else
      if (!halt) begin
         automatic int affected_reg = 8;
         casez (ins)
         'h0zzz: begin
            case (ins[11])
            0:  // 0000_0ddd_nnnn_nnnn  load immediate lower half of reg[D]
              regs[ins[10:8]] <= (regs[ins[10:8]] & 'hff00 | (ins & 'hff));
            1:  // 0000_1ddd_nnnn_nnnn  load immediate upper half of reg[D]
              regs[ins[10:8]] <= (regs[ins[10:8]] & 'h00ff | (ins & 'hff) << 8);
            endcase
            affected_reg = ins[10:8];
            end
         'h1zzz: begin
            case (ins[11:9])
            0: begin  // 0001_000d_ddaa_abbb  reg[D] = reg[A] + reg[B]
               regs[ins[8:6]] <= regs[ins[5:3]] + regs[ins[2:0]];
               `reg_flag_zero <= ((regs[ins[5:3]] - regs[ins[2:0]]) == 0) ? 1 : 0;
            end
            1: begin  // 0001_000d_ddaa_abbb  reg[D] = reg[A] - reg[B]
               regs[ins[8:6]] <= regs[ins[5:3]] - regs[ins[2:0]];
               `reg_flag_zero <= ((regs[ins[5:3]] - regs[ins[2:0]]) == 0) ? 1 : 0;
            end
            endcase
            affected_reg = ins[8:6];
            end
         'h2zzz:
            casez (ins[11:6])
            'b000000:  // 0010_0000_00aa_abbb  store reg[A] to mem[reg[B]]
                mem[regs[ins[2:0]]] <= regs[ins[5:3]];
            'b000001: begin  // 0010_0000_01aa_abbb  load reg[A] from mem[reg[B]]
                 regs[ins[5:3]] <= mem[regs[ins[2:0]]];
                 affected_reg = ins[5:3];
              end
            'b000010: begin  // 0010_0000_10aa_abbb  move reg[B] to reg[A]
                 regs[ins[5:3]] <= regs[ins[2:0]];
                 affected_reg = ins[5:3];
              end
            'b01zzzz:  // 0010_0100_00aa_abbb  move reg[B] to reg[A] if not flag[F]
               if (!`reg_flag[ins[9:6]]) begin
                  regs[ins[5:3]] <= regs[ins[2:0]];
                  affected_reg = ins[5:3];
               end
            'b10zzzz:  // 0010_10ff_ffaa_abbb  move reg[B] to reg[A] if flag[F]
               if (`reg_flag[ins[9:6]]) begin
                  regs[ins[5:3]] <= regs[ins[2:0]];
                  affected_reg = ins[5:3];
               end
            endcase
         'hfzzz:
            case (ins[11:0])
            0: begin  // 1111_0000_0000_0000  halt
               halt <= 1;
               affected_reg = 6;  // pc
               end
            endcase
         endcase
         if (affected_reg != 6)
           `reg_pc <= `reg_pc + 1;
      end
   end

   max7219_display #( .NUM_CASCADES(NUM_CASCADES), .INTENSITY(1) )
     disp(sysclk, reset_sw, frame, spi_clk, dout, cs, stop, pin);

endmodule
