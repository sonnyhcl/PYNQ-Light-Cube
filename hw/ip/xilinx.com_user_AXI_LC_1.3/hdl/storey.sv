`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/27/2017 11:45:44 AM
// Design Name: 
// Module Name: storey
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


module storey (
	input logic clk, reset,
	input logic [7:0][7:0] addr,
	input logic ser_init, rck_init, sck_init, // rck and sck should be high at default (lights down)
	output logic ser, rck, sck	
);
	parameter [15:0] ONE_MCRSEC = 16'd99;
	parameter [15:0] TWO_MCRSEC = 16'd199;
	parameter [15:0] FIVE_MCRSEC = 16'd499;
	
//	// for simulation
//	parameter [15:0] ONE_MCRSEC = 16'd9;
//	parameter [15:0] TWO_MCRSEC = 16'd19;
//	parameter [15:0] FIVE_MCRSEC = 16'd49;
	
	logic ser_in, rck_in, sck_in;
	logic [7:0] cnt_0, cnt_1, num;
	logic [7:0] cnt_0_in, cnt_1_in, num_in;
	logic [15:0] cnt_delay, cnt_delay_in;
	
	enum logic [3:0] {INIT, START, SER, WAIT_SER, SCK_LOW, WAIT_SCK, SCK_HIGH, SHIFT, NEXT, DONE} curr_state, next_state;
	
	always_ff @ (posedge clk) begin
		if (reset) begin
			ser <= ser_init;
			rck <= rck_init;
			sck <= sck_init;
			curr_state <= INIT;
			cnt_0 <= 8'b0;
			cnt_1 <= 8'b0;
			cnt_delay <= 16'b0;
			num <= 8'b0;
		end else begin
			ser <= ser_in;
			rck <= rck_in;
			sck <= sck_in;
			curr_state <= next_state;
			cnt_0 <= cnt_0_in;
			cnt_1 <= cnt_1_in;
			cnt_delay <= cnt_delay_in;
			num <= num_in;
		end
	end
	
	always_comb begin
		ser_in = ser;
		rck_in = rck;
		sck_in = sck;
		next_state = curr_state;
		cnt_0_in = cnt_0;
		cnt_1_in = cnt_1;
		cnt_delay_in = cnt_delay;
		num_in = num;
		unique case (curr_state)
			INIT: begin
				next_state = START;
			end
			START: begin
				next_state = SER;
			end
			SER: begin
				next_state = WAIT_SER;
			end
			WAIT_SER: begin
				if (cnt_delay == ONE_MCRSEC)
					next_state = SCK_LOW;
				else
					next_state = WAIT_SER;
			end
			SCK_LOW: begin
				next_state = WAIT_SCK;
			end
			WAIT_SCK: begin
				if (cnt_delay == ONE_MCRSEC)
					next_state = SCK_HIGH;
				else
					next_state = WAIT_SCK;
			end
			SCK_HIGH: begin
				next_state = SHIFT;
			end
			SHIFT: begin
				if (cnt_1 == 8'd7)
					next_state = NEXT;
				else
					next_state = SER;
			end
			NEXT: begin
				if (cnt_0 == 8'd7)
					next_state = DONE;
				else
					next_state = INIT;
			end
			DONE: begin
			end
		endcase
		
		unique case (curr_state)
			INIT: begin
			end
			START: begin
				num_in = addr[cnt_0];
			end
			SER: begin
				if (num & 8'h80)
					ser_in = 1'b1;
				else
					ser_in = 1'b0;
			end
			WAIT_SER: begin
				if (cnt_delay == ONE_MCRSEC)
					cnt_delay_in = 16'd0;
				else
					cnt_delay_in = cnt_delay + 16'd1;
			end
			SCK_LOW: begin
				sck_in = 1'b0;
			end
			WAIT_SCK: begin
				if (cnt_delay == ONE_MCRSEC)
					cnt_delay_in = 16'd0;
				else
					cnt_delay_in = cnt_delay + 16'd1;
			end
			SCK_HIGH: begin
				sck_in = 1'b1;
			end
			SHIFT: begin
				num_in = num << 8'b1;
				if (cnt_1 == 8'd7)
					cnt_1_in = 8'd0;
				else
					cnt_1_in = cnt_1 + 8'd1;
			end
			NEXT: begin
				if (cnt_0 == 8'd7)
					cnt_0_in = 8'd0;
				else
					cnt_0_in = cnt_0 + 8'd1;
			end
			DONE: begin
			end
		endcase
	end
endmodule
