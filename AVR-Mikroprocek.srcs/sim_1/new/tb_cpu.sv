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
    initial $readmemh("basic.mem", prog);

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
            uart_send_byte(inst[15:8]); // high byte
            uart_send_byte(inst[7:0]); // low byte
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
