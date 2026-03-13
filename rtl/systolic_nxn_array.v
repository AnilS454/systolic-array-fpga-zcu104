`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.01.2026 14:34:34
// Design Name: 
// Module Name: systolic_nxn_array
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


module systolic_nxn_array #(
    parameter N = 4,
    parameter DATA_W = 8,
    parameter ACC_W  = 32
)(
    input  logic clk,
    input  logic reset,
    input  logic clear_acc,
    input  logic valid_in,
    input  logic [DATA_W-1:0] A [0:N-1], 
    input  logic [DATA_W-1:0] B [0:N-1], 

    output logic [ACC_W-1:0] C [0:N-1][0:N-1],
    output logic valid_out
);

    // Pipeline registers
    logic [DATA_W-1:0] a_pipe [0:N-1][0:N];
    logic [DATA_W-1:0] b_pipe [0:N][0:N-1];
    logic v_a_pipe [0:N-1][0:N];
    logic v_b_pipe [0:N][0:N-1];

    genvar r, c;
    generate
        for (r = 0; r < N; r++) begin : ROW
            for (c = 0; c < N; c++) begin : COL
                PE pe_inst (
                    .clk(clk),
                    .reset(reset),
                    .clear_acc(clear_acc),
                    .v_a_in(v_a_pipe[r][c]),
                    .v_b_in(v_b_pipe[r][c]),
                    .a_in(a_pipe[r][c]),
                    .b_in(b_pipe[r][c]),
                    .v_a_out(v_a_pipe[r][c+1]),
                    .v_b_out(v_b_pipe[r+1][c]),
                    .a_out(a_pipe[r][c+1]),
                    .b_out(b_pipe[r+1][c]),
                    .psum(C[r][c])
                );
            end
        end
    endgenerate

    // Boundary Assignments
    generate
        for (genvar i = 0; i < N; i++) begin
            assign a_pipe[i][0]   = A[i];
            assign b_pipe[0][i]   = B[i];
            assign v_a_pipe[i][0] = valid_in;
            assign v_b_pipe[0][i] = valid_in;
        end
    endgenerate

    // Final valid signal from the bottom-right PE
    assign valid_out = v_a_pipe[N-1][N];

endmodule


