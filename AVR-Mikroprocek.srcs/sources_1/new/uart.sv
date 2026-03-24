// Działanie:
// IDLE - czeka na start bit (0) ? przechodzi do START : czeka dalej 
// START - czeka HALF_BIT_TIME i jeszcze raz sprawdza czy dalej jest start bit ? przechodzi do DATA : wraca do IDLE
// DATA - co CLKS_PER_BIT taktów odczytuje kolejny bit i wpisuje go do poczekalnie rx_shift aż będzie 8 bitów, potem przechodzi do STOP
// STOP - sprawdza czy pojawia się stop bit (1) ? wysyła data valid (1) i przerzuca rx_shift do data_out : zwraca frame_error (1) i wraca do IDLE

`timescale 1ns / 1ps

module pmem_uart #(
    // Moduł musi wiedzieć ile taktów zegara FPGA trwa 1 bit UART, inaczej się rozjedzie 
    parameter CLK_FREQ,                 // częstotliwość zegara FPGA
    parameter BAUD_RATE = 115200         // prędkość UART
)(
    input  logic clk,
    input  logic reset,
    input  logic uart_rx,                // szeregowe dane odbierane przez uart

    output logic [7:0] data_out,         // równoległe dane wyjściowe 
    output logic data_valid,             // walidacja bajtu danych
    output logic frame_error             // stop bit nie stop bituje ;c
);

    // liczba taktów zegara przypadająca na 1 bit UART
    localparam integer CLKS_PER_BIT  = CLK_FREQ / BAUD_RATE;

    // połowa czasu bitu - co by nam zakłócenia nie przeszkadzały
    localparam integer HALF_BIT_TIME = CLKS_PER_BIT / 2;

    
    typedef enum logic [1:0] {
        IDLE,    // czekanie na start bit
        START,   // sprawdzanie start bitu (czy to nie zakłócenie)
        DATA,    // odbiór 8 bitów danych
        STOP     // sprawdzanie stop bitu i powrót na IDLE
    } state_t;

    state_t state;           

    integer clk_count;       // liczy takty zegara w bicie
    integer bit_index;       // indeksuje aktualny bit
    logic [7:0] rx_shift;    // poczekalnia między uart_rx, a data_out 

    always_ff @(posedge clk) begin
        if (reset) begin
            state       <= IDLE;
            clk_count   <= 0;
            bit_index   <= 0;
            rx_shift    <= 8'b0;
            data_out    <= 8'b0;
            data_valid  <= 1'b0;
            frame_error <= 1'b0;
        end
        else begin
            data_valid <= 1'b0;

            case (state)

                IDLE: begin
                    // jak będzie start bit = 0 to przechodzimy do START
                    clk_count   <= 0;
                    bit_index   <= 0;
                    frame_error <= 1'b0;

                    if (uart_rx == 1'b0) begin
                        state <= START;
                    end
                end

                START: begin
                    // sprawdzamy czy to zakłócenie
                    if (clk_count == HALF_BIT_TIME) begin
                        clk_count <= 0;

                        // jeśli nie zakłócenie to przechodzimy do DATA
                        if (uart_rx == 1'b0) begin
                            state <= DATA;
                        end
                        else begin
                            // jeśli zakłócenie wracamy do IDLE
                            state <= IDLE;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1;
                    end
                end

                DATA: begin
                    // co pełny czas bitu próbkujemy kolejny bit danych
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;

                        // ładujemy poczekalnie rx_shift, zanim wypuścimy dane do cpu (NFZ?)
                        rx_shift[bit_index] <= uart_rx;

                        if (bit_index == 7) begin
                            // po odebraniu 8 bitów przechodzimy do stanu STOP
                            bit_index <= 0;
                            state <= STOP;
                        end
                        else begin
                            // jeśli to nie był 8 bit to ładujemy dalej
                            bit_index <= bit_index + 1;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1;
                    end
                end

                STOP: begin
                    // po czasie 1 bitu sprawdzamy stop bit
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;

                        if (uart_rx == 1'b1) begin
                            // poprawny odbiór bajtu
                            data_out    <= rx_shift;
                            data_valid  <= 1'b1;
                            state       <= IDLE;
                        end
                        else begin
                            // zły stop bit
                            frame_error <= 1'b1;
                            state       <= IDLE;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1;
                    end
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule