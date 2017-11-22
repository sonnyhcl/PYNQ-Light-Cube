`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/29/2017 11:32:52 AM
// Design Name: 
// Module Name: shifter
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


module shifter (
	input logic clk, reset,
	input logic up, down,
	output logic [63:0][7:0] addr
);
    
    parameter [63:0][7:0] ADDR_INIT = {
		8'h01,8'h03,8'h07,8'h0F,8'h1F,8'h3F,8'h7F,8'hFF,
		8'h03,8'h07,8'h0F,8'h1F,8'h3F,8'h7F,8'hFF,8'hFE,
		8'h07,8'h0F,8'h1F,8'h3F,8'h7F,8'hFF,8'hFE,8'hFC,
		8'h0F,8'h1F,8'h3F,8'h7F,8'hFF,8'hFE,8'hFC,8'hF8,
		8'h1F,8'h3F,8'h7F,8'hFF,8'hFE,8'hFC,8'hF8,8'hF0,
		8'h3F,8'h7F,8'hFF,8'hFE,8'hFC,8'hF8,8'hF0,8'hE0,
		8'h7F,8'hFF,8'hFE,8'hFC,8'hF8,8'hF0,8'hE0,8'hC0,
		8'hFF,8'hFE,8'hFC,8'hF8,8'hF0,8'hE0,8'hC0,8'h80
	};
//	parameter [29:0] VLC_INIT = 30'd9999999;
	parameter [29:0] VLC_INIT = 30'd9999999;
	
	logic [63:0][14:0] addr_alt, addr_alt_in, addr_alt_init;
	logic [63:0][7:0] addr_in;
	
	logic [31:0] cnt, cnt_in, vlc, vlc_in, cnt_btn, cnt_btn_in;
	
	enum logic [1:0] {RESET, RUN, WAIT} curr_state, next_state;
	
	always_comb begin
		for (int i = 0; i < 64; i ++) begin
			addr_alt_init[i] = {~ADDR_INIT[i][7:1], ADDR_INIT[i][7:0]};
		end
	end
	
	always_ff @ (posedge clk) begin
		if (reset) begin
			addr <= ADDR_INIT;
			addr_alt <= addr_alt_init;
			curr_state <= RESET;
			cnt <= 32'b0;
			vlc <= VLC_INIT;
			cnt_btn <= 32'd0;
		end else begin
			addr <= addr_in;
			addr_alt <= addr_alt_in;
			curr_state <= next_state;
			cnt <= cnt_in;
			vlc <= vlc_in;
			cnt_btn <= cnt_btn_in;
		end
	end
	
	always_comb begin
		addr_in = addr;
		addr_alt_in = addr_alt;
		cnt_in = cnt;
		vlc_in = vlc;
		cnt_btn_in = cnt_btn;
		if (cnt_btn == 32'd0) begin
			if (up)
				if (vlc >= 30'd2500000)
					vlc_in = vlc - 30'd1;
			if (down)
				vlc_in = vlc + 30'd1;
		end else if (cnt_btn == 32'd1000)
			cnt_btn_in = 32'd0;
		else
			cnt_btn_in = cnt_btn + 32'd1;
		unique case (curr_state)
			RESET: begin
				next_state = RUN;
			end
			RUN: begin
				next_state = WAIT;
				for (int i = 0; i < 64; i ++) begin
					addr_alt_in[i] = {addr_alt[i][0], addr_alt[i][14:1]};
					addr_in[i] = addr_alt[i][7:0];
				end
			end
			WAIT: begin
				if (cnt >= vlc) begin
					cnt_in = 16'd0;
					next_state = RUN;
				end else begin
					cnt_in = cnt + 16'd1;
					next_state = WAIT;
				end
			end
		endcase
	end
endmodule
