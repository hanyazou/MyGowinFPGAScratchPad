//  0 0000_0000_0000  NOP
function [15:0] I_NOP;
   return { 4'h0, 12'b0000_0000_0000 };
endfunction

//  0 0000_0000_0001  HALT
function [15:0] I_HALT;
   return { 4'h0, 12'b0000_0000_0001 };
endfunction

//  0 0100_00ff_rrrr JPN f, (R) (jump to R if F is false)
function [15:0] I_JP_N_(flag_num_t f, reg_num_t r);
   return { 4'h0, 6'b0100_00, f[1:0], r[3:0] };
endfunction
function [15:0] I_JP_NZ(reg_num_t r);
   return I_JP_N_(reg_flag_zero, r);
endfunction

//  1 dddd_nnnn_nnnn  reg[D][7:0] = n
function [15:0] I_LD_RL_I(reg_num_t r, int i);
   return { 4'h1, r[3:0], i[7:0]};
endfunction

//  2 dddd_nnnn_nnnn  reg[D][15:8] = 8'hzz
function [15:0] I_LD_RH_I(reg_num_t r, int i);
   return { 4'h2, r[3:0], i[7:0]};
endfunction

//
//  memory load/store
//
//  3 ttt0_aaaa_abbb R/W reg[A] from/to memory address reg[B]
function [15:0] I_LD_M_R (reg_num_t rb, reg_num_t ra);
   return { 4'h3, bus_cmd_write,   BUS_MEM, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_LD_R_M (reg_num_t ra, reg_num_t rb);
   return { 4'h3, bus_cmd_read,    BUS_MEM, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_LD_M_RW(reg_num_t rb, reg_num_t ra);
   return { 4'h3, bus_cmd_write_w, BUS_MEM, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_LD_RW_M(reg_num_t ra, reg_num_t rb);
   return { 4'h3, bus_cmd_read_w,  BUS_MEM, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_LD_M_RB(reg_num_t rb, reg_num_t ra);
   return { 4'h3, bus_cmd_write_b, BUS_MEM, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_LD_RB_M(reg_num_t ra, reg_num_t rb);
   return { 4'h3, bus_cmd_read_b,  BUS_MEM, ra[3:0], rb[3:0] };
endfunction

//
//  I/O read/write
//
//  3 ttt1_aaaa_abbb R/W reg[A] from/to I/O address reg[B]
function [15:0] I_OUT (reg_num_t rb, reg_num_t ra);
   return { 4'h3, bus_cmd_write,   BUS_IO, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_IN  (reg_num_t ra, reg_num_t rb);
   return { 4'h3, bus_cmd_read,    BUS_IO, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_OUTW(reg_num_t rb, reg_num_t ra);
   return { 4'h3, bus_cmd_write_w, BUS_IO, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_INW (reg_num_t ra, reg_num_t rb);
   return { 4'h3, bus_cmd_read_w,  BUS_IO, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_OUTB(reg_num_t rb, reg_num_t ra);
   return { 4'h3, bus_cmd_write_b, BUS_IO, ra[3:0], rb[3:0] };
endfunction
function [15:0] I_INB (reg_num_t ra, reg_num_t rb);
   return { 4'h3, bus_cmd_read_b,  BUS_IO, ra[3:0], rb[3:0] };
endfunction

//
//  move
//
function [15:0] I_LD_R_R(reg_num_t rb, reg_num_t ra);
   if (ra[4] && ~rb[4])
     //  3 110a_aaaa_bbbb  move reg[A] to reg[B]
     return { 4'h3, 3'b110, ra[4:0], rb[3:0] };
   else
   if (~ra[4] && rb[4])
     //  3 111a_aaaa_bbbb  move reg[B] to reg[A]
     return { 4'h3, 3'b111, rb[4:0], ra[3:0] };
   else
     return { 4'h0, 4'h0, 8'hff };  // invalid instruction
endfunction

//
//  three register operations
//
//  8 dddd_aaaa_bbbb  reg[D] = reg[A] + reg[B]
function [15:0] I_ADD(reg_num_t dst, reg_num_t ra, reg_num_t rb);
   return { 4'h8, dst[3:0], ra[3:0], rb[3:0] };
endfunction

//  9 001d_ddaa_abbb  reg[D] = reg[A] - reg[B]
function [15:0] I_SUB(reg_num_t dst, reg_num_t ra, reg_num_t rb);
   return { 4'h9, dst[3:0], ra[3:0], rb[3:0] };
endfunction
