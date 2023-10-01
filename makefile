assembler := nasm
assembler_flags := -f bin
bootloader := ./src/bootloader/boot.asm
boot_binary := ./bin/boot.bin
virtual_machine := qemu-system-x86_64

all: ./bin
	$(assembler) $(assembler_flags) $(bootloader) -o $(boot_binary)

qemu:
	$(virtual_machine) -hda $(boot_binary)

clean:
	rm -rf ./bin

./bin:
	mkdir -p ./bin
