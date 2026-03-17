`timescale 1ns / 1ps

module tb_pmem_top;

    parameter CLK_FREQ     = 100_000_000;
    parameter BAUD_RATE    = 115200;
    parameter CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    logic clk = 0;
    logic reset = 1;
    logic load_mode = 0;
    logic uart_rx = 1;
    logic [7:0] cpu_addr = 0;
    logic [15:0] instr_out;
    logic frame_error;

    pmem_top dut (
        .clk(clk),
        .reset(reset),
        .load_mode(load_mode),
        .uart_rx(uart_rx),
        .cpu_addr(cpu_addr),
        .instr_out(instr_out),
        .frame_error(frame_error)
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

    initial begin
        repeat (10) @(posedge clk);
        reset = 0;

        load_mode = 1;

        uart_send_byte(8'h34);
        uart_send_byte(8'h12);

        repeat (20) @(posedge clk);

        load_mode = 0;
        cpu_addr = 8'h00;

        repeat (2) @(posedge clk);

        $display("instr_out = %h", instr_out);

        repeat (20) @(posedge clk);
    end

endmodule