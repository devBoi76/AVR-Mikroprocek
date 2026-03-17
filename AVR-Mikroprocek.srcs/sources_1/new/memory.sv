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

module pmem_memory #(
    parameter BITS = 8, 
    parameter INSTR = 16
)(
    input  logic clk,                       // zegar
    input  logic out_reset,                 // reset wyjścia
    input  logic mem_reset,                 // całkowity reset pamięci mem
    input  logic load_mode,                 // ładowanie programu (1) czy nie (0)
    input  logic [BITS-1:0] load_addr,      // adres z countera
    input  logic [INSTR-1:0] rx_data,       // dane do zapisania
    input  logic rx_valid,                  // dane poprawne i gotowe do zapisu
    input  logic [BITS-1:0] cpu_addr,       // adres odczytu procesora
    output logic [INSTR-1:0] instr_out      // instrukcja wyjściowa 
);
    
    logic [INSTR-1:0] mem [0:(2**BITS)-1];  // pamięć
    integer i;

// mem_reset (1) - reset pamięci wraz z wyjściem
// out_reset (1) - reset samego wyjścia
// load_mode (1) i rx_valid (1) - zapis danych do pamięci
// load_mode (0) - przekazania wskazanej instrukcji do dekodera 


    always_ff @(posedge clk) begin
        if (mem_reset) begin
            for (i = 0; i < (2**BITS); i = i + 1) begin
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