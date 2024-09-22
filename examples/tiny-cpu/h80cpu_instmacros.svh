function ins_t I_NOP;           return { 4'h0, 12'b0000_0000_0000 }; endfunction
function ins_t I_HALT;          return { 4'h0, 12'b0000_0000_0001 }; endfunction
function ins_t I_RET;           return { 4'h0, 12'b0000_0000_0010 }; endfunction
// 0000_0000_0000_0011 to 0111_1110 reserved
function ins_t I_INV;           return { 4'h0, 12'b0000_0111_1111 }; endfunction

function ins_t I_RET_N_(flag_num_t f);  return { 4'h0, 8'b0000_1000, 2'b00, f[1:0] }; endfunction
function ins_t I_RET_NZ;                return I_RET_N_(reg_flag_zero); endfunction
function ins_t I_RET_(flag_num_t f);    return { 4'h0, 8'b0000_1000, 2'b01, f[1:0] }; endfunction
function ins_t I_RET_Z;                 return I_RET_(reg_flag_zero); endfunction
// 0000_0000_1000_1000 to 1111_1111 reserved

function ins_t I_PUSH_R(reg_num_t r);   return { 4'h0, 8'b0001_0000, r[3:0] }; endfunction
function ins_t I_POP_R(reg_num_t r);    return { 4'h0, 8'b0001_0001, r[3:0] }; endfunction
function ins_t I_EXTN_RW(reg_num_t r);  return { 4'h0, 8'b0001_0010, r[3:0] }; endfunction
function ins_t I_EXTN_RB(reg_num_t r);  return { 4'h0, 8'b0001_0011, r[3:0] }; endfunction

function ins_t I_CPL_R(reg_num_t r);    return { 4'h0, 8'b0001_0100, r[3:0] }; endfunction
function ins_t I_NEG_R(reg_num_t r);    return { 4'h0, 8'b0001_0101, r[3:0] }; endfunction
function ins_t I_LD_R_I(reg_num_t r);   return { 4'h0, 8'b0001_0110, r[3:0] }; endfunction
function ins_t I_LD_RW_I(reg_num_t r);  return { 4'h0, 8'b0001_0111, r[3:0] }; endfunction

function ins_t I_INVF(flag_num_t f);    return { 4'h0, 8'b0001_1000, f[3:0] }; endfunction
function ins_t I_SETF(flag_num_t f);    return { 4'h0, 8'b0001_1001, f[3:0] }; endfunction
function ins_t I_CLRF(flag_num_t f);    return { 4'h0, 8'b0001_1010, f[3:0] }; endfunction
function ins_t I_TESTF(flag_num_t f);   return { 4'h0, 8'b0001_1011, f[3:0] }; endfunction

function ins_t I_CALL_R(reg_num_t r);   return { 4'h0, 8'b0001_1100, r[3:0] }; endfunction
function ins_t I_RST_N(bus_addr_t n);   return { 4'h0, 8'b0001_1101, 4'(n/8) }; endfunction
function ins_t I_JP_R(reg_num_t r);     return { 4'h0, 8'b0001_1110, r[3:0] }; endfunction
function ins_t I_JR_R(reg_num_t r);     return { 4'h0, 8'b0001_1111, r[3:0] }; endfunction

//  0 0010_00ff_rrrr CALLN f, (R) (call R if F is false)
function [15:0] I_CALL_N_(flag_num_t f, reg_num_t r);
   return { 4'h0, 6'b0010_00, f[1:0], r[3:0] };
endfunction
function [15:0] I_CALL_NZ(reg_num_t r);
   return I_CALL_N_(reg_flag_zero, r);
endfunction

//  0 0010_01ff_rrrr CALL f, (R) (call to R if F is false)
function [15:0] I_CALL_(flag_num_t f, reg_num_t r);
   return { 4'h0, 6'b0010_01, f[1:0], r[3:0] };
endfunction
function [15:0] I_CALL_Z(reg_num_t r);
   return I_CALL_(reg_flag_zero, r);
endfunction

//  0 0010_10ff_rrrr reserved 空き
//  0 0010_11ff_rrrr reserved 空き

//  0 0011_00ff_rrrr JPN f, (R) (jump to R if F is false)
function [15:0] I_JP_N_(flag_num_t f, reg_num_t r);
   return { 4'h0, 6'b0011_00, f[1:0], r[3:0] };
endfunction
function [15:0] I_JP_NZ(reg_num_t r); return I_JP_N_(reg_flag_zero, r);         endfunction
function [15:0] I_JP_NC(reg_num_t r); return I_JP_N_(reg_flag_carry, r);        endfunction
function [15:0] I_JP_NV(reg_num_t r); return I_JP_N_(reg_flag_overflow, r);     endfunction
function [15:0] I_JP_NP(reg_num_t r); return I_JP_N_(reg_flag_parity, r);       endfunction
function [15:0] I_JP_NS(reg_num_t r); return I_JP_N_(reg_flag_sign, r);         endfunction

//  0 0011_01ff_rrrr JP f, (R) (jump to R if F is false)
function [15:0] I_JP_(flag_num_t f, reg_num_t r);
   return { 4'h0, 6'b0011_01, f[1:0], r[3:0] };
endfunction
function [15:0] I_JP_Z (reg_num_t r); return I_JP_(reg_flag_zero, r);           endfunction
function [15:0] I_JP_C (reg_num_t r); return I_JP_(reg_flag_carry, r);          endfunction
function [15:0] I_JP_V (reg_num_t r); return I_JP_(reg_flag_overflow, r);       endfunction
function [15:0] I_JP_P (reg_num_t r); return I_JP_(reg_flag_parity, r);         endfunction
function [15:0] I_JP_S (reg_num_t r); return I_JP_(reg_flag_sign, r);           endfunction

//  0 0011_10ff_rrrr JRN f, (R) (jump to R if F is false)
function [15:0] I_JR_N_(flag_num_t f, reg_num_t r);
   return { 4'h0, 6'b0011_10, f[1:0], r[3:0] };
endfunction
function [15:0] I_JR_NZ(reg_num_t r); return I_JR_N_(reg_flag_zero, r);         endfunction
function [15:0] I_JR_NC(reg_num_t r); return I_JR_N_(reg_flag_carry, r);        endfunction
function [15:0] I_JR_NV(reg_num_t r); return I_JR_N_(reg_flag_overflow, r);     endfunction
function [15:0] I_JR_NP(reg_num_t r); return I_JR_N_(reg_flag_parity, r);       endfunction
function [15:0] I_JR_NS(reg_num_t r); return I_JR_N_(reg_flag_sign, r);         endfunction

//  0 0011_11ff_rrrr JR f, (R) (jump to R if F is false)
function [15:0] I_JR_(flag_num_t f, reg_num_t r);
   return { 4'h0, 6'b0011_11, f[1:0], r[3:0] };
endfunction
function [15:0] I_JR_Z (reg_num_t r); return I_JR_(reg_flag_zero, r);           endfunction
function [15:0] I_JR_C (reg_num_t r); return I_JR_(reg_flag_carry, r);          endfunction
function [15:0] I_JR_V (reg_num_t r); return I_JR_(reg_flag_overflow, r);       endfunction
function [15:0] I_JR_P (reg_num_t r); return I_JR_(reg_flag_parity, r);         endfunction
function [15:0] I_JR_S (reg_num_t r); return I_JR_(reg_flag_sign, r);           endfunction

function ins_t I_SRA_R_I(reg_num_t a, n); return { 4'h0, 4'b0100, a[3:0], n[3:0] }; endfunction
function ins_t I_SRL_R_I(reg_num_t a, n); return { 4'h0, 4'b0101, a[3:0], n[3:0] }; endfunction
function ins_t I_SL_R_I (reg_num_t a, n); return { 4'h0, 4'b0110, a[3:0], n[3:0] }; endfunction
function ins_t I_RLC_R_I(reg_num_t a, n); return { 4'h0, 4'b0111, a[3:0], n[3:0] }; endfunction
function ins_t I_ADD_R_I(reg_num_t a, n); return { 4'h0, 4'b1000, a[3:0], n[3:0] }; endfunction
function ins_t I_SUB_R_I(reg_num_t a, n); return { 4'h0, 4'b1001, a[3:0], n[3:0] }; endfunction

//  0 1010_aaaa_bbbb DJNZ A, (B) (decrement A and jump to B if A is not zero)
function ins_t I_DJNZ(reg_num_t a, b);  return { 4'h0, 4'b1010, a[3:0], b[3:0] }; endfunction

//  0 110a_aaaa_bbbb EX A, B
function [15:0] I_EX_R_R(reg_num_t a, b);
   if (a[4] && ~b[4])
     return { 4'h0, 3'b110, a[4:0], b[3:0] };
   else
   if (~a[4] && b[4])
     return { 4'h0, 3'b110, b[4:0], a[3:0] };
   else
     return I_INV();
endfunction

//  0 1110_aaaa_bbbb reserved 空き
//  0 1111_aaaa_bbbb reserved 空き

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
function [15:0] I_ADD(reg_num_t dst, reg_num_t ra, reg_num_t rb);
   return { 4'h8, dst[3:0], ra[3:0], rb[3:0] };
endfunction
function [15:0] I_SUB(reg_num_t dst, reg_num_t ra, reg_num_t rb);
   return { 4'h9, dst[3:0], ra[3:0], rb[3:0] };
endfunction
function [15:0] I_MUL(reg_num_t dst, reg_num_t ra, reg_num_t rb);
   return { 4'ha, dst[3:0], ra[3:0], rb[3:0] };
endfunction
function [15:0] I_DIV(reg_num_t dst, reg_num_t ra, reg_num_t rb);
   return { 4'hb, dst[3:0], ra[3:0], rb[3:0] };
endfunction
function [15:0] I_AND(reg_num_t dst, reg_num_t ra, reg_num_t rb);
   return { 4'hc, dst[3:0], ra[3:0], rb[3:0] };
endfunction
function [15:0] I_OR (reg_num_t dst, reg_num_t ra, reg_num_t rb);
   return { 4'hd, dst[3:0], ra[3:0], rb[3:0] };
endfunction
function [15:0] I_XOR(reg_num_t dst, reg_num_t ra, reg_num_t rb);
   return { 4'he, dst[3:0], ra[3:0], rb[3:0] };
endfunction
function [15:0] I_CP (reg_num_t dst, reg_num_t ra, reg_num_t rb);
   return { 4'hf, dst[3:0], ra[3:0], rb[3:0] };
endfunction
