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
import cpu_defs::addr_word_t;
import cpu_defs::inst_word_t;

module top #(parameter UART_CLK_FREQ=100_000_000, parameter UART_BR=9600) (input logic clk, input logic uart_rx, input logic load_mode, input logic uart_reset);
    
    addr_word_t prog_addr;
    inst_word_t prog_data;
    logic frame_error;
    
    pmem_top #(.CLK_FREQ(UART_CLK_FREQ), .BR(UART_BR)) pmem (
    .clk(clk), .reset(uart_reset), .load_mode(load_mode), .uart_rx(uart_rx),
    .cpu_addr(prog_addr), .instr_out(prog_data), .frame_error(frame_error));
    
    cpu cpu (.clk(clk & (load_mode == 0)), .prog_addr(prog_addr), .prog_data(prog_data));
endmodule
