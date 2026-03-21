`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/14/2026 12:34:45 PM
// Design Name: 
// Module Name: decode
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

import cpu_defs::*;

module decode(
    input inst_t inst,
    output opcode_e opcode,
    output reg_addr_t Rd,
    output reg_addr_t Rr,
    output data_word_t K
    );
    
    always_comb begin
        casez (inst.raw)
            16'b1110????????????: begin 
                opcode = OP_LDI;
                Rd = {1'b1, inst.imm.d}; // r16-r31
                K = {inst.imm.K_top_bits, inst.imm.K_btm_bits};
            end
            16'b1001000?????0000: begin
                opcode = OP_LDS;
                Rd = {inst.rr_rd.d};
            end
            16'b1001001?????0000: begin
                opcode = OP_STS;
                Rd = {inst.rr_rd.d};
            end
            16'b1001001?????1111: begin
                opcode = OP_PUSH;
                Rd = {inst.rr_rd.d};
            end
            16'b1001000?????1111: begin
                opcode = OP_POP;
                Rd = {inst.rr_rd.d};
            end
            16'b000011??????????: begin
                opcode = OP_ADD;
                Rd = inst.rr_rd.d;
                Rr = {inst.rr_rd.r_top_bit, inst.rr_rd.r_btm_bits };
            end
            16'b000111??????????: begin
                opcode = OP_ADC;
                Rd = inst.rr_rd.d;
                Rr = {inst.rr_rd.r_top_bit, inst.rr_rd.r_btm_bits };
            end
            16'b000110??????????: begin
                opcode = OP_SUB;
                Rd = inst.rr_rd.d;
                Rr = {inst.rr_rd.r_top_bit, inst.rr_rd.r_btm_bits };
            end
            16'b000010??????????: begin
                opcode = OP_SBC;
                Rd = inst.rr_rd.d;
                Rr = {inst.rr_rd.r_top_bit, inst.rr_rd.r_btm_bits };
            end
            default: begin
                opcode = OP_UNKNOWN;
                Rd = '0;
                Rr = '0;
                K = '0;
            end
        endcase
    end
    
endmodule
