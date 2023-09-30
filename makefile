assembler = nasm
assembler_flags := -f bin
bootloader = ./src/bootloader/boot.asm
boot_binary = ./src/bin/boot.bin
virtual_machine = qemu-system-x86_64

boot: $(bootloader) | ./src/bin
	$(assembler) $(assembler_flags) $(bootloader) -o $(boot_binary)
# appending the contents of 'msg.txt' from the './src/bootloader/' directory
# to 'boot.bin' located in './src/bin/'. this combines text data with binary data
	dd if=./src/bootloader/msg.txt >> ./src/bin/boot.bin
# adding a 512-byte block of null bytes to 'boot.bin' to ensure it's the standard
# boot sector size. this is common practice in bootloader development
	dd if=/dev/zero bs=512 count=1 >> ./src/bin/boot.bin

qemu:
	$(virtual_machine) -hda $(boot_binary)

clean:
	rm -rf ./src/bin

./src/bin:
	mkdir -p ./src/bin
