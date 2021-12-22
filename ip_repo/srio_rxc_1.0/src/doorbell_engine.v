`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/02 21:27:47
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


module doorbell_engine #(
    parameter DW = 32,
    parameter AW = 4,
    parameter [15:0] C_DEV_ID = 16'hF201,
    parameter [15:0] C_DEST_ID = 16'h7801
)(
    input aclk,
    input aresetn,

    input s_axis_treq_tvalid,
    (* mark_debug = "true" *) output s_axis_treq_tready,
    input [63:0] s_axis_treq_tdata,

    output doorbell_irq,

// tresp signals
    output m_axis_tresp_tvalid,
    input m_axis_tresp_tready,
    output [63:0] m_axis_tresp_tdata,
    output [7:0] m_axis_tresp_tkeep,
    output m_axis_tresp_tlast,
    output [31:0] m_axis_tresp_tuser,
// end of tresp signals

// AXI4-Lite control signals
    input [AW-1:0] s_axil_awaddr,
    input [2:0] s_axil_awprot,
    input s_axil_awvalid,
    output s_axil_awready,

    input [DW-1:0] s_axil_wdata,
    input [(DW/8-1):0] s_axil_wstrb,
    input s_axil_wvalid,
    output s_axil_wready,

    output [1:0] s_axil_bresp,
    output s_axil_bvalid,
    input s_axil_bready,

    input [AW-1:0] s_axil_araddr,
    input [2:0] s_axil_arprot,
    input s_axil_arvalid,
    output s_axil_arready,

    output [DW-1:0] s_axil_rdata,
    output [1:0] s_axil_rresp,
    output s_axil_rvalid,
    input s_axil_rready
// end of AXI4-Lite control signals
);
    localparam RESP = 4'd13;
    localparam NODATA = 4'd0;
    localparam prio = 2'b01; //priority
    localparam CRF = 1'b0; //critical request flow

// user defined signals
    // CSR[0]: Doorbell Interrupt Enable
    // CSR[31:16] Doorbell Info
    (* mark_debug = "true" *) reg [DW-1:0] CSR;

    // (* mark_debug = "true" *) reg [15:0] info_sr[0:1];
    (* mark_debug = "true" *) wire is_doorbell;
    (* mark_debug = "true" *) wire [15:0] doorbell_info;
    (* mark_debug = "true" *) wire [7:0] src_tid;
    (* mark_debug = "true" *) wire doorbell_valid;
    (* mark_debug = "true" *) wire doorbell_en;
    (* mark_debug = "true" *) wire doorbell_nack;
    (* mark_debug = "true" *) reg treq_tready;

    (* mark_debug = "true" *) wire rden;
    (* mark_debug = "true" *) wire wren;
    (* mark_debug = "true" *) wire handshake_rd;
    (* mark_debug = "true" *) reg aw_en;

    reg irq;
    reg [2:0] cnt;

    reg tresp_tvalid;
    reg [63:0] tresp_tdata;
    reg [7:0] tresp_tkeep;
    reg tresp_tlast;
    reg [31:0] tresp_tuser;
    wire handshake_tresp;

    reg axil_awready;
    reg axil_wready;
    reg [1:0] axil_bresp;
    reg axil_bvalid;
    reg axil_arready;
    reg [DW-1:0] axil_rdata;
    reg [1:0] axil_rresp;
    reg axil_rvalid;
    reg nack;

    wire [1:0] prio_req;
    wire [1:0] prio_resp;
// end of user defined signals

    assign s_axil_awready = axil_awready;
    assign s_axil_wready = axil_wready;
    assign s_axil_bresp = axil_bresp;
    assign s_axil_bvalid = axil_bvalid;
    assign s_axil_arready = axil_arready;
    assign s_axil_rdata = axil_rdata;
    assign s_axil_rresp = axil_rresp;
    assign s_axil_rvalid = axil_rvalid;

    assign m_axis_tresp_tvalid = tresp_tvalid;
    assign m_axis_tresp_tdata = tresp_tdata;
    assign m_axis_tresp_tkeep = tresp_tkeep;
    assign m_axis_tresp_tlast = tresp_tlast;
    assign m_axis_tresp_tuser = tresp_tuser;
    assign handshake_tresp = m_axis_tresp_tvalid & m_axis_tresp_tready;

    assign doorbell_nack = tresp_tvalid | nack;
    assign s_axis_treq_tready = (CSR[0])? (treq_tready & ~doorbell_nack & ~irq): treq_tready;
    assign is_doorbell = (s_axis_treq_tdata[55:48] == 8'hA0)? 1'b1:1'b0;
    assign doorbell_info = s_axis_treq_tdata[31:16];
    assign src_tid = s_axis_treq_tdata[63:56];
    assign doorbell_valid = s_axis_treq_tvalid & is_doorbell;
    assign doorbell_en = s_axis_treq_tready & doorbell_valid;

    assign prio_req = s_axis_treq_tdata[46:45];
    assign prio_resp = prio_req + 2'b1;

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            treq_tready <= 1'b0;
        end
        else if(~s_axis_treq_tready && doorbell_valid) begin
            treq_tready <= 1'b1;
        end
        else if(s_axis_treq_tready && doorbell_valid) begin
            treq_tready <= 1'b0;
        end
    end

    assign doorbell_irq = irq;
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn || (cnt == 3'b100)) begin
            cnt <= 3'b0;
            irq <= 1'b0;
        end
        else if((doorbell_en && CSR[0]) || irq) begin
            cnt <= cnt + 3'b1;
            irq <= 1'b1;
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            nack <= 1'b0;
        end
        else if(doorbell_en && CSR[0]) begin
            nack <= 1'b1;
        end
        else if(handshake_rd) begin
            nack <= 1'b0;
        end
    end

// awready
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            aw_en <= 1'b1;
            axil_awready <= 1'b0;
        end
        else begin
            if(~axil_awready && s_axil_awvalid && s_axil_wvalid && aw_en) begin
                axil_awready <= 1'b1;
                aw_en = 1'b0;
            end
            else if(s_axil_bready && axil_bvalid) begin
                aw_en <= 1'b1;
                axil_awready <= 1'b0;
            end
            else begin
                axil_awready <= 1'b0;
            end
        end
    end
// end of awready

// wready
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            axil_wready <= 1'b0;
        end
        else begin
            if(~axil_wready && s_axil_awvalid && s_axil_wvalid && aw_en) begin
                axil_wready <= 1'b1;
            end
            else begin
                axil_wready <= 1'b0;
            end
        end
    end
// end of wready

// write data to regs
    assign wren = axil_wready && s_axil_wvalid && axil_awready && s_axil_awvalid;

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            CSR <= 'b0;
        end
        else begin
            if(wren) begin
                CSR[0] <= s_axil_wdata[0];
            end
            
            if(doorbell_en && CSR[0]) begin
                CSR[31:16] <= doorbell_info;
            end
        end
    end
// end of write data to regs

// bvalid & bresp
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            axil_bvalid <= 'b0;
            axil_bresp <= 2'b00;
        end
        else begin
            if(~axil_bvalid && wren) begin
                axil_bvalid <= 1'b1;
            end
            else if(s_axil_bready && axil_bvalid) begin
                axil_bvalid <= 1'b0;
            end
        end
    end
// end of bvalid & bresp

// arready
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            axil_arready <= 'b0;
            // axil_araddr <= 'b0;
        end
        else begin
            if(~axil_arready && s_axil_arvalid) begin
                axil_arready <= 1'b1;
                // axil_araddr <= s_axil_araddr;
            end
            else begin
                axil_arready <= 1'b0;
            end
        end
    end
// end of arready

// rvalid & rresp
    assign handshake_rd = axil_rvalid && s_axil_rready;
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            axil_rvalid <= 'b0;
            axil_rresp <= 2'b00;
        end
        else begin
            if(~axil_rvalid && axil_arready && s_axil_arvalid) begin
                axil_rvalid <= 1'b1;
            end
            else if(handshake_rd) begin
                axil_rvalid <= 1'b0;
            end
        end
    end
// end of rvalid & rresp

// read data from regs
    assign rden = axil_arready & s_axil_arvalid & ~axil_rvalid;
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            axil_rdata <= 'b0;
        end
        else begin
            if(rden) begin
                axil_rdata <= CSR;
            end
        end
    end
// end of read data from regs

// doorbell response
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            tresp_tvalid <= 1'b0;
            tresp_tdata <= 64'b0;
            tresp_tkeep <= 8'b0;
            tresp_tlast <= 1'b0;
            tresp_tuser <= 32'b0;
        end
        else begin
            if(doorbell_en) begin
                tresp_tvalid <= 1'b1;
                tresp_tdata <= {src_tid, RESP, NODATA, 1'b0, prio_resp, CRF, 44'b0 };
                tresp_tkeep <= 8'hFF;
                tresp_tlast <= 1'b1;
                tresp_tuser <= {C_DEV_ID, C_DEST_ID};
            end
            else if(handshake_tresp) begin
                tresp_tvalid <= 1'b0;
                tresp_tdata <= 64'b0;
                tresp_tkeep <= 8'b0;
                tresp_tlast <= 1'b0;
                tresp_tuser <= 32'b0;
            end
        end
    end
// end of doorbell response

endmodule
