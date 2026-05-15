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
    MEM_FETCH_WAIT,
    MEM_CALL,
    MEM_RET1,
    MEM_RET2
} memop_dir_e;

module cpu(input clk, 
    output addr_word_t prog_addr,
    input inst_word_t prog_data, 
    //Poniższe I/O są używane do przekazywania danych do ALU
    output opcode_e opcode_out, 
    output data_word_t alu_primary, 
    output data_word_t alu_secondary, 
    output flags_t flags_out,
    //Poniżej wejścia do zmiany flag oraz zawartości rejestrów
    input data_word_t register_in,
    input data_word_t multiply_high,
    input flags_t flags_in);    


    
    addr_word_t pc = 0; // program counter
    assign prog_addr = pc;
    addr_word_t pc_plus_one; 
    assign pc_plus_one = pc + 1;
    addr_word_t pc_plus_two;
    assign pc_plus_two = pc + 2;

    data_word_t r[31:0];
    localparam int SRAM_MAX_ADDR = 'h3FF; // 1KB 'h1FFF; // 8KB
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
    addr_word_t scratch_addr_reg; // Używany w czytaniu stosu przy wykonywaniu RET
    
    //flagi i zmienne do wyliczeń
    flags_t flags = '{C:0, Z:0, N:0, V:0, S:0, H:0, T:0, I:0};
    data_word_t tmp_rd, tmp_rr, result_alu, result_mul_MSB, result_mul_LSB;
    
    //Sygnał mówiący czy operacja jest mnożeniem (potrzebuje 2 rejestrów)
    logic is_it_mul = 1'b0;
    
    //Utrzymanie rejestru rd i opcode do alu
    reg_addr_t alu_rd;
    opcode_e alu_opcode;
    
    //Źródło sygnału
    source_e source = NONE;
    //Można dodać sygnał reset_flags do resetowania wszystkich flag
    
    
    cpu_state_e state = S_EXECUTE;
    always_ff @(negedge clk) begin // always_ff <=> używamy '<=' nieblokujące
        opcode_out <= opcode;
        flags_out <= flags;
        alu_rd <= Rd;
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
                        alu_primary <= r[Rd];
                        alu_secondary <= r[Rr];
                        state <= S_EXECUTE;
                        source <= SOURCE_ALU;
                    end
                    OP_ADC: begin
                        pc <= pc + 1;
                        alu_primary <= r[Rd];
                        alu_secondary <= r[Rr];
                        state <= S_EXECUTE;
                        source <= SOURCE_ALU;
                    end
                    OP_SUB: begin
                        pc <= pc + 1;
                        alu_primary <= r[Rd];
                        alu_secondary <= r[Rr];
                        state <= S_EXECUTE;
                        source <= SOURCE_ALU;
                     end
                     OP_SBC: begin
                        pc <= pc + 1;
                        alu_primary <= r[Rd];
                        alu_secondary <= r[Rr];
                        state <= S_EXECUTE;
                        source <= SOURCE_ALU;
                     end
                     OP_AND: begin
                        pc <= pc + 1;
                        alu_primary <= r[Rd];
                        alu_secondary <= r[Rr];
                        state <= S_EXECUTE;
                        source <= SOURCE_ALU;
                     end
                     OP_ANDI: begin
                        pc <= pc + 1;
                        alu_primary <= r[Rd];
                        alu_secondary <= K;
                        state <= S_EXECUTE;
                        source <= SOURCE_ALU;
                     end
                     OP_OR: begin
                        pc <= pc + 1;
                        alu_primary <= r[Rd];
                        alu_secondary <= r[Rr];
                        state <= S_EXECUTE;
                        source <= SOURCE_ALU;
                     end
                     OP_ORI: begin
                        pc <= pc + 1;
                        alu_primary <= r[Rd];
                        alu_secondary <= K;
                        state <= S_EXECUTE;
                        source <= SOURCE_ALU;
                     end
                     OP_EOR: begin
                        pc <= pc + 1;
                        alu_primary <= r[Rd];
                        alu_secondary <= r[Rr];
                        state <= S_EXECUTE;
                        source <= SOURCE_ALU;
                     end
                     OP_INC: begin
                        pc <= pc + 1;
                        alu_primary <= r[Rd];
                        state <= S_EXECUTE;
                        source <= SOURCE_ALU;
                     end
                     OP_DEC: begin
                        pc <= pc + 1;
                        alu_primary <= r[Rd];
                        state <= S_EXECUTE;
                        source <= SOURCE_ALU;
                     end
                     OP_TST: begin
                        pc <= pc + 1;
                        alu_primary <= r[Rd];
                        state <= S_EXECUTE;
                        source <= SOURCE_ALU;
                     end
                     OP_CLR: begin
                        pc <= pc + 1;
                        alu_primary <= r[Rd];
                        state <= S_EXECUTE;
                        source <= SOURCE_ALU;
                     end
                     OP_MUL: begin
                        pc <= pc + 1;
                        is_it_mul <= 1;
                        alu_primary <= r[Rd];
                        alu_secondary <= r[Rr];
                        state <= S_EXECUTE;
                        source <= SOURCE_ALU;
                     end
                     OP_MULS: begin
                        pc <= pc + 1;
                        is_it_mul <= 1;
                        alu_primary <= r[Rd];
                        alu_secondary <= r[Rr];
                        state <= S_EXECUTE;
                        source <= SOURCE_ALU;
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
                     OP_BRNE: begin
                        if (flags.Z == 0)
                            pc <=  pc + addr_word_t'(signed'(big_K)) + 1;
                        else
                            pc <= pc + 1;
                        state <= S_EXECUTE;
                     end
                     OP_BREQ: begin
                        if (flags.Z == 1)
                            pc <=  pc + addr_word_t'(signed'(big_K)) + 1;
                        else
                            pc <= pc + 1;
                        state <= S_EXECUTE;
                     end
                     OP_CALL: begin
                        pc <= pc + 1;
                        memop_dir <= MEM_CALL;
                        state <= S_MEMOP;
                        // push PC to stack. `PC+2` bo mamy: <call> <addr> <inna instrukcja>
                        sram[sp] <= pc_plus_two[15:8]; // high byte
                        sp <= sp - 1;
                     end
                     OP_RET: begin
                        sp <= sp + 1;
                        memop_dir <= MEM_RET1;
                        state <= S_MEMOP;
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
                    MEM_CALL: begin
                        pc <= prog_data;
                        state <= S_EXECUTE;
                        // `PC+1` bo mamy: <addr> <inna instrukcja>
                        sram[sp] <= pc_plus_one[7:0]; // low byte
                        sp <= sp - 1;
                    end
                    MEM_RET1: begin
                        sp <= sp + 1;
                        scratch_addr_reg[7:0] <= sram[sp]; // low byte
                        memop_dir <= MEM_RET2;
                        state <= S_MEMOP;
                    end
                    MEM_RET2: begin
                        pc <= {sram[sp], scratch_addr_reg[7:0]};
                        state <= S_EXECUTE;
                    end
                endcase
            end
        
        endcase
    end
    always_ff @(posedge clk) begin
        case(source)
            NONE:begin
            end
            SOURCE_CPU:begin
            end
            SOURCE_ALU:begin
                source <= NONE;
                flags <= flags_in;
                if(is_it_mul) begin
                    is_it_mul <= 0;
                    r[1] <= multiply_high;
                    r[0] <= register_in;
                end
                else begin
                    r[alu_rd] <= register_in;
                end
            end
        endcase
    end

endmodule
