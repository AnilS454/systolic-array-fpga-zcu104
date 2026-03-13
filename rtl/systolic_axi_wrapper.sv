`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.02.2026 11:02:54
// Design Name: 
// Module Name: systolic_axi_wrapper
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


module systolic_axi_wrapper #(
    parameter N      = 8,
    parameter DATA_W = 8,
    parameter ACC_W  = 32
)(
    input  logic              ACLK,
    input  logic              ARESETN,

    // Slave AXI-Stream
    input  logic [31:0]       S_AXIS_TDATA,
    input  logic              S_AXIS_TVALID,
    output logic              S_AXIS_TREADY,
    input  logic              S_AXIS_TLAST,

    // Master AXI-Stream
    output logic [31:0]       M_AXIS_TDATA,
    output logic              M_AXIS_TVALID,
    input  logic              M_AXIS_TREADY,
    output logic              M_AXIS_TLAST
);

    // Internal 2D Staging Buffers
    logic [DATA_W-1:0] matrix_A [0:N-1][0:N-1];
    logic [DATA_W-1:0] matrix_B [0:N-1][0:N-1];
    logic [ACC_W-1:0]  matrix_C [0:N-1][0:N-1];

    // Control Signals
    logic [$clog2(N*N)-1:0] element_cnt;
    logic [$clog2(N*N)-1:0] out_cnt;
    logic                   load_sel; 
    logic                   compute_start;
    logic                   core_done;
    
    typedef enum {LOADING, COMPUTING, STREAMING} state_t;
    state_t state;

    // Slave Interface Logic
    assign S_AXIS_TREADY = (state == LOADING);
    wire axis_push = S_AXIS_TVALID && S_AXIS_TREADY;

    always_ff @(posedge ACLK) begin
        if (!ARESETN) begin
            state <= LOADING;
            element_cnt <= 0;
            load_sel <= 0;
            compute_start <= 0;
            out_cnt <= 0;
        end else begin
            case (state)
                LOADING: begin
                    if (axis_push) begin
                        if (load_sel == 0)
                            matrix_A[element_cnt / N][element_cnt % N] <= S_AXIS_TDATA[DATA_W-1:0];
                        else
                            matrix_B[element_cnt / N][element_cnt % N] <= S_AXIS_TDATA[DATA_W-1:0];

                        if (element_cnt == (N*N) - 1) begin
                            element_cnt <= 0;
                            if (load_sel == 1) begin
                                load_sel <= 0;
                                state <= COMPUTING;
                                compute_start <= 1; 
                            end else begin
                                load_sel <= 1;
                            end
                        end else begin
                            element_cnt <= element_cnt + 1;
                        end
                    end
                end

                COMPUTING: begin
                    compute_start <= 0;
                    if (core_done) state <= STREAMING;
                end

                STREAMING: begin
                    if (M_AXIS_TVALID && M_AXIS_TREADY) begin
                        if (out_cnt == (N*N) - 1) begin
                            out_cnt <= 0;
                            state <= LOADING;
                        end else begin
                            out_cnt <= out_cnt + 1;
                        end
                    end
                end
            endcase
        end
    end

    // Master Interface Logic
    assign M_AXIS_TVALID = (state == STREAMING);
    assign M_AXIS_TDATA  = matrix_C[out_cnt / N][out_cnt % N];
    assign M_AXIS_TLAST  = (out_cnt == (N*N) - 1);

    // --- Fixed Instantiation ---
    systolic_top #(.N(N), .DATA_W(DATA_W), .ACC_W(ACC_W)) core_inst (
        .clk(ACLK),
        .reset(!ARESETN),
        .start(compute_start),
        .src_valid(1'b1),    // Data in buffers is already valid
        .src_ready(),        // Open loop
        .sink_ready(1'b1),   // Wrapper is always ready to receive results
        .sink_valid(),       // Managed by core_done
        .A_in(matrix_A),
        .B_in(matrix_B),
        .C_out(matrix_C),
        .done(core_done)     // Connects to FSM for state transition
    );

endmodule
