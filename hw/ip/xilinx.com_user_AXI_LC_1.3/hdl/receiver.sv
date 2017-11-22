`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/20/2017 10:46:38 AM
// Design Name: 
// Module Name: receiver
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


module receiver(
	input logic clk, reset,
	input logic [31:0] data_out2ctr,
	input logic [31:0] addr_slv2ctr,
	input logic init_slv2ctr,
	input logic mode_slv2ctr,
	input logic enbl_mst2ctr,
	output logic done_ctr2slv, 
	output logic init_ctr2mst,
	output logic [31:0] addr_ctr2mst,
	output logic mode_ctr2lcc,
	output logic [63:0][7:0] data_ctr2lcc
);
	parameter [63:0][7:0] DATA_INIT = {
		8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
		8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
		8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
		8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
		8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
		8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
		8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
		8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF
	};
	
	logic done_ctr2slv_in;
	logic init_ctr2mst_in;
	logic [31:0] addr_ctr2mst_in;
	logic mode_ctr2lcc_in;
	logic [63:0][7:0] data_ctr2lcc_in, data_ctr, data_ctr_in;
	
	logic [7:0] addr_cnt, addr_cnt_in, cycle_cnt, cycle_cnt_in;
	
	logic init_ff_0, init_ff_1, init_pulse;
	assign init_pulse = (!init_ff_1) && init_ff_0;
	
	enum logic [3:0] {INIT, WAIT, READY, READ, CHECK} curr_state, next_state;
	
	always_ff @ (posedge clk) begin
		if (reset) begin
			done_ctr2slv <= 1'b1;
			init_ctr2mst <= 1'b0;
			addr_ctr2mst <= 32'h0;
			mode_ctr2lcc <= 1'b0;
			data_ctr2lcc <= DATA_INIT;
			data_ctr <= DATA_INIT;
			addr_cnt <= 8'd0;
			cycle_cnt <= 8'd0;
			init_ff_0 <= 1'b0;
			init_ff_1 <= 1'b0;
			curr_state <= INIT;
		end else begin
			done_ctr2slv <= done_ctr2slv_in;
			init_ctr2mst <= init_ctr2mst_in;
			addr_ctr2mst <= addr_ctr2mst_in;
			mode_ctr2lcc <= mode_ctr2lcc_in;
			data_ctr2lcc <= data_ctr2lcc_in;
			data_ctr <= data_ctr_in;
			addr_cnt <= addr_cnt_in;
			cycle_cnt <= cycle_cnt_in;
			init_ff_0 <= init_slv2ctr;
			init_ff_1 <= init_ff_0;
			curr_state <= next_state;
		end
	end
	
	always_comb begin
		done_ctr2slv_in = done_ctr2slv;
		init_ctr2mst_in = init_ctr2mst;
		addr_ctr2mst_in = addr_ctr2mst;
		mode_ctr2lcc_in = mode_slv2ctr;
		data_ctr2lcc_in = data_ctr2lcc;
		data_ctr_in = data_ctr;
		addr_cnt_in = addr_cnt;
		cycle_cnt_in = cycle_cnt;
		next_state = curr_state;
		
		unique case (curr_state) 
			INIT: begin
				next_state = WAIT;
			end
			WAIT: begin
				if (init_pulse)
					next_state = READY;
				else
					next_state = WAIT;
			end
			READY: begin
				next_state = READ;
			end
			READ: begin
				if (enbl_mst2ctr || cycle_cnt <= 4'd10)
					next_state = READ;
				else
					next_state = CHECK;
			end
			CHECK: begin
				if (addr_cnt == 8'd63)
					next_state = WAIT;
				else
					next_state = READY;
			end
		endcase
		
		unique case (curr_state)
			INIT: begin
				done_ctr2slv_in = 1'b1;
				init_ctr2mst_in = 1'b0;
				addr_ctr2mst_in = 32'h0;
				mode_ctr2lcc_in = 1'b0;
				data_ctr2lcc_in = DATA_INIT;
				data_ctr_in = DATA_INIT;
				addr_cnt_in = 8'd0;
				cycle_cnt_in = 8'd0;
			end
			WAIT: begin
			end
			READY: begin
				done_ctr2slv_in = 1'b0;
				init_ctr2mst_in = 1'b1;
				addr_ctr2mst_in = addr_slv2ctr + addr_cnt*4;
			end
			READ: begin
				cycle_cnt_in = cycle_cnt + 1'b1;
				if (enbl_mst2ctr) begin
					data_ctr_in[addr_cnt][7:0] = data_out2ctr[7:0];
				end
			end
			CHECK: begin
				init_ctr2mst_in = 1'b0;
				cycle_cnt_in = 4'b0;
				if (addr_cnt == 8'd63) begin
					data_ctr2lcc_in = data_ctr;
					done_ctr2slv_in = 1'b1;
					addr_cnt_in = 8'd0;
				end else begin
					addr_cnt_in = addr_cnt + 1'b1;
				end
			end
		endcase
	end
endmodule
