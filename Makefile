
upload: hardware.bin firmware.bin
	stty -F /dev/ttyACM0 raw -echo 115200
	cat hardware.bin >/dev/ttyACM0

hardware.json: hardware.v spimemio.v simpleuart.v picosoc.v picorv32.v iceioddr.v wbsdram.v genuctrl.v sdram.v
	yosys -ql hardware.log -p 'synth_ice40 -top hardware -json hardware.json' $^

hardware.asc: hardware.pcf hardware.json
	nextpnr-ice40 --freq 25 --hx8k --package tq144:4k --json hardware.json --pcf hardware.pcf --asc hardware.asc --opt-timing --placer heap
hardware.bin: hardware.asc
	icetime -d hx8k -c 20 -mtr hardware.rpt hardware.asc
	icepack -s hardware.asc hardware.bin

firmware.elf: sections.lds start.S firmware.c 
	/opt/riscv32i/bin/riscv32-unknown-elf-gcc -march=rv32imc -nostartfiles -Wl,-Bstatic,-T,sections.lds,--strip-debug,-Map=firmware.map,--cref  -ffreestanding -nostdlib -o firmware.elf start.S firmware.c

firmware.bin: firmware.elf
	/opt/riscv32i/bin/riscv32-unknown-elf-objcopy -O binary firmware.elf /dev/stdout > firmware.bin

clean:
	rm -f firmware.elf firmware.hex firmware.bin firmware.o firmware.map \
	      hardware.json hardware.log hardware.asc hardware.rpt hardware.bin




