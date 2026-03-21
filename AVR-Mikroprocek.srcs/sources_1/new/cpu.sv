`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/14/2026 12:51:02 PM
// Design Name: 
// Module Name: cpu
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

typedef enum logic [1:0] {
    MEM_READ_PC,
    MEM_POP_SP,
    MEM_WRITE_PC,
    MEM_PUSH_SP
} memop_dir_e;

module cpu(input clk, output addr_word_t prog_addr, input inst_word_t prog_data);    
    
    addr_word_t pc = 0; // program counter
    assign prog_addr = pc;

    data_word_t r[31:0];
    localparam int SRAM_MAX_ADDR = 'h1FFF; // 8KB
    data_word_t sram[SRAM_MAX_ADDR:0];
    assign sram[31:0] = r[31:0];
    addr_word_t sp = SRAM_MAX_ADDR; // stack pointer

    // zmienne potrzebne do dekodowania instrukcji
    opcode_e opcode;
    reg_addr_t Rd;
    reg_addr_t Rr;
    data_word_t K;
    decode decode (.inst(prog_data), .opcode(opcode), .Rd(Rd), .Rr(Rr), .K(K));
    
    // przechowują dane potrzebne do wynokania operacji na pamięci w następnym cyklu
    memop_dir_e memop_dir;
    reg_addr_t memop_r;
    
    //flagi i zmienne do wyliczeń
    flags_t flags = '{C:0, Z:0, N:0, V:0, S:0, H:0, T:0, I:0};
    data_word_t tmp_rd, tmp_rr, result_alu;
    //Można dodać sygnał reset_flags do resetowania wszystkich flag
    
    logic [1:0] pc_inc_amount = 0;
    cpu_state_e state = S_EXECUTE;
    always_ff @(posedge clk) begin // always_ff <=> używamy '<=' nieblokujące
        if (pc_inc_amount > 0) begin
            pc <= pc + 1;
            pc_inc_amount <= pc_inc_amount - 1; 
        end
        case (state)
            S_EXECUTE: begin
                // W przyszłości lepiej rozbudować to w ten sposób:
                // - np. dodać moduł ALU
                // - podpiąć mu Rd, Rr, opcode, itd.
                // - wysterować sygnał 1 na clk gdy ma wykonać instrukcję
                case (opcode)
                    OP_LDI: begin
                        r[Rd] <= K;
                        pc_inc_amount <= 1;
                        state <= S_EXECUTE;
                    end
                    OP_LDS: begin
                        pc_inc_amount <= 2;
                        memop_r <= Rd;
                        memop_dir <= MEM_READ_PC;  
                        state <= S_MEMOP;
                    end
                    OP_STS: begin
                        pc_inc_amount <= 2;
                        memop_r <= Rd;
                        memop_dir <= MEM_WRITE_PC;
                        state <= S_MEMOP;
                    end
                    OP_PUSH: begin
                        pc_inc_amount <= 1;
                        sram[sp] <= r[Rd];
                        memop_dir <= MEM_PUSH_SP;
                        state <= S_MEMOP;
                    end
                    OP_POP: begin
                        pc_inc_amount <= 1;
                        sp <= sp + 1;
                        memop_r <= Rd;
                        memop_dir <= MEM_POP_SP;
                        state <= S_MEMOP;
                    end
                    OP_ADD: begin
                        pc_inc_amount <= 1;
                        tmp_rd = r[Rd];
                        tmp_rr = r[Rr];
                        {flags.C, result_alu} = r[Rd] + r[Rr];
                        r[Rd] <= result_alu;
                        flags.H <= (tmp_rd[3] & tmp_rr[3]) | (tmp_rr[3] & !result_alu[3]) | (tmp_rd[3] & !result_alu[3]);
                        flags.V <= (tmp_rd[7] & tmp_rr[7] & !result_alu[7]) | (!tmp_rd[7] & !tmp_rr[7] & result_alu[7]);
                        flags.N <= result_alu[7];
                        flags.S <= result_alu[7] ^ ((tmp_rd[7] & tmp_rr[7] & !result_alu[7]) | (!tmp_rd[7] & !tmp_rr[7] & result_alu[7]));
                        flags.Z <= (result_alu == 0);
                        state <= S_EXECUTE;
                    end
                    OP_ADC: begin
                        pc_inc_amount <= 1;
                        tmp_rd = r[Rd];
                        tmp_rr = r[Rr];
                        {flags.C, result_alu} = r[Rd] + r[Rr] + flags.C;
                        r[Rd] <= result_alu;
                        flags.H <= (tmp_rd[3] & tmp_rr[3]) | (tmp_rr[3] & !result_alu[3]) | (tmp_rd[3] & !result_alu[3]);
                        flags.V <= (tmp_rd[7] & tmp_rr[7] & !result_alu[7]) | (!tmp_rd[7] & !tmp_rr[7] & result_alu[7]);
                        flags.N <= result_alu[7];
                        flags.S <= result_alu[7] ^ ((tmp_rd[7] & tmp_rr[7] & !result_alu[7]) | (!tmp_rd[7] & !tmp_rr[7] & result_alu[7]));
                        flags.Z <= (result_alu == 0);
                        state <= S_EXECUTE;
                    end
                    OP_SUB: begin
                        pc_inc_amount <= 1;
                        tmp_rd = r[Rd];
                        tmp_rr = r[Rr];
                        result_alu = r[Rd] - r[Rr];
                        flags.C = tmp_rr > tmp_rd;
                        r[Rd] <= result_alu;
                        flags.H <= (!tmp_rd[3] & tmp_rr[3]) | (tmp_rr[3] & result_alu[3]) | (result_alu[3] & !tmp_rd[3]);
                        flags.V <= (tmp_rd[7] & !tmp_rr[7] &!result_alu[7]) | (!tmp_rd[7] & tmp_rr[7] & result_alu[7]);
                        flags.N <= result_alu[7];
                        flags.S <= result_alu[7] ^ ((tmp_rd[7] & !tmp_rr[7] &!result_alu[7]) | (!tmp_rd[7] & tmp_rr[7] & result_alu[7]));
                        flags.Z <= (result_alu == 0);
                        state <= S_EXECUTE;
                     end
                     OP_SBC: begin
                        pc_inc_amount <= 1;
                        tmp_rd = r[Rd];
                        tmp_rr = r[Rr];
                        result_alu = r[Rd] - r[Rr] - flags.C;
                        flags.C = tmp_rr + flags.C > tmp_rd;
                        r[Rd] <= result_alu;
                        flags.H <= (!tmp_rd[3] & tmp_rr[3]) | (tmp_rr[3] & result_alu[3]) | (result_alu[3] & !tmp_rd[3]);
                        flags.V <= (tmp_rd[7] & !tmp_rr[7] & !result_alu[7]) | (!tmp_rd[7] & tmp_rr[7] & result_alu[7]);
                        flags.N <= result_alu[7];
                        flags.S <= result_alu[7] ^((tmp_rd[7] & !tmp_rr[7] & !result_alu[7]) | (!tmp_rd[7] & tmp_rr[7] & result_alu[7]));
                        flags.Z <= (result_alu == 0) & flags.Z;
                        state <= S_EXECUTE;
                     end
                endcase
            end
            S_MEMOP: begin
                case (memop_dir)
                    MEM_READ_PC: begin
                        r[memop_r] <= sram[prog_data];
                        state <= S_EXECUTE;
                    end
                    MEM_WRITE_PC: begin
                        sram[prog_data] <= r[memop_r];
                        state <= S_EXECUTE;
                    end
                    MEM_POP_SP: begin
                        r[memop_r] <= sram[sp];
                        state <= S_EXECUTE;
                    end
                    MEM_PUSH_SP: begin
                        sp <= sp - 1;
                        state <= S_EXECUTE;
                    end
                endcase
            end
        
        endcase
    end

endmodule
