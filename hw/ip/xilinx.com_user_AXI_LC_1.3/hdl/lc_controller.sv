`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/13/2017 09:17:00 AM
// Design Name: 
// Module Name: lc_controller
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


module lc_controller(
	input logic clk, reset,
	input logic sw,
	input logic [63:0][7:0] addr_in,
	output logic ser, rck, sck
);

	logic [63:0][7:0] addr, addr_shift;

	always_comb begin
		case (sw)
			2'b0: begin
				addr = addr_shift;
			end
			2'b1: begin
				addr = addr_in;
			end
			default: begin
				addr = addr_shift;
			end
		endcase
	end
	
	frame_controller frame_controller_0 (.*);

	shifter shifter_0 (.*, .addr(addr_shift));

endmodule