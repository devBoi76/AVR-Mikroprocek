`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.03.2026 15:04:39
// Design Name: 
// Module Name: memory
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
import cpu_defs::BITS_INST;

module pmem_memory #(
    parameter ADDR_BITS
) (
    input  logic clk,
    input  logic out_reset,                     // reset wyjścia
    input  logic mem_reset,                     // całkowity reset pamięci mem
    input  logic load_mode,                     // ładowanie programu (1) czy nie (0)
    input  logic [ADDR_BITS-1:0] load_addr,     // adres z countera
    input  logic [BITS_INST-1:0] rx_data,       // dane do zapisania
    input  logic rx_valid,                      // dane poprawne i gotowe do zapisu
    input  logic [ADDR_BITS-1:0] cpu_addr,      // adres odczytu procesora
    output logic [BITS_INST-1:0] instr_out      // instrukcja wyjściowa 
);
    logic [BITS_INST-1:0] mem [0:(2**ADDR_BITS)-1];
    integer i;

// Działanie:
// mem_reset - zeruje całą pamięć mem oraz wyjście instr_out
// out_reset - zeruje tylko wyjście instr_out
// load_mode = 1 i rx_valid = 1 - zapisuje rx_data do pamięci pod adres load_addr
// load_mode = 0 - odczytuje z pamięci instrukcję spod cpu_addr i wystawia ją na instr_out
// load_mode = 1 - blokuje normalne wyjście do CPU i ustawia instr_out na 0

    always_ff @(posedge clk) begin
        if (mem_reset) begin
            for (i = 0; i < (2**ADDR_BITS); i = i + 1) begin
                mem[i] <= 0;
            end
            instr_out <= 0;
        end
        else if (out_reset) begin
            instr_out <= 0;           
        end
        else begin
            if (load_mode && rx_valid) begin
                mem[load_addr] <= rx_data;
            end
                
            if (!load_mode) begin
                instr_out <= mem[cpu_addr];
            end
            else begin
                instr_out <= 0;
            end 
        end
    end

endmodule