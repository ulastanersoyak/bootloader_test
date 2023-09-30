org 0
BITS 16
jmp 0x7C0:start
start:
    cli ;disable device interrputs. section below is critical and it must be initialized without any interruption.
    mov ax, 0x7C0 ;manually set data segment
    mov ds, ax ;initialize data segment with desired value
    mov es, ax
    mov ax, 0x00
    mov ss, ax ;initialize stack
    mov sp, 0x7C00
    sti ;enable interrupt flag
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
    ;https://en.wikibooks.org/wiki/X86_Assembly/X86_Architecture documentation for x86 asm registers
    mov ah, 0eh
    int 0x10 ;bios routine for character output
    ret
message : db 'hello world!', 0

times 510-($-$$) db 0;fills 510 bytes of data ($ -> current address $$ -> beginning of current section 
                    ;so $-$$ -> how far this in this section
dw 0xAA55;bios signature 55AA little endian