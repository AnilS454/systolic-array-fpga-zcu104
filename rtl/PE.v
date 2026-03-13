`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.01.2026 10:48:39
// Design Name: 
// Module Name: PE
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


module PE (
    input  logic        clk,
    input  logic        reset,
    input  logic        clear_acc,
    input  logic        v_a_in,  
    input  logic        v_b_in,  
    input  logic [7:0]  a_in,
    input  logic [7:0]  b_in,

    output logic        v_a_out,
    output logic        v_b_out,
    output logic [7:0]  a_out,
    output logic [7:0]  b_out,
    output logic [31:0] psum
);

    always_ff @(posedge clk) begin
        if (reset || clear_acc) begin
            psum    <= 32'b0;
            a_out   <= 8'b0;
            b_out   <= 8'b0;
            v_a_out <= 1'b0;
            v_b_out <= 1'b0;
        end else begin
            // Shift data and valids every clock cycle
            v_a_out <= v_a_in;
            v_b_out <= v_b_in;
            a_out   <= a_in;
            b_out   <= b_in;

            // Math only happens when data from BOTH directions meets
            if (v_a_in && v_b_in) begin
                psum <= psum + (a_in * b_in);
            end
        end
    end
endmodule

