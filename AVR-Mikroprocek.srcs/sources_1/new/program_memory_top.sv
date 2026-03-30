`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.03.2026 10:24:17
// Design Name: 
// Module Name: program_memory_top
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

module pmem_top
    # (
    parameter CLK_FREQ,
    parameter BR
    )
    (

    input  logic    clk,
    input  logic    reset,
    input  logic    load_mode,
    input  logic    uart_rx,
    input  addr_word_t cpu_addr,
    
    output inst_word_t instr_out,
    output logic    frame_error
  
    );
    
    logic [7:0]  uart_data;
    logic        uart_valid;

    inst_word_t  instr_data;
    logic        instr_valid;

    addr_word_t  load_addr;
    
    pmem_uart #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BR)) u_pmem_uart (
        .clk(clk),
        .reset(reset),
        .uart_rx(uart_rx),
        .data_out(uart_data),
        .data_valid(uart_valid),
        .frame_error(frame_error)
    );
    
    pmem_loader u_pmem_loader (
        .clk(clk),
        .reset(reset),
        .load_mode(load_mode),
        .uart_data(uart_data),
        .uart_valid(uart_valid),
        .data_out(instr_data),
        .instr_valid(instr_valid)
    );
    
    localparam ADDR_BITS = 8;
    pmem_counter #(.BITS(ADDR_BITS)) u_pmem_counter (
        .clk(clk),
        .rst(reset),
        .enable(instr_valid),
        .count(load_addr)
    );
    
    pmem_memory #(.ADDR_BITS(ADDR_BITS)) u_pmem_memory (
        .clk(clk),
        .out_reset(reset),
        .mem_reset(reset),
        .load_mode(load_mode),
        .load_addr(load_addr),
        .rx_data(instr_data),
        .rx_valid(instr_valid),
        .cpu_addr(cpu_addr), // 
        .instr_out(instr_out)
    );

    
endmodule
