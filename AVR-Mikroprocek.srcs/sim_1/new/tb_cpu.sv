`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/14/2026 01:06:36 PM
// Design Name: 
// Module Name: tb_cpu
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


module tb_cpu();

    typedef logic [15:0] inst_word_t;

    localparam PROG_SIZE = 32;
    inst_word_t prog[PROG_SIZE:0];
    
    initial begin
        prog[0] = 16'b1110_0000_0000_1010; // LDI r16, 10
        prog[1] = 16'b1110_0001_0001_0100; // LDI r17, 20
        prog[2] = 16'b001000_11_0000_0001; // AND r16, r17
        prog[3] = 16'b001000_11_0000_0000; // TST r16
        prog[4] = 16'b0110_1111_0000_0000; // ORI r16, 240
        prog[5] = 16'b1001010_10000_1010; //DEC r16
        prog[6] = 16'b100111_11_0000_0001; //MUL r16, r17
        prog[7] = 16'b0000_0010_0000_0001; //MULS r16, r17
        prog[8] = 16'b001001_11_0001_0001; //CLR r17
        prog[9] = 16'b1001001_10000_0000; // STS r16
        prog[10] = 16'b0000_0000_1000_0000; // ADDR = 128
        prog[11] = 16'b1001000_10010_0000; // LDS r18
        prog[12] = 16'b0000_0000_1000_0000; // ADDR = 128
        prog[13] = 16'b1001001_10000_1111; // PUSH r16
        prog[14] = 16'b1001000_00000_1111; // POP r0
        prog[15]  = 16'b001011_1_10011_0010; // MOV r19, r18
        prog[16] = 16'b10111_00_10011_0101; // OUT 5, r19
        prog[17] = 16'b10110_00_10100_0101; // IN r20, 5
        prog[18] = 16'b1110_0000_0000_0011; // LDI r16, 3
        prog[19] = 16'b1001010_10000_1010; //DEC r16
        prog[20] = 16'b111101_1111110_001; // BRNE -2
        prog[21] = 16'b1100_1111_1111_1100; // RJMP -4
    end

    logic uart_rx = 1;
    logic load_mode = 0;
    logic uart_reset = 1;
    logic clk = 0;

    parameter UART_CLK_FREQ     = 500;//100_000_000;
    parameter BAUD_RATE    = 100;
    parameter CLKS_PER_BIT = UART_CLK_FREQ / BAUD_RATE;
    
    top #(.UART_CLK_FREQ(UART_CLK_FREQ), .UART_BR(BAUD_RATE)) top (
        .clk(clk),
        .uart_rx(uart_rx),
        .load_mode(load_mode),
        .uart_reset(uart_reset)
    );

    always #5 clk = ~clk;


    
    task uart_send_byte(input [7:0] data);
        integer i;
        begin
            uart_rx = 0;
            repeat (CLKS_PER_BIT) @(posedge clk);

            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = data[i];
                repeat (CLKS_PER_BIT) @(posedge clk);
            end

            uart_rx = 1;
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask
    
    task uart_send_inst(input inst_word_t inst);
        begin
            uart_send_byte(inst[7:0]); // low byte
            uart_send_byte(inst[15:8]); // high byte
        end
    endtask

    integer i;

    initial begin
        repeat (10) @(posedge clk);
        load_mode = 1;
        uart_reset = 0;
        #20;
        
        
        for (i = 0; i < PROG_SIZE; i++) begin
            uart_send_inst(prog[i]);
        end
        
        repeat (20) @(posedge clk);
        load_mode = 0;
        
        #1000 $finish;
    end

endmodule
