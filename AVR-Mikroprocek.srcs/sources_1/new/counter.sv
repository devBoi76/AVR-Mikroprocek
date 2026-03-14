`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/14/2026 11:38:31 AM
// Design Name: 
// Module Name: counter
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

module counter #(BITS=8) (
    input logic clk,
    input logic rst,
    output logic [BITS-1:0] count = 0
    );
    
    always_ff @(posedge clk) begin
        if (rst)
            count <= 0;
        else
            count <= count + 1;
    end
endmodule
