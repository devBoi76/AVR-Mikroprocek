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

typedef enum logic {
    MEM_READ,
    MEM_WRITE
} memop_dir_e;

module cpu(input clk);    
    
    addr_word_t pc = 0; // program counter
    
    //logic pc_reset = 0;
    //logic pc_inc = 0;
    //counter #(.BITS(BITS_ADDR)) program_counter (.clk(pc_inc), .rst(pc_reset), .count(pc));
    
    inst_word_t prog[15:0];
    initial begin
        prog[0] = 'b1110_0000_0000_1010; // LDI r16, 10
        prog[1] = 'b1110_0001_0001_0100; // LDI r17, 20
        prog[2] = 'b000011_11_0000_0001; // ADD r16, r17
        prog[3] = 'b1001001_10000_0000; // STS r16
        prog[4] = 'b0000_0000_1000_0000; // ADDR = 128
        prog[5] = 'b1001000_10010_0000; // LDS r18
        prog[6] = 'b0000_0000_1000_0000; // ADDR = 128
    end
    data_word_t r[31:0];
    localparam int SRAM_MAX_ADDR = 'h1FFF; // 8KB
    data_word_t sram[SRAM_MAX_ADDR:0];
    assign sram[31:0] = r[31:0];

    // zmienne potrzebne do dekodowania instrukcji
    opcode_e opcode;
    reg_addr_t Rd;
    reg_addr_t Rr;
    data_word_t K;
    decode decode (.inst(prog[pc]), .opcode(opcode), .Rd(Rd), .Rr(Rr), .K(K));
    
    // przechowują dane potrzebne do wynokania operacji na pamięci w następnym cyklu
    memop_dir_e memop_dir;
    reg_addr_t memop_r;
    
    cpu_state_e state = S_EXECUTE;
    always_ff @(posedge clk) begin // always_ff <=> używamy '<=' nieblokujące
        pc <= pc + 1;
        case (state)
            S_EXECUTE: begin
                // W przyszłości lepiej rozbudować to w ten sposób:
                // - np. dodać moduł ALU
                // - podpiąć mu Rd, Rr, opcode, itd.
                // - wysterować sygnał 1 na clk gdy ma wykonać instrukcję
                case (opcode)
                    OP_LDI: begin
                        r[Rd] <= K;
                        state <= S_EXECUTE;
                    end
                    OP_LDS: begin
                        memop_r <= Rd;
                        memop_dir <= MEM_READ;  
                        state <= S_MEMOP;
                    end
                    OP_STS: begin
                        memop_r <= Rd;
                        memop_dir <= MEM_WRITE;
                        state <= S_MEMOP;
                    end
                    OP_ADD: begin
                        r[Rd] <= r[Rd] + r[Rr];
                        state <= S_EXECUTE; 
                    end
                endcase
            end
            S_MEMOP: begin
                case (memop_dir)
                    MEM_READ: begin
                        r[memop_r] <= sram[prog[pc]];
                        state <= S_EXECUTE;
                    end
                    MEM_WRITE: begin
                        sram[prog[pc]] <= r[memop_r];
                        state <= S_EXECUTE;
                    end
                endcase
            end
        
        endcase
    end

endmodule
