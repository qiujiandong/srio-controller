`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/07 19:36:37
// Design Name: 
// Module Name: nread_engine
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


module nread_engine(
    input aclk,
    input aresetn,

    input nread_start,
    input [31:0] srcAddr,
    input [31:0] dstAddr,
    input [15:0] size_dw,
    output nread_irq,
    output nread_finish,

// ireq signals
    output m_axis_ireq_tvalid,
    input m_axis_ireq_tready,
    output [63:0] m_axis_ireq_tdata,
    output m_axis_ireq_tlast,
// end of ireq signals

// iresp signals
    input s_axis_iresp_tvalid,
    output s_axis_iresp_tready,
    input [63:0] s_axis_iresp_tdata,
    input [7:0] s_axis_iresp_tkeep,
    input s_axis_iresp_tlast,
// end of iresp signals

// m_axi
    output [31 : 0] m_axi_awaddr,
    output [7 : 0] m_axi_awlen,
    output m_axi_awvalid,
    input m_axi_awready,

    output [63 : 0] m_axi_wdata,
    output m_axi_wlast,
    output m_axi_wvalid,
    input m_axi_wready
// end of m_axi
    );
endmodule
