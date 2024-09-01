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
   reg [15:0] mem[15:0];

   wire clk;
   assign clk = S1;
   wire reset_sw;
   assign reset_sw = S2;

   `define reg_pc regs[6]
   `define reg_flag regs[7]

   logic [63:0] counter = 0;
   always @(posedge clk)
     counter <= counter + 1;

   parameter NUM_CASCADES = 2;
   wire [7:0] frame[4 * NUM_CASCADES];
   assign frame[0] = `reg_pc[15:8];
   assign frame[1] = `reg_pc[7:0];
   assign frame[2] = ins[15:8];
   assign frame[3] = ins[7:0];
   assign frame[4] = regs[0][15:8];
   assign frame[5] = regs[0][7:0];
   assign frame[6] = mem[0][15:8];
   assign frame[7] = mem[0][7:0];

   initial begin
      reset = 1;
      mem['h0000] = 'h0012;  // 0000_0ddd_nnnn_nnnn  reg[0][7:0] = 'h12
      mem['h0001] = 'h0800;  // 0000_1ddd_nnnn_nnnn  reg[0][15:9] = 'h00
      mem['h0002] = 'h0134;  // 0000_0ddd_nnnn_nnnn  reg[1][7:0] = 'h34
      mem['h0003] = 'h0900;  // 0000_1ddd_nnnn_nnnn  reg[1][15:9] = 'h00
      mem['h0004] = 'h1001;  // 0001_000d_ddaa_abbb  reg[0] = reg[0] + reg[1]
      mem['h0005] = 'h0100;  // 0000_0ddd_nnnn_nnnn  reg[1][7:0] = 'h00
      mem['h0006] = 'h2001;  // 0010_0000_00aa_abbb  store reg[0] to mem[reg[1]]
      mem['h0007] = 'h00ff;  // 0000_0ddd_nnnn_nnnn  reg[0][7:0] = 'hff
      mem['h0008] = 'h2041;  // 0010_0000_01aa_abbb  load reg[0] from mem[reg[1]]
      mem['h0009] = 'hf000;  // 1111_0000_0000_0000  halt
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
         case (ins & 'hf000)
         'h0000:
            case (ins[11])
            0:  // 0000_0ddd_nnnn_nnnn  load immediate lower half of reg[D]
              regs[ins[10:8]] <= (regs[ins[10:8]] & 'hff00 | (ins & 'hff));
            1:  // 0000_1ddd_nnnn_nnnn  load immediate upper half of reg[D]
              regs[ins[10:8]] <= (regs[ins[10:8]] & 'h00ff | (ins & 'hff) << 8);
            endcase
         'h1000:
            case (ins[11:9])
            0:  // 0001_000d_ddaa_abbb  reg[D] = reg[A] + reg[B]
              regs[ins[8:6]] <= regs[ins[5:3]] + regs[ins[2:0]];
            endcase
         'h2000:
            case (ins[11:6])
            0:  // 0010_0000_00aa_abbb  store reg[A] to mem[reg[B]]
              mem[regs[ins[2:0]]] <= regs[ins[5:3]];
            1:  // 0010_0000_01aa_abbb  load reg[A] from mem[reg[B]]
              regs[ins[5:3]] <= mem[regs[ins[2:0]]];
            endcase
         'hf000:
            case (ins[11:0])
            0:  // 1111_0000_0000_0000  halt
              halt <= 1;
            endcase
         endcase
         `reg_pc <= `reg_pc + 1;
      end
   end

   max7219_display #( .NUM_CASCADES(NUM_CASCADES), .INTENSITY(1) )
     disp(sysclk, reset_sw, frame, spi_clk, dout, cs, stop, pin);

endmodule
