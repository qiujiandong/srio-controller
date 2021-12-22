`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/07 19:36:37
// Design Name: 
// Module Name: doorbell_engine
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


module doorbell_engine(
    input aclk,
    input aresetn,

    input doorbell_start,
    input [15:0] doorbell_info,
    output doorbell_finish,

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
    input s_axis_iresp_tlast
// end of iresp signals
    );

    localparam [1:0] pri = 2'b01;
    localparam [0:0] CRF = 1'b0;
    localparam [7:0] DOORB = 8'hA0;
    localparam [7:0] RESP_NODATA = 8'hD0;

    reg ireq_tvalid;
    reg [63:0] ireq_tdata;
    reg ireq_tlast;
    reg iresp_tready;

    (* mark_debug = "true" *) reg [15:0] src_tid_free;
    (* mark_debug = "true" *) reg [3:0] src_tid;

    wire handshake_ireq;
    wire handshake_iresp;

    (* mark_debug = "true" *) wire is_db_response;
    wire [3:0] resp_src_tid;
    reg finish;
    reg finish_q;


    assign m_axis_ireq_tvalid = ireq_tvalid;
    assign m_axis_ireq_tdata = ireq_tdata;
    assign m_axis_ireq_tlast = ireq_tlast;
    assign s_axis_iresp_tready = iresp_tready;
    
    assign handshake_ireq = m_axis_ireq_tvalid & m_axis_ireq_tready;
    assign handshake_iresp = s_axis_iresp_tvalid & s_axis_iresp_tready;

    assign is_db_response = (s_axis_iresp_tdata[55:48] == RESP_NODATA && s_axis_iresp_tdata[63:60] == 4'b0)? 1'b1:1'b0;

    assign resp_src_tid = s_axis_iresp_tdata[59:56];
    assign doorbell_finish = ({finish,finish_q} == 2'b10)? 1'b1:1'b0;

    always @(*) begin
        if(|src_tid_free) begin 
            finish = m_axis_ireq_tvalid;
        end
        else begin
            finish = ~(|src_tid_free);
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin 
            finish_q <= 1'b0;
        end
        else begin 
            finish_q <= finish;
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin 
            src_tid_free <= 16'hFFFF;
        end
        else begin 
            if(handshake_ireq) begin
                src_tid_free[src_tid] <= 1'b0;
            end
            if(handshake_iresp && is_db_response) begin 
                src_tid_free[resp_src_tid] <= 1'b1;
            end
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin 
            src_tid <= 8'b0;
        end
        else if(handshake_ireq) begin
            src_tid <= src_tid + 8'b1;
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin 
            ireq_tvalid <= 1'b0;
            ireq_tlast <= 1'b0;
            ireq_tdata <= 'b0;
        end
        else begin
            if(doorbell_start && src_tid_free[src_tid]) begin 
                ireq_tvalid <= 1'b1;
                ireq_tlast <= 1'b1;
                ireq_tdata <= {4'b0, src_tid, DOORB, 1'b0, pri, CRF, 12'b0, doorbell_info, 16'b0};
            end
            else if(handshake_ireq) begin 
                ireq_tvalid <= 1'b0;
                ireq_tlast <= 1'b0;
                ireq_tdata <= 'b0;
            end
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin 
            iresp_tready <= 1'b0;
        end
        else begin
            if(!iresp_tready && s_axis_iresp_tvalid && is_db_response) begin
                iresp_tready <= 1'b1;
            end
            else begin
                iresp_tready <= 1'b0;
            end
        end
    end

endmodule
