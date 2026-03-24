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

typedef enum logic [2:0] {
    MEM_READ_PC,
    MEM_POP_SP,
    MEM_WRITE_PC,
    MEM_FETCH_WAIT
} memop_dir_e;

module cpu(input clk, output addr_word_t prog_addr, input inst_word_t prog_data);    
    
    addr_word_t pc = 0; // program counter
    assign prog_addr = pc;

    data_word_t r[31:0];
    localparam int SRAM_MAX_ADDR = 'h1FFF; // 8KB
    localparam int IO_BASE = 16'h0020; //32
    data_word_t sram[SRAM_MAX_ADDR:0];
    assign sram[31:0] = r[31:0];
    addr_word_t sp = SRAM_MAX_ADDR; // stack pointer

    // zmienne potrzebne do dekodowania instrukcji
    opcode_e opcode;
    reg_addr_t Rd;
    reg_addr_t Rr;
    data_word_t K;
    logic signed [11:0] big_K;
    addr_io_word_t A;
    decode decode (.inst(prog_data), .opcode(opcode), .Rd(Rd), .Rr(Rr), .K(K), .big_K(big_K), .A(A));
    
    // przechowują dane potrzebne do wynokania operacji na pamięci w następnym cyklu
    memop_dir_e memop_dir;
    reg_addr_t memop_r;
    
    //flagi i zmienne do wyliczeń
    flags_t flags = '{C:0, Z:0, N:0, V:0, S:0, H:0, T:0, I:0};
    data_word_t tmp_rd, tmp_rr, result_alu, result_mul_MSB, result_mul_LSB;
    //Można dodać sygnał reset_flags do resetowania wszystkich flag
    
    
    cpu_state_e state = S_EXECUTE;
    always_ff @(negedge clk) begin // always_ff <=> używamy '<=' nieblokujące
        case (state)
            S_EXECUTE: begin
                // W przyszłości lepiej rozbudować to w ten sposób:
                // - np. dodać moduł ALU
                // - podpiąć mu Rd, Rr, opcode, itd.
                // - wysterować sygnał 1 na clk gdy ma wykonać instrukcję
                case (opcode)
                    OP_LDI: begin
                        r[Rd] <= K;
                        pc <= pc + 1;
                        state <= S_EXECUTE;
                    end
                    OP_LDS: begin
                        pc <= pc + 1;
                        memop_r <= Rd;
                        memop_dir <= MEM_READ_PC;  
                        state <= S_MEMOP;
                    end
                    OP_STS: begin
                        pc <= pc + 1;
                        memop_r <= Rd;
                        memop_dir <= MEM_WRITE_PC;
                        state <= S_MEMOP;
                    end
                    OP_PUSH: begin
                        pc <= pc + 1;
                        sram[sp] <= r[Rd];
                        sp <= sp - 1;
                        state <= S_EXECUTE;
                    end
                    OP_POP: begin
                        sp <= sp + 1;
                        memop_r <= Rd;
                        memop_dir <= MEM_POP_SP;
                        state <= S_MEMOP;
                    end
                    OP_ADD: begin
                        pc <= pc + 1;
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
                        pc <= pc + 1;
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
                        pc <= pc + 1;
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
                        pc <= pc + 1;
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
                     OP_AND: begin
                        pc <= pc + 1;
                        result_alu = r[Rd] & r[Rr];
                        r[Rd] <= result_alu;
                        flags.V = 0;
                        flags.N = result_alu[7];
                        flags.S = 0 ^ result_alu[7];
                        flags.Z = (result_alu == 0);
                        state <= S_EXECUTE;
                     end
                     OP_ANDI: begin
                        pc <= pc + 1;
                        result_alu = r[Rd] & K;
                        r[Rd] <= result_alu;
                        flags.V = 0;
                        flags.N = result_alu[7];
                        flags.S = 0 ^ result_alu[7];
                        flags.Z = (result_alu == 0);
                        state <= S_EXECUTE;
                     end
                     OP_OR: begin
                        pc <= pc + 1;
                        result_alu = r[Rd] | r[Rr];
                        r[Rd] <= result_alu;
                        flags.V = 0;
                        flags.N = result_alu[7];
                        flags.Z = (result_alu == 0);
                        flags.S = 0 ^ result_alu[7];
                        state <= S_EXECUTE;
                     end
                     OP_ORI: begin
                        pc <= pc + 1;
                        result_alu = r[Rd] | K;
                        r[Rd] <= result_alu;
                        flags.V = 0;
                        flags.N = result_alu[7];
                        flags.Z = (result_alu == 0);
                        flags.S = 0 ^ result_alu[7];
                        state <= S_EXECUTE;
                     end
                     OP_EOR: begin
                        pc <= pc + 1;
                        result_alu = r[Rd] ^ r[Rr];
                        r[Rd] <= result_alu;
                        flags.V = 0;
                        flags.N = result_alu[7];
                        flags.Z = (result_alu == 0);
                        flags.S = 0 ^ result_alu[7];
                        state <= S_EXECUTE;
                     end
                     OP_INC: begin
                        pc <= pc + 1;
                        result_alu = r[Rd] + 1;
                        r[Rd] <= result_alu;
                        flags.V = (result_alu == 128);
                        flags.N = result_alu[7];
                        flags.S = (result_alu[7]) ^ (result_alu == 128);
                        flags.Z = (result_alu == 0);
                        state <= S_EXECUTE;
                     end
                     OP_DEC: begin
                        pc <= pc + 1;
                        result_alu = r[Rd] - 1;
                        r[Rd] <= result_alu;
                        flags.V = (result_alu == 127);
                        flags.N = result_alu[7];
                        flags.S = (result_alu[7]) ^ (result_alu == 127);
                        flags.Z = (result_alu == 0);
                        state <= S_EXECUTE;
                     end
                     OP_TST: begin
                        pc <= pc + 1;
                        flags.V = 0;
                        flags.N = r[Rd][7];
                        flags.S = 0 ^ r[Rd][7];
                        flags.Z = (r[Rd] == 0);
                        state <= S_EXECUTE;
                     end
                     OP_CLR: begin
                        pc <= pc + 1;
                        flags.S = 0;
                        flags.V = 0;
                        flags.N = 0;
                        flags.Z = 1;
                        r[Rd] = r[Rd] ^ r[Rd];
                        state <= S_EXECUTE;
                     end
                     OP_MUL: begin
                        pc <= pc + 1;
                        {result_mul_MSB, result_mul_LSB} = r[Rd] * r[Rr];
                        r[1] <= result_mul_MSB;
                        r[0] <= result_mul_LSB;
                        flags.C = result_mul_MSB[7];
                        flags.Z = (result_mul_MSB == 0 & result_mul_LSB == 0);
                        state <= S_EXECUTE;
                     end
                     OP_MULS: begin
                        pc <= pc + 1;
                        {result_mul_MSB, result_mul_LSB} = $signed(r[Rd]) * $signed(r[Rr]);
                        r[1] <= result_mul_MSB;
                        r[0] <= result_mul_LSB;
                        flags.C = result_mul_MSB[7];
                        flags.Z = (result_mul_MSB == 0 & result_mul_LSB == 0);
                        state <= S_EXECUTE;
                     end
                     OP_IN: begin
                        pc <= pc + 1;
                        r[Rd] <= sram[IO_BASE + A];
                        state <= S_EXECUTE;
                     end
                     OP_OUT: begin
                        pc <= pc + 1;
                        sram[IO_BASE + A] <= r[Rr];
                        state <= S_EXECUTE;
                     end
                     OP_MOV: begin
                        pc <= pc + 1;
                        r[Rd] <= r[Rr];
                        state <= S_EXECUTE;
                     end
                     OP_RJMP: begin
                        // big_K ma 12 bitów, a pc ma 16 bitów. Trzeba castować, bo jedynki nie są powielane w przypatku ujemnej liczby.
                        pc <= pc + addr_word_t'(signed'(big_K)) + 1;
                        state <= S_EXECUTE;
                     end 
                endcase
            end
            S_MEMOP: begin
                case (memop_dir)
                    MEM_READ_PC: begin
                        pc <= pc + 1;
                        r[memop_r] <= sram[prog_data];
                        state <= S_EXECUTE;
                    end
                    MEM_WRITE_PC: begin
                        pc <= pc + 1;
                        sram[prog_data] <= r[memop_r];
                        state <= S_EXECUTE;
                    end
                    MEM_POP_SP: begin
                        pc <= pc + 1;
                        r[memop_r] <= sram[sp];
                        state <= S_EXECUTE;
                    end
                    MEM_FETCH_WAIT: begin
                        state <= S_EXECUTE;
                    end
                endcase
            end
        
        endcase
    end

endmodule
