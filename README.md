# updosoc
Upduino 2.0 SoC based on PicoRV32/PicoSoC. Just for education and entertainment

The first commit of this project is based on [this repo](https://github.com/void-spark/picorv32),
which is a fork of [PicoSoC](https://github.com/cliffordwolf/picorv32/tree/master/picosoc) with the minimal tweaks needed for Upduino v2.0 support.

I hope to add more features and different firmwares to this over time :)

## Current setup
An Upduino 2.0 with:
- With it's PIN 35, and PIN J6 (12Mhz clock) connected using a 470 ohm resistor. To give it a more stable clock.
- With PIN 46 connected to TX of an external UART using a 470 ohm resistor.
- With PIN 45 connected to RX of an external UART using a 470 ohm resistor.
- With GND connected between the Upduino and the external UART (obvious, but annoying to forget :) )

The 470 ohm resistors are just to prevent accidents if an input port is accidentally set as output.

I use a CP2102 as external UART.
With the default divider (104 in firmware.c) and 12Mhz clock, baudrate is 115384.6, so using 115200 should work.

So far this works!

## Known issues
 - The flash chip (W25Q32JV) on the Upduino v2.0 only has two IO pins connected to the FPGA. So you're not getting any Quad SPI to it.
 - The simple uart does not do any buffering, so if characters are sent quickly, your code might miss most of them. Use a terminal that sends every character seperatly when you type it.
 - If I leave my CP2102 unpowered, the cpu doesn't run. Can be solved by just disconnecting it from TX/RX. Really not sure why that is yet..
 - The RGB led is bright even at the lowest power setting, since we don't do PWM.
 - First time flashing new firmware after running the cpu always fails for me. I guess the flash chip is in a funny mode, or the cpu interferes?
 