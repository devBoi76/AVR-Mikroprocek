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
    output data_word_t K,
    output addr_io_word_t A
    );
    
    always_comb begin
        opcode = OP_UNKNOWN;
        Rd = '0;
        Rr = '0;
        K = '0;
        A = '0;
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
            16'b001000??????????: begin 
                Rd = inst.rr_rd.d;
                Rr = {inst.rr_rd.r_top_bit, inst.rr_rd.r_btm_bits };
                if(Rd == Rr)
                    opcode = OP_TST;
                else
                    opcode = OP_AND;
            end
            16'b0111????????????: begin
                opcode = OP_ANDI;
                Rd = {1'b1, inst.imm.d};
                K = {inst.imm.K_top_bits, inst.imm.K_btm_bits};
            end
            16'b001010??????????: begin
                opcode = OP_OR;
                Rd = inst.rr_rd.d;
                Rr = {inst.rr_rd.r_top_bit, inst.rr_rd.r_btm_bits };
            end
            16'b0110????????????: begin
                opcode = OP_ORI;
                Rd = {1'b1, inst.imm.d};
                K = {inst.imm.K_top_bits, inst.imm.K_btm_bits};
            end
            16'b001001??????????: begin
                opcode = OP_EOR;
                Rd = inst.rr_rd.d;
                Rr = {inst.rr_rd.r_top_bit, inst.rr_rd.r_btm_bits };
                if(Rd == Rr)
                    opcode = OP_CLR;
                else
                    opcode = OP_EOR;
            end
            16'b1001010?????0011: begin
                opcode = OP_INC;
                Rd = {inst.rr_rd.d};
            end
            16'b1001010?????1010: begin
                opcode = OP_DEC;
                Rd = {inst.rr_rd.d};
            end
            16'b100111??????????: begin
                opcode = OP_MUL;
                Rd = inst.rr_rd.d;
                Rr = {inst.rr_rd.r_top_bit, inst.rr_rd.r_btm_bits };
            end
            16'b00000010????????: begin
                opcode = OP_MULS;
                Rd = {1'b1, inst.raw[7:4]};
                Rr = {1'b1, inst.raw[3:0]};
            end
            16'b001011??????????: begin
                opcode = OP_MOV;
                Rd = inst.rr_rd.d;
                Rr = {inst.rr_rd.r_top_bit, inst.rr_rd.r_btm_bits };
            end            
            16'b10110???????????: begin
                opcode = OP_IN;
                Rd = inst.io.d;
                A = {inst.io.A_top_bits, inst.io.A_btm_bits };
            end
            16'b10111???????????: begin
                opcode = OP_OUT;
                Rr = inst.io.d;
                A = {inst.io.A_top_bits, inst.io.A_btm_bits };
            end
            default: begin
                opcode = OP_UNKNOWN;
                Rd = '0;
                Rr = '0;
                K = '0;
                A = '0;
            end
        endcase
    end
    
endmodule
