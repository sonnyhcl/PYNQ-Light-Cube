
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/20/2017 02:39:22 PM
// Design Name: 
// Module Name: testbench
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


module testbench();

	timeunit 10 ns;
	timeprecision 1ns;
	
	logic clk, reset;
	logic [31:0] data_out2ctr;
	logic [31:0] addr_slv2ctr;
	logic init_slv2ctr;
	logic mode_slv2ctr;
	logic enbl_mst2ctr;
	logic done_ctr2slv; 
	logic init_ctr2mst;
	logic [31:0] addr_ctr2mst;
	logic mode_ctr2lcc;
	logic [63:0][7:0] data_ctr2lcc;
	
	receiver receiver_0 (.*);
	
	always begin
		#1 clk = ~clk;
	end
	
	initial begin
		clk = 1'b0;
		reset = 1'b0;
		data_out2ctr = 32'h12345678;
		addr_slv2ctr = 32'h0;
		init_slv2ctr = 1'b0;
		mode_slv2ctr = 1'b1;
		enbl_mst2ctr = 1'b0;
		
		#2 reset = 1'b1;
		#2 reset = 1'b0;
		
		#2 init_slv2ctr = 1'b1;
		#2 enbl_mst2ctr = 1'b1;
		#2 enbl_mst2ctr = 1'b0;
				
	end
endmodule
