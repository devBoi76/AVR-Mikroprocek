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

typedef enum logic [3:0] {
    MEM_LDS1,
    MEM_LDS2,
    MEM_POP1,
    MEM_STS1,

    MEM_CALL,
    MEM_RET1,
    MEM_RET2,
    MEM_RET3
} memop_dir_e;

module cpu(input clk,
    output addr_word_t prog_addr,
    input inst_word_t prog_data
        );


    // === STAN CPU ===

    addr_word_t pc = 0; // program counter
    assign prog_addr = pc;
    addr_word_t sp = SRAM_MAX_ADDR; // stack pointer

    //flagi i zmienne do wyliczeń
    flags_t flags = '{C:0, Z:0, N:0, V:0, S:0, H:0, T:0, I:0};


    // === BLOKI LOGICZNE ===
    // zmienne potrzebne do dekodowania instrukcji

    opcode_e opcode;
    reg_addr_t Rd;
    reg_addr_t Rr;
    data_word_t K; // stała (np. LDI)
    logic signed [11:0] big_K; // duża stała (rjmp)
    addr_io_word_t A; // adres MMIO (in, out)
    ctrl_t ctrl; // sygnały kontrolne
    decode decode (.inst(prog_data), .opcode(opcode), .Rd(Rd), .Rr(Rr), .K(K), .big_K(big_K), .A(A), .ctrl(ctrl));

    dataspace_memop_e dataspace_memop = DATASPACE_MEM_NONE;
    reg_addr_t dataspace_Rmemop;
    addr_word_t dataspace_memop_addr;

    data_word_t dataspace_sram_in;
    data_word_t dataspace_sram_out;

    data_word_t dataspace_Rd_in;
    data_word_t dataspace_Rd_out;
    data_word_t dataspace_Rr_in;
    data_word_t dataspace_Rr_out;

    dataspace dataspace(
        .clk(clk),
        .memop(dataspace_memop),

        .Rmemop(dataspace_Rmemop),
        .mmio_addr_in(dataspace_memop_addr),

        .sram_addr_in(dataspace_memop_addr),
        .sram_data_in(dataspace_sram_in),
        .sram_data_out(dataspace_sram_out),

        .Rd(Rd),
        .Rd_data_in(dataspace_Rd_in),
        .Rd_data_out(dataspace_Rd_out),
        .Rr(Rr),
        .Rr_data_in(dataspace_Rr_in),
        .Rr_data_out(dataspace_Rr_out)
        );

    data_word_t ALU_a;
    data_word_t ALU_b;
    data_word_t ALU_out;
    data_word_t ALU_out_mul;
    data_word_t ALU_out_flags;
    ALU alu (.opcode(opcode), .A(ALU_a), .B(ALU_b), .flags(flags), .result_alu(ALU_out), .multiply_high(ALU_out_mul), .flagsout(ALU_out_flags));



    // === MULTIPLEKSERY I LOGIKA KOMBINACYJNA ===

    // program counter
    addr_word_t pc_plus_one;
    assign pc_plus_one = pc + 1;
    addr_word_t pc_plus_two;
    assign pc_plus_two = pc + 2;

    // ALU sources
    logic is_alu_instruction;
    always_comb begin
        case(ctrl.alu_op_src)
        ALU_OPERANDS_NONE: begin
            ALU_a = 'x;
            ALU_b = 'x;
            is_alu_instruction = 0;
        end
        ALU_OPERANDS_RD: begin
            ALU_a = dataspace_Rd_out;
            ALU_b = 'x;
            is_alu_instruction = 1;
        end
        ALU_OPERANDS_RD_RR: begin
            ALU_a = dataspace_Rd_out;
            ALU_b = dataspace_Rr_out;
            is_alu_instruction = 1;
        end
        ALU_OPERANDS_RD_K: begin
            ALU_a = dataspace_Rd_out;
            ALU_b = K;
            is_alu_instruction = 1;
        end
        endcase
    end

    // === ZACHOWANIE I MASZYNA STANÓW ===

    // przechowują dane potrzebne do wynokania operacji na pamięci w następnym cyklu
    memop_dir_e memop_dir;
    addr_word_t scratch_addr_reg; // Używany w czytaniu stosu przy wykonywaniu RET

    cpu_state_e state = S_EXECUTE;
    always_ff @(negedge clk) begin // always_ff <=> używamy '<=' nieblokujące
        if (is_alu_instruction) begin
            pc <= pc + 1;
            flags <= ALU_out_flags;

            if(ctrl.alu_is_mul) begin
                dataspace_memop <= DATASPACE_MEM_DOUBLE_WRITE;
                dataspace_Rmemop = 0;
                dataspace_Rd_in <= ALU_out; // low
                dataspace_Rr_in <= ALU_out_mul; // high
            end else begin
                dataspace_memop <= DATASPACE_MEM_REG_WRITE;
                dataspace_Rmemop <= Rd;
                dataspace_Rd_in <= ALU_out;
            end

            state <= S_EXECUTE;
        end else case (state)
            S_EXECUTE: begin
                case (opcode)
                    OP_LDI: begin
                        dataspace_memop <= DATASPACE_MEM_REG_WRITE;
                        dataspace_Rmemop <= Rd;
                        dataspace_Rd_in <= K;

                        pc <= pc + 1;
                        state <= S_EXECUTE;
                    end
                    OP_LDS: begin // LDS dzielimy na dwie fazy: 1. v = SRAM_READ(addr) 2. Rd <- v
                        pc <= pc + 1;

                        dataspace_memop <= DATASPACE_MEM_NONE; // musimy załadować adres w następnym bajcie
                        dataspace_Rmemop <= Rd; // zapisz Rd na później

                        memop_dir <= MEM_LDS1;
                        state <= S_MEMOP;
                    end
                    OP_STS: begin
                        pc <= pc + 1;

                        dataspace_memop <= DATASPACE_MEM_NONE; // drugi krok wykonany w MEM_STS1
                        dataspace_sram_in <= dataspace_Rd_out; // "budujemy" argumenty do operacji na pamięci

                        memop_dir <= MEM_STS1;
                        state <= S_MEMOP;
                    end
                    OP_PUSH: begin
                        pc <= pc + 1;

                        // sram[sp] <= registers[Rd];
                        dataspace_memop <= DATASPACE_MEM_SRAM_WRITE;
                        dataspace_memop_addr <= sp;
                        dataspace_sram_in <= dataspace_Rd_out;

                        sp <= sp - 1;
                        state <= S_EXECUTE;
                    end
                    OP_POP: begin // POP dzielimy na trzy fazy: 1. sp += 1; 2. v = SRAM_READ(addr) 3. Rd <- v (tożsame z LDS2)

                        dataspace_memop <= DATASPACE_MEM_NONE; // drugi krok wykonany w MEM_POP1
                        dataspace_Rmemop <= Rd;

                        sp <= sp + 1;
                        memop_dir <= MEM_POP1;
                        state <= S_MEMOP;
                    end
                    OP_IN: begin
                        pc <= pc + 1;

                        // Rd <- mmio[A]
                        dataspace_memop <= DATASPACE_MEM_MMIO_READ;
                        dataspace_Rmemop <= Rd;
                        dataspace_memop_addr <= A;

                        state <= S_EXECUTE;
                     end
                    OP_OUT: begin
                        pc <= pc + 1;

                        // mmio[A] <- Rr
                        dataspace_memop <= DATASPACE_MEM_MMIO_WRITE;
                        dataspace_Rmemop <= Rr;
                        dataspace_memop_addr <= A;

                        state <= S_EXECUTE;
                     end
                     OP_MOV: begin
                        pc <= pc + 1;

                        dataspace_memop <= DATASPACE_MEM_MOV;

                        state <= S_EXECUTE;
                     end
                     OP_CALL: begin
                        pc <= pc + 1;

                        // push PC to stack. `PC+2` bo mamy: <call> <addr> <inna instrukcja>
                        // sram[sp] <= pc_plus_two[15:8];
                        dataspace_memop <= DATASPACE_MEM_SRAM_WRITE;
                        dataspace_memop_addr <= sp;
                        dataspace_sram_in <= pc_plus_two[15:8]; // high byte

                        sp <= sp - 1;
                        memop_dir <= MEM_CALL;
                        state <= S_MEMOP;
                     end
                     OP_RET: begin // 1. sp += 1; 2. a <- sram[sp] oraz sp += 1; 3. b <- sram[sp] 4. pc <= {sram[sp], a};
                        // 1.
                        sp <= sp + 1;
                        memop_dir <= MEM_RET1;
                        state <= S_MEMOP;
                     end
                     // === NIE DOTYKA PAMIĘCI / REJESTRÓW
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
                endcase
            end
            S_MEMOP: begin
                case (memop_dir)
                    MEM_LDS1: begin
                        // 1. v <- SRAM_READ(addr)
                        dataspace_memop <= DATASPACE_MEM_SRAM_READ;
                        dataspace_memop_addr <= prog_data;

                        memop_dir <= MEM_LDS2;
                        state <= S_MEMOP;
                    end
                    MEM_LDS2: begin
                        pc <= pc + 1;
                        // 2. Rd <- v
                        dataspace_memop <= DATASPACE_MEM_REG_WRITE;
                        dataspace_Rd_in <= dataspace_sram_out;

                        state <= S_EXECUTE;
                    end
                    MEM_POP1: begin
                        // 1. v <- SRAM_READ(sp)
                        dataspace_memop <= DATASPACE_MEM_SRAM_READ;
                        dataspace_memop_addr <= sp;

                        memop_dir <= MEM_LDS2;
                        state <= S_MEMOP;
                    end
                    MEM_STS1: begin
                        pc <= pc + 1;

                        dataspace_memop <= DATASPACE_MEM_SRAM_WRITE;
                        dataspace_memop_addr <= prog_data;

                        state <= S_EXECUTE;
                    end
                    MEM_POP1: begin
                        pc <= pc + 1;

                        dataspace_memop <= DATASPACE_MEM_SRAM_READ;
                        dataspace_memop_addr <= sp;

                        state <= S_EXECUTE;
                    end
                    MEM_CALL: begin
                        pc <= prog_data;
                        state <= S_EXECUTE;
                        // `PC+1` bo mamy: <addr> <inna instrukcja>
                        dataspace_memop <= DATASPACE_MEM_SRAM_WRITE;
                        dataspace_memop_addr <= sp;
                        dataspace_sram_in <= pc_plus_one[7:0]; // low byte

                        sp <= sp - 1;
                    end
                    MEM_RET1: begin // 2. load low byte
                        sp <= sp + 1;

                        // scratch_addr_reg[7:0] <= sram[sp]; // low byte
                        dataspace_memop <= DATASPACE_MEM_SRAM_READ;
                        dataspace_memop_addr <= sp;

                        memop_dir <= MEM_RET2;
                        state <= S_MEMOP;
                    end
                    MEM_RET2: begin // 3. load high byte
                        scratch_addr_reg[7:0] <= dataspace_sram_out;
                        dataspace_memop <= DATASPACE_MEM_SRAM_READ;
                        dataspace_memop_addr <= sp;

                        memop_dir <= MEM_RET3;
                        state <= S_MEMOP;
                    end
                    MEM_RET3: begin // 4. load into pc
                        pc <= {dataspace_sram_out, scratch_addr_reg[7:0]};
                        state <= S_EXECUTE;
                    end
                endcase
            end
        endcase
    end
endmodule
