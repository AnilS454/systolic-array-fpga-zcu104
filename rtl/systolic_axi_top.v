`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.02.2026 22:52:31
// Design Name: 
// Module Name: systolic_axi_top
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




// Verilog-2001 Top-Level Wrapper for AIE-Flex
// This file allows SystemVerilog modules to be used in Vivado Block Design
module systolic_axi_top #(
    parameter N      = 8,
    parameter DATA_W = 8,
    parameter ACC_W  = 32
)(
    input  wire        ACLK,
    input  wire        ARESETN,

    // Slave AXI-Stream (Input Data)
    input  wire [31:0] S_AXIS_TDATA,
    input  wire        S_AXIS_TVALID,
    output wire        S_AXIS_TREADY,
    input  wire        S_AXIS_TLAST,

    // Master AXI-Stream (Output Results)
    output wire [31:0] M_AXIS_TDATA,
    output wire        M_AXIS_TVALID,
    input  wire        M_AXIS_TREADY,
    output wire        M_AXIS_TLAST
);

    // Instantiate the SystemVerilog AXI Wrapper
    systolic_axi_wrapper #(
        .N(N),
        .DATA_W(DATA_W),
        .ACC_W(ACC_W)
    ) aie_flex_inst (
        .ACLK(ACLK),
        .ARESETN(ARESETN),
        
        // Slave Ports
        .S_AXIS_TDATA(S_AXIS_TDATA),
        .S_AXIS_TVALID(S_AXIS_TVALID),
        .S_AXIS_TREADY(S_AXIS_TREADY),
        .S_AXIS_TLAST(S_AXIS_TLAST),
        
        // Master Ports
        .M_AXIS_TDATA(M_AXIS_TDATA),
        .M_AXIS_TVALID(M_AXIS_TVALID),
        .M_AXIS_TREADY(M_AXIS_TREADY),
        .M_AXIS_TLAST(M_AXIS_TLAST)
    );

endmodule
