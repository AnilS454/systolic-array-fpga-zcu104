`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.01.2026 09:40:27
// Design Name: 
// Module Name: systolic_top
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


module systolic_top #(
    parameter N = 4,
    parameter DATA_W = 8,
    parameter ACC_W  = 32
)(
    input  logic clk,
    input  logic reset,
    input  logic start,
    input  logic src_valid,
    output logic src_ready,
    input  logic sink_ready,
    output logic sink_valid,
    input  logic [DATA_W-1:0] A_in [0:N-1][0:N-1],
    input  logic [DATA_W-1:0] B_in [0:N-1][0:N-1],
    output logic [ACC_W-1:0]  C_out [0:N-1][0:N-1],
    output logic done
);

    logic [DATA_W-1:0] row_to_array [0:N-1];
    logic [DATA_W-1:0] col_to_array [0:N-1];
    logic valid_to_array, clear_acc_wire, array_final_valid;

    // Instantiate Controller
    systolic_controller #(
        .N(N),
        .DATA_W(DATA_W)
    ) controller_inst (
        .clk(clk), .reset(reset), .start(start),
        .src_valid(src_valid), .src_ready(src_ready),
        .sink_valid(sink_valid), .sink_ready(sink_ready),
        .A_in(A_in), .B_in(B_in),
        .A_row(row_to_array), .B_col(col_to_array),
        .array_valid_out(array_final_valid),
        .valid_to_array(valid_to_array),
        .done(done), .clear_acc(clear_acc_wire)
    );

    // Instantiate Array
    systolic_nxn_array #(
        .N(N),
        .DATA_W(DATA_W),
        .ACC_W(ACC_W)
    ) array_inst (
        .clk(clk), .reset(reset), .clear_acc(clear_acc_wire),
        .valid_in(valid_to_array),
        .A(row_to_array), .B(col_to_array),
        .C(C_out),
        .valid_out(array_final_valid) 
    );

endmodule
