`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/29/2017 09:14:55 AM
// Design Name: 
// Module Name: frame_controller
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


module frame_controller (
	input logic clk, reset,
	input logic [63:0][7:0] addr,
	output logic ser, rck, sck
);
	logic [15:0] vlc;
	logic ser_init, rck_init, sck_init;
	logic ser_out, rck_out, sck_out;
	logic ser_out_in, rck_out_in, sck_out_in;
	logic ser_clc_out, rck_clc_out, sck_clc_out;
	logic ser_frm_out, rck_frm_out, sck_frm_out;
	logic rst_clc, rst_clc_in;
	logic rst_frm, rst_frm_in;
	logic ready_clc, ready_frm;
	
	assign vlc = 16'd1;
	assign ser_init = 1'b0;
	assign rck_init = 1'b1;
	assign sck_init = 1'b1;
	
	assign ser = ser_out;
	assign rck = rck_out;
	assign sck = sck_out;
	
	logic [63:0][7:0] addr_alt;
	logic [7:0] addr_tp;
	always_comb begin
		for (int i = 0; i < 8; i ++) begin
			for (int j = 0; j < 4; j ++) begin
				addr_alt[i*8 + j] = addr[i*8 + 7 - j];
				addr_alt[i*8 + 7 - j] = addr[i*8 + j];
			end
		end
	end
	
	
	clc clc_0 (
		.clk,
		.reset(rst_clc),
		.ser_init,
		.rck_init,
		.sck_init,
		.ser(ser_clc_out),
		.rck(rck_clc_out),
		.sck(sck_clc_out),
		.ready(ready_clc)
	);
	
	frame frame_0 (
		.clk,
		.reset(rst_frm),
		.addr(addr_alt),
		.vlc,
		.ser_init,
		.rck_init,
		.sck_init,
		.ser(ser_frm_out),
		.rck(rck_frm_out),
		.sck(sck_frm_out),
		.ready(ready_frm)
	);
	
	enum logic [1:0] {RESET, CLEAR, RESET_FRM, FRAME} curr_state, next_state;
	
	always_ff @ (posedge clk) begin
		if (reset) begin
			rst_frm <= 1'b1;
			rst_clc <= 1'b1;
			ser_out <= ser_init;
			rck_out <= rck_init;
			sck_out <= sck_init;
			curr_state <= RESET;
		end else begin
			rst_frm <= rst_frm_in;
			rst_clc <= rst_clc_in;
			ser_out <= ser_out_in;
			rck_out <= rck_out_in;
			sck_out <= sck_out_in;
			curr_state <= next_state;
		end
	end
	
	always_comb begin
		rst_frm_in = rst_frm;
		rst_clc_in = rst_clc;
		ser_out_in = ser_out;
		rck_out_in = rck_out;
		sck_out_in = sck_out;
		next_state = curr_state;
		unique case (curr_state)
			RESET: begin
				next_state = CLEAR;
				rst_clc_in = 1'b1;
			end
			CLEAR: begin
				if (ready_clc)
					next_state = RESET_FRM;
				else
					next_state = CLEAR;
				rst_clc_in = 1'b0;
				ser_out_in = ser_clc_out;
				rck_out_in = rck_clc_out;
				sck_out_in = sck_clc_out;
			end
			RESET_FRM: begin
				next_state = FRAME;
				rst_frm_in = 1'b1;
			end
			FRAME: begin
				if (ready_frm)
					next_state = RESET_FRM;
				else
					next_state = FRAME;
				rst_frm_in = 1'b0;
				ser_out_in = ser_frm_out;
				rck_out_in = rck_frm_out;
				sck_out_in = sck_frm_out;
			end
		endcase
	end
	
endmodule
