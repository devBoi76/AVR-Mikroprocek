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


module cpu(input clk);    
    
    addr_word_t pc; // program counter
    logic pc_reset = 0;
    logic pc_inc = 0;
    counter #(.BITS(BITS_ADDR)) program_counter (.clk(pc_inc), .rst(pc_reset), .count(pc));
    
    inst_word_t prog[15:0];
    initial begin
        prog[0] = 'b1110_0000_0000_1010; // LDI r16, 10
        prog[1] = 'b1110_0001_0001_0100; // LDI r17, 20
        prog[2] = 'b000011_11_0000_0001; // ADD r16, r17
    end
    data_word_t r[31:0];

    // zmienne potrzebne do dekodowania instrukcji
    inst_word_t inst;
    opcode_e opcode;
    reg_addr_t Rd;
    reg_addr_t Rr;
    data_word_t K;
    decode decode (.inst(inst), .opcode(opcode), .Rd(Rd), .Rr(Rr), .K(K));
    
    cpu_state_e state = S_FETCH;
    always_ff @(posedge clk) begin // always_ff <=> używamy '<=' nieblokujące
        if (pc_inc) pc_inc <= 0;
        
        case (state)
            S_FETCH: begin
                inst <= prog[pc];
                state <= S_EXECUTE;
                pc_inc <= 1;
            end
            S_EXECUTE: begin
                // W przyszłości lepiej rozbudować to w ten sposób:
                // - np. dodać moduł ALU
                // - podpiąć mu Rd, Rr, opcode, itd.
                // - wysterować sygnał 1 na clk gdy ma wykonać instrukcję
                case (opcode)
                    OP_LDI: begin
                        r[Rd] <= K;
                        state <= S_FETCH;
                    end
                    OP_ADD: begin
                        r[Rd] <= r[Rd] + r[Rr];
                        state <= S_FETCH; 
                    end
                endcase
            end
        
        endcase
    end

endmodule
