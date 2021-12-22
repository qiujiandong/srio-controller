`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/07 19:36:37
// Design Name: 
// Module Name: swrite_engine
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


module swrite_engine(
    input aclk,
    input aresetn,

    input swrite_start,
    input [31:0] srcAddr,
    input [31:0] dstAddr,
    // real size is size_dw + 1
    input [15:0] size_dw,
    input [15:0] doorbell_info,
    output swrite_irq,
    output swrite_finish,

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
    output [31 : 0] m_axi_araddr,
    output [7 : 0] m_axi_arlen,
    output m_axi_arvalid,
    input m_axi_arready,

    input [63 : 0] m_axi_rdata,
    input m_axi_rlast,
    input m_axi_rvalid,
    output m_axi_rready
// end of m_axi
    );

    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] HEAD = 2'b01;
    localparam [1:0] DATA = 2'b10;
    localparam [1:0] DOORBELL = 2'b11;

    localparam [7:0] SWRITE = 8'h60;
    localparam [1:0] pri = 2'b01;
    localparam [0:0] CRF = 1'b0;
    localparam [7:0] DOORB = 8'hA0;

    (* mark_debug = "true" *) reg [1:0] cstate;
    (* mark_debug = "true" *) reg [1:0] nstate;

    (* mark_debug = "true" *) reg [11:0] read_slice;
    (* mark_debug = "true" *) reg [10:0] swrite_slice;
    (* mark_debug = "true" *) reg [15:0] db_info;
    (* mark_debug = "true" *) reg [3:0] read_beats_tail;
    (* mark_debug = "true" *) reg [4:0] swrite_beats_tail;

    wire handshake_ireq;
    wire handshake_ar;
    wire handshake_r;

    (* mark_debug = "true" *) reg [11:0] read_cnt;
    (* mark_debug = "true" *) reg [10:0] swrite_cnt;
    (* mark_debug = "true" *) reg [4:0] swrite_beats_cnt;

    reg [31:0] axi_araddr;
    reg [7:0] axi_arlen;
    reg axi_arvalid;
    reg axi_rready;

    reg ireq_tvalid;
    reg [63:0] ireq_tdata;
    reg ireq_tlast;

    wire is_swdb_response;
    reg iresp_tready;

    reg [1:0] irq_cnt;

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin 
            read_slice <= 'b0;
            swrite_slice <= 'b0;
            db_info <= 'b0;
            read_beats_tail <= 'b0;
            swrite_beats_tail <= 'b0;
        end
        else if(swrite_start) begin 
            read_slice <= size_dw >> 4;
            swrite_slice <= size_dw >> 5;
            db_info <= doorbell_info;
            read_beats_tail <= size_dw[3:0];
            swrite_beats_tail <= size_dw[4:0];
        end
    end

// handshake
    assign handshake_ireq = m_axis_ireq_tvalid && m_axis_ireq_tready;
    assign handshake_ar = m_axi_arvalid && m_axi_arready;
    assign handshake_r = m_axi_rvalid && m_axi_rready;
// end of handshake

// cnts
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin 
            read_cnt <= 'b0;
        end
        else begin
            if(handshake_ar) begin
                if(read_cnt < read_slice) begin
                    read_cnt <= read_cnt + 12'b1;
                end
                else begin
                    read_cnt <= 'b0;
                end
            end
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            swrite_cnt <= 'b0;
        end
        else begin
            if(cstate == DATA && m_axis_ireq_tlast && handshake_ireq) begin
                if(swrite_cnt < swrite_slice ) begin
                    swrite_cnt <= swrite_cnt + 11'b1;
                end
                else if(swrite_cnt == swrite_slice) begin
                    swrite_cnt <= 'b0;
                end
            end
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            swrite_beats_cnt <= 'b0;
        end
        else begin
            if(handshake_ireq && cstate == DATA) begin 
                if(swrite_cnt < swrite_slice) begin
                    if(swrite_beats_cnt < 5'd31) begin
                        swrite_beats_cnt <= swrite_beats_cnt + 5'b1;
                    end
                    else begin
                        swrite_beats_cnt <= 'b0;
                    end
                end
                else begin
                    if(swrite_beats_cnt < swrite_beats_tail) begin
                        swrite_beats_cnt <= swrite_beats_cnt + 5'b1;
                    end
                    else begin
                        swrite_beats_cnt <= 'b0;
                    end
                end
            end
        end
    end
// end of cnts

// state machine
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin 
            cstate <= IDLE;
        end
        else begin 
            cstate <= nstate;
        end
    end

    always @(*) begin
        nstate = cstate;
        case (cstate)
            IDLE:
                if(swrite_start) begin
                    nstate = HEAD;
                end
            HEAD:
                if(handshake_ireq) begin
                    nstate = DATA;
                end
            DATA:
                if(m_axis_ireq_tlast && handshake_ireq) begin
                    if(swrite_cnt < swrite_slice) begin
                        nstate = HEAD;
                    end
                    else if(swrite_cnt == swrite_slice) begin
                        nstate = DOORBELL;
                    end
                end
            DOORBELL:
                if(handshake_ireq) begin
                    nstate = IDLE;
                end
            default: 
                nstate = IDLE;
        endcase
    end
// end of state machine

// m_axi signals
    assign m_axi_araddr = axi_araddr;
    assign m_axi_arlen = axi_arlen;
    assign m_axi_arvalid = axi_arvalid;
    assign m_axi_rready = axi_rready;

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            axi_araddr <= 'b0;
            axi_arlen <= 'b0;
        end
        else begin
            if(swrite_start) begin
                axi_araddr <= srcAddr;
                if(read_cnt < read_slice) begin
                    axi_arlen <= 8'h0F;
                end
                else begin
                    axi_arlen <= {4'b0, size_dw[3:0]};
                end
            end
            else if(handshake_ar && read_cnt < read_slice) begin
                axi_araddr <= axi_araddr + ((axi_arlen + 8'b1)<<3);
                if(read_cnt == read_slice - 12'b1) begin
                    axi_arlen <= {4'b0, read_beats_tail};
                end
                else begin
                    axi_arlen <= 8'h0F;
                end
            end
            else if(handshake_ar && read_cnt == read_slice) begin
                axi_arlen <= 'b0;
                axi_araddr <= 'b0;
            end
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            axi_arvalid <= 1'b0;
        end
        else begin
            if(swrite_start) begin
                axi_arvalid <= 1'b1;
            end
            else if(read_cnt == read_slice && handshake_ar) begin 
                axi_arvalid <= 1'b0;
            end
        end
    end

    always @(*) begin
        if(cstate == DATA) begin
            axi_rready = m_axis_ireq_tready;
        end
        else begin
            axi_rready = 1'b0;
        end
    end

// end of m_axi_signals

    // output m_axis_ireq_tvalid,
    // input m_axis_ireq_tready,
    // output [63:0] m_axis_ireq_tdata,
    // output m_axis_ireq_tlast,
// ireq signals
    assign m_axis_ireq_tvalid = ireq_tvalid;
    assign m_axis_ireq_tdata = ireq_tdata;
    assign m_axis_ireq_tlast = ireq_tlast;

    always @(*) begin
        ireq_tlast = 1'b0;
        if(cstate == DOORBELL) begin
            ireq_tlast = 1'b1;
        end
        else if(cstate == DATA) begin
            if(swrite_cnt < swrite_slice) begin
                if(swrite_beats_cnt == 5'd31) begin
                    ireq_tlast = 1'b1;
                end
            end
            else begin
                if(swrite_beats_cnt == swrite_beats_tail) begin
                    ireq_tlast = 1'b1;
                end
            end
        end 
    end

    reg [31:0] treq_addr;
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            treq_addr <= 'b0;
        end
        else begin
            if(swrite_start) begin
                treq_addr <= dstAddr;
            end
            else if(ireq_tlast && handshake_ireq) begin
                if(swrite_cnt < swrite_slice) begin
                    if(swrite_beats_cnt == 5'd31) begin
                        treq_addr = treq_addr + 32'd256;
                    end
                end
            end
        end
    end

    always @(*) begin
        ireq_tvalid = 1'b0;
        ireq_tdata = 'b0;
        if(cstate == HEAD) begin
            ireq_tvalid = 1'b1;
            ireq_tdata = {8'b0, SWRITE, 1'b0, pri, CRF, 12'b0, treq_addr};
        end
        else if(cstate == DATA) begin
            ireq_tvalid = m_axi_rvalid;
            ireq_tdata[7:0] = m_axi_rdata[63:56];
            ireq_tdata[15:8] = m_axi_rdata[55:48];
            ireq_tdata[23:16] = m_axi_rdata[47:40];
            ireq_tdata[31:24] = m_axi_rdata[39:32];
            ireq_tdata[39:32] = m_axi_rdata[31:24];
            ireq_tdata[47:40] = m_axi_rdata[23:16];
            ireq_tdata[55:48] = m_axi_rdata[15:8];
            ireq_tdata[63:56] = m_axi_rdata[7:0];
        end
        else if(cstate == DOORBELL) begin
            ireq_tvalid = 1'b1;
            ireq_tdata = {8'h10, DOORB, 1'b0, pri, CRF, 12'b0, db_info, 16'b0};
        end
    end

// end of ireq signals

// iresp signals
    assign is_swdb_response = (s_axis_iresp_tdata[63:48] == 16'h10D0)? 1'b1: 1'b0;
    assign s_axis_iresp_tready = iresp_tready;
    assign swrite_finish = iresp_tready;

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            iresp_tready <= 1'b0;
        end
        else begin
            if(!iresp_tready && s_axis_iresp_tvalid && is_swdb_response) begin
                iresp_tready <= 1'b1;
            end
            else begin
                iresp_tready <= 1'b0;
            end
        end
    end
// end of iresp signals

// irq
    assign swrite_irq = (|irq_cnt)? 1'b1: 1'b0;
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            irq_cnt <= 2'b0;
        end
        else begin
            if(iresp_tready || irq_cnt) begin
                irq_cnt <= irq_cnt + 2'b1;
            end
        end
    end
// end of irq
endmodule
