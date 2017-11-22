
`timescale 1 ns / 1 ps

	module AXI_LC_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S_AXI
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_ADDR_WIDTH	= 5,

		// Parameters of Axi Master Bus Interface M_AXI
		parameter  C_M_AXI_START_DATA_VALUE	= 32'hAA000000,
		parameter  C_M_AXI_TARGET_SLAVE_BASE_ADDR	= 32'h40000000,
		parameter integer C_M_AXI_ADDR_WIDTH	= 32,
		parameter integer C_M_AXI_DATA_WIDTH	= 32,
		parameter integer C_M_AXI_TRANSACTIONS_NUM	= 4
	)
	(
		// Users to add ports here
		output logic init_slv2ctr,
		output logic done_ctr2slv,
		output logic mode_ctr2lcc,
		output logic ser,
		output logic rck,
		output logic sck,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S_AXI
		input logic  s_axi_aclk,
		input logic  s_axi_aresetn,
		input logic [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr,
		input logic [2 : 0] s_axi_awprot,
		input logic  s_axi_awvalid,
		output logic  s_axi_awready,
		input logic [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata,
		input logic [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb,
		input logic  s_axi_wvalid,
		output logic  s_axi_wready,
		output logic [1 : 0] s_axi_bresp,
		output logic  s_axi_bvalid,
		input logic  s_axi_bready,
		input logic [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr,
		input logic [2 : 0] s_axi_arprot,
		input logic  s_axi_arvalid,
		output logic  s_axi_arready,
		output logic [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata,
		output logic [1 : 0] s_axi_rresp,
		output logic  s_axi_rvalid,
		input logic  s_axi_rready,

		// Ports of Axi Master Bus Interface M_AXI
//		input logic  m_axi_init_axi_txn,
		output logic  m_axi_error,
//		output logic  m_axi_txn_done,
		input logic  m_axi_aclk,
		input logic  m_axi_aresetn,
		output logic [C_M_AXI_ADDR_WIDTH-1 : 0] m_axi_awaddr,
		output logic [2 : 0] m_axi_awprot,
		output logic  m_axi_awvalid,
		input logic  m_axi_awready,
		output logic [C_M_AXI_DATA_WIDTH-1 : 0] m_axi_wdata,
		output logic [C_M_AXI_DATA_WIDTH/8-1 : 0] m_axi_wstrb,
		output logic  m_axi_wvalid,
		input logic  m_axi_wready,
		input logic [1 : 0] m_axi_bresp,
		input logic  m_axi_bvalid,
		output logic  m_axi_bready,
		output logic [C_M_AXI_ADDR_WIDTH-1 : 0] m_axi_araddr,
		output logic [2 : 0] m_axi_arprot,
		output logic  m_axi_arvalid,
		input logic  m_axi_arready,
		input logic [C_M_AXI_DATA_WIDTH-1 : 0] m_axi_rdata,
		input logic [1 : 0] m_axi_rresp,
		input logic  m_axi_rvalid,
		output logic  m_axi_rready
	);
	
// Add user logic here
	logic clk;
	assign clk = s_axi_aclk;
	logic reset_ah;
	assign reset_ah = ~s_axi_aresetn;
	logic enbl_mst2ctr;
	assign enbl_mst2ctr = m_axi_rvalid;
	
	logic init_ctr2mst;
	logic [31:0] addr_ctr2mst;
	
	logic [63:0][7:0] data_ctr2lcc;
	
	logic [31:0] addr_slv2ctr;
	logic mode_slv2ctr;
	
	receiver receiver_0 (
		.clk(clk),
		.reset(reset_ah),
		.data_out2ctr(m_axi_rdata),
		.addr_slv2ctr(addr_slv2ctr),
		.init_slv2ctr(init_slv2ctr),
		.mode_slv2ctr(mode_slv2ctr),
		.enbl_mst2ctr(enbl_mst2ctr),
		.done_ctr2slv(done_ctr2slv),
		.init_ctr2mst(init_ctr2mst),
		.addr_ctr2mst(addr_ctr2mst),
		.mode_ctr2lcc(mode_ctr2lcc),
		.data_ctr2lcc(data_ctr2lcc)
	);
	
	lc_controller lc_controller_0 (
		.clk(clk),
		.reset(reset_ah),
		.sw(mode_ctr2lcc),
		.addr_in(data_ctr2lcc),
		.ser(ser),
		.rck(rck),
		.sck(sck)
	);
	
// User logic ends

// Instantiation of Axi Bus Interface S_AXI
	AXI_LC_v1_0_S_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	) AXI_LC_v1_0_S_AXI_inst (
		// user added ports
		.done_ctr2slv(done_ctr2slv),
		.addr_slv2ctr(addr_slv2ctr),
		.init_slv2ctr(init_slv2ctr),
		.mode_slv2ctr(mode_slv2ctr),
		// user added ports ends
		.S_AXI_ACLK(s_axi_aclk),
		.S_AXI_ARESETN(s_axi_aresetn),
		.S_AXI_AWADDR(s_axi_awaddr),
		.S_AXI_AWPROT(s_axi_awprot),
		.S_AXI_AWVALID(s_axi_awvalid),
		.S_AXI_AWREADY(s_axi_awready),
		.S_AXI_WDATA(s_axi_wdata),
		.S_AXI_WSTRB(s_axi_wstrb),
		.S_AXI_WVALID(s_axi_wvalid),
		.S_AXI_WREADY(s_axi_wready),
		.S_AXI_BRESP(s_axi_bresp),
		.S_AXI_BVALID(s_axi_bvalid),
		.S_AXI_BREADY(s_axi_bready),
		.S_AXI_ARADDR(s_axi_araddr),
		.S_AXI_ARPROT(s_axi_arprot),
		.S_AXI_ARVALID(s_axi_arvalid),
		.S_AXI_ARREADY(s_axi_arready),
		.S_AXI_RDATA(s_axi_rdata),
		.S_AXI_RRESP(s_axi_rresp),
		.S_AXI_RVALID(s_axi_rvalid),
		.S_AXI_RREADY(s_axi_rready)
	);

// Instantiation of Axi Bus Interface M_AXI
	AXI_LC_v1_0_M_AXI # ( 
		.C_M_START_DATA_VALUE(C_M_AXI_START_DATA_VALUE),
		.C_M_TARGET_SLAVE_BASE_ADDR(C_M_AXI_TARGET_SLAVE_BASE_ADDR),
		.C_M_AXI_ADDR_WIDTH(C_M_AXI_ADDR_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_M_AXI_DATA_WIDTH),
		.C_M_TRANSACTIONS_NUM(C_M_AXI_TRANSACTIONS_NUM)
	) AXI_LC_v1_0_M_AXI_inst (
		// user added ports
		.addr_ctr2mst(addr_ctr2mst),
		.INIT_AXI_TXN(init_ctr2mst),
		.ERROR(m_axi_error),
		.TXN_DONE(m_axi_txn_done),
		.M_AXI_ACLK(m_axi_aclk),
		.M_AXI_ARESETN(m_axi_aresetn),
		.M_AXI_AWADDR(m_axi_awaddr),
		.M_AXI_AWPROT(m_axi_awprot),
		.M_AXI_AWVALID(m_axi_awvalid),
		.M_AXI_AWREADY(m_axi_awready),
		.M_AXI_WDATA(m_axi_wdata),
		.M_AXI_WSTRB(m_axi_wstrb),
		.M_AXI_WVALID(m_axi_wvalid),
		.M_AXI_WREADY(m_axi_wready),
		.M_AXI_BRESP(m_axi_bresp),
		.M_AXI_BVALID(m_axi_bvalid),
		.M_AXI_BREADY(m_axi_bready),
		.M_AXI_ARADDR(m_axi_araddr),
		.M_AXI_ARPROT(m_axi_arprot),
		.M_AXI_ARVALID(m_axi_arvalid),
		.M_AXI_ARREADY(m_axi_arready),
		.M_AXI_RDATA(m_axi_rdata),
		.M_AXI_RRESP(m_axi_rresp),
		.M_AXI_RVALID(m_axi_rvalid),
		.M_AXI_RREADY(m_axi_rready)
	);

	endmodule
