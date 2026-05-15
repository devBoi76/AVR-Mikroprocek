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
    input inst_word_t prog_data
        );


    // === STAN CPU ===

    addr_word_t pc = 0; // program counter
    assign prog_addr = pc;
    addr_word_t sp = SRAM_MAX_ADDR; // stack pointer

    data_word_t registers[31:0];
    localparam int IO_BASE = 16'h0020; //32

    //flagi i zmienne do wyliczeń
    flags_t flags = '{C:0, Z:0, N:0, V:0, S:0, H:0, T:0, I:0};


    // === BLOKI LOGICZNE ===
    // zmienne potrzebne do dekodowania instrukcji

    inst_word_t inst_currently_decoded;
    inst_word_t inst_extra_loaded_addr;
    opcode_e opcode;
    reg_addr_t Rd;
    reg_addr_t Rr;
    data_word_t K; // stała (np. LDI)
    logic signed [11:0] big_K; // duża stała (rjmp)
    addr_io_word_t A; // adres MMIO (in, out)
    ctrl_t ctrl; // sygnały kontrolne
    decode decode (.inst(inst_currently_decoded), .last_ctrl(ctrl), .opcode(opcode), .Rd(Rd), .Rr(Rr), .K(K), .big_K(big_K), .A(A), .ctrl(ctrl));

    dataspace_memop_e dataspace_memop = DATASPACE_MEM_NONE;
    reg_addr_t dataspace_Rmemop;
    addr_word_t dataspace_memop_addr;

    reg_addr_t dataspace_Rd_in;
    reg_addr_t dataspace_Rd_out;
    reg_addr_t dataspace_Rr_in;
    reg_addr_t dataspace_Rr_out;

    dataspace dataspace(
        .clk(clk),
        .memop(dataspace_memop),

        .Rmemop(dataspace_Rmemop),
        .sram_addr_in(dataspace_memop_addr),
        .mmio_addr_in(dataspace_memop_addr),

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



    // === MULTIPLEKSERY ===

    // program counter
    addr_word_t pc_plus_one;
    assign pc_plus_one = pc + 1;
    addr_word_t pc_plus_two;
    assign pc_plus_two = pc + 2;

    addr_word_t pc_jmp_addr;
    addr_word_t pc_next;
    always_comb begin
        case(ctrl.pc_source)
            PC_PLUS_ONE: pc_next = pc_plus_one;
            PC_PLUS_TWO: pc_next = pc_plus_two;
            PC_JMP: pc_next = pc_jmp_addr;
            PC_RET: pc_next = pc_jmp_addr;
        endcase
    end

    // loading nextword address on two word instructions
    logic keep_current_inst = 0;
    inst_word_t inst_prev;
    always_ff @(negedge clk) begin
        keep_current_inst <= ctrl.next_instruction_word_is_addr && ~keep_current_inst;
        inst_prev <= inst_currently_decoded;
    end
    always_comb begin
        case(keep_current_inst)
            0: inst_currently_decoded = prog_data;
            1: inst_currently_decoded = inst_prev;
        endcase
    end

    // register writeback data source
    data_word_t register_writeback_mux;
    always_comb begin
        case(ctrl.register_writeback_source)
            SOURCE_NONE: register_writeback_mux = 'x;
            SOURCE_CONSTANT: register_writeback_mux = K;
            SOURCE_SRAM: register_writeback_mux = sram_data_out;
            SOURCE_MMIO: register_writeback_mux = MMIO_data_out;
            SOURCE_ALU: register_writeback_mux = ALU_out; // TODO: mul
            SOURCE_REGISTER: register_writeback_mux = registers[Rr]; // TODO: verify
        endcase
    end
    logic register_do_write;
    always_comb begin
        case(ctrl.register_writeback_source)
            SOURCE_NONE: register_do_write = 0;
            default: register_do_write = 1;
        endcase
    end

    logic is_alu_instruction;
    always_comb begin
        case(ctrl.register_writeback_source)
            SOURCE_ALU: is_alu_instruction = 1;
            default: is_alu_instruction = 0;
        endcase
    end

    // ALU sources
    always_comb begin
        case(ctrl.ctrl.alu_op_src)
        ALU_OPERANDS_NONE: begin
            ALU_a = 'x;
            ALU_b = 'x;
        end
        ALU_OPERANDS_RD: begin
            ALU_a = registers[Rd];
            ALU_b = 'x;
        end
        ALU_OPERANDS_RD_RR: begin
            ALU_a = registers[Rd];
            ALU_b = registers[Rr];
        end
        ALU_OPERANDS_RD_K: begin
            ALU_a = registers[Rd];
            ALU_b = K;
        end
        endcase
    end

    // sram source
    assign sram_data_in = registers[Rr]; // TODO: verify. `registers[Rr]` is for `STS`, `PUSH`
    always_comb begin
        case(ctrl.sram_addr_source)
            SRAM_ADDR_NONE: sram_addr_in = 'x;
            SRAM_ADDR_SP: sram_addr_in = sp;
            SRAM_ADRR_NEXTWORD: sram_addr_in = prog_data;
        endcase
    end

    // MMIO source
    assign MMIO_data_out = registers[Rr]; // TODO: verify. `registers[Rr]` is for `OUT`

    // === ZACHOWANIE I MASZYNA STANÓW ===


    // przechowują dane potrzebne do wynokania operacji na pamięci w następnym cyklu
    memop_dir_e memop_dir;
    reg_addr_t memop_r;
    addr_word_t scratch_addr_reg; // Używany w czytaniu stosu przy wykonywaniu RET

    //Sygnał mówiący czy operacja jest mnożeniem (potrzebuje 2 rejestrów)
    logic is_it_mul = 1'b0;

    cpu_state_e state = S_EXECUTE;
    always_ff @(negedge clk) begin
        // zmiania PC
        pc <= pc_next;

        // zapis do rejestru
        if (register_do_write) begin
            registers[Rd] <= register_writeback_mux;
        end

        // obsługa sram
        case (ctrl.sram_cmd)
            SRAM_NONE: begin end
            SRAM_READ: begin
                sram_data_out <= sram[sram_addr_in];
            end
            SRAM_WRITE: begin
                sram[sram_addr_in] <= sram_data_in;
            end
        endcase
    end

    always_ff @(negedge clk) begin // always_ff <=> używamy '<=' nieblokujące
        if (is_alu_instruction) begin
            pc <= pc + 1;
            flags <= ALU_out_flags;

            if(ctrl.alu_is_mul) begin
                registers[1] <= ALU_out_mul;
                registers[0] <= ALU_out;
            end else begin
                registers[Rd] <= ALU_out;
            end

            state <= S_EXECUTE;
        end else case (state)
            S_EXECUTE: begin
                case (opcode)
                    OP_LDI: begin // ok
                        registers[Rd] <= K;
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
                        sram[sp] <= registers[Rd];
                        sp <= sp - 1;
                        state <= S_EXECUTE;
                    end
                    OP_POP: begin
                        sp <= sp + 1;
                        memop_r <= Rd;
                        memop_dir <= MEM_POP_SP;
                        state <= S_MEMOP;
                    end
                    OP_IN: begin
                        pc <= pc + 1;
                        registers[Rd] <= sram[IO_BASE + A];
                        state <= S_EXECUTE;
                     end
                    OP_OUT: begin
                        pc <= pc + 1;
                        sram[IO_BASE + A] <= registers[Rr];
                        state <= S_EXECUTE;
                     end
                     OP_MOV: begin
                        pc <= pc + 1;
                        registers[Rd] <= registers[Rr];
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
                        registers[memop_r] <= sram[prog_data];
                        state <= S_EXECUTE;
                    end
                    MEM_WRITE_PC: begin
                        pc <= pc + 1;
                        sram[prog_data] <= registers[memop_r];
                        state <= S_EXECUTE;
                    end
                    MEM_POP_SP: begin
                        pc <= pc + 1;
                        registers[memop_r] <= sram[sp];
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
endmodule
