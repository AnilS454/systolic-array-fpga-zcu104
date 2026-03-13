`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.01.2026 10:19:28
// Design Name: 
// Module Name: tb_systolic_nxn
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






module tb_systolic_nxn;

    parameter N = 4;
    parameter DATA_W = 8;
    parameter ACC_W  = 32;

    logic clk;
    logic reset;
    logic valid_in;

    // UPDATED: These are now 1D arrays to match the new 1D boundary ports
    logic [DATA_W-1:0] A_port [0:N-1]; 
    logic [DATA_W-1:0] B_port [0:N-1];
    
    wire  [ACC_W-1:0]  C [0:N-1][0:N-1];
    wire valid_out;

    // Internal storage for the full matrices
    logic [DATA_W-1:0] A_mat [0:N-1][0:N-1];
    logic [DATA_W-1:0] B_mat [0:N-1][0:N-1];

    systolic_nxn_array #(
        .N(N),
        .DATA_W(DATA_W),
        .ACC_W(ACC_W)
    ) dut (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .A(A_port), // Connects 1D to 1D
        .B(B_port), // Connects 1D to 1D
        .C(C),
        .valid_out(valid_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    integer i, j, t;

    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        valid_in = 0;

        // Initialize ports to zero
        for (i = 0; i < N; i++) begin
            A_port[i] = 0;
            B_port[i] = 0;
        end

        // Define Matrix A and B values (1 to 16)
        for (i = 0; i < N; i++) begin
            for (j = 0; j < N; j++) begin
                A_mat[i][j] = (i * N) + j + 1;
                B_mat[i][j] = (i * N) + j + 1;
            end
        end

        #20 reset = 0;
        @(posedge clk);

        // --- SKEWED DATA FEEDING ---
        // Matrix A enters from Left (Row i starts at time t=i)
        // Matrix B enters from Top  (Col j starts at time t=j)
        for (t = 0; t < 3*N; t++) begin
            @(posedge clk);
            valid_in = (t < 2*N); 

            for (i = 0; i < N; i++) begin
                // Row i of A: A_mat[i][0], then A_mat[i][1]...
                if (t >= i && (t - i) < N)
                    A_port[i] = A_mat[i][t-i];
                else
                    A_port[i] = 0;

                // Column i of B: B_mat[0][i], then B_mat[1][i]...
                if (t >= i && (t - i) < N)
                    B_port[i] = B_mat[t-i][i];
                else
                    B_port[i] = 0;
            end
        end

        valid_in = 0;

        // Wait for the pipeline to finish processing
        wait(valid_out);
        repeat (2) @(posedge clk);

        // Display results
        $display("\n===== OUTPUT MATRIX C =====");
        for (i = 0; i < N; i++) begin
            $write("| ");
            for (j = 0; j < N; j++) begin
                $write("%4d ", C[i][j]);
            end
            $display(" |");
        end

        #20 $stop;
    end
endmodule


