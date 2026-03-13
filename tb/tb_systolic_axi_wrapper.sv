`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.02.2026 11:05:03
// Design Name: 
// Module Name: tb_systolic_axi_wrapper
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




module tb_systolic_axi_wrapper();

    // Parameters matching your hardware implementation
    parameter N = 8;
    parameter DATA_W = 8;
    parameter ACC_W = 32;

    logic ACLK;
    logic ARESETN;

    // Slave Interface (Input Stream)
    logic [31:0] S_AXIS_TDATA;
    logic        S_AXIS_TVALID;
    logic        S_AXIS_TREADY;
    logic        S_AXIS_TLAST;

    // Master Interface (Output Stream)
    logic [31:0] M_AXIS_TDATA;
    logic        M_AXIS_TVALID;
    logic        M_AXIS_TREADY;
    logic        M_AXIS_TLAST;

    // Instantiate the Wrapper
    systolic_axi_wrapper #(.N(N), .DATA_W(DATA_W), .ACC_W(ACC_W)) dut (.*);

    // Clock Generation: 200MHz (5ns period) to match your timing closure
    always #2.5 ACLK = ~ACLK;

    initial begin
        // Initialize Signals
        ACLK = 0;
        ARESETN = 0;
        S_AXIS_TDATA = 0;
        S_AXIS_TVALID = 0;
        S_AXIS_TLAST = 0;
        M_AXIS_TREADY = 1; // Receiver is always ready for results

        #20 ARESETN = 1; // Release Reset
        #10;

        // --- PHASE 1: Stream Matrix A (64 Elements) ---
        $display("Streaming Matrix A...");
        for (int i = 0; i < N*N; i++) begin
            @(posedge ACLK);
            wait(S_AXIS_TREADY); // Respect the hardware handshake
            S_AXIS_TVALID = 1;
            S_AXIS_TDATA = i + 1; // Example data: 1, 2, 3...
            if (i == (N*N)-1) S_AXIS_TLAST = 1;
        end
        @(posedge ACLK);
        S_AXIS_TVALID = 0;
        S_AXIS_TLAST = 0;

        // --- PHASE 2: Stream Matrix B (64 Elements) ---
        $display("Streaming Matrix B...");
        for (int i = 0; i < N*N; i++) begin
            @(posedge ACLK);
            wait(S_AXIS_TREADY);
            S_AXIS_TVALID = 1;
            S_AXIS_TDATA = 2; // Fixed multiplier for easy verification
        end
        @(posedge ACLK);
        S_AXIS_TVALID = 0;

        // --- PHASE 3: Wait for Results ---
        $display("Waiting for Matrix C output stream...");
        wait(M_AXIS_TVALID);
        
        // Collect 64 results from the Master interface
        for (int i = 0; i < N*N; i++) begin
            @(posedge ACLK);
            if (M_AXIS_TVALID && M_AXIS_TREADY) begin
                $display("Result Element %0d: %0d", i, M_AXIS_TDATA);
            end
        end

        $display("Simulation Complete.");
        $finish;
    end

endmodule
