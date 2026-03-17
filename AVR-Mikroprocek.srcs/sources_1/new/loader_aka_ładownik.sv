`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.03.2026 23:27:59
// Design Name: 
// Module Name: loader
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


module loader(
    logic  input clk,
    logic  input reset,
    logic  input load_mode,
    logic  input [7:0] uart_data,
    logic  input uart_valid,
    
    logic output [15:0] data_out,
    logic output instr_valid

    );
    
    
endmodule
