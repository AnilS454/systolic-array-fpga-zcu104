`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.01.2026 09:38:48
// Design Name: 
// Module Name: systolic_controller
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


module systolic_controller #(
    parameter N = 4,
    parameter DATA_W = 8  // Added parameter to fix VRFC 10-2861
)(
    input  logic clk,
    input  logic reset,
    input  logic start,

    // Interface to Source (Handshaking)
    input  logic src_valid,   
    output logic src_ready,   

    // Interface to Sink (Handshaking) - Added to fix VRFC 10-3180
    output logic sink_valid,  
    input  logic sink_ready,  

    // Data from Buffers
    input  logic [DATA_W-1:0] A_in [0:N-1][0:N-1],
    input  logic [DATA_W-1:0] B_in [0:N-1][0:N-1],
    input  logic array_valid_out, 

    // Outputs to the Systolic Array
    output logic [DATA_W-1:0] A_row [0:N-1],
    output logic [DATA_W-1:0] B_col [0:N-1],
    output logic valid_to_array,
    
    // Status
    output logic done,
    output logic clear_acc
);

    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        FEED    = 2'b01,
        FLUSH   = 2'b10,
        FINISH  = 2'b11
    } state_t;

    state_t state;
    integer k; 
    integer i;

    assign src_ready = (state == FEED);
    assign clear_acc = (state == IDLE && start);

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            k <= 0;
            sink_valid <= 0;
            valid_to_array <= 0;
            done <= 0;
            for (i = 0; i < N; i++) begin
                A_row[i] <= 0;
                B_col[i] <= 0;
            end
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    k <= 0;
                    sink_valid <= 0;
                    valid_to_array <= 0;
                    if (start) state <= FEED;
                end

                FEED: begin
                    if (src_valid) begin
                        valid_to_array <= 1;
                        for (i = 0; i < N; i++) begin
                            // SKEW LOGIC: 
                            // Only feed data if the current cycle 'k' has reached 
                            // the required delay for that specific row/column.
                            if (k >= i && (k - i) < N) begin
                                A_row[i] <= A_in[i][k - i];
                                B_col[i] <= B_in[k - i][i];
                            end else begin
                                A_row[i] <= 0;
                                B_col[i] <= 0;
                            end
                        end

                        // For N=4, we now need more cycles to finish feeding 
                        // because of the skew (N + N - 1 cycles).
                        if (k == (2*N - 2)) begin
                            state <= FLUSH;
                            k <= 0;
                        end else begin
                            k <= k + 1;
                        end
                    end else begin
                        valid_to_array <= 0;
                    end
                end

                FLUSH: begin
                    valid_to_array <= 1; 
                    for (i = 0; i < N; i++) begin
                        A_row[i] <= 0; B_col[i] <= 0;
                    end
                    // Wait for trailing edge of wavefront
                    if (k >= 3*N) begin 
                        state <= FINISH;
                        valid_to_array <= 0;
                    end else k <= k + 1;
                end

                FINISH: begin
                    sink_valid <= 1;
                    if (sink_ready) begin
                        done <= 1;
                        sink_valid <= 0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule
    
    