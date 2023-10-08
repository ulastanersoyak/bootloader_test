; a bootloader is a small program (512 bytes) that sets up the environment for the kernel and loads it into memory
; it's typically written in 16-bit assembly for backward compatibility with x86 processors
; why 16-bit?
; the x86 processors start in 16-bit real mode. real mode is simpler, making it suitable for bootloaders
; bootloader's role:
; - initializes hardware
; - loads the kernel into memory
; - passes control to the kernel
; bios (basic input output system):
; - located in rom (read-only memory)
; - loads the bootloader into memory
; - kicks off the boot process
; transition to 32-bit:
; bootloaders may transition to 32-bit or 64-bit mode for modern operating systems that require it
; real mode vs. protected mode:
; - real mode: simple, limited to 1 mb, no memory protection
; - protected mode: provides memory protection and access to more memory
;for further reading :
;https://stackoverflow.com/questions/26539603/why-bootloaders-for-x86-use-16bit-code-first
;https://www.quora.com/Why-do-CPUs-start-executing-code-in-16-bit-mode

org 0x7C00
BITS 16
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start
_start:
    jmp short start
    nop
    times 33 db 0 ;fill the bios parameter blocks bytes with null
start:
    jmp 0:step2; set code segment to 0x7C0

step2:
    ;relying on bios initialization of segments might crash the bootloader so in this section segment registers
    ;are initialized without relying on bios so making it more hardware independent
    cli ;disable device interrputs. section below is critical and it must be initialized without any interruption.

    mov ax, 0x00
    mov ds, ax ;initialize data segment as 0x7C0 
    mov es, ax ;initialize extra segment as 0x7C0

    ;stack grows downwards in memory. stack segment marks the start (bottom) of the stack and stack pointer 
    ;always points to the top of the stack. https://stackoverflow.com/questions/24508207/bootloader-stack-configuration
    mov ss, ax ;initialize stack segment as 0x00
    mov sp, 0x7C00 ;initializing stack pointer at address 0x7C00 enables a 

    sti ;enable interrupt flag and exit critical section of the code.

.load_protected:
    cli
    lgdt[gdt_descriptor]
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    jmp CODE_SEG:load32

; GDT
gdt_start:
gdt_null:
    dd 0x0
    dd 0x0
; offset 0x8
gdt_code:     ; CS SHOULD POINT TO THIS
    dw 0xffff ; segment limit first 0-15 bits
    dw 0      ; base first 0-15 bits
    db 0      ; base 16-23 bits
    db 0x9a   ; access byte
    db 11001111b ; high 4 bit flags and the low 4 bit flags
    db 0        ; base 24-31 bits

; offset 0x10
gdt_data:      ; DS, SS, ES, FS, GS
    dw 0xffff ; segment limit first 0-15 bits
    dw 0      ; base first 0-15 bits
    db 0      ; base 16-23 bits
    db 0x92   ; access byte
    db 11001111b ; high 4 bit flags and the low 4 bit flags
    db 0        ; base 24-31 bits

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start-1
    dd gdt_start

[BITS 32]
load32:
  mov eax, 1 ;sector to load from. sector 0 is bootloader and kernel starts from sector 1
  mov ecx, 100 ;number of total sectors declared in makefiles linker part (dd if=/dev/zero bs=512 count=100 >> ./bin/os.bin)
  mov edi, 0x0100000 ;address to load kernel into
  call ata_lba_read
  jmp CODE_SEG:0x0100000

ata_lba_read:
  mov ebx, eax ;backup lba (logical block addressing)
  ;send highest 8 bits of lba to hard disk controller
  shr eax, 24 ;shift right by 24 bits giving highest 8 bits as result
  or eax, 0xE0 ;select master drive
  mov dx, 0x1F6 ;port
  out dx, al ;sent highest 8 bits to lba
  ;send the total to read
  mov eax, ecx
  mov dx, 0x1F2
  out dx, al ;finished sending
  ;send more bits of lba
  mov eax ,ebx ;restore backup lba
  mov dx, 0x1F3
  out dx, al
  ;finised sending more bits
  mov dx, 0x1F4
  mov eax,ebx 
  shr eax, 8
  out dx, al
  ;send upper 16 bits of lba
  mov dx, 0x1F5
  mov eax ,ebx ;restore backup lba
  shr eax, 16
  out dx, al
  ;finished upper 16 bits
  mov dx, 0x1F7
  mov al, 0x20
  out dx, al
  ;read all sectors into memory
.next_sector:
  push ecx

.try_again: ; check if more reads needed
  mov dx, 0x1F7
  in al, dx
  test al, 8
  jz .try_again

  ;read 256 words at a time (512 bytes = 1 sector)
  mov ecx, 256
  mov dx, 0x1F0
  rep insw ;reads word ecx times (256 in this case) from the porx 0x1F0 and stores it do the edi register (0x0100000 in this case)
  pop ecx 
  loop .next_sector
  ;end of reading sectors into memory
  ret

times 510-($-$$) db 0;fills 510 bytes of data ($ -> current address $$ -> beginning of current section 
                    ;so $-$$ -> how far this in this section
dw 0xAA55;bios recognizes the bootloader from the signatur of 0x55AA on last 2 bytes of the 512 byte block. it is written reverse
;because intel processors are little endian. https://stackoverflow.com/questions/22030657/little-endian-vs-big-endian
