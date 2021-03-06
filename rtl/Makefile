# Generate the flashable bitstream for the SoC, after first checking timing
upduino.bin: upduino.asc
	icetime -d up5k -c 12 -mtr upduino.rpt upduino.asc
	icepack upduino.asc upduino.bin

# Generate the asc bitstream file for the SoC
upduino.asc: upduino.pcf upduino.json
	nextpnr-ice40 --freq 13 --up5k --asc upduino.asc --pcf upduino.pcf --json upduino.json

# Synthesize the SoC to a json design file
upduino.json: upduino.v ice40up5k_spram.v spimemio.v simpleuart.v picosoc.v picorv32.v
	yosys -ql $(basename $@).log -p 'synth_ice40 -top upduino -json $@' $^

# Synthesize the SoC to a json design file, but limit memory size
upduino_memlimit.json: upduino.v ice40up5k_spram.v spimemio.v simpleuart.v picosoc.v picorv32.v
	yosys -ql $(basename $@).log -p 'chparam -set MEM_WORDS 256 upduino; synth_ice40 -top upduino -json $@' $^

# Generate Icarus Verilog vvp assembly from the SoC testbench.
upduino_tb.vvp: upduino_tb.v upduino.v ice40up5k_spram.v spimemio.v simpleuart.v picosoc.v picorv32.v spiflash.v
	iverilog -s testbench -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

# Generate Icarus Verilog vvp assembly from the SoC testbench based on the synthesized SoC.
upduino_syn_tb.vvp: upduino_tb.v upduino_syn.v spiflash.v
	iverilog -s testbench -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

# Generate verilog from the systhesized SoC.
upduino_syn.v: upduino_memlimit.json
	yosys -p 'read_json $<; write_verilog $@'

# Generate Icarus Verilog vvp assembly from the SPI testbench
spiflash_tb.vvp: spiflash_tb.v spiflash.v 
	iverilog -s testbench -o $@ $^

# Generate Icarus Verilog vvp assembly from the uart testbench
simpleuart_tb.vvp: simpleuart_tb.v simpleuart.v
	iverilog -s testbench -o $@ $^

.PHONY: clean
clean:
	rm -f *.vvp *.asc *.bin *.json *.log *.rpt *syn.v
