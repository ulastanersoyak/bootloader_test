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
    dw 0xffff ; Segment limit first 0-15 bits
    dw 0      ; Base first 0-15 bits
    db 0      ; Base 16-23 bits
    db 0x9a   ; Access byte
    db 11001111b ; High 4 bit flags and the low 4 bit flags
    db 0        ; Base 24-31 bits

; offset 0x10
gdt_data:      ; DS, SS, ES, FS, GS
    dw 0xffff ; Segment limit first 0-15 bits
    dw 0      ; Base first 0-15 bits
    db 0      ; Base 16-23 bits
    db 0x92   ; Access byte
    db 11001111b ; High 4 bit flags and the low 4 bit flags
    db 0        ; Base 24-31 bits

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start-1
    dd gdt_start
[BITS 32]
load32:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov ebp, 0x00200000
    mov esp, ebp
    in al, 0x92
    ;https://wiki.osdev.org/A20_Line enabling a20 line.
    or al, 2
    out 0x92, al
    jmp $
times 510-($-$$) db 0;fills 510 bytes of data ($ -> current address $$ -> beginning of current section 
                    ;so $-$$ -> how far this in this section
dw 0xAA55;bios recognizes the bootloader from the signatur of 0x55AA on last 2 bytes of the 512 byte block. it is written reverse
;because intel processors are little endian. https://stackoverflow.com/questions/22030657/little-endian-vs-big-endian