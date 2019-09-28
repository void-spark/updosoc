# User the riscv32i versions of the toolchain
AS            := riscv32-unknown-elf-as
CC            := riscv32-unknown-elf-gcc
CPP           := riscv32-unknown-elf-cpp 
OBJCOPY       := riscv32-unknown-elf-objcopy
LD            := riscv32-unknown-elf-ld

# Preprocessor flags
CPPFLAGS      :=

# Generate instructions for the machine type cpu-type.
ASFLAGS       := -march=rv32ic

# Generate instructions for the machine type cpu-type.
CFLAGS        := -march=rv32ic
# Assert that compilation targets a freestanding environment.
CFLAGS        += -ffreestanding

# Do not link against shared libraries
LDFLAGS       := -Bstatic
# Strip debugging symbols
LDFLAGS       += --strip-debug
# Only use library directories specified on the command line
LDFLAGS       += -nostdlib

# Automatically include any .c file in the folder
src = $(wildcard *.c)
obj = $(src:.c=.o)
dep = $(obj:.o=.d)

.PHONY: all
all: upduino_fw.hex upduino_fw.bin

# Preprocess the linker script
upduino_sections.lds: sections.lds
	$(CPP) $(CPPFLAGS) -P -o $@ $<

upduino_fw.elf: upduino_sections.lds start.o $(obj)
	$(LD) $(LDFLAGS) -T upduino_sections.lds -o $@ start.o $(obj)

%.hex: %.elf
	$(OBJCOPY) -O verilog $< $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

# include all dep files in the makefile
-include $(dep)

# Generate a dep file by using the C preprocessor
%.d: %.c
	@$(CPP) $(CPPFLAGS) $< -MM -MT $(@:.d=.o) >$@


.PHONY: clean
clean:
	rm -f upduino_sections.lds $(dep) $(obj) start.o $(src:.c=.s) *.elf *.hex *.bin
