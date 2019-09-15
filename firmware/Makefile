.PHONY: all
all: upduino_fw.hex upduino_fw.bin

upduino_sections.lds: sections.lds
	riscv32-unknown-elf-cpp -P -DICEBREAKER -o $@ $^

upduino_fw.elf: upduino_sections.lds start.s firmware.c
	riscv32-unknown-elf-gcc -DICEBREAKER -march=rv32ic -Wl,-Bstatic,-T,upduino_sections.lds,--strip-debug -ffreestanding -nostdlib -o upduino_fw.elf start.s firmware.c

upduino_fw.hex: upduino_fw.elf
	riscv32-unknown-elf-objcopy -O verilog upduino_fw.elf upduino_fw.hex

upduino_fw.bin: upduino_fw.elf
	riscv32-unknown-elf-objcopy -O binary upduino_fw.elf upduino_fw.bin

.PHONY: clean
clean:
	rm -f upduino_sections.lds *.elf *.hex *.bin
