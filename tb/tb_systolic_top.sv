`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.01.2026 09:45:03
// Design Name: 
// Module Name: tb_systolic_top
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



`timescale 1ns / 1ps

module tb_systolic_top();

    parameter N = 8; // Changed to 8
    parameter DATA_W = 8;
    parameter ACC_W = 32;

    logic clk, reset, start;
    logic src_valid, sink_ready;
    logic src_ready, sink_valid, done;

    logic [DATA_W-1:0] A_in [0:N-1][0:N-1];
    logic [DATA_W-1:0] B_in [0:N-1][0:N-1];
    logic [ACC_W-1:0]  C_out [0:N-1][0:N-1];
    logic [ACC_W-1:0]  Expected_C [0:N-1][0:N-1];

    // Instantiate Top Module with Parameter N=8
    systolic_top #(.N(N), .DATA_W(DATA_W), .ACC_W(ACC_W)) dut (
        .clk(clk), .reset(reset), .start(start),
        .src_valid(src_valid), .src_ready(src_ready),
        .sink_ready(sink_ready), .sink_valid(sink_valid),
        .A_in(A_in), .B_in(B_in),
        .C_out(C_out), .done(done)
    );

    // Clock Generation (100MHz)
    always #5 clk = ~clk;

    initial begin
        // Initialize
        clk = 0; reset = 1; start = 0;
        src_valid = 0; sink_ready = 1;

        // 1. Generate Input Data & Golden Model
        // A[i][j] = i+j+1, B[i][j] = 2 (Fixed multiplier for easy verification)
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                A_in[i][j] = i + j + 1;
                B_in[i][j] = 2;
            end
        end

        // Calculate Expected C (Golden Model)
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                Expected_C[i][j] = 0;
                for (int k = 0; k < N; k++) begin
                    Expected_C[i][j] += A_in[i][k] * B_in[k][j];
                end
            end
        end

        #20 reset = 0;
        #20 start = 1; src_valid = 1;
        #10 start = 0;

        // 2. Wait for Completion
        wait(done);
        #20;

        // 3. Verification
        $display("--- Verification Result for N=%0d ---", N);
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                if (C_out[i][j] === Expected_C[i][j])
                    $display("[PASS] C[%0d][%0d]: HW=%d, Expected=%d", i, j, C_out[i][j], Expected_C[i][j]);
                else
                    $display("[FAIL] C[%0d][%0d]: HW=%d, Expected=%d", i, j, C_out[i][j], Expected_C[i][j]);
            end
        end

        $display("Simulation Complete.");
        $finish;
    end

endmodule
