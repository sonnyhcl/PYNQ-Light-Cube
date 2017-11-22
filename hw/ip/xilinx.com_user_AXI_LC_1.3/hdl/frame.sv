`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/27/2017 11:44:39 AM
// Design Name: 
// Module Name: frame
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


module frame (
	input logic clk, reset,
	input logic [63:0][7:0] addr,
	input logic [15:0] vlc,
	input logic ser_init, rck_init, sck_init,
	output logic ser, rck, sck,
	output logic ready
	// the three control bits for light cube
);

	parameter [15:0] ONE_MCRSEC = 16'd99;
	parameter [15:0] TWO_MCRSEC = 16'd199;
	parameter [15:0] FIVE_MCRSEC = 16'd499;
	parameter [15:0] STOREY_TIME = 16'd15000;
	
//	// for simulation
//	parameter [15:0] ONE_MCRSEC = 16'd9;
//	parameter [15:0] TWO_MCRSEC = 16'd19;
//	parameter [15:0] FIVE_MCRSEC = 16'd49;
//	parameter [15:0] STOREY_TIME = 16'd2000;
		
	logic [15:0] cnt_vlc, cnt_vlc_in;
	logic ser_in, rck_in, sck_in;
	logic ready_in;
	
	logic rst_sty, rst_sty_in; // reset for storey
	logic [7:0][7:0] addr_sty, addr_sty_in;
	logic ser_sty_out, rck_sty_out, sck_sty_out;
	
	logic [7:0] cnt_0, cnt_1, num;
	logic [7:0] cnt_0_in, cnt_1_in, num_in;
	logic [15:0] cnt_delay, cnt_delay_in;
	
	storey storey_0 (
		.clk,
		.reset(rst_sty),
		.addr(addr_sty),
		.ser_init(ser),
		.rck_init(rck),
		.sck_init(sck),
		.ser(ser_sty_out),
		.rck(rck_sty_out),
		.sck(sck_sty_out)
	);
	
	enum logic [5:0] 
		{INIT, START, SHIFT, RCK_LOW, SER_LOW, WAIT_SER_0, SCK_LOW_0, WAIT_SCK_0, SCK_HIGH_0, NEXT,
		SER, WAIT_SER_1, SCK_LOW_1, WAIT_SCK_1, SCK_HIGH_1, SHIFT_NEXT, STOREY_PRE, STOREY, RCK_HIGH, WAIT_NEXT, DONE} curr_state, next_state;
	
	always_ff @ (posedge clk) begin
		if (reset) begin
			cnt_vlc <= vlc;
			ser <= ser_init;
			rck <= rck_init;
			sck <= sck_init;
			rst_sty <= 1'b0;
			addr_sty <= {8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
			cnt_0 <= 8'b0;
			cnt_1 <= 8'b0;
			cnt_delay <= 16'b0;
			num <= 8'b0;
			curr_state <= INIT;
			ready <= 1'b0;
		end else begin
			cnt_vlc <= cnt_vlc_in;
			ser <= ser_in;
			rck <= rck_in; 
			sck <= sck_in;
			rst_sty <= rst_sty_in;
			addr_sty <= addr_sty_in;
			cnt_0 <= cnt_0_in;
			cnt_1 <= cnt_1_in;
			cnt_delay <= cnt_delay_in;
			num <= num_in;
			ready <= ready_in;
			curr_state <= next_state;
		end
	end
	
	always_comb begin
		cnt_vlc_in = cnt_vlc;
		ser_in = ser;
		rck_in = rck;
		sck_in = sck;
		rst_sty_in = rst_sty;
		addr_sty_in = addr_sty;
		cnt_0_in = cnt_0;
		cnt_1_in = cnt_1;
		cnt_delay_in = cnt_delay;
		num_in = num;
		ready_in = ready;
		next_state = curr_state;
		unique case (curr_state)
			INIT: begin
				next_state = START;
			end
			START: begin
				next_state = SHIFT;
			end
			SHIFT: begin
				next_state = RCK_LOW;
			end
			RCK_LOW: begin
				next_state = SER_LOW;
			end
			SER_LOW: begin
				next_state = WAIT_SER_0;
			end
			WAIT_SER_0: begin
				if (cnt_delay == ONE_MCRSEC)
					next_state = SCK_LOW_0;
				else
					next_state = WAIT_SER_0;
			end
			SCK_LOW_0: begin
				next_state = WAIT_SCK_0;
			end
			WAIT_SCK_0: begin
				if (cnt_delay == ONE_MCRSEC)
					next_state = SCK_HIGH_0;
				else
					next_state = WAIT_SCK_0;
			end
			SCK_HIGH_0: begin
				next_state = NEXT;
			end
			NEXT: begin
				if (cnt_1 == 8'd7)
					next_state = SER;
				else
					next_state = SER_LOW;
			end
			SER: begin
				next_state = WAIT_SER_1;
			end
			WAIT_SER_1: begin
				if (cnt_delay == ONE_MCRSEC)
					next_state = SCK_LOW_1;
				else
					next_state = WAIT_SER_1; 
			end
			SCK_LOW_1: begin
				next_state = WAIT_SCK_1;
			end
			WAIT_SCK_1: begin
				if (cnt_delay == ONE_MCRSEC)
					next_state = SCK_HIGH_1;
				else
					next_state = WAIT_SCK_1;
			end
			SCK_HIGH_1: begin
				next_state = SHIFT_NEXT;
			end
			SHIFT_NEXT: begin
				if (cnt_1 == 8'd7)
					next_state = STOREY_PRE;
				else
					next_state = SER;
			end
			STOREY_PRE:begin
				next_state = STOREY;
			end
			STOREY: begin
				// it has to wait for the storey.sv operations
				if (cnt_delay == STOREY_TIME)
					next_state = RCK_HIGH;
				else
					next_state = STOREY;
			end
			RCK_HIGH: begin
				next_state = WAIT_NEXT;
			end
			WAIT_NEXT: begin
				if (cnt_delay == FIVE_MCRSEC)
					if (cnt_0 == 8'd7)
						if (cnt_vlc == 16'd0)
							next_state = DONE;
						else
							next_state = START;
					else
						next_state = SHIFT;
				else
					next_state = WAIT_NEXT;
			end
			DONE: begin
			end
		endcase
		
		unique case (curr_state)
			INIT: begin
			end
			START: begin
				num_in = 8'd1;
			end
			SHIFT: begin
				num_in = num << cnt_0;
			end
			RCK_LOW: begin
				rck_in = 1'b0;
			end
			SER_LOW: begin
				ser_in = 1'b0;
			end
			WAIT_SER_0: begin
				if (cnt_delay == ONE_MCRSEC)
					cnt_delay_in = 16'd0;
				else
					cnt_delay_in = cnt_delay + 16'd1;
			end
			SCK_LOW_0: begin
				sck_in = 1'b0;
			end
			WAIT_SCK_0: begin
				if (cnt_delay == ONE_MCRSEC)
					cnt_delay_in = 16'd0;
				else
					cnt_delay_in = cnt_delay + 16'd1;
			end
			SCK_HIGH_0: begin
				sck_in = 1'b1;
			end
			NEXT: begin
				if (cnt_1 == 8'd7)
					cnt_1_in = 8'd0;
				else
					cnt_1_in = cnt_1 + 8'd1;
			end
			SER: begin
				if (num & 8'h80)
					ser_in = 1'b1;
				else
					ser_in = 1'b0;
			end
			WAIT_SER_1: begin
				if (cnt_delay == ONE_MCRSEC)
					cnt_delay_in = 16'd0;
				else
					cnt_delay_in = cnt_delay + 16'd1;				
			end
			SCK_LOW_1: begin
				sck_in = 1'b0;
			end
			WAIT_SCK_1: begin
				if (cnt_delay == ONE_MCRSEC)
					cnt_delay_in = 16'd0;
				else
					cnt_delay_in = cnt_delay + 16'd1;	
			end
			SCK_HIGH_1: begin
				sck_in = 1'b1;
			end
			SHIFT_NEXT: begin
				num_in = num << 1'b1;
				if (cnt_1 == 8'd7)
					cnt_1_in = 8'd0;
				else
					cnt_1_in = cnt_1 + 8'd1;
			end
			STOREY_PRE: begin // prepare for storey
				rst_sty_in = 1'b1; 
				unique case (cnt_0)
					8'd0:
						addr_sty_in = addr[63:56];
					8'd1:
						addr_sty_in = addr[55:48];
					8'd2:
						addr_sty_in = addr[47:40];
					8'd3:
						addr_sty_in = addr[39:32];
					8'd4:
						addr_sty_in = addr[31:24];
					8'd5:
						addr_sty_in = addr[23:16];
					8'd6:
						addr_sty_in = addr[15:8];
					8'd7:
						addr_sty_in = addr[7:0];
				endcase	
			end
			STOREY: begin
				rst_sty_in = 1'b0;
				ser_in = ser_sty_out;
				rck_in = rck_sty_out;
				sck_in = sck_sty_out;
				if (cnt_delay == STOREY_TIME)
					cnt_delay_in = 16'd0;
				else
					cnt_delay_in = cnt_delay + 1'b1;
			end
			RCK_HIGH: begin
				rck_in = 1'b1;
			end
			WAIT_NEXT: begin
				num_in = 8'd1;
				if (cnt_delay == FIVE_MCRSEC) begin
					cnt_delay_in = 16'd0;
					if (cnt_0 == 8'd7) begin
						cnt_0_in = 8'd0;
						if (cnt_vlc == 16'd0)
							cnt_vlc_in = vlc;
						else
						
							cnt_vlc_in = cnt_vlc - 1'b1;
					end else
						cnt_0_in = cnt_0 + 1'b1;
				end else
					cnt_delay_in = cnt_delay + 1'b1;
			end
			DONE: begin
				ready_in = 1'b1;
			end
		endcase	
	end
	
endmodule
