`timescale 1ns / 1ps
`include "common.sv"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/15 15:50:49
// Design Name: 
// Module Name: srio_trc_tb
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


module srio_trc_tb#(
    parameter [0:0] TX_ONLY = 1'b1,
    parameter [15:0] C_DEV_ID = 16'hF201,
    parameter [15:0] C_DEST_ID = 16'h7801,
    parameter AXIL_DW = 32,
    parameter AXIL_AW = 4
    );

    import SimSrcGen::*;
    logic aclk;
    initial GenClk(aclk, 1, 6.4);
    logic aresetn;
    initial GenArst(aclk, aresetn, 2, 3);

    logic [31:0] cnt;

    always_ff @( posedge aclk or negedge aresetn ) begin
        if(!aresetn) begin
            cnt <= 'b0;
        end
        else begin
            cnt <= cnt + 'b1;
        end
    end

    logic nread_irq;
    logic swrite_irq;

// ireq
    logic m_axis_ireq_tvalid;
    logic m_axis_ireq_tready;
    logic [63:0] m_axis_ireq_tdata;
    logic [7:0] m_axis_ireq_tkeep;
    logic m_axis_ireq_tlast;
    logic [31:0] m_axis_ireq_tuser;
// end of ireq

    // logic m_axis_ireq_tready;
    assign m_axis_ireq_tready = 1'b1;

// iresp
    logic s_axis_iresp_tvalid;
    logic s_axis_iresp_tready;
    logic [63:0] s_axis_iresp_tdata;
    logic [7:0] s_axis_iresp_tkeep;
    logic s_axis_iresp_tlast;
    logic [31:0] s_axis_iresp_tuser;
// end of iresp

    // logic s_axis_iresp_tvalid;
    // logic [63:0] s_axis_iresp_tdata;
    // logic [7:0] s_axis_iresp_tkeep;
    // logic s_axis_iresp_tlast;
    // logic [31:0] s_axis_iresp_tuser;
    // assign s_axis_iresp_tvalid = 1'b0;
    // assign s_axis_iresp_tdata = 'b0;
    // assign s_axis_iresp_tlast = 1'b0;
    // assign s_axis_iresp_tkeep = 'b0;
    // assign s_axis_iresp_tuser = 'b0;
    always_ff @( posedge aclk or negedge aresetn ) begin : iresp
        if(!aresetn) begin
            s_axis_iresp_tvalid <= 1'b0;
            s_axis_iresp_tdata <= 'b0;
            s_axis_iresp_tlast <= 1'b0;
            s_axis_iresp_tkeep <= 'b0;
            s_axis_iresp_tuser <= 'b0;
        end
        else begin 
            if(cnt == 32'd20) begin
                s_axis_iresp_tvalid <= 1'b1;
                s_axis_iresp_tdata <= {8'b0, 8'hd0, 1'b0, 2'b10, 1'b0, 44'b0};
                s_axis_iresp_tlast <= 1'b1;
                s_axis_iresp_tkeep <= 8'hFF;
                s_axis_iresp_tuser <= {C_DEST_ID, C_DEV_ID};
            end
            else if(s_axis_iresp_tvalid && s_axis_iresp_tready)begin
                s_axis_iresp_tvalid <= 1'b0;
                s_axis_iresp_tdata <= 'b0;
                s_axis_iresp_tlast <= 1'b0;
                s_axis_iresp_tkeep <= 'b0;
                s_axis_iresp_tuser <= 'b0;
            end
        end
    end


// axi_lite
    logic [AXIL_AW-1:0] s_axil_awaddr;
    logic [2:0] s_axil_awprot;
    logic s_axil_awvalid;
    logic s_axil_awready;

    logic [AXIL_DW-1:0] s_axil_wdata;
    logic [3:0] s_axil_wstrb;
    logic s_axil_wvalid;
    logic s_axil_wready;

    logic [1:0] s_axil_bresp;
    logic s_axil_bvalid;
    logic s_axil_bready;

    logic [AXIL_AW-1:0] s_axil_araddr;
    logic [2:0] s_axil_arprot;
    logic s_axil_arvalid;
    logic s_axil_arready;

    logic [AXIL_DW-1:0] s_axil_rdata;
    logic [1:0] s_axil_rresp;
    logic s_axil_rvalid;
    logic s_axil_rready;
// end of axi_lite

    // logic [AXIL_AW-1:0] s_axil_awaddr;
    // logic [2:0] s_axil_awprot;
    // logic s_axil_awvalid;
    // logic [AXIL_DW-1:0] s_axil_wdata;
    // logic [3:0] s_axil_wstrb;
    // logic s_axil_wvalid;
    // logic s_axil_bready;
    // logic [AXIL_AW-1:0] s_axil_araddr;
    // logic [2:0] s_axil_arprot;
    // logic s_axil_arvalid;
    // logic s_axil_rready;
    logic handshake_aw;
    logic handshake_w;

    assign handshake_aw = s_axil_awvalid && s_axil_awready;
    assign handshake_w = s_axil_wvalid && s_axil_wready;

    assign s_axil_awprot = 'b0;
    // assign s_axil_awvalid = 'b0;
    // assign s_axil_wdata = 'b1;
    assign s_axil_wstrb = 8'hFF;
    // assign s_axil_wvalid = 'b0;
    assign s_axil_bready = 1'b1;
    assign s_axil_araddr = 'b0;
    assign s_axil_arprot = 'b0;
    assign s_axil_arvalid = 'b0;
    assign s_axil_rready = 1'b1;

    // always_ff @( posedge aclk or negedge aresetn ) begin : doorbell_test
    //     if(!aresetn) begin
    //         s_axil_awvalid <= 1'b0;
    //         s_axil_wvalid <= 1'b0;
    //         s_axil_wdata <= 'b1;
    //         s_axil_awaddr = 'b0;
    //     end
    //     else begin
    //         if(cnt%10 == 'b1) begin
    //             s_axil_awvalid <= 1'b1;
    //             s_axil_wvalid <= 1'b1;
    //         end
    //         if(s_axil_awvalid && s_axil_awready) begin
    //             s_axil_awvalid <= 1'b0;
    //         end
    //         if(s_axil_wvalid && s_axil_wready) begin
    //             s_axil_wvalid <= 1'b0;
    //         end
    //     end
    // end

    always_ff @( posedge aclk or negedge aresetn ) begin : swrite_test
        if(!aresetn) begin
            s_axil_awvalid <= 1'b0;
            s_axil_wvalid <= 1'b0;
            s_axil_wdata <= 'b0;
            s_axil_awaddr = 'b0;
        end
        else begin
            if(cnt == 10) begin
                s_axil_awvalid <= 1'b1;
                s_axil_wvalid <= 1'b1;
                s_axil_wdata <= 32'h8000_0000;
                s_axil_awaddr <= 4'h4;
            end
            if(cnt == 20) begin
                s_axil_awvalid <= 1'b1;
                s_axil_wvalid <= 1'b1;
                s_axil_wdata <= 32'h0C00_0000;
                s_axil_awaddr <= 4'h8;
            end
            if(cnt == 30) begin
                s_axil_awvalid <= 1'b1;
                s_axil_wvalid <= 1'b1;
                s_axil_wdata <= 32'h5555_BFFF;
                s_axil_awaddr <= 4'hC;
            end
            if(cnt == 40) begin
                s_axil_awvalid <= 1'b1;
                s_axil_wvalid <= 1'b1;
                s_axil_wdata <= 32'h0000_0002;
                s_axil_awaddr <= 4'h0;
            end
            if(handshake_w) begin
                s_axil_wvalid <= 1'b0;
            end
            if(handshake_aw) begin
                s_axil_awvalid <= 1'b0;
            end
        end
    end

// m_axi
    logic [2 : 0] m_axi_awsize;
    logic [1 : 0] m_axi_awburst;
    logic m_axi_awlock;
    logic [3 : 0] m_axi_awcache;
    logic [2 : 0] m_axi_awprot;
    logic [3 : 0] m_axi_awqos;
    logic [7 : 0] m_axi_wstrb;
    logic [2 : 0] m_axi_arsize;
    logic [1 : 0] m_axi_arburst;
    logic m_axi_arlock;
    logic [3 : 0] m_axi_arcache;
    logic [2 : 0] m_axi_arprot;
    logic [3 : 0] m_axi_arqos;
    logic m_axi_bready;
    logic [1 : 0] m_axi_rresp;
    logic [1 : 0] m_axi_bresp;
    logic m_axi_bvalid;

    logic [31 : 0] m_axi_awaddr;
    logic [7 : 0] m_axi_awlen;
    logic m_axi_awvalid;
    logic m_axi_awready;

    logic [63 : 0] m_axi_wdata;
    logic m_axi_wlast;
    logic m_axi_wvalid;
    logic m_axi_wready;

    logic [31 : 0] m_axi_araddr;
    logic [7 : 0] m_axi_arlen;
    logic m_axi_arvalid;
    logic m_axi_arready;

    logic [63 : 0] m_axi_rdata;
    logic m_axi_rlast;
    logic m_axi_rvalid;
    logic m_axi_rready;
// end of m_axi
    // logic [1 : 0] m_axi_rresp;
    // logic [1 : 0] m_axi_bresp;
    // logic m_axi_bvalid;
    // logic m_axi_awready;
    // logic m_axi_wready;
    // logic m_axi_arready;
    // logic [63 : 0] m_axi_rdata;
    // logic m_axi_rlast;
    // logic m_axi_rvalid;
    logic handshake_maxi_ar;
    logic handshake_maxi_r;
    logic [3:0] r_cnt;
    logic [7:0] arlen;

    assign handshake_maxi_ar = m_axi_arvalid & m_axi_arready;
    assign handshake_maxi_r = m_axi_rvalid & m_axi_rready;

    assign m_axi_rresp = 'b0;
    assign m_axi_bresp = 'b0;
    assign m_axi_bvalid = 'b0;
    assign m_axi_awready = 'b0;
    assign m_axi_wready = 'b0;
    assign m_axi_rdata = 64'h5555_AAAA_5555_AAAA;

    // assign m_axi_arready = 'b0;
    // assign m_axi_rlast = 'b0;
    // assign m_axi_rvalid = 'b0;

    always_ff @( posedge aclk or negedge aresetn ) begin
        if(!aresetn) begin
            m_axi_arready <= 1'b0;
            m_axi_rvalid <= 1'b0;
            r_cnt <= 'b0;
        end
        else begin
            if(!m_axi_arready && m_axi_arvalid && !m_axi_rvalid) begin
                m_axi_arready <= 1'b1;
            end
            else begin
                m_axi_arready <= 1'b0;
            end

            if(handshake_maxi_ar) begin
                m_axi_rvalid <= 1'b1;
                arlen <= m_axi_arlen;
            end
            else if(handshake_maxi_r && m_axi_rlast) begin
                m_axi_rvalid <= 1'b0;
                arlen <= 'b0;
            end

            if(handshake_maxi_r) begin
                if(r_cnt < arlen) begin
                    r_cnt <= r_cnt + 'b1;
                end
                else begin
                    r_cnt <= 'b0;
                end
            end
        end
    end
    assign m_axi_rlast = (r_cnt == arlen && m_axi_rvalid)? 1'b1: 1'b0;

srio_trc #(
    .TX_ONLY   (TX_ONLY   ),
    .C_DEV_ID  (C_DEV_ID  ),
    .C_DEST_ID (C_DEST_ID ),
    .AXIL_DW   (AXIL_DW   ),
    .AXIL_AW   (AXIL_AW   )
)
srio_trc_inst(
    .aclk                (aclk                ),
    .aresetn             (aresetn             ),
    .nread_irq           (nread_irq           ),
    .swrite_irq          (swrite_irq          ),
    .m_axis_ireq_tvalid  (m_axis_ireq_tvalid  ),
    .m_axis_ireq_tready  (m_axis_ireq_tready  ),
    .m_axis_ireq_tdata   (m_axis_ireq_tdata   ),
    .m_axis_ireq_tkeep   (m_axis_ireq_tkeep   ),
    .m_axis_ireq_tlast   (m_axis_ireq_tlast   ),
    .m_axis_ireq_tuser   (m_axis_ireq_tuser   ),
    .s_axis_iresp_tvalid (s_axis_iresp_tvalid ),
    .s_axis_iresp_tready (s_axis_iresp_tready ),
    .s_axis_iresp_tdata  (s_axis_iresp_tdata  ),
    .s_axis_iresp_tkeep  (s_axis_iresp_tkeep  ),
    .s_axis_iresp_tlast  (s_axis_iresp_tlast  ),
    .s_axis_iresp_tuser  (s_axis_iresp_tuser  ),
    .s_axil_awaddr       (s_axil_awaddr       ),
    .s_axil_awprot       (s_axil_awprot       ),
    .s_axil_awvalid      (s_axil_awvalid      ),
    .s_axil_awready      (s_axil_awready      ),
    .s_axil_wdata        (s_axil_wdata        ),
    .s_axil_wstrb        (s_axil_wstrb        ),
    .s_axil_wvalid       (s_axil_wvalid       ),
    .s_axil_wready       (s_axil_wready       ),
    .s_axil_bresp        (s_axil_bresp        ),
    .s_axil_bvalid       (s_axil_bvalid       ),
    .s_axil_bready       (s_axil_bready       ),
    .s_axil_araddr       (s_axil_araddr       ),
    .s_axil_arprot       (s_axil_arprot       ),
    .s_axil_arvalid      (s_axil_arvalid      ),
    .s_axil_arready      (s_axil_arready      ),
    .s_axil_rdata        (s_axil_rdata        ),
    .s_axil_rresp        (s_axil_rresp        ),
    .s_axil_rvalid       (s_axil_rvalid       ),
    .s_axil_rready       (s_axil_rready       ),
    .m_axi_awsize        (m_axi_awsize        ),
    .m_axi_awburst       (m_axi_awburst       ),
    .m_axi_awlock        (m_axi_awlock        ),
    .m_axi_awcache       (m_axi_awcache       ),
    .m_axi_awprot        (m_axi_awprot        ),
    .m_axi_awqos         (m_axi_awqos         ),
    .m_axi_wstrb         (m_axi_wstrb         ),
    .m_axi_arsize        (m_axi_arsize        ),
    .m_axi_arburst       (m_axi_arburst       ),
    .m_axi_arlock        (m_axi_arlock        ),
    .m_axi_arcache       (m_axi_arcache       ),
    .m_axi_arprot        (m_axi_arprot        ),
    .m_axi_arqos         (m_axi_arqos         ),
    .m_axi_bready        (m_axi_bready        ),
    .m_axi_rresp         (m_axi_rresp         ),
    .m_axi_bresp         (m_axi_bresp         ),
    .m_axi_bvalid        (m_axi_bvalid        ),
    .m_axi_awaddr        (m_axi_awaddr        ),
    .m_axi_awlen         (m_axi_awlen         ),
    .m_axi_awvalid       (m_axi_awvalid       ),
    .m_axi_awready       (m_axi_awready       ),
    .m_axi_wdata         (m_axi_wdata         ),
    .m_axi_wlast         (m_axi_wlast         ),
    .m_axi_wvalid        (m_axi_wvalid        ),
    .m_axi_wready        (m_axi_wready        ),
    .m_axi_araddr        (m_axi_araddr        ),
    .m_axi_arlen         (m_axi_arlen         ),
    .m_axi_arvalid       (m_axi_arvalid       ),
    .m_axi_arready       (m_axi_arready       ),
    .m_axi_rdata         (m_axi_rdata         ),
    .m_axi_rlast         (m_axi_rlast         ),
    .m_axi_rvalid        (m_axi_rvalid        ),
    .m_axi_rready        (m_axi_rready        )
);

endmodule
