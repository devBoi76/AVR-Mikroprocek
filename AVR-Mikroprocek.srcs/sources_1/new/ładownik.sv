`timescale 1ns / 1ps

import cpu_defs::addr_word_t;

module pmem_loader(
    input  logic clk,
    input  logic reset,
    input  logic load_mode,         // ładuje(1) 
    input  logic [7:0] uart_data,   // dane z uarta
    input  logic uart_valid,        // potwierdzenie o poprawności danych wysłane przez uart
    
    output inst_word_t data_out,   // dane wyjściowe
    output logic instr_valid        // zatwierdzenie instrukcji 
);

    typedef enum logic [1:0] {
        IDLE,
        LOAD_FIRST,
        LOAD_SECOND,
        SEND
    } state_t;

    state_t state;

    logic [7:0] first_byte;     // przechowywalnia dla pierwszej instrukcji 

    always_ff @(posedge clk) begin
        if (reset) begin
            data_out    <= 16'b0;
            instr_valid <= 1'b0;
            first_byte  <= 8'b0;
            state       <= IDLE;
        end
        else begin
            instr_valid <= 1'b0;

            case (state)

                IDLE: begin
                    if (load_mode && uart_valid) begin
                        state <= LOAD_FIRST;
                    end
                end

                LOAD_FIRST: begin
                    first_byte <= uart_data;
                    state <= LOAD_SECOND;
                end

                LOAD_SECOND: begin
                    if (load_mode && uart_valid) begin
                        data_out <= {uart_data, first_byte};
                        state <= SEND;
                    end
                end

                SEND: begin
                    instr_valid <= 1'b1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule