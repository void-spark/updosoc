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

`ifdef PICOSOC_V
`error "upduino.v must be read before picosoc.v!"
`endif

`define PICOSOC_MEM ice40up5k_spram

module upduino (
	input clk,

    input reset_button,

	output ser_tx,
	input ser_rx,

	output led_r,
	output led_g,
	output led_b,

	output flash_csb,
	output flash_clk,
	inout  flash_io0,
	inout  flash_io1
);
	parameter integer MEM_WORDS = 32768;

	reg [5:0] reset_cnt = 0;
	wire reset_ready = &reset_cnt;
	wire resetn = reset_ready && !reset_button;

	always @(posedge clk) begin
		reset_cnt <= reset_cnt + !reset_ready;
	end

	wire pwm_r;
	wire pwm_g;
	wire pwm_b;

	assign pwm_r = gpio[0];	
	assign pwm_g = gpio[1];	
	assign pwm_b = gpio[2];	

	wire flash_io0_oe, flash_io0_do, flash_io0_di;
	wire flash_io1_oe, flash_io1_do, flash_io1_di;

	SB_IO #(
		.PIN_TYPE(6'b 1010_01), // PIN_INPUT: Simple input pin + PIN_OUTPUT_TRISTATE: The output pin may be tristated using the enable
		.PULLUP(1'b 0) // No pull up
	) flash_io_buf [1:0] (
		.PACKAGE_PIN({flash_io1, flash_io0}),
		.OUTPUT_ENABLE({flash_io1_oe, flash_io0_oe}),
		.D_OUT_0({flash_io1_do, flash_io0_do}),
		.D_IN_0({flash_io1_di, flash_io0_di})
	);

	wire        iomem_valid;
	reg         iomem_ready;
	wire [3:0]  iomem_wstrb;
	wire [31:0] iomem_addr;
	wire [31:0] iomem_wdata;
	reg  [31:0] iomem_rdata;

	reg [31:0] gpio;

	always @(posedge clk) begin
		if (!resetn) begin
			gpio <= 0;
		end else begin
			iomem_ready <= 0;
			if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h 03) begin
				iomem_ready <= 1;
				iomem_rdata <= gpio;
				if (iomem_wstrb[0]) gpio[ 7: 0] <= iomem_wdata[ 7: 0];
				if (iomem_wstrb[1]) gpio[15: 8] <= iomem_wdata[15: 8];
				if (iomem_wstrb[2]) gpio[23:16] <= iomem_wdata[23:16];
				if (iomem_wstrb[3]) gpio[31:24] <= iomem_wdata[31:24];
			end
		end
	end

	picosoc #(
		.BARREL_SHIFTER(0),
		.ENABLE_MULDIV(0),
		.MEM_WORDS(MEM_WORDS)
	) soc (
		.clk          (clk         ),
		.resetn       (resetn      ),

		.ser_tx       (ser_tx      ),
		.ser_rx       (ser_rx      ),

		.flash_csb    (flash_csb   ),
		.flash_clk    (flash_clk   ),

		.flash_io0_oe (flash_io0_oe),
		.flash_io1_oe (flash_io1_oe),

		.flash_io0_do (flash_io0_do),
		.flash_io1_do (flash_io1_do),

		.flash_io0_di (flash_io0_di),
		.flash_io1_di (flash_io1_di),

		.irq_5        (1'b0        ),
		.irq_6        (1'b0        ),
		.irq_7        (1'b0        ),

		.iomem_valid  (iomem_valid ),
		.iomem_ready  (iomem_ready ),
		.iomem_wstrb  (iomem_wstrb ),
		.iomem_addr   (iomem_addr  ),
		.iomem_wdata  (iomem_wdata ),
		.iomem_rdata  (iomem_rdata )
	);

	// Use ICE40 RGB driver IP, to lower current a bit
	SB_RGBA_DRV RGBA_DRIVER (
	  .CURREN(1'b1),
	  .RGBLEDEN(1'b1),
	  .RGB0PWM(pwm_r),
	  .RGB1PWM(pwm_g),
	  .RGB2PWM(pwm_b),
	  .RGB0(led_r),
	  .RGB1(led_g),
	  .RGB2(led_b)
	);

	defparam RGBA_DRIVER.CURRENT_MODE = "0b1"; // Half Current Mode
	defparam RGBA_DRIVER.RGB0_CURRENT = "0b000001"; // 2 mA for Half Mode
	defparam RGBA_DRIVER.RGB1_CURRENT = "0b000001"; // 2 mA for Half Mode
	defparam RGBA_DRIVER.RGB2_CURRENT = "0b000001"; // 2 mA for Half Mode

endmodule
