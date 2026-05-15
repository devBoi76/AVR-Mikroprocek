`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 05/15/2026 08:25:17 PM
// Design Name:
// Module Name: dataspace
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
import cpu_defs::addr_io_word_t;
import cpu_defs::data_word_t;
import cpu_defs::REG_MAX_ADDR;
import cpu_defs::MMIO_ADDR_SIZE;
import cpu_defs::MMIO_MAX_ADDR;


// - asynchroniczny odczyt rejestrów
// - synchroniczny odczyt
// - synchroniczny zapis (rejestrów, mmio, sram) @posedge clk
module dataspace(
    input logic clk,
    input dataspace_memop_e memop,

    input reg_addr_t Rmemop,
    input addr_word_t sram_addr_in,

    input addr_io_word_t mmio_addr_in,

    input reg_addr_t Rd,
    input data_word_t Rd_data_in,
    input data_word_t Rd_data_out,
    input reg_addr_t Rr,
    input data_word_t Rr_data_in,
    input data_word_t Rr_data_out
    );

    data_word_t registers[REG_MAX_ADDR-1:0];
    data_word_t mmio[MMIO_ADDR_SIZE-1:0];
    data_word_t sram[SRAM_MAX_ADDR-MMIO_MAX_ADDR:0];

    // odczyt rejestrów kombinacyjnie
    always_comb begin
        Rd_data_out = registers[Rd];
        Rr_data_out = registers[Rr];
    end

    always_ff @(posedge clk) begin
        case(memop)
            DATASPACE_MEM_NONE: begin end
            DATASPACE_MEM_MOV: begin
                registers[Rd] <= registers[Rr];
            end
            DATASPACE_MEM_DOUBLE_WRITE: begin
                registers[Rmemop] <= Rd_data_in;
                registers[Rmemop + 1] <= Rr_data_in;
            end
            DATASPACE_MEM_REG_WRITE: begin
                registers[Rd] <= Rd_data_in;
                registers[Rr] <= Rr_data_in;
            end
            DATASPACE_MEM_MMIO_READ: begin
                registers[Rd] <= mmio[mmio_addr_in];
            end
            DATASPACE_MEM_MMIO_WRITE: begin
                mmio[mmio_addr_in] <= registers[Rr];
            end
            DATASPACE_MEM_SRAM_READ: begin
                if (sram_addr_in < REG_MAX_ADDR) begin
                    registers[Rmemop] <= registers[sram_addr_in];
                end else if (sram_addr_in < MMIO_MAX_ADDR) begin
                    registers[Rmemop] <= mmio[sram_addr_in - REG_MAX_ADDR];
                end else begin
                    registers[Rmemop] <= sram[sram_addr_in];
                end
            end
            DATASPACE_MEM_SRAM_WRITE: begin
                if (sram_addr_in < REG_MAX_ADDR) begin
                    registers[sram_addr_in] <= registers[Rmemop];
                end else if (sram_addr_in < MMIO_MAX_ADDR) begin
                    mmio[sram_addr_in - REG_MAX_ADDR] <= registers[Rmemop];
                end else begin
                    sram[sram_addr_in] <= registers[Rmemop];
                end
            end
        endcase
    end

endmodule
