`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/01 10:35:59
// Design Name: 
// Module Name: srio_rxc
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


module srio_rxc#(
    parameter [15:0] C_DEV_ID = 16'hF201,
    parameter [15:0] C_DEST_ID = 16'h7801
)(
    input aclk,
    input aresetn,

    (* mark_debug = "true" *) output doorbell_irq,
    
// treq signals
    (* mark_debug = "true" *) input s_axis_treq_tvalid,
    (* mark_debug = "true" *) output s_axis_treq_tready,
    (* mark_debug = "true" *) input [63:0] s_axis_treq_tdata,
    (* mark_debug = "true" *) input [7:0] s_axis_treq_tkeep,
    (* mark_debug = "true" *) input s_axis_treq_tlast,
    (* mark_debug = "true" *) input [31:0] s_axis_treq_tuser,
// end of treq signals

// tresp signals
    (* mark_debug = "true" *) output m_axis_tresp_tvalid,
    (* mark_debug = "true" *) input m_axis_tresp_tready,
    (* mark_debug = "true" *) output [63:0] m_axis_tresp_tdata,
    (* mark_debug = "true" *) output [7:0] m_axis_tresp_tkeep,
    (* mark_debug = "true" *) output m_axis_tresp_tlast,
    (* mark_debug = "true" *) output [31:0] m_axis_tresp_tuser,
// end of tresp signals

// AXI4-Lite control signals
    input [3:0] s_axil_awaddr,
    input [2:0] s_axil_awprot,
    input s_axil_awvalid,
    output s_axil_awready,

    input s_axil_wdata,
    input [3:0] s_axil_wstrb,
    input s_axil_wvalid,
    output s_axil_wready,

    output [1:0] s_axil_bresp,
    output s_axil_bvalid,
    input s_axil_bready,

    input [3:0] s_axil_araddr,
    input [2:0] s_axil_arprot,
    input s_axil_arvalid,
    output s_axil_arready,

    output [31:0] s_axil_rdata,
    output [1:0] s_axil_rresp,
    output s_axil_rvalid,
    input s_axil_rready,
// end of AXI4-Lite control signals

// axi master interface
    output [2 : 0] m_axi_awsize,
    output [1 : 0] m_axi_awburst,
    output [0 : 0] m_axi_awlock,
    output [3 : 0] m_axi_awcache,
    output [2 : 0] m_axi_awprot,
    output [3 : 0] m_axi_awregion,
    output [3 : 0] m_axi_awqos,
    output m_axi_bready,

    output [31 : 0] m_axi_awaddr,
    output [7 : 0] m_axi_awlen,
    output m_axi_awvalid,
    input m_axi_awready,

    output [63 : 0] m_axi_wdata,
    output [7 : 0] m_axi_wstrb,
    output m_axi_wlast,
    output m_axi_wvalid,
    input m_axi_wready,

    input [1 : 0] m_axi_bresp,
    input m_axi_bvalid
// end of axi master interface
    );

// fifo slave interface 
    // wire [31 : 0] s_axi_awaddr;
    // wire [7 : 0] s_axi_awlen;
    // wire [2 : 0] s_axi_awsize;
    // wire [1 : 0] s_axi_awburst;
    // wire [0 : 0] s_axi_awlock;
    // wire [3 : 0] s_axi_awcache;
    // wire [2 : 0] s_axi_awprot;
    // wire [3 : 0] s_axi_awregion;
    // wire [3 : 0] s_axi_awqos;
    // wire s_axi_awvalid;
    // wire s_axi_awready;
    // wire [63 : 0] s_axi_wdata;
    // wire [7 : 0] s_axi_wstrb;
    // wire s_axi_wlast;
    // wire s_axi_wvalid;
    // wire s_axi_wready;
    // wire [1 : 0] s_axi_bresp;
    // wire s_axi_bvalid;
    // wire s_axi_bready;
// end of fifo slave interface

// user defined signals

    wire treq_tready_db;
    wire treq_tready_nw;
    
// end of user defined signals 

// assign of interface configuration
    assign m_axi_awsize = 3'b011; // awsize = 8 bytes
    assign m_axi_awburst = 2'b01; // INCR
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = 4'b0011; // Normal Non-cacheable Bufferable
    assign m_axi_awprot = 3'b010;
    assign m_axi_awregion = 4'h0;
    assign m_axi_awqos = 4'h0;
    assign m_axi_wstrb = 8'hFF;
    assign m_axi_bready = 1'b1;

    // assign m_axis_tresp_tuser = {C_DEV_ID, C_DEST_ID};
// end of assign of interface configuration

    assign s_axis_treq_tready = treq_tready_db | treq_tready_nw;

// fifo instance
    // axi_data_fifo_0 axi_fifo (
    // .aclk(aclk),                      // input wire aclk
    // .aresetn(aresetn),                // input wire aresetn
    // .s_axi_awaddr(s_axi_awaddr),      // input wire [31 : 0] s_axi_awaddr
    // .s_axi_awlen(s_axi_awlen),        // input wire [7 : 0] s_axi_awlen
    // .s_axi_awsize(s_axi_awsize),      // input wire [2 : 0] s_axi_awsize
    // .s_axi_awburst(s_axi_awburst),    // input wire [1 : 0] s_axi_awburst
    // .s_axi_awlock(s_axi_awlock),      // input wire [0 : 0] s_axi_awlock
    // .s_axi_awcache(s_axi_awcache),    // input wire [3 : 0] s_axi_awcache
    // .s_axi_awprot(s_axi_awprot),      // input wire [2 : 0] s_axi_awprot
    // .s_axi_awregion(s_axi_awregion),  // input wire [3 : 0] s_axi_awregion
    // .s_axi_awqos(s_axi_awqos),        // input wire [3 : 0] s_axi_awqos
    // .s_axi_awvalid(s_axi_awvalid),    // input wire s_axi_awvalid
    // .s_axi_awready(s_axi_awready),    // output wire s_axi_awready
    // .s_axi_wdata(s_axi_wdata),        // input wire [63 : 0] s_axi_wdata
    // .s_axi_wstrb(s_axi_wstrb),        // input wire [7 : 0] s_axi_wstrb
    // .s_axi_wlast(s_axi_wlast),        // input wire s_axi_wlast
    // .s_axi_wvalid(s_axi_wvalid),      // input wire s_axi_wvalid
    // .s_axi_wready(s_axi_wready),      // output wire s_axi_wready
    // .s_axi_bresp(s_axi_bresp),        // output wire [1 : 0] s_axi_bresp
    // .s_axi_bvalid(s_axi_bvalid),      // output wire s_axi_bvalid
    // .s_axi_bready(s_axi_bready),      // input wire s_axi_bready
    // .m_axi_awaddr(m_axi_awaddr),      // output wire [31 : 0] m_axi_awaddr
    // .m_axi_awlen(m_axi_awlen),        // output wire [7 : 0] m_axi_awlen
    // .m_axi_awsize(m_axi_awsize),      // output wire [2 : 0] m_axi_awsize
    // .m_axi_awburst(m_axi_awburst),    // output wire [1 : 0] m_axi_awburst
    // .m_axi_awlock(m_axi_awlock),      // output wire [0 : 0] m_axi_awlock
    // .m_axi_awcache(m_axi_awcache),    // output wire [3 : 0] m_axi_awcache
    // .m_axi_awprot(m_axi_awprot),      // output wire [2 : 0] m_axi_awprot
    // .m_axi_awregion(m_axi_awregion),  // output wire [3 : 0] m_axi_awregion
    // .m_axi_awqos(m_axi_awqos),        // output wire [3 : 0] m_axi_awqos
    // .m_axi_awvalid(m_axi_awvalid),    // output wire m_axi_awvalid
    // .m_axi_awready(m_axi_awready),    // input wire m_axi_awready
    // .m_axi_wdata(m_axi_wdata),        // output wire [63 : 0] m_axi_wdata
    // .m_axi_wstrb(m_axi_wstrb),        // output wire [7 : 0] m_axi_wstrb
    // .m_axi_wlast(m_axi_wlast),        // output wire m_axi_wlast
    // .m_axi_wvalid(m_axi_wvalid),      // output wire m_axi_wvalid
    // .m_axi_wready(m_axi_wready),      // input wire m_axi_wready
    // .m_axi_bresp(m_axi_bresp),        // input wire [1 : 0] m_axi_bresp
    // .m_axi_bvalid(m_axi_bvalid),      // input wire m_axi_bvalid
    // .m_axi_bready(m_axi_bready)      // output wire m_axi_bready
    // );
// end of fifo instance

// doorbell engin instance
    doorbell_engine #(
        .DW(32),
        .AW(4),
        .C_DEV_ID(C_DEV_ID),
        .C_DEST_ID(C_DEST_ID)
    )
    db_engine_inst(
        .aclk(aclk),
        .aresetn(aresetn),

        .s_axis_treq_tvalid(s_axis_treq_tvalid),
        .s_axis_treq_tready(treq_tready_db),
        .s_axis_treq_tdata(s_axis_treq_tdata),

        .doorbell_irq(doorbell_irq),

        .m_axis_tresp_tvalid(m_axis_tresp_tvalid),
        .m_axis_tresp_tready(m_axis_tresp_tready),
        .m_axis_tresp_tdata(m_axis_tresp_tdata),
        .m_axis_tresp_tkeep(m_axis_tresp_tkeep),
        .m_axis_tresp_tlast(m_axis_tresp_tlast),
        .m_axis_tresp_tuser(m_axis_tresp_tuser),

        .s_axil_awaddr(s_axil_awaddr),
        .s_axil_awprot(s_axil_awprot),
        .s_axil_awvalid(s_axil_awvalid),
        .s_axil_awready(s_axil_awready),

        .s_axil_wdata(s_axil_wdata),
        .s_axil_wstrb(s_axil_wstrb),
        .s_axil_wvalid(s_axil_wvalid),
        .s_axil_wready(s_axil_wready),

        .s_axil_bresp(s_axil_bresp),
        .s_axil_bvalid(s_axil_bvalid),
        .s_axil_bready(s_axil_bready),

        .s_axil_araddr(s_axil_araddr),
        .s_axil_arprot(s_axil_arprot),
        .s_axil_arvalid(s_axil_arvalid),
        .s_axil_arready(s_axil_arready),

        .s_axil_rdata(s_axil_rdata),
        .s_axil_rresp(s_axil_rresp),
        .s_axil_rvalid(s_axil_rvalid),
        .s_axil_rready(s_axil_rready)
    );
// end of doorbell engin instance

// nwrite receive engine instance
    nwrite_engine nw_engine_inst(
        .aclk(aclk),
        .aresetn(aresetn),

        .s_axis_treq_tvalid(s_axis_treq_tvalid),
        .s_axis_treq_tready(treq_tready_nw),
        .s_axis_treq_tdata(s_axis_treq_tdata),
        .s_axis_treq_tkeep(s_axis_treq_tkeep),
        .s_axis_treq_tlast(s_axis_treq_tlast),
        .s_axis_treq_tuser(s_axis_treq_tuser),

        .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),
        .m_axi_awlen(m_axi_awlen),

        .m_axi_wdata(m_axi_wdata),
        .m_axi_wlast(m_axi_wlast),
        .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready)
    );
// end of nwrite receive engine instance
endmodule
