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
    // real size is size_dw + 1
    input [15:0] size_dw,
    input [15:0] doorbell_info,
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
    (* mark_debug = "true" *) output [31 : 0] m_axi_awaddr,
    (* mark_debug = "true" *) output [7 : 0] m_axi_awlen,
    (* mark_debug = "true" *) output m_axi_awvalid,
    (* mark_debug = "true" *) input m_axi_awready,

    (* mark_debug = "true" *) output [63 : 0] m_axi_wdata,
    (* mark_debug = "true" *) output m_axi_wlast,
    (* mark_debug = "true" *) output m_axi_wvalid,
    (* mark_debug = "true" *) input m_axi_wready
// end of m_axi
    );

    localparam [2:0] IDLE = 3'b000;
    localparam [2:0] HEAD = 3'b001;
    localparam [2:0] WAIT = 3'b010;
    localparam [2:0] DATA = 3'b011;
    localparam [2:0] DOORBELL = 3'b100;

    localparam [7:0] NREAD = 8'h24;
    localparam [1:0] pri = 2'b01;
    localparam [0:0] CRF = 1'b0;
    localparam [7:0] DOORB = 8'hA0;

    (* mark_debug = "true" *) reg [2:0] cstate;
    (* mark_debug = "true" *) reg [2:0] nstate;

    (* mark_debug = "true" *) reg [11:0] write_slice;
    (* mark_debug = "true" *) reg [10:0] nread_slice;
    (* mark_debug = "true" *) reg [15:0] db_info;
    (* mark_debug = "true" *) reg [3:0] write_beats_tail;
    (* mark_debug = "true" *) reg [4:0] nread_beats_tail;

    wire handshake_iresp;
    wire handshake_ireq;
    wire handshake_aw;
    wire handshake_w;

    (* mark_debug = "true" *) reg [11:0] write_cnt;
    (* mark_debug = "true" *) reg [10:0] nread_cnt;
    (* mark_debug = "true" *) reg [3:0] write_beats_cnt;
    (* mark_debug = "true" *) reg [4:0] nread_beats_cnt;

    reg [31:0] axi_awaddr;
    reg [7:0] axi_awlen;
    reg axi_awvalid;
    reg [63 : 0] axi_wdata;
    reg axi_wlast;
    reg axi_wvalid;

    (* mark_debug = "true" *) reg ireq_tvalid;
    (* mark_debug = "true" *) reg [63:0] ireq_tdata;
    (* mark_debug = "true" *) reg ireq_tlast;

    wire is_nrdb_response;
    wire is_nr_response;
    reg iresp_tready;

    reg [1:0] irq_cnt;
    

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin 
            write_slice <= 'b0;
            nread_slice <= 'b0;
            db_info <= 'b0;
            write_beats_tail <= 'b0;
            nread_beats_tail <= 'b0;
        end
        else if(nread_start) begin 
            write_slice <= size_dw >> 4; // max burst len is 16, slice read data into slices
            nread_slice <= size_dw >> 5; // nread max is 256 bytes every package
            db_info <= doorbell_info;
            write_beats_tail <= size_dw[3:0];
            nread_beats_tail <= size_dw[4:0];
        end
    end

    // handshake
    assign handshake_iresp = s_axis_iresp_tvalid && s_axis_iresp_tready;
    assign handshake_ireq = m_axis_ireq_tvalid && m_axis_ireq_tready;
    assign handshake_aw = m_axi_awvalid && m_axi_awready;
    assign handshake_w = m_axi_wvalid && m_axi_wready;
    // end of handshake

    // cnts
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin 
            write_cnt <= 'b0;
        end
        else begin
            if(handshake_aw) begin
                if(write_cnt < write_slice) begin
                    write_cnt <= write_cnt + 12'b1;
                end
                else begin
                    write_cnt <= 'b0;
                end
            end
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            nread_cnt <= 'b0;
        end
        else begin
            if(cstate == DATA && s_axis_iresp_tlast && handshake_iresp) begin
                if(nread_cnt < nread_slice ) begin
                    nread_cnt <= nread_cnt + 11'b1;
                end
                else if(nread_cnt == nread_slice) begin
                    nread_cnt <= 'b0;
                end
            end
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            write_beats_cnt <= 'b0;
        end
        else begin
            if(handshake_w && cstate == DATA) begin 
                if(write_cnt < write_slice) begin
                    if(write_beats_cnt < 4'd15) begin
                        write_beats_cnt <= write_beats_cnt + 5'b1;
                    end
                    else begin
                        write_beats_cnt <= 'b0;
                    end
                end
                else begin
                    if(write_beats_cnt < write_beats_tail) begin
                        write_beats_cnt <= write_beats_cnt + 5'b1;
                    end
                    else begin
                        write_beats_cnt <= 'b0;
                    end
                end
            end
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            nread_beats_cnt <= 'b0;
        end
        else begin
            if(handshake_iresp && cstate == DATA) begin 
                if(nread_cnt < nread_slice) begin
                    if(nread_beats_cnt < 5'd31) begin
                        nread_beats_cnt <= nread_beats_cnt + 5'b1;
                    end
                    else begin
                        nread_beats_cnt <= 'b0;
                    end
                end
                else begin
                    if(nread_beats_cnt < nread_beats_tail) begin
                        nread_beats_cnt <= nread_beats_cnt + 5'b1;
                    end
                    else begin
                        nread_beats_cnt <= 'b0;
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
                if(nread_start) begin
                    nstate = HEAD;
                end
            HEAD:
                if(handshake_ireq) begin
                    nstate = WAIT;
                end
            WAIT:
                if(handshake_iresp) begin
                    nstate = DATA;
                end
            DATA:
                if(s_axis_iresp_tlast && handshake_iresp) begin
                    if(nread_cnt < nread_slice) begin
                        nstate = HEAD;
                    end
                    else if(nread_cnt == nread_slice) begin
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
    assign m_axi_awaddr = axi_awaddr;
    assign m_axi_awlen = axi_awlen;
    assign m_axi_awvalid = axi_awvalid;

    assign m_axi_wdata = axi_wdata;
    assign m_axi_wlast = axi_wlast;
    assign m_axi_wvalid = axi_wvalid;

    // axi_awaddr and axi_awlen
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            axi_awaddr <= 'b0;
            axi_awlen <= 'b0;
        end
        else begin
            if(nread_start) begin
                axi_awaddr <= dstAddr;
                if(write_cnt < write_slice) begin
                    axi_awlen <= 8'h0F;
                end
                else begin
                    axi_awlen <= {4'b0, size_dw[3:0]};
                end
            end
            else if(handshake_aw && write_cnt < write_slice) begin
                axi_awaddr <= axi_awaddr + ((axi_awlen + 8'b1)<<3);
                if(write_cnt == write_slice - 12'b1) begin
                    axi_awlen <= {4'b0, write_beats_tail};
                end
                else begin
                    axi_awlen <= 8'h0F;
                end
            end
            else if(handshake_aw && write_cnt == write_slice) begin
                axi_awlen <= 'b0;
                axi_awaddr <= 'b0;
            end
        end
    end

    // axi_awvalid
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            axi_awvalid <= 1'b0;
        end
        else begin
            if(nread_start) begin
                axi_awvalid <= 1'b1;
            end
            else if(write_cnt == write_slice && handshake_aw) begin 
                axi_awvalid <= 1'b0;
            end
        end
    end

    // axi_wvalid, axi_wdata and axi_wlast
    always @(*) begin
        axi_wvalid = 1'b0;
        axi_wdata = 'b0;
        axi_wlast = 1'b0;
        if(cstate == DATA) begin
            axi_wvalid = s_axis_iresp_tvalid;
            axi_wdata[7:0]   = s_axis_iresp_tdata[63:56];
            axi_wdata[15:8]  = s_axis_iresp_tdata[55:48];
            axi_wdata[23:16] = s_axis_iresp_tdata[47:40];
            axi_wdata[31:24] = s_axis_iresp_tdata[39:32];
            axi_wdata[39:32] = s_axis_iresp_tdata[31:24];
            axi_wdata[47:40] = s_axis_iresp_tdata[23:16];
            axi_wdata[55:48] = s_axis_iresp_tdata[15:8];
            axi_wdata[63:56] = s_axis_iresp_tdata[7:0];
            if(write_cnt < write_slice) begin
                if(write_beats_cnt == 4'd15) begin
                    axi_wlast = 1'b1;
                end
            end
            else begin
                if(write_beats_cnt == write_beats_tail) begin
                    axi_wlast = 1'b1;
                end
            end
        end
    end

// end of m_axi_signals

// ireq signals
    assign m_axis_ireq_tvalid = ireq_tvalid;
    assign m_axis_ireq_tdata = ireq_tdata;
    assign m_axis_ireq_tlast = ireq_tlast;

    always @(*) begin
        ireq_tlast = 1'b0;
        if(cstate == DOORBELL || cstate == HEAD) begin
            ireq_tlast = 1'b1;
        end
    end

    reg [31:0] ireq_addr;
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            ireq_addr <= 'b0;
        end
        else begin
            if(nread_start) begin
                ireq_addr <= srcAddr;
            end
            else if(cstate == HEAD && nstate == WAIT) begin
                if(nread_cnt < nread_slice) begin
                    ireq_addr = ireq_addr + 32'd256;
                end
            end
        end
    end

    reg [7:0] srcTID;
    always @(posedge aclk or posedge aresetn) begin
        if(!aresetn) begin
            srcTID <= 8'b0;
        end
        else if (handshake_ireq && ireq_tlast && (cstate == HEAD || cstate == DOORBELL)) begin
            srcTID[6:0] <= srcTID[6:0] + 7'b1;
        end
    end

    always @(*) begin
        ireq_tvalid = 1'b0;
        ireq_tdata = 'b0;
        if(cstate == HEAD) begin
            ireq_tvalid = 1'b1;
            if(nread_cnt == nread_slice) begin
                ireq_tdata = {srcTID, NREAD, 1'b0, pri, CRF, {nread_beats_tail, 3'b111}, 4'b0, ireq_addr};
            end
            else begin
                ireq_tdata = {srcTID, NREAD, 1'b0, pri, CRF, 8'd255, 4'b0, ireq_addr};
            end
        end
        else if(cstate == DOORBELL) begin
            ireq_tvalid = 1'b1;
            ireq_tdata = {8'h80, DOORB, 1'b0, pri, CRF, 12'b0, db_info, 16'b0};
        end
    end

// end of ireq signals

// iresp signals
    reg iresp_tready_q;
    assign is_nrdb_response = (s_axis_iresp_tdata == 64'h80d0_4000_0000_0000)? 1'b1: 1'b0;
    assign is_nr_response = (s_axis_iresp_tdata[55:48] == 8'hD8)? 1'b1: 1'b0;
    assign s_axis_iresp_tready = iresp_tready;
    assign nread_finish = is_nrdb_response & handshake_iresp;

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            iresp_tready_q <= 1'b0;
        end
        else begin
            if(cstate == WAIT && s_axis_iresp_tvalid && is_nr_response) begin
                iresp_tready_q = m_axi_wready;
            end
            else if(!iresp_tready && s_axis_iresp_tvalid && is_nrdb_response) begin
                iresp_tready_q <= 1'b1;
            end
            else begin
                iresp_tready_q <= 1'b0;
            end
        end
    end

    always @(*) begin
        iresp_tready = 1'b0;
        if(cstate == DATA) begin
            iresp_tready = m_axi_wready;
        end
        else begin
            iresp_tready = iresp_tready_q;
        end
    end
// end of iresp signals

// irq
    assign nread_irq = (|irq_cnt)? 1'b1: 1'b0;
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            irq_cnt <= 2'b0;
        end
        else begin
            if((is_nrdb_response & handshake_iresp) || irq_cnt) begin
                irq_cnt <= irq_cnt + 2'b1;
            end
        end
    end
// end of irq

endmodule
