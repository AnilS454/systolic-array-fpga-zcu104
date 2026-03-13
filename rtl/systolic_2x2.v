`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.01.2026 13:23:43
// Design Name: 
// Module Name: systolic_2x2
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


module systolic_2x2 (
    input logic clk,
    input  logic reset,
    input  logic valid_in,

    input  logic [7:0] a00, a01,
    input  logic [7:0] a10, a11,

    input  logic [7:0] b00, b01,
    input  logic [7:0] b10, b11,

    output logic valid_out,
    output logic [31:0] c00, c01,
    output logic [31:0] c10, c11
);

    // ====================================================
    // Pipeline control
    // ====================================================
    reg [1:0] cycle;

    // A and B input staging
    reg [7:0] a_row0, a_row1;
    reg [7:0] b_col0, b_col1;

    // Pipeline registers for alignment
    reg [7:0] a_row1_d;
    reg [7:0] b_col0_d;
    reg [7:0] b_col1_d;
    reg [7:0] a10_to_11_d;
    reg [7:0] b01_to_11_d;


    // Valid pipeline
    reg v00_d, v01_d, v10_d, v11_d;

    // Interconnects
    wire [7:0] a00_to_01, a10_to_11;
    wire [7:0] b00_to_10, b01_to_11;

    // ====================================================
    // Cycle counter
    // ====================================================
    always @(posedge clk) begin
        if (reset)
            cycle <= 0;
        else
            cycle <= cycle + 1;
    end

    // ====================================================
    // Input scheduling
    // ====================================================
    always @(posedge clk) begin
        if (reset) begin
            a_row0 <= 0; a_row1 <= 0;
            b_col0 <= 0; b_col1 <= 0;
        end else begin
            case (cycle)
                0: begin
                    a_row0 <= a00;
                    a_row1 <= a10;
                    b_col0 <= b00;
                    b_col1 <= b01;
                end
                1: begin
                    a_row0 <= a01;
                    a_row1 <= a11;
                    b_col0 <= b10;
                    b_col1 <= b11;
                end
                default: begin
                    a_row0 <= 0;
                    a_row1 <= 0;
                    b_col0 <= 0;
                    b_col1 <= 0;
                end
            endcase
        end
    end

    // ====================================================
    // Pipeline registers for alignment
    // ====================================================
    always @(posedge clk) begin
        if (reset) begin
            b_col0_d     <= 0;
            b_col1_d     <= 0;
            a_row1_d     <= 0;
            a10_to_11_d  <= 0;
            b01_to_11_d <=0;

            v00_d <= 0;
            v01_d <= 0;
            v10_d <= 0;
            v11_d <= 0;
        end else begin
            b_col0_d    <= b_col0;
            b_col1_d    <= b_col1;
            a_row1_d    <= a_row1;
            a10_to_11_d <= a10_to_11;
            b01_to_11_d <= b01_to_11;

            v00_d <= valid_in;
            v01_d <= v00_d;
            v10_d <= v00_d;
            v11_d <= v01_d;
        end
    end

    // ====================================================
    // Processing Elements
    // ====================================================

    PE PE00 (
        .clk(clk), .reset(reset),
        .valid_in(v00_d),
        .a_in(a_row0),
        .b_in(b_col0),
        .a_out(a00_to_01),
        .b_out(b00_to_10),
        .psum(c00)
    );

    PE PE01 (
        .clk(clk), .reset(reset),
        .valid_in(v01_d),
        .a_in(a00_to_01),
        .b_in(b_col1_d),
        .a_out(),
        .b_out(b01_to_11),
        .psum(c01)
    );

    PE PE10 (
        .clk(clk), .reset(reset),
        .valid_in(v10_d),
        .a_in(a_row1_d),
        .b_in(b_col0_d),
        .a_out(a10_to_11),
        .b_out(),
        .psum(c10)
    );

    PE PE11 (
        .clk(clk), .reset(reset),
        .valid_in(v11_d),
        .a_in(a10_to_11_d),
        .b_in(b01_to_11_d),
        .a_out(),
        .b_out(),
        .psum(c11)
    );

    assign valid_out = v11_d;

endmodule


