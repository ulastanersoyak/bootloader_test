assembler = nasm
assembler_flags := -f bin
bootloader = ./src/bootloader/boot.asm
boot_binary = ./src/bin/boot.bin
virtual_machine = qemu-system-x86_64

boot: $(bootloader) | ./src/bin
	$(assembler) $(assembler_flags) $(bootloader) -o $(boot_binary)

qemu:
	$(virtual_machine) -hda $(boot_binary)

clean:
	rm -rf ./src/bin

./src/bin:
	mkdir -p ./src/bin
