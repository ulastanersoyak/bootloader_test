org 0
BITS 16
;https://en.wikibooks.org/wiki/X86_Assembly/X86_Architecture documentation for x86 asm registers
jmp 0x7C0:start; set code segment to 0x7C0
start:
    ;relying on bios initialization of segments might crash the bootloader so in this section segment registers
    ;are initialized without relying on bios so making it more hardware independent

    cli ;disable device interrputs. section below is critical and it must be initialized without any interruption.
    mov ax, 0x7C0
    mov ds, ax ;initialize data segment as 0x7C0 
    mov es, ax ;initialize extra segment as 0x7C0

    mov ax, 0x00
    ;stack grows downwards in memory. stack segment marks the start (bottom) of the stack and stack pointer always points to the top of the stack.
    ;https://stackoverflow.com/questions/24508207/bootloader-stack-configuration
    mov ss, ax ;initialize stack segment as 0x00
    mov sp, 0x7C00 ;initializing stack pointer at address 0x7C00 enables a 

    sti ;enable interrupt flag and exit critical section of the code.
    mov si, message
    call print
    jmp $
print:
    mov bx, 0
.loop:
    lodsb
    cmp al, 0
    je .done
    call printchar
    jmp .loop
.done:
    ret
printchar:
    ;http://www.ctyme.com/intr/rb-0106.htm documentation for this particular bios routine call
    mov ah, 0eh
    int 0x10 ;bios routine for character output
    ret
message : db 'hello world!', 0

times 510-($-$$) db 0;fills 510 bytes of data ($ -> current address $$ -> beginning of current section 
                    ;so $-$$ -> how far this in this section
dw 0xAA55;bios signature 55AA little endian