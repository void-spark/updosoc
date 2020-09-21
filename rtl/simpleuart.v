/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

module simpleuart #(parameter integer DEFAULT_DIV = 1) (

	// Clock signal for the uart.
	input clk,

	// Reset line (inverted).
	input resetn,

	// Serial out.
	output ser_tx,

	// Serial in.
	input  ser_rx,

	/// Divider register
	// 4 bits which indicate write enable for the four bytes in the register word.
	input   [3:0] reg_div_we,
	// The register word to be written to externally, no wait.
	input  [31:0] reg_div_di,
	// The register word to be read externally, no wait.
	output [31:0] reg_div_do,

	/// Serial value register
	// Write enable for the register word, should stay high until reg_dat_wait is set low.
	input         reg_dat_we,
	// Read enable for the register word, should stay high until reg_dat_wait is set low.
	input         reg_dat_re,
	// The register word to be written to externally, must stay set until reg_dat_wait is set low.
	// Only the lowest 8 bits are actually used.
	input  [31:0] reg_dat_di,
	// The register word to be read externally, must wait until reg_dat_wait is set low to be read.
	// Only the lowest 8 bits are actually driven.
	output [31:0] reg_dat_do,
	// Bit which indicates the serial register word read or write is not done yet.
	output        reg_dat_wait
);

	// The current divider value.
	reg [31:0] cfg_divider;

	// Receive state machine state.
	reg [3:0] recv_state;
	reg [31:0] recv_divcnt;
	reg [7:0] recv_pattern;
	reg [7:0] recv_buf_data;
	reg recv_buf_valid;

	// Buffer with pattern to send, rightmost bit is attached to ser_tx
	// Total 10 bits, 1 start, 8 data, 1 stop
	reg [9:0] send_pattern;
	// Bits left to send
	reg [3:0] send_bitcnt;
	// Starts at 0 on first pos-edge after reset, and counts up 1 each following pos-edge.
	// Counts up to the set divider + 1 for each bit, which means each bit is dev+2 clocks long (0 .. dev+1)
	// TODO: Apply https://github.com/cliffordwolf/picorv32/pull/162/files
	reg [31:0] send_divcnt;
	// Bit to indicate sending should be initialized, we keep tx high for 16 bit lengths.
	reg send_init;

	// Reading the divider register always gives the current value.
	assign reg_div_do = cfg_divider;

	// Once the external system has set a byte to send, make it wait till it's send.
	assign reg_dat_wait = reg_dat_we && (send_init || send_bitcnt);

	// Reading the serial value register gives the current received byte, or 255/-1 if not valid.
	assign reg_dat_do = recv_buf_valid ? recv_buf_data : ~0;

	// Control setting the cfg_divider value:
	// - Set to default on reset
	// - Set from reg_div_di when the corresponding reg_div_we enable bits are active.
	always @(posedge clk) begin
		if (!resetn) begin
			cfg_divider <= DEFAULT_DIV;
		end else begin
			if (reg_div_we[0]) cfg_divider[ 7: 0] <= reg_div_di[ 7: 0];
			if (reg_div_we[1]) cfg_divider[15: 8] <= reg_div_di[15: 8];
			if (reg_div_we[2]) cfg_divider[23:16] <= reg_div_di[23:16];
			if (reg_div_we[3]) cfg_divider[31:24] <= reg_div_di[31:24];
		end
	end

	// Receiving state machine
	always @(posedge clk) begin
		if (!resetn) begin
			recv_state <= 0;
			recv_divcnt <= 0;
			recv_pattern <= 0;
			recv_buf_data <= 0;
			recv_buf_valid <= 0;
		end else begin
			recv_divcnt <= recv_divcnt + 1;
			if (reg_dat_re)
				recv_buf_valid <= 0;
			case (recv_state)
				0: begin
					if (!ser_rx)
						recv_state <= 1;
					recv_divcnt <= 0;
				end
				1: begin
					if (2*recv_divcnt > cfg_divider) begin
						recv_state <= 2;
						recv_divcnt <= 0;
					end
				end
				10: begin
					if (recv_divcnt > cfg_divider) begin
						recv_buf_data <= recv_pattern;
						recv_buf_valid <= 1;
						recv_state <= 0;
					end
				end
				default: begin
					if (recv_divcnt > cfg_divider) begin
						recv_pattern <= {ser_rx, recv_pattern[7:1]};
						recv_state <= recv_state + 1;
						recv_divcnt <= 0;
					end
				end
			endcase
		end
	end

	// Attach rightmost bit of send_pattern to ser_tx
	assign ser_tx = send_pattern[0];

	always @(posedge clk) begin
		if (reg_div_we)
			// Send init to 1, we re-init after changing the divider.
			send_init <= 1;
		// Always count up the divider count when we're not in reset.
		send_divcnt <= send_divcnt + 1;
		if (!resetn) begin
			// Set initial values
			// All bits in send pattern to high, which is the default state for the tx line.
			send_pattern <= ~0;
			// Bit counter to 0.
			send_bitcnt <= 0;
			// Division counter to 0.
			send_divcnt <= 0;
			// Send init to 1.
			send_init <= 1;
		end else begin
			if (send_init && !send_bitcnt) begin
				// If we should (re)init, and are not sending, queue up 15 bits set to 'high'
				// TODO: This doesn't make full sense, if we are sending, we continue at the new bitrate. So why wait?
				// Set the send pattern bits to high.
				send_pattern <= ~0;
				// Set to bit count to it's max, 15.
				send_bitcnt <= 15;
				// Reset the division counter to 0.
				send_divcnt <= 0;
				// We've handled the init flag, reset it to 0.
				send_init <= 0;
			end else
			if (reg_dat_we && !send_bitcnt) begin
				// If write enable for data is set, and we're not sending already, queue the byte.
				// Set the pattern to send, including one start and one stop bit.
				// The lowest/right most bit is connected to tx, so will be sent directly.
				send_pattern <= {1'b1, reg_dat_di[7:0], 1'b0};
				// We'll be sending 10 bits in total.
				send_bitcnt <= 10;
				// Reset the division counter to 0.
				send_divcnt <= 0;
			end else
			if (send_divcnt > cfg_divider && send_bitcnt) begin
				// When one bit of clocks has passed, and there's bits left to send
				// Shift send_pattern right one bit, padding on the left with a 1 bit.
				send_pattern <= {1'b1, send_pattern[9:1]};
				// Decrement the amount of bits to send
				send_bitcnt <= send_bitcnt - 1;
				send_divcnt <= 0;
			end
		end
	end
endmodule
