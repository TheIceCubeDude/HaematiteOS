;;The MBR lets the user select a VBR to boot
start:
;;Setup stack and segments
mov esp, 0x600 ;;Stack grows downwards
xor ax, ax
mov ss, ax
mov ds, ax
mov es, ax
;;Relocate to 0x600
mov esi, 0x7C00
mov edi, esp
mov ecx, 512
rep movsb

;;Jump to relocated MBR
jmp 0:main ;;Force absolute jump, but also CS may be non-zero (eg. The BIOS may load us at 0x7C0:0x0 rather than 0x0:0x7C00)

main:
;;Save boot drive number
push dx
;;Print info
mov ecx, BOOT_STR
call print_string
;;Print MBR partitions (that are non-zero size)
mov al, 0x2F
mov ebx, partition_1 - 16 + 12 
check_partitions:
add ebx, 16
inc al
cmp al, 4
je get_input
cmp dword [ebx], 0
je check_partitions
push ebx
push ax
call print
mov al, ' '
call print
pop ax
pop ebx
jmp check_partitions

get_input:
xor ax, ax
int 0x16
sub al, 0x30
shl ax, 8 ;;Get rid of scancode in AH
shr ax, 8
cmp ax, 4
jae get_input

load_vbr:
;;Check for Int 0x13 extentions support
pop dx
push dx
push ax
mov ah, 0x41
mov bx, 0x55AA
int 0x13
jc int13_extention_err
;;Extended read the VBR
pop cx
mov dx, 0
mov eax, 16
mul cx
add ax, partition_1
mov ebx, [eax + 12]
cmp ebx, 0 ;;Check if the selected partition has a zero size
je get_input
mov ebx, [eax + 8]
mov [DAP.lba], ebx
mov [DAP.offset], word 0x7C00
pop dx
push ax
mov ah, 0x42
mov esi, DAP
int 0x13
;;Jump to loaded VBR (if it failed to load it will just run MBR again)
mov ecx, VBR_SEP_STR
call print_string
xor esi, esi
pop si
jmp 0x7C00

int13_extention_err:
mov ecx, INT13_EXTENTION_ERR_STR
call print_string
hlt

print:
;;AL = char
mov ah, 0xE
xor bx, bx
int 0x10
ret

%include "boot/util/misc.asm"

INT13_EXTENTION_ERR_STR: db 0xA, 0xD, "-> Int 13h extentions not supported on this system/boot media", 0
BOOT_STR: db 0xA, 0xA, 0xD, "-> HaematiteOS MBR <-", 0xA, 0xA, 0xD, "-> Which partition number would you like to boot? Type the number now.", 0xA, 0xD, "-> Avaliable partitions:   ", 0
VBR_SEP_STR: db 0xA, 0xA, 0xD, 0
