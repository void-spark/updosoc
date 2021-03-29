`timescale 1 ns / 1 ps

module testbench;
    reg         uart_clk;
    reg         uart_resetn;
    wire        uart_ser_tx;
    reg         uart_ser_rx;
    reg   [3:0] uart_reg_div_we;
    reg  [31:0] uart_reg_div_di;
    wire [31:0] uart_reg_div_do;
    reg         uart_reg_dat_we;
    reg         uart_reg_dat_re;
    reg  [31:0] uart_reg_dat_di;
    wire [31:0] uart_reg_dat_do;
    wire        uart_reg_dat_wait;

	simpleuart uut (
        .clk(uart_clk),
        .resetn(uart_resetn),
        .ser_tx(uart_ser_tx),
        .ser_rx(uart_ser_rx),
        .reg_div_we(uart_reg_div_we),
        .reg_div_di(uart_reg_div_di),
        .reg_div_do(uart_reg_div_do),
        .reg_dat_we(uart_reg_dat_we),
        .reg_dat_re(uart_reg_dat_re),
        .reg_dat_di(uart_reg_dat_di),
        .reg_dat_do(uart_reg_dat_do),
        .reg_dat_wait(uart_reg_dat_wait)
	);

	always #5 uart_clk = (uart_clk === 1'b0);

	initial begin
		$dumpfile("simpleuart_tb.vcd");
		$dumpvars(0, testbench);
		$display("");

        // Start clock rising edge
        uart_clk = 1'b1;
        // Start with reset active (low)
        uart_resetn = 1'b0;
        // Start with rx inactive (high)
        uart_ser_rx = 1'b1;
        // Start with no divider reg write enable
        uart_reg_div_we = 4'b0000;
        // Start with divider reg value zero'd
        uart_reg_div_di = 32'h0000_0000;
        // Start with serial value reg write enable inactive (low)
        uart_reg_dat_we = 1'b0;
        // Start with serial value reg read enable inactive (low)
        uart_reg_dat_re = 1'b0;
        // Start with serial value reg value zero'd
        uart_reg_dat_di = 32'h0000_0000;

        // Keep in reset for 2 clocks
        #20;

        // Reset to inactive (high)
        uart_resetn = 1'b1;

        // Init should take 1(+2) * 15 clocks = 45
        // Let it play so we can look at the trace
        #450

        // Wait 2 more clocks
        #20;

        // Write enable divider reg all 4 bits
        uart_reg_div_we = 4'b1111;
        // Put divider reg value
        uart_reg_div_di = 32'h0000_0030; // 48 = 250000 baud @ 12Mhz

        // Wait one clock, which is also how long it will take for init to start after a div change.
        #10;

        // Write disable divider reg
        uart_reg_div_we = 4'b0000;

        // Check the new div value can be read
        if (uart_reg_div_do !== 32'h0000_0030) begin
            $display("ERROR: Got %x but expected %x.", uart_reg_div_do, 32'h0000_002A);
        end

        // Init should take 48(+2) * 15 clocks = 750
        // We can send before that, but wait should stay high.
        #7500;

        // Wait 2 more clocks
        #20;

        // Write enable serial value
        uart_reg_dat_we = 1'b1;
        // Put value
        uart_reg_dat_di = 32'h0000_0013;

        // Wait 1 clocks
        #10;

        if (uart_reg_dat_wait !== 1'b1) begin
            $display("ERROR: Expected uart_reg_dat_wait to go high");
        end

        // One bit is 48(+2) clocks (50), 500 ticks.
        // Check each bit halfway, value: 0-11001000-1
        #250;
        if (uart_ser_tx !== 1'b0) begin
            $display("ERROR: Expected uart_ser_tx start bit to be low");
        end
        #500;
        if (uart_ser_tx !== 1'b1) begin
            $display("ERROR: Expected uart_ser_tx bit 0 to be high");
        end
        #500;
        if (uart_ser_tx !== 1'b1) begin
            $display("ERROR: Expected uart_ser_tx bit 1 to be high");
        end
        #500;
        if (uart_ser_tx !== 1'b0) begin
            $display("ERROR: Expected uart_ser_tx bit 2 to be low");
        end
        #500;
        if (uart_ser_tx !== 1'b0) begin
            $display("ERROR: Expected uart_ser_tx bit 3 to be low");
        end
        #500;
        if (uart_ser_tx !== 1'b1) begin
            $display("ERROR: Expected uart_ser_tx bit 4 to be high");
        end
        #500;
        if (uart_ser_tx !== 1'b0) begin
            $display("ERROR: Expected uart_ser_tx bit 5 to be low");
        end
        #500;
        if (uart_ser_tx !== 1'b0) begin
            $display("ERROR: Expected uart_ser_tx bit 6 to be low");
        end
        #500;
        if (uart_ser_tx !== 1'b0) begin
            $display("ERROR: Expected uart_ser_tx bit 7 to be low");
        end
        #500;
        if (uart_ser_tx !== 1'b1) begin
            $display("ERROR: Expected uart_ser_tx end bit to be high");
        end

        // Wait remainder of last bit
        #250;

        if (uart_reg_dat_wait !== 1'b0) begin
            $display("ERROR: Expected uart_reg_dat_wait to go low");
        end

        // Write disable serial value
        uart_reg_dat_we = 1'b0;
        // No longer provide value
        uart_reg_dat_di = 32'h0000_0000;

        // Wait 2 clocks
        #20;

        $display("Tx test done");


        // Initially, no byte should be available, reported as '-1', or all 1's
        if (uart_reg_dat_do !== 32'hffff_ffff) begin
            $display("ERROR: Got %x but expected %x.", uart_reg_dat_do, 32'h0000_0013);
        end

        // One bit is 48(+2) clocks (50), 500 ticks.
        // Write each bit, value: 0-11001000-1
        // Start bit
        uart_ser_rx = 1'b0;
        #500;
        // Bit 0
        uart_ser_rx = 1'b1;
        #500;
        // Bit 1
        uart_ser_rx = 1'b1;
        #500;
        // Bit 2
        uart_ser_rx = 1'b0;
        #500;
        // Bit 3
        uart_ser_rx = 1'b0;
        #500;
        // Bit 4
        uart_ser_rx = 1'b1;
        #500;
        // Bit 5
        uart_ser_rx = 1'b0;
        #500;
        // Bit 6
        uart_ser_rx = 1'b0;
        #500;
        // Bit 7
        uart_ser_rx = 1'b0;
        #500;
        // Stop bit
        uart_ser_rx = 1'b1;
        #500;

        if (uart_reg_dat_wait !== 1'b0) begin
            $display("ERROR: Expected uart_reg_dat_wait to be low");
        end

        // Set read enable serial value.
        uart_reg_dat_re = 1'b1;

        // Read on the same clock(!)
        if (uart_reg_dat_do !== 32'h0000_0013) begin
            $display("ERROR: Got %x but expected %x.", uart_reg_dat_do, 32'h0000_0013);
        end

        // Wait 1 clocks
        #10;

        // After one clock the value is already reset
        if (uart_reg_dat_do !== 32'hffff_ffff) begin
            $display("ERROR: Got %x but expected %x.", uart_reg_dat_do, 32'h0000_0013);
        end

        // Set read disable serial value.
        uart_reg_dat_re = 1'b0;

        // Wait 2 clocks
        #20;

        $display("Rx test done");

        $finish;
	end

endmodule
