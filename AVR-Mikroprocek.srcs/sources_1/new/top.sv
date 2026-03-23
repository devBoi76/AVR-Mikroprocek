`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/14/2026 07:00:34 PM
// Design Name: 
// Module Name: top
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

module top(input logic clk);
    
    inst_word_t prog[15:0];
    initial begin
        prog[0] = 16'b1110_0000_0000_1010; // LDI r16, 10
        prog[1] = 16'b1110_0001_0001_0100; // LDI r17, 20
        prog[2] = 16'b000011_11_0000_0001; // ADD r16, r17
        prog[3] = 16'b1001001_10000_0000; // STS r16
        prog[4] = 16'b0000_0000_1000_0000; // ADDR = 128
        prog[5] = 16'b1001000_10010_0000; // LDS r18
        prog[6] = 16'b0000_0000_1000_0000; // ADDR = 128
        prog[7] = 16'b1001001_10000_1111; // PUSH r16
        prog[8] = 16'b1001000_00000_1111; // POP r0
        prog[9]  = 16'b0010_1110_0110_0010; // MOV r19, r18
        prog[10] = 16'b1011_1001_0011_0101; // OUT 5, r19
        prog[11] = 16'b1011_0001_0100_0101; // IN r20, 5
    end
    addr_word_t prog_addr;
    inst_word_t prog_data;
    assign prog_data = prog[prog_addr];
    
    cpu cpu (.clk(clk), .prog_addr(prog_addr), .prog_data(prog_data));
endmodule
