[BITS 16]
[ORG 0x7C00]
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start
start:
    jmp 0x0000:stage2
	
stage2:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    call enable_a20
	
.load_protected:
    lgdt [gdt_descriptor]
    mov eax, cr0
    or  eax, 0x1
    mov cr0, eax
    jmp CODE_SEG:load32
enable_a20:
    call    .wait_input
    mov     al, 0xAD
    out     0x64, al
    call    .wait_input
    mov     al, 0xD0
    out     0x64, al
    call    .wait_output
    in      al, 0x60
    push    eax
    call    .wait_input
    mov     al, 0xD1
    out     0x64, al
    call    .wait_input
    pop     eax
    or      al, 2
    out     0x60, al
    call    .wait_input
    mov     al, 0xAE
    out     0x64, al
    call    .wait_input
    ret
	
.wait_input:
    in      al, 0x64
    test    al, 2
    jnz     .wait_input
    ret
	
.wait_output:
    in      al, 0x64
    test    al, 1
    jz      .wait_output
    ret
gdt_start:
gdt_null:
    dq 0x0
	
gdt_code:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00
	
gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00
	
gdt_end:
gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start
[BITS 32]
load32:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x200000
    mov eax, 1
    mov ecx, 100
    mov edi, 0x00010000
    call ata_lba_read 
    jmp CODE_SEG:0x00010000 ; a kernel in this address is needed for this to work
	
ata_lba_read:
    mov ebx, eax
    shr eax, 24
    or  eax, 0xE0
    mov dx, 0x1F6
    out dx, al
    mov eax, ecx
    mov dx, 0x1F2
    out dx, al
    mov eax, ebx
    mov dx, 0x1F3
    out dx, al
    mov eax, ebx
    shr eax, 8
    mov dx, 0x1F4
    out dx, al
    mov eax, ebx
    shr eax, 16
    mov dx, 0x1F5
    out dx, al
    mov dx, 0x1F7
    mov al, 0x20
    out dx, al
	
.next_sector:
    push ecx
	
.wait_drq:
    mov dx, 0x1F7
    in  al, dx
    test al, 8
    jz  .wait_drq
    mov ecx, 256
    mov dx, 0x1F0
    rep insw
    pop ecx
    loop .next_sector
    ret
	
times 510 - ($ - $$) db 0
dw 0xAA55
