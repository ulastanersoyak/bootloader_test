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
org 0
BITS 16
;some bios programs expects bios parameter blocks at certain offsets. in order to make this bootloader usable on most
;of the hardware, bios parameter blocks must be set at the required offsets, else the bios might corrupt bootloader when
;it overrides the bootloader with its own parameters.
;https://wiki.osdev.org/FAT for mor information about bios parameter blocks
;https://en.wikibooks.org/wiki/X86_Assembly/X86_Architecture documentation for x86 asm registers
_start:
    jmp short start
    nop
    times 33 db 0;fill the bios parameter blocks bytes with null
start:
    jmp 0x7C0:step2; set code segment to 0x7C0
    ;relying on bios initialization of segments might crash the bootloader so in this section segment registers
    ;are initialized without relying on bios so making it more hardware independent

;interrupts are signal to the cpu. below is a custom implementation of interrupt 0. https://wiki.osdev.org/Interrupts.
;when int 0 gets called, it will jump here
;handle_zero: ;code implementation of interrupt 0
;   mov ah, 0eh
;   mov al, 'A'
;   mov bx, 0x00
;   int 0x10 ;a bios interrupt for video services
;   iret ;return from interrupt

step2:
    cli ;disable device interrputs. section below is critical and it must be initialized without any interruption.

    mov ax, 0x7C0
    mov ds, ax ;initialize data segment as 0x7C0 
    mov es, ax ;initialize extra segment as 0x7C0

    ;stack grows downwards in memory. stack segment marks the start (bottom) of the stack and stack pointer 
    ;always points to the top of the stack. https://stackoverflow.com/questions/24508207/bootloader-stack-configuration
    mov ax, 0x00
    mov ss, ax ;initialize stack segment as 0x00
    mov sp, 0x7C00 ;initializing stack pointer at address 0x7C00 enables a 

    sti ;enable interrupt flag and exit critical section of the code.

    ;http://www.ctyme.com/intr/rb-0607.htm documentation for reading from disk interrupt. code below just
    ;implements the requirements for the reading. if you are curious about the magic numbers take a look at the link
    mov ah, 2 ;read sector command
    mov al, 1 ;read one sector command
    mov ch, 0 ;cylinder number 0
    mov cl, 2 ;read sector 2
    mov dh, 0 ;head number 0 
    mov bx, buffer
    int 0x13
    jc error ;jump to error if carry flag is set. carry flag is set when interrupt 0x13 fails
    mov si,buffer ;if not failed, print message to the screen
    call print
    jmp $
error:
    mov si, err_message
    call print

;    mov word[ss:0x00], handle_zero ; interrupts are 4 bytes long in the interrupt vector table. first 2 bytes are for offset 
;   mov word[ss:0x02], 0x7C0 ;and last 2 is for segments. so here interrupt 0 is set to the address of 00:7xC0 to 00:7xC2
;   int 0;here is an interrupt call for 0. interrupt 0 is called when divide by 0 exception occurs (https://wiki.osdev.org/Exceptions)
;   ;code below forces a call for interrupt 0 even though interrupt 0 is not called, it will execute
;   mov ax, 0x00 ;load a register with 0
;   div ax ;divide a with itself resulting in a interrupt 0 call
;   mov si, message
;   call print

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
;message : db 'hello world!', 0
err_message : db 'failed to load sector', 0
times 510-($-$$) db 0;fills 510 bytes of data ($ -> current address $$ -> beginning of current section 
                    ;so $-$$ -> how far this in this section
dw 0xAA55;bios recognizes the bootloader from the signatur of 0x55AA on last 2 bytes of the 512 byte block. it is written reverse
;because intel processors are little endian. https://stackoverflow.com/questions/22030657/little-endian-vs-big-endian
buffer:;for reading from disk. its below to ensure reading will not overwrite any code