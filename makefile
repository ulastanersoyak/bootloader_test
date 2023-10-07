boot_binary := ./bin/boot.bin
virtual_machine := qemu-system-x86_64
SRC_DIR := ./src
BIN_DIR := ./bin
BUILD_DIR := ./build

FILES := $(BIN_DIR)/os.bin
BOOT_ASM_SRC := $(SRC_DIR)/bootloader/boot.asm
KERNEL_ASM_SRC := $(SRC_DIR)/kernel.asm
KERNEL_ASM_OBJ := $(BUILD_DIR)/kernel.asm.o

all: $(FILES)
	rm -rf $(BIN_DIR)/os.bin
	dd if=$(boot_binary) >> $(FILES)

$(boot_binary): $(BOOT_ASM_SRC) | $(BIN_DIR)
	nasm -f bin $(BOOT_ASM_SRC) -o $(boot_binary)

$(KERNEL_ASM_OBJ): $(KERNEL_ASM_SRC) | $(BUILD_DIR)
	nasm -f elf -g $(KERNEL_ASM_SRC) -o $(KERNEL_ASM_OBJ)

qemu: $(boot_binary)
	$(virtual_machine) -hda $(boot_binary)

clean:
	rm -rf $(BIN_DIR)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
