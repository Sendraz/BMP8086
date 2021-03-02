.8086
.model small
.stack 140h
.data	
buf db 64000 dup (?)
msg1 db "BMP file reader 8086 v1.0 by Sendraz",10,"$"
err1 db 10,"ERROR: NO FILE WAS FOUND!$"	
err2 db 10,"ERROR: NOT AN BMP FILE!$"
fnlen db 13
fnact db ?
fname db 13 dup(0)
resa dw ?
curfile dw ?
hdr dw 27 dup (?)
palette db 256*4 dup (?)

.code
Start:
	mov ax, @data
	mov ds, ax
	mov dx, offset msg1
	mov ah, 9
	int 21h
InputFile:
	mov ah, 0Ah
	mov dx, offset fnlen
	int 21h
	
	xor bx,bx
findCR:
	mov si, offset fname
	mov bl,[fnlen+1]
	mov byte ptr[bx+si],0
LoadFile:
	mov ah, 3Dh
	mov al, 0
	mov dx, offset fname
	int 21h
	jc Error1
	mov curfile, ax
	
ReadHeader:
	mov ah, 3Fh
	mov bx, curfile
	mov cx, 54 ;size of the header
	mov dx, offset hdr
	int 21h
CheckHeader:
	mov ax, hdr
	cmp ax, 4D42h ;default bmp header
	jne Error2
ReadPal:	
	mov ah, 3Fh
	mov bx, curfile
	mov cx, 1024 ;size of the color palette
	mov dx, offset palette
	int 21h
	jmp CalculateImgSize
	
Error1:
	mov dx, offset err1
	mov ah, 9
	int 21h
	jmp QUIT
Error2:
	mov dx, offset err2
	mov ah, 9
	int 21h
	jmp QUIT
CalculateImgSize:
	mov ax, hdr[12h] ;x size (line counter)
	
	mov bx, hdr[16h];y size
	
	mul bx
	mov resa, ax
ReadImage:
	mov ah, 3Fh
	mov bx, curfile
	mov cx, resa
	mov dx, offset buf
	int 21h
GFXMODE:
	;set graphics mode 
	mov al, 13h
	mov ah, 0
	int 10h
	call ChangePalette
	
	mov di, 0 ;vga offset
	mov ax, 0A000h;vga segment
	mov es, ax ;move ax to es
	
	
	mov bx, hdr[12h];x size (line counter)
	mov cx, hdr[16h];y size
	
	xor ax, ax
	mov si, resa
ReverseBytes:
	dec si
	mov al, [ds:si] ;bmp file pixels	
	push ax	
	dec bx
	jnz ReverseBytes
	mov bx, hdr[12h]
DisplayLineLoop:
	pop ax
	mov [es:di], al ;vga pixel buffer
	inc di	
	dec bx
	jnz DisplayLineLoop
.NewLine:
	mov ax, 320
	sub ax, hdr[12h]
	add di, ax	
	mov bx, hdr[12h] 
	
	cmp si, 0
	jne ReverseBytes
	
	
WaitForInput:
	mov ah, 0Bh
	int 21h
	cmp al, 0FFh
	jne WaitForInput

CloseFile:
	mov ah, 3Eh
	mov bx, curfile
	int 21h
	jmp QUIT
QUIT:
	mov ah, 4Ch
	int 21h
	
ChangePalette:
	mov si, offset palette
	mov cx, 256
	mov dx, 3C8h
	mov al, 0
	
	out dx, al
	inc dx ;change to 3C9h
SetPalette:
	;red
	mov al,[si+2]
	shr al, 2
	out dx, al
	
	;green
	mov al, [si+1]
	shr al, 2
	out dx, al
	
	;blue
	mov al, [si]
	shr al, 2
	out dx, al
	
	;next
	add si, 4
	dec cx
	jnz SetPalette
	ret
end
	



