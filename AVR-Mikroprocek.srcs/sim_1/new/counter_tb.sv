`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/14/2026 11:40:27 AM
// Design Name: 
// Module Name: counter_tb
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


module counter_tb();

    logic clk = 0;
    logic rst = 0;
    localparam BITS = 8;
    logic [BITS-1:0] count;
    
    counter #(.BITS(BITS)) c (.clk(clk), .rst(rst), .count(count));
    
    always #5 clk = ~clk;
    
    initial begin
        #20 rst = 1;
        #5 rst = 0;
        #100 $finish;
    end
    
endmodule
