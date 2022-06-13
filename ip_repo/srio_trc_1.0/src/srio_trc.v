`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/07 19:36:37
// Design Name: 
// Module Name: srio_trc
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


module srio_trc#(
    parameter [0:0] TX_ONLY = 1'b0,
    parameter [15:0] C_DEV_ID = 16'hF201,
    parameter [15:0] C_DEST_ID = 16'h7801,
    parameter AXIL_DW = 32,
    parameter AXIL_AW = 4
    )(
    input aclk,
    input aresetn,

    (* mark_debug = "true" *) output nread_irq,
    (* mark_debug = "true" *) output swrite_irq,

// ireq signals
    (* mark_debug = "true" *) output m_axis_ireq_tvalid,
    (* mark_debug = "true" *) input m_axis_ireq_tready,
    (* mark_debug = "true" *) output [63:0] m_axis_ireq_tdata,
    (* mark_debug = "true" *) output [7:0] m_axis_ireq_tkeep,
    (* mark_debug = "true" *) output m_axis_ireq_tlast,
    (* mark_debug = "true" *) output [31:0] m_axis_ireq_tuser,
// end of ireq signals   

// iresp signals
    (* mark_debug = "true" *) input s_axis_iresp_tvalid,
    (* mark_debug = "true" *) output s_axis_iresp_tready,
    (* mark_debug = "true" *) input [63:0] s_axis_iresp_tdata,
    (* mark_debug = "true" *) input [7:0] s_axis_iresp_tkeep,
    (* mark_debug = "true" *) input s_axis_iresp_tlast,
    (* mark_debug = "true" *) input [31:0] s_axis_iresp_tuser,
// end of iresp signals

// AXI4-Lite control signals
    input [AXIL_AW-1:0] s_axil_awaddr,
    input [2:0] s_axil_awprot,
    input s_axil_awvalid,
    output s_axil_awready,

    input [AXIL_DW-1:0] s_axil_wdata,
    input [3:0] s_axil_wstrb,
    input s_axil_wvalid,
    output s_axil_wready,

    output [1:0] s_axil_bresp,
    output s_axil_bvalid,
    input s_axil_bready,

    input [AXIL_AW-1:0] s_axil_araddr,
    input [2:0] s_axil_arprot,
    input s_axil_arvalid,
    output s_axil_arready,

    output [AXIL_DW-1:0] s_axil_rdata,
    output [1:0] s_axil_rresp,
    output s_axil_rvalid,
    input s_axil_rready,
// end of AXI4-Lite control signals

// axi master interface
    // input  m_axi_init_axi_txn,
    // output m_axi_txn_done,
    // output m_axi_error,
    // input m_axi_aclk,
    // input m_axi_aresetn,
    // output [C_m_axi_ID_WIDTH-1 : 0] m_axi_awid,
    // output [C_m_axi_AWUSER_WIDTH-1 : 0] m_axi_awuser,
    // output [C_m_axi_WUSER_WIDTH-1 : 0] m_axi_wuser,
    // input [C_m_axi_ID_WIDTH-1 : 0] m_axi_bid,
    // input [C_m_axi_BUSER_WIDTH-1 : 0] m_axi_buser,
    // output [C_m_axi_ID_WIDTH-1 : 0] m_axi_arid,
    // output [C_m_axi_ARUSER_WIDTH-1 : 0] m_axi_aruser,
    // input [C_m_axi_ID_WIDTH-1 : 0] m_axi_rid,
    // input [C_m_axi_RUSER_WIDTH-1 : 0] m_axi_ruser,

    output [2 : 0] m_axi_awsize,
    output [1 : 0] m_axi_awburst,
    output m_axi_awlock,
    output [3 : 0] m_axi_awcache,
    output [2 : 0] m_axi_awprot,
    output [3 : 0] m_axi_awqos,
    output [7 : 0] m_axi_wstrb,
    output [2 : 0] m_axi_arsize,
    output [1 : 0] m_axi_arburst,
    output m_axi_arlock,
    output [3 : 0] m_axi_arcache,
    output [2 : 0] m_axi_arprot,
    output [3 : 0] m_axi_arqos,
    output m_axi_bready,
    input [1 : 0] m_axi_rresp,
    input [1 : 0] m_axi_bresp,
    input m_axi_bvalid,
    // aw
    output [31 : 0] m_axi_awaddr,
    output [7 : 0] m_axi_awlen,
    output m_axi_awvalid,
    input m_axi_awready,
    // w
    output [63 : 0] m_axi_wdata,
    output m_axi_wlast,
    output m_axi_wvalid,
    input m_axi_wready,
    // ar
    output [31 : 0] m_axi_araddr,
    output [7 : 0] m_axi_arlen,
    output m_axi_arvalid,
    input m_axi_arready,
    // r
    input [63 : 0] m_axi_rdata,
    input m_axi_rlast,
    input m_axi_rvalid,
    output m_axi_rready
// end of axi master interface
    );
    integer i;

    reg axil_awready;
    reg axil_wready;
    reg [1:0] axil_bresp;
    reg axil_bvalid;

    reg axil_arready;
    reg axil_rvalid;
    reg [1:0] axil_rresp;
    reg [31:0] axil_rdata;
    reg axil_rlast;

    reg allow_aw;

    wire handshake_aw;
    wire handshake_w;
    wire handshake_b;
    wire handshake_ar;
    wire handshake_r;

    wire write_en;

    (* mark_debug = "true" *) reg [AXIL_DW-1:0] START;
    (* mark_debug = "true" *) reg [AXIL_DW-1:0] SRCADDR;
    (* mark_debug = "true" *) reg [AXIL_DW-1:0] DSTADDR;
    (* mark_debug = "true" *) reg [AXIL_DW-1:0] INFOSIZE;

    (* mark_debug = "true" *) wire doorbell_finish;
    (* mark_debug = "true" *) wire swrite_finish;
    (* mark_debug = "true" *) wire nread_finish;

    wire ireq_tvalid_sw;
    wire [63:0] ireq_tdata_sw;
    wire ireq_tlast_sw;
    wire iresp_tready_sw;

    wire ireq_tvalid_db;
    wire [63:0] ireq_tdata_db;
    wire ireq_tlast_db;
    wire iresp_tready_db;
    
    wire ireq_tvalid_nr;
    wire [63:0] ireq_tdata_nr;
    wire ireq_tlast_nr;
    wire iresp_tready_nr;

    wire [AXIL_DW-1:0] srcAddr;
    wire [AXIL_DW-1:0] dstAddr;
    wire [15:0] size_dw;
    wire [15:0] doorbell_info;

    (* mark_debug = "true" *) wire doorbell_start;
    (* mark_debug = "true" *) wire swrite_start;
    (* mark_debug = "true" *) wire nread_start;

    reg db_start_q;
    reg sw_start_q;
    reg nr_start_q;

    assign m_axis_ireq_tuser = {C_DEV_ID, C_DEST_ID};
    assign m_axis_ireq_tkeep = 8'hFF;

// axi master
    assign m_axi_awsize = 3'b011; // awsize = 8 bytes
    assign m_axi_awburst = 2'b01; // INCR
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = 4'b0011; // Normal Non-cacheable Non-bufferable
    assign m_axi_awprot = 3'b010;
    assign m_axi_awqos = 4'b0;
    assign m_axi_wstrb = 8'hFF;
    assign m_axi_arsize = 3'b011;
    assign m_axi_arburst = 2'b01;
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = 4'b0011; // Normal Non-cacheable
    assign m_axi_arprot = 3'b010;
    assign m_axi_arqos = 4'b0;
    assign m_axi_bready = 1'b1;
// end of axi master

// common srio port signals
    assign m_axis_ireq_tvalid = ireq_tvalid_db | ireq_tvalid_sw | ireq_tvalid_nr;
    assign m_axis_ireq_tdata = ireq_tdata_db | ireq_tdata_sw | ireq_tdata_nr;
    assign m_axis_ireq_tlast = ireq_tlast_db | ireq_tlast_sw | ireq_tlast_nr;
    assign s_axis_iresp_tready = iresp_tready_db | iresp_tready_sw | iresp_tready_nr;
// end of common srio port signals

// axi-lite signals
    assign s_axil_awready = axil_awready;
    assign s_axil_wready = axil_wready;
    assign s_axil_bresp = axil_bresp;
    assign s_axil_bvalid = axil_bvalid;

    assign s_axil_arready = axil_arready;
    assign s_axil_rresp = axil_rresp;
    assign s_axil_rvalid = axil_rvalid;
    assign s_axil_rdata = axil_rdata;
    assign s_axil_rlast = axil_rlast; 

    assign handshake_aw = s_axil_awvalid & s_axil_awready;
    assign handshake_w = s_axil_wvalid & s_axil_wready;
    assign handshake_b = s_axil_bvalid & s_axil_bready;
    assign handshake_ar = s_axil_arvalid & s_axil_arready;
    assign handshake_r = s_axil_rvalid & s_axil_rready;
    // allow_aw
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            allow_aw <= 1'b1;
        end
        else begin
            if(s_axil_awvalid && s_axil_wvalid && allow_aw) begin 
                allow_aw <= 1'b0;
            end
            else if(handshake_b) begin
                allow_aw <= 1'b1;
            end
        end
    end

    // awready
    always @(posedge aclk or negedge aresetn) begin 
        if (!aresetn) begin 
            axil_awready <= 1'b0;
        end 
        else begin
            if(!axil_awready && s_axil_awvalid && s_axil_wvalid && allow_aw) begin 
                axil_awready <= 1'b1;
            end
            else begin // make awready stay only one cycle
                axil_awready <= 1'b0;
            end
        end
    end

    // wready
    always @(posedge aclk or negedge aresetn) begin 
        if(!aresetn) begin 
            axil_wready <= 1'b0;
        end
        else begin 
            if(!axil_wready && s_axil_awvalid && s_axil_wvalid && allow_aw) begin 
                axil_wready <= 1'b1;
            end
            else begin 
                axil_wready <= 1'b0;
            end
        end
    end

    // write regs
    assign write_en = handshake_aw & handshake_w;

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin 
            START <= 'b0;
            SRCADDR <= 'b0;
            DSTADDR <= 'b0;
            INFOSIZE <= 'b0;
        end
        else begin
            if(write_en) begin 
                case (s_axil_awaddr[AXIL_AW-1:2])
                    2'b00:
                        for(i = 0; i < 4; i = i + 1)
                            if(s_axil_wstrb[i]) START[(i*8)+:8] <= s_axil_wdata[(i*8)+:8];
                    2'b01:
                        for(i = 0; i < 4; i = i + 1)
                            if(s_axil_wstrb[i]) SRCADDR[(i*8)+:8] <= s_axil_wdata[(i*8)+:8];
                    2'b10:
                        for(i = 0; i < 4; i = i + 1)
                            if(s_axil_wstrb[i]) DSTADDR[(i*8)+:8] <= s_axil_wdata[(i*8)+:8];
                    2'b11:
                        for(i = 0; i < 4; i = i + 1)
                            if(s_axil_wstrb[i]) INFOSIZE[(i*8)+:8] <= s_axil_wdata[(i*8)+:8]; 
                endcase
            end
            if(doorbell_finish) begin
                START[0] <= 1'b0;
            end
            if(swrite_finish) begin
                START[1] <= 1'b0;
            end
            if(nread_finish) begin
                START[2] <= 1'b0;
            end
        end
    end
    // s_axil_bresp
    // s_axil_bvalid
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            axil_bresp <= 2'b0;
            axil_bvalid <= 1'b0;
        end
        else begin
            if(!axil_bvalid && write_en) begin
                axil_bvalid <= 1'b1;
            end
            else if(handshake_b) begin
                axil_bvalid <= 1'b0;
            end
        end
    end

    // s_axil_arready
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin 
            axil_arready <= 1'b0;
        end
        else begin 
            if(!axil_arready && s_axil_arvalid) begin 
                axil_arready <= 1'b1;
            end
            else begin
                axil_arready <= 1'b0;
            end
        end
    end

    // rvalid rresp rdata
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin 
            axil_rvalid <= 1'b0;
            axil_rresp <= 2'b0;
            axil_rdata <= 'b0;
        end
        else begin 
            if(!axil_rvalid && handshake_ar) begin
                axil_rvalid <= 1'b1;
                case (s_axil_araddr[AXIL_AW-1:2])
                    2'b00: axil_rdata <= START; 
                    2'b01: axil_rdata <= SRCADDR;
                    2'b10: axil_rdata <= DSTADDR;
                    2'b11: axil_rdata <= INFOSIZE;
                endcase
            end
            else if(handshake_r) begin
                axil_rvalid <= 1'b0;
                axil_rdata <= 'b0;
            end
        end
    end
    
// end of axi-lite signals

// registers relevant signals
    assign srcAddr = SRCADDR;
    assign dstAddr = DSTADDR;
    assign size_dw = INFOSIZE[15:0];
    assign doorbell_info = INFOSIZE[31:16];
    assign doorbell_start = ({db_start_q, START[0]} == 2'b01)? 1'b1: 1'b0;
    assign swrite_start = ({sw_start_q, START[1]} == 2'b01)? 1'b1: 1'b0;
    assign nread_start = ({nr_start_q, START[2]} == 2'b01)? 1'b1: 1'b0;

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin 
            db_start_q <= 1'b0;
            sw_start_q <= 1'b0;
            nr_start_q <= 1'b0;
        end
        else begin
            db_start_q <= START[0];
            sw_start_q <= START[1];
            nr_start_q <= START[2];
        end
    end
// end registers relevant signals

    doorbell_engine  db_engine_inst (
        .aclk                    ( aclk                  ),
        .aresetn                 ( aresetn               ),
        .doorbell_start          ( doorbell_start        ),
        .doorbell_info           ( doorbell_info         ),
        .m_axis_ireq_tready      ( m_axis_ireq_tready    ),
        .s_axis_iresp_tvalid     ( s_axis_iresp_tvalid   ),
        .s_axis_iresp_tdata      ( s_axis_iresp_tdata    ),
        .s_axis_iresp_tkeep      ( s_axis_iresp_tkeep    ),
        .s_axis_iresp_tlast      ( s_axis_iresp_tlast    ),

        .m_axis_ireq_tvalid      ( ireq_tvalid_db    ),
        .m_axis_ireq_tdata       ( ireq_tdata_db     ),
        .m_axis_ireq_tlast       ( ireq_tlast_db     ),
        .s_axis_iresp_tready     ( iresp_tready_db   ),
        .doorbell_finish         (doorbell_finish)
    );

    swrite_engine  sw_engine_inst (
        .aclk                    ( aclk                 ),
        .aresetn                 ( aresetn              ),
        .swrite_start            ( swrite_start         ),
        .srcAddr                 ( srcAddr              ),
        .dstAddr                 ( dstAddr              ),
        .size_dw                 ( size_dw              ),
        .doorbell_info           ( doorbell_info        ),
        .m_axis_ireq_tready      ( m_axis_ireq_tready   ),
        .m_axi_arready           ( m_axi_arready        ),
        .m_axi_rdata             ( m_axi_rdata          ),
        .m_axi_rlast             ( m_axi_rlast          ),
        .m_axi_rvalid            ( m_axi_rvalid         ),
        .s_axis_iresp_tvalid     ( s_axis_iresp_tvalid   ),
        .s_axis_iresp_tdata      ( s_axis_iresp_tdata    ),
        .s_axis_iresp_tkeep      ( s_axis_iresp_tkeep    ),
        .s_axis_iresp_tlast      ( s_axis_iresp_tlast    ),

        .m_axis_ireq_tvalid      ( ireq_tvalid_sw   ),
        .m_axis_ireq_tdata       ( ireq_tdata_sw    ),
        .m_axis_ireq_tlast       ( ireq_tlast_sw    ),
        .m_axi_araddr            ( m_axi_araddr         ),
        .m_axi_arlen             ( m_axi_arlen          ),
        .m_axi_arvalid           ( m_axi_arvalid        ),
        .m_axi_rready            ( m_axi_rready         ),
        .swrite_irq              ( swrite_irq      ),
        .swrite_finish           (swrite_finish),
        .s_axis_iresp_tready     ( iresp_tready_sw   )
    );

    generate
        if( TX_ONLY == 1 ) begin: exclude_nread
            assign ireq_tvalid_nr = 1'b0;
            assign ireq_tdata_nr = 'b0;
            assign ireq_tlast_nr = 1'b0;
            assign iresp_tready_nr = 1'b0;
            assign nread_irq = 1'b0;

            assign m_axi_awaddr = 'b0;
            assign m_axi_awlen = 'b0;
            assign m_axi_awvalid = 1'b0;
            assign m_axi_wdata = 'b0;
            assign m_axi_wlast = 1'b0;
            assign m_axi_wvalid = 1'b0;
        end
        else begin: include_nread
            nread_engine  nr_engine_inst (
                .aclk                    ( aclk                  ),
                .aresetn                 ( aresetn               ),
                .nread_start             ( nread_start           ),
                .srcAddr                 ( srcAddr               ),
                .dstAddr                 ( dstAddr               ),
                .size_dw                 ( size_dw               ),
                .doorbell_info           ( doorbell_info        ),
                .m_axis_ireq_tready      ( m_axis_ireq_tready    ),
                .s_axis_iresp_tvalid     ( s_axis_iresp_tvalid   ),
                .s_axis_iresp_tdata      ( s_axis_iresp_tdata    ),
                .s_axis_iresp_tkeep      ( s_axis_iresp_tkeep    ),
                .s_axis_iresp_tlast      ( s_axis_iresp_tlast    ),
                .m_axi_awready           ( m_axi_awready         ),
                .m_axi_wready            ( m_axi_wready          ),

                .nread_irq               ( nread_irq             ),
                .nread_finish(nread_finish),
                .m_axis_ireq_tvalid      ( ireq_tvalid_nr    ),
                .m_axis_ireq_tdata       ( ireq_tdata_nr     ),
                .m_axis_ireq_tlast       ( ireq_tlast_nr     ),
                .s_axis_iresp_tready     ( iresp_tready_nr   ),
                .m_axi_awaddr            ( m_axi_awaddr          ),
                .m_axi_awlen             ( m_axi_awlen           ),
                .m_axi_awvalid           ( m_axi_awvalid         ),
                .m_axi_wdata             ( m_axi_wdata           ),
                .m_axi_wlast             ( m_axi_wlast           ),
                .m_axi_wvalid            ( m_axi_wvalid          )
            );
        end
    endgenerate

endmodule
