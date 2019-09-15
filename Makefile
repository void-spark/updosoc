# Simulate SoC + firmware
.PHONY: updusim
updusim: rtl/upduino_tb.vvp firmware/upduino_fw.hex
	vvp -N $< +firmware=firmware/upduino_fw.hex

# Simulate synthesized SoC + firmware
.PHONY: updusynsim
updusynsim: rtl/upduino_syn_tb.vvp firmware/upduino_fw.hex
	vvp -N $< +firmware=firmware/upduino_fw.hex

# Flash SoC + firmware
.PHONY: upduprog
upduprog: rtl/upduino.bin firmware/upduino_fw.bin
	iceprog rtl/upduino.bin
	iceprog -o 1M firmware/upduino_fw.bin

# Flash just firmware
.PHONY: upduprog_fw
upduprog_fw: firmware/upduino_fw.bin
	iceprog -o 1M firmware/upduino_fw.bin

.PHONY: rtl/upduino_tb.vvp
rtl/upduino_tb.vvp:
	$(MAKE) -C rtl upduino_tb.vvp

.PHONY: rtl/upduino_syn_tb.vvp
rtl/upduino_syn_tb.vvp:
	$(MAKE) -C rtl upduino_syn_tb.vvp

.PHONY: rtl/upduino.bin
rtl/upduino.bin:
	$(MAKE) -C rtl upduino.bin

.PHONY: firmware/upduino_fw.hex
firmware/upduino_fw.hex:
	$(MAKE) -C firmware upduino_fw.hex

.PHONY: firmware/upduino_fw.bin
firmware/upduino_fw.bin:
	$(MAKE) -C firmware upduino_fw.bin

# ---- Testbench for SPI Flash Model ----

.PHONY: spiflash_tb
spiflash_tb: rtl/spiflash_tb.vvp firmware/upduino_fw.hex
	vvp -N $< +firmware=firmware/upduino_fw.hex

.PHONY: rtl/spiflash_tb.vvp
rtl/spiflash_tb.vvp:
	$(MAKE) -C rtl spiflash_tb.vvp

# ---- Clean ----

.PHONY: clean
clean:
	rm -f *.vcd
	$(MAKE) -C firmware clean
	$(MAKE) -C rtl clean
