const int bus_cmd_nop = 2'b00;
const int bus_cmd_read = 2'b01;
const int bus_cmd_write = 2'b10;

module top(
   input logic sysclk, S1, S2,
   output logic spi_clk, dout, cs, stop,
   output logic [10:1] pin
   );

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
   assign ins = bus_rd_data[BUS_MEM];

   logic [63:0] counter = 0;
   always @(posedge sysclk)
     counter <= counter + 1;

   wire clk;
   //assign clk = S1;
   assign clk = counter[24];
   wire reset_sw;
   assign reset_sw = S2;

   const int reg_pc = 6;
   const int reg_flag = 7;
   const int reg_flag_zero = 0;

   parameter NUM_CASCADES = 2;
   wire [7:0] frame[4 * NUM_CASCADES];
   assign frame[0] = bus_addr[15:8];
   assign frame[1] = bus_addr[7:0];
   assign frame[2] = ins[15:8];
   assign frame[3] = ins[7:0];
   assign frame[4] = regs[0][15:8];
   assign frame[5] = regs[0][7:0];
   assign frame[6] = { state[3:0], bus_cmd[1:0], bus_run[BUS_MEM], bus_done[BUS_MEM] };
   assign frame[7] = regs[reg_flag][7:0];

   memory mem(clk, reset_sw, bus_addr, bus_cmd, bus_run[BUS_MEM], bus_wr_data,
              bus_rd_data[BUS_MEM], bus_done[BUS_MEM]);

   task reset();
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
   endtask
   
   task start_instruction_fetch(input [15:0] addr);
      bus_addr <= addr;
      bus_cmd <= bus_cmd_read;
      bus_run[BUS_MEM] <= ~bus_run[BUS_MEM];
      state <= 0;
   endtask // start_instruction_fetch

   initial begin
      reset();
   end

   `define register(regnum, value) do begin \
      automatic int register_tmp; \
      if ((regnum) == reg_pc) \
         next_ins_addr = (value); \
      register_tmp = (value); \
      regs[regnum] <= register_tmp[15:0]; \
   end while(0)

   always @(negedge clk) begin
      automatic int tmp;
      if (reset_sw) begin
         reset();
      end else
      if (halt) begin
         // halted with no execution
      end else
      if (bus_run[BUS_MEM] != bus_done[BUS_MEM]) begin
         // wait for memory access completion
      end else
      case (state)
      0: begin  // fetch and execution
         automatic int do_memory_access = 0;
         automatic int next_ins_addr = regs[reg_pc] + 1;
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
            casez (ins[11:6])
            'b000000: begin  // 3 0000_00aa_abbb  store reg[A] to mem[reg[B]]
               bus_addr <= regs[ins[2:0]];
               bus_wr_data <= regs[ins[5:3]];
               bus_cmd <= bus_cmd_write;
               bus_run[BUS_MEM] <= ~bus_run[BUS_MEM];
               do_memory_access = 1;
               end
            'b000001: begin  // 3 0000_01aa_abbb  load reg[A] from mem[reg[B]]
               bus_addr <= regs[ins[2:0]];
               bus_rd_reg <= ins[5:3];
               bus_cmd <= bus_cmd_read;
               bus_run[BUS_MEM] <= ~bus_run[BUS_MEM];
               do_memory_access = 1;
               end
            'b000010:  // 3 0000_10aa_abbb  move reg[B] to reg[A]
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
         if (bus_rd_reg == reg_pc)
            start_instruction_fetch(bus_rd_data[BUS_MEM]);
         else
            start_instruction_fetch(regs[reg_pc]);
      end
      endcase // case (state)
   end // always @ (negedge clk)

   max7219_display #( .NUM_CASCADES(NUM_CASCADES), .INTENSITY(1) )
     disp(sysclk, reset_sw, frame, spi_clk, dout, cs, stop, pin);

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
      mem['h0000] = 'h1004;  // LD r0.l, 04h    1 0ddd_nnnn_nnnn  reg[0][7:0] = 'h04
      mem['h0001] = 'h1800;  // LD r0.h, 00h    1 1ddd_nnnn_nnnn  reg[0][15:9] = 'h00
      mem['h0002] = 'h1101;  // LD r1.l, 0fh    1 0ddd_nnnn_nnnn  reg[1][7:0] = 'h01
      mem['h0003] = 'h1900;  // LD r1.h, 00h    1 1ddd_nnnn_nnnn  reg[1][15:9] = 'h00
      mem['h0004] = 'h1208;  // LD r2.l, 08h    1 0ddd_nnnn_nnnn  reg[2][7:0] = 'h08
      mem['h0005] = 'h1a00;  // LD r2.h, 00h    1 1ddd_nnnn_nnnn  reg[2][15:9] = 'h00
      mem['h0006] = 'h130f;  // LD r3.l, 0fh    1 0ddd_nnnn_nnnn  reg[3][7:0] = 'h0f
      mem['h0007] = 'h1b00;  // LD r3.h, 00h    1 1ddd_nnnn_nnnn  reg[3][15:9] = 'h00

      mem['h0008] = 'h2201;  // SUB r0, r0, r1  2 001d_ddaa_abbb  reg[0] = reg[0] - reg[1]
      mem['h0009] = 'h3003;  // ST r0, (r3)     3 0000_00aa_abbb  store reg[0] to mem[reg[3]]
      mem['h000a] = 'h10ff;  // LD r0.l, FFh    1 0ddd_nnnn_nnnn  reg[0][7:0] = 'hff
      mem['h000b] = 'h3043;  // LD r0, (r3)     3 0000_01aa_abbb  load reg[0] from mem[reg[3]]
      mem['h000c] = 'h3432;  // JPNZ (r2)       3 01ff_ffaa_abbb  move reg[2] to reg[6] if flag[F]
      mem['h000d] = 'h0000;  // NOP             0 zzzz_zzzz_zzzz  nop
      mem['h000e] = 'hf000;  // HALT            f 0000_0000_0000  halt
      mem['h000f] = 'h0000;  // work area
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
                  rd_data <= mem[addr];
               bus_cmd_write:
                  mem[addr] <= wr_data;
               endcase
               done <= ~done;
               state <= 0;  // there is only one state, no transition
            end
         end
         endcase
      end // else: !if(reset)
   end // always @ (posedge clk)

endmodule
