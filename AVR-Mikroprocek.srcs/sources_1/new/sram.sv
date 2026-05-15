`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 05/15/2026 05:23:27 PM
// Design Name:
// Module Name: sram
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
import cpu_defs::data_word_t;
import cpu_defs::SRAM_MAX_ADDR;
import cpu_defs::sram_command_e;

module sram(
    input logic clk,
    input sram_command_e cmd,
    input addr_word_t addr_in,
    input data_word_t data_in,

    output data_word_t data_out
    );

    data_word_t sram[SRAM_MAX_ADDR:0];

    always_ff @(negedge clk) begin
        case (cmd)
            SRAM_NONE: begin
            end
            SRAM_READ: begin
                data_out <= sram[addr_in];
            end
            SRAM_WRITE: begin
                sram[addr_in] <= data_in;
            end
        endcase
    end
endmodule
