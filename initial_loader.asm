org 0x7c00


Start: jmp LOADER

;; needed messages
msg_start db "Welcome To DENOS !",0xd,0xa,0xd,0xa,0
msg_io_disk_reset db "IO Op: disk reset...",0xd,0xa,0
msg_io_disk_read db "IO Op: disk read...",0xd,0xa,0
msg_io_disk_done db "IO Op: disk done!",0xd,0xa,0xd,0xa,0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; bios interrupts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; BIOS interrupt reset hard drive
;; INT 0x13
;; Function 0x0 -> Reset
;;	AH = 0x0
;; Reset hard drive
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; BIOS interrupt read hard drive
;; INT 0x13
;; Function 0x02 -> Read
;;	AH = 0x02
;;	AL = Number of sectors to read
;;	CH = Low eight bits of cylinder number
;;	CL = Sector number (Bits 0-5). Bits 6-7 are cylinder higher bits for hard disk only
;;	DH = Head number
;;	DL = Drive number // 0x0 for floppy, 0xF0 for hard drive
;;	ES:BX = Buffer to read sectors to
;; Returns:
;;	AH = Status code
;;	AL = Number of sectors read
;;	CF = Set if failure, cleared is successfull
;; Read hard drive
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; BIOS interrupt
;; INT 0x10
;; Function 0x0e -> Print
;; AH = 0x0e
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; STR PRINT
PRINT:
	mov si,ax				; get address of string as parameter in ax
	mov ax,cs				; messages in code segment
	mov ds,ax				; so ds is same with cs
	.print:
	mov ah,0x0e
	lodsb					; load al from DS:SI
	or al,al				; check if al is zero or not
	jz .print_done			; if zero go to done(ret)
	int 0x10				; call interrupt
	jmp .print
	.print_done:
		ret
;; END PRINT

;; STR READ_SECTOR
READ_SECTOR:
		push dx
		; arguments, ax is drive number
		mov dl,al
		; arguments, bx is cyclinder number
		mov ax,cx					; store cx in ax, sector number
		mov ch,bl					; low eight bits of cyclinder number
		and bx,0xff00				; 0 bl
		shl bx,0x6
		xor cl,cl
		or cl,bh					; higher bits of cyclinder number, cx = cccccccc cc000000
		; arguments, cl is sector number is in al now
		; arguments, ch is head number is in ah now
		and al,0x3f
		xor cl,al					; cx = cccccccc ccssssss
		mov dh,ah					; head number
		; arguments, dx is offset for buffer
		pop bx						; get dx to ax
	.reset:
		mov ax,msg_io_disk_reset
		call PRINT					; print the operation
		
		xor ah,ah					; function reset
		xor dl,dl					; floppy disk
		int 0x13
		jc .reset					; if error, try again reset
		mov ax,msg_io_disk_done
		call PRINT
	.read:
		mov ax,msg_io_disk_read
		call PRINT					; print the operation

		mov ah,0x2					; function read
		mov al,0x1					; 1 sector to read
		int 0x13
		jc .read					; if error try again read
		mov ax,msg_io_disk_done
		call PRINT
		ret
		
;; END READ_SECTOR


LOADER:

	mov ax,msg_start
	call PRINT						; Welcome message

	mov ax,0x1000
	mov es,ax						; buffer's start address to read
	mov ax,0x0						; driver number, floppy now
	mov bx,0x0						; cyclinder number
	mov cl,0x2						; sector number
	mov ch,0x0						; head number
	mov dx,0x0						; buffer's offset
	call READ_SECTOR				; read second sector

	jmp 0x1000:0x0

	times 510 - ($-$$) db 0x0
	dw 0xAA55						; bootable device signature
