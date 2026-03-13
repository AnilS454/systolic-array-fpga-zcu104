`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.01.2026 10:49:45
// Design Name: 
// Module Name: tb_PE
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




module tb_PE;

    reg clk;
    reg reset;
    reg valid_in;
    reg [7:0] a_in;
    reg [7:0] b_in;

    wire valid_out;
    wire [7:0] a_out;
    wire [7:0] b_out;
    wire [31:0] psum;

    PE dut (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .a_in(a_in),
        .b_in(b_in),
        .valid_out(valid_out),
        .a_out(a_out),
        .b_out(b_out),
        .psum(psum)
    );

    // Clock
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        valid_in = 0;
        a_in = 0;
        b_in = 0;

        #20 reset = 0;

        #10 valid_in = 1; a_in = 3; b_in = 4;
        #10 a_in = 2; b_in = 5;
        #10 a_in = 1; b_in = 6;
        #10 valid_in = 0;

        #50;
        $stop;
    end
endmodule

