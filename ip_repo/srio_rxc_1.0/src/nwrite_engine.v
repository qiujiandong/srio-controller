`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/02 21:27:47
// Design Name: 
// Module Name: nwrite_engine
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


module nwrite_engine(
    input aclk,
    input aresetn,

// treq signals
    input s_axis_treq_tvalid,
    (* mark_debug = "true" *) output s_axis_treq_tready,
    input [63:0] s_axis_treq_tdata,
    input [7:0] s_axis_treq_tkeep,
    input s_axis_treq_tlast,
    input [31:0] s_axis_treq_tuser,
// end of treq signals

//  interface
    (* mark_debug = "true" *) output [31 : 0] m_axi_awaddr,
    (* mark_debug = "true" *) output m_axi_awvalid,
    (* mark_debug = "true" *) input m_axi_awready,
    (* mark_debug = "true" *) output [7:0] m_axi_awlen,

    (* mark_debug = "true" *) output [63 : 0] m_axi_wdata,
    (* mark_debug = "true" *) output m_axi_wlast,
    (* mark_debug = "true" *) output m_axi_wvalid,
    (* mark_debug = "true" *) input m_axi_wready
// end axi master interface
    );

// user defined signals

    (* mark_debug = "true" *) wire is_nwrite;
    (* mark_debug = "true" *) wire nwrite_valid;
    (* mark_debug = "true" *) wire nwrite_en;
    (* mark_debug = "true" *) wire nwrite_busy;

    (* mark_debug = "true" *) wire [31:0] first_byte_addr;
    (* mark_debug = "true" *) wire [7:0] nwrite_size;

    wire handshake_treq;
    reg treq_tready;
    reg data_mask;

    wire [31:0] last_byte_addr;
    wire is_cross_boundary;
    wire [31:0] boundary;
    reg [1:0] num_transaction;
    reg [7:0] num_bytes[0:2];

    (* mark_debug = "true" *) reg [1:0] num_transaction_q;
    (* mark_debug = "true" *) reg [7:0] awlen[0:2];

    reg [31:0] maxi_awaddr;
    reg maxi_awvalid;
    reg [7:0] maxi_awlen;
    
    reg [63:0] maxi_wdata;
    reg maxi_wlast;
    wire handshake_maxi_aw;
    wire handshake_maxi_w;
    (* mark_debug = "true" *) wire last_wtransfer;
    (* mark_debug = "true" *) wire last_wtransfer_inner;

    (* mark_debug = "true" *) reg [1:0] cnt_transaction;
    (* mark_debug = "true" *) reg [7:0] cnt_beat;


// end of user defined signals

    assign handshake_treq = s_axis_treq_tvalid & s_axis_treq_tready;

    assign is_nwrite = (s_axis_treq_tdata[55:48] == 8'h54)? 1'b1:1'b0;
    assign nwrite_busy = data_mask;
    assign nwrite_valid = s_axis_treq_tvalid & is_nwrite & ~nwrite_busy;
    assign nwrite_en = treq_tready & nwrite_valid;
    
    assign m_axi_awaddr = maxi_awaddr;
    assign m_axi_awvalid = maxi_awvalid;
    assign m_axi_awlen = maxi_awlen;
    assign m_axi_wdata = maxi_wdata;
    assign m_axi_wlast = maxi_wlast;
    assign handshake_maxi_aw = m_axi_awvalid & m_axi_awready;
    assign handshake_maxi_w = m_axi_wvalid & m_axi_wready;
    assign last_wtransfer = m_axi_wlast & handshake_maxi_w;
    assign last_wtransfer_inner = last_wtransfer & (cnt_transaction != num_transaction_q);

// s_axis_treq_tready & m_axi_wvalid
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            treq_tready <= 1'b0;
        end
        else if(~treq_tready && nwrite_valid) begin
            treq_tready <= 1'b1;
        end
        else if(treq_tready && nwrite_valid) begin
            treq_tready <= 1'b0;
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            data_mask <= 1'b0;
        end
        else if(nwrite_en) begin
            data_mask <= 1'b1;
        end
        else if(s_axis_treq_tlast && handshake_treq) begin
            data_mask <= 1'b0;
        end
    end
    assign s_axis_treq_tready = (m_axi_wready & data_mask) | treq_tready;
    assign m_axi_wvalid = data_mask & s_axis_treq_tvalid;
// end of s_axis_treq_tready & m_axi_wvalid

// inner signals for determine pack organization
    assign nwrite_size = s_axis_treq_tdata[43:36]; // size - 1
    assign nwrite_busy = data_mask;
    assign first_byte_addr = s_axis_treq_tdata[31:0];
    assign last_byte_addr = first_byte_addr + nwrite_size;
    assign boundary = {last_byte_addr[31:12], 12'h0000};
    assign is_cross_boundary = (first_byte_addr[31:12] != last_byte_addr[31:12])? 1'b1:1'b0;

    always @(*) begin
        if(is_cross_boundary) begin
            // 3 times 
            if(boundary - first_byte_addr > 128 || last_byte_addr - boundary > 128) begin
                num_transaction = 2'b10;
                if(boundary - first_byte_addr > 128) begin
                    num_bytes[0] = 8'd127;
                    num_bytes[1] = boundary - first_byte_addr - 8'd129;
                    num_bytes[2] = last_byte_addr - boundary;
                end
                else begin
                    num_bytes[0] = boundary - first_byte_addr - 8'b1;
                    num_bytes[1] = 8'd127;
                    num_bytes[2] = last_byte_addr - boundary - 8'd128;
                end
            end
            // 2 times 
            else begin
                num_transaction = 2'b01;
                num_bytes[0] = boundary - first_byte_addr - 8'b1;
                num_bytes[1] = last_byte_addr - boundary;
                num_bytes[2] = 8'b0;
            end
        end
        // 1 or 2 times 
        else begin
            num_transaction = (nwrite_size>>7);
            num_bytes[0] = (nwrite_size>>7)? 8'd127: nwrite_size;
            num_bytes[1] = (nwrite_size>>7)? (nwrite_size - 8'd128): 8'b0;
            num_bytes[2] = 8'b0; 
        end
    end
// end of inner signals for determine pack organization

// num_transaction_q & awlen
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            num_transaction_q <= 2'b0;
            awlen[0] <= 8'b0;
            awlen[1] <= 8'b0;
            awlen[2] <= 8'b0;
        end
        else if(nwrite_en) begin
            num_transaction_q <= num_transaction;
            awlen[0] <= num_bytes[0] >> 3;
            awlen[1] <= num_bytes[1] >> 3;
            awlen[2] <= num_bytes[2] >> 3;
        end
    end
// end of num_transaction_q & awlen


// maxi_awaddr;
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            maxi_awaddr <= 'b0;
        end
        else begin
            if(nwrite_en) begin
                maxi_awaddr <= first_byte_addr;
            end
            else if(last_wtransfer_inner) begin
                maxi_awaddr <= maxi_awaddr + ((maxi_awlen+8'b1) << 3);
            end
        end
    end
// end of maxi_awaddr

// maxi_awvalid;
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            maxi_awvalid <= 1'b0;
        end
        else begin
            if(~maxi_awvalid && (nwrite_en || last_wtransfer_inner)) begin
                maxi_awvalid <= 1'b1;
            end
            else if(handshake_maxi_aw) begin
                maxi_awvalid <= 1'b0;
            end
        end
    end
// end of maxi_awvalid

// maxi_awlen;
    always @(*) begin
        case (cnt_transaction)
            2'b00: begin
                maxi_awlen = awlen[0];
            end 
            2'b01: begin
                maxi_awlen = awlen[1];
            end
            2'b10: begin
                maxi_awlen = awlen[2];
            end
        endcase
    end
// end of maxi_awlen

// maxi_wdata
    always @(*) begin
        if(data_mask) begin
            maxi_wdata[7:0] = s_axis_treq_tdata[63:56];
            maxi_wdata[15:8] = s_axis_treq_tdata[55:48];
            maxi_wdata[23:16] = s_axis_treq_tdata[47:40];
            maxi_wdata[31:24] = s_axis_treq_tdata[39:32];
            maxi_wdata[39:32] = s_axis_treq_tdata[31:24];
            maxi_wdata[47:40] = s_axis_treq_tdata[23:16];
            maxi_wdata[55:48] = s_axis_treq_tdata[15:8];
            maxi_wdata[63:56] = s_axis_treq_tdata[7:0];
        end
        else begin
            maxi_wdata = 'b0;
        end
    end
// end of maxi_wdata

// maxi_wlast
    always @(*) begin
        if(m_axi_wvalid && (cnt_beat == maxi_awlen)) begin
            maxi_wlast = 1'b1;
        end
        else begin
            maxi_wlast = 1'b0;
        end
    end
// end of maxi_wlast

// cnt_transaction
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            cnt_transaction <= 2'b0;
        end
        else begin
            if(last_wtransfer_inner) begin
                cnt_transaction <= cnt_transaction + 2'b01;
            end
            else if(nwrite_en) begin
                cnt_transaction <= 2'b0;
            end
        end
    end
// end of cnt_transaction

// cnt_beat
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            cnt_beat <= 8'b0;
        end
        else begin
            if(handshake_maxi_w && (cnt_beat != maxi_awlen)) begin
                cnt_beat <= cnt_beat + 8'b1;
            end
            else if(handshake_maxi_w && (cnt_beat == maxi_awlen)) begin
                cnt_beat <= 8'b0;
            end
        end
    end
// end of cnt_beat



endmodule
