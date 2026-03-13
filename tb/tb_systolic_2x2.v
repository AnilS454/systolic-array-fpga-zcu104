`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.01.2026 13:26:24
// Design Name: 
// Module Name: tb_systolic_2x2
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



module tb_systolic_2x2;

    logic clk;
    logic reset;
    logic valid_in;

    logic [7:0] a00, a01, a10, a11;
    logic [7:0] b00, b01, b10, b11;

    logic valid_out;
    logic [31:0] c00, c01, c10, c11;


    // Instantiate DUT
    systolic_2x2 DUT (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),

        .a00(a00), .a01(a01),
        .a10(a10), .a11(a11),

        .b00(b00), .b01(b01),
        .b10(b10), .b11(b11),

        .valid_out(valid_out),
        .c00(c00), .c01(c01),
        .c10(c10), .c11(c11)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
    clk = 0;
    reset = 1;
    valid_in = 0;

    a00 = 0; a01 = 0;
    a10 = 0; a11 = 0;
    b00 = 0; b01 = 0;
    b10 = 0; b11 = 0;

    #20;
    reset = 0;

    // Apply inputs
    @(posedge clk);
    valid_in = 1;

    a00 = 8'd1;  a01 = 8'd2;
    a10 = 8'd3;  a11 = 8'd4;

    b00 = 8'd5;  b01 = 8'd6;
    b10 = 8'd7;  b11 = 8'd8;

    // KEEP VALID HIGH FOR 2 CYCLES
    repeat (4) @(posedge clk);

    valid_in = 0;

    // Wait for pipeline to flush
    repeat (4) @(posedge clk);

    $display("C00 = %d", c00);
    $display("C01 = %d", c01);
    $display("C10 = %d", c10);
    $display("C11 = %d", c11);

    $stop;
end


endmodule

