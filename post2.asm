; post2.asm - ADC y SBB: suma y resta de 32 bits en DX:AX
; Autora: Maria Fernanda Becerra Coronel (1152509)
; Compilar: nasm -f bin post2.asm -o post2.com
ORG 100h

DOS_CAR      equ 02h            ; INT 21h: imprimir caracter en DL
DOS_CADENA   equ 09h            ; INT 21h: imprimir cadena DS:DX terminada en "$"
DOS_SALIR    equ 4Ch            ; INT 21h: terminar programa
CF_BIT       equ 0001h          ; bit 0 del registro de flags

; A = 0001FFFFh = 131071, B = 00010001h = 65537
A_LO         equ 0FFFFh
A_HI         equ 0001h
B_LO         equ 0001h
B_HI         equ 0001h
; Resultados esperados
SUMA_LO      equ 0000h          ; A + B = 00030000h = 196608
SUMA_HI      equ 0003h
RESTA_LO     equ 0FFFFh         ; (A + B) - B = 0001FFFFh = 131071
RESTA_HI     equ 0001h

section .data
  aLo    dw A_LO
  aHi    dw A_HI
  bLo    dw B_LO
  bHi    dw B_HI
  resLo  dw 0
  resHi  dw 0
  flgLo  dw 0                   ; flags tras la operacion de las partes bajas
  msgSum db "Suma  0001:FFFF + 0001:0001 = $"
  msgRes db "Resta 0003:0000 - 0001:0001 = $"
  msgCF  db "   CF parte baja: $"
  msgSOk db "Suma OK: $"
  msgROk db "Resta OK: $"
  msgErr db "Error en la operacion.$"
  dosPt  db ":$"
  crlf   db 0Dh,0Ah,"$"

section .text
start:
  ; ---------- Suma de 32 bits: ADD (baja) + ADC (alta) ----------
  mov ax, [aLo]
  mov dx, [aHi]
  mov bx, [bLo]
  mov cx, [bHi]

  add ax, bx                    ; FFFFh + 0001h = 0000h, CF=1
  pushf
  pop word [flgLo]              ; POP no modifica los flags: CF sigue intacto
  adc dx, cx                    ; 0001h + 0001h + CF(1) = 0003h

  mov [resLo], ax
  mov [resHi], dx
  mov ah, DOS_CADENA
  mov dx, msgSum
  int 21h
  call mostrarResultado

  mov ax, [resLo]
  mov dx, [resHi]
  cmp ax, SUMA_LO
  jne .error
  cmp dx, SUMA_HI
  jne .error
  mov ah, DOS_CADENA
  mov dx, msgSOk
  int 21h
  call imprimirPar
  mov ah, DOS_CADENA
  mov dx, crlf
  int 21h

  ; ---------- Resta de 32 bits: SUB (baja) + SBB (alta) ----------
  mov ax, SUMA_LO               ; A' = 00030000h (el resultado de la suma)
  mov dx, SUMA_HI
  mov bx, [bLo]
  mov cx, [bHi]

  sub ax, bx                    ; 0000h - 0001h = FFFFh, CF=1 (prestamo)
  pushf
  pop word [flgLo]
  sbb dx, cx                    ; 0003h - 0001h - CF(1) = 0001h

  mov [resLo], ax
  mov [resHi], dx
  mov ah, DOS_CADENA
  mov dx, msgRes
  int 21h
  call mostrarResultado

  mov ax, [resLo]
  mov dx, [resHi]
  cmp ax, RESTA_LO
  jne .error
  cmp dx, RESTA_HI
  jne .error
  mov ah, DOS_CADENA
  mov dx, msgROk
  int 21h
  call imprimirPar
  mov ah, DOS_CADENA
  mov dx, crlf
  int 21h
  jmp .fin

.error:
  mov ah, DOS_CADENA
  mov dx, msgErr
  int 21h
  mov dx, crlf
  int 21h
.fin:
  mov ah, DOS_SALIR
  xor al, al
  int 21h

; ---- mostrarResultado: imprime resHi:resLo y el CF de la parte baja ----
mostrarResultado:
  call imprimirPar
  mov ah, DOS_CADENA
  mov dx, msgCF
  int 21h
  mov dl, "0"
  test word [flgLo], CF_BIT
  jz .listo
  mov dl, "1"
.listo:
  mov ah, DOS_CAR
  int 21h
  mov ah, DOS_CADENA
  mov dx, crlf
  int 21h
  ret

; ---- imprimirPar: imprime resHi:resLo en hexadecimal ----
imprimirPar:
  mov ax, [resHi]
  call impHex16
  mov ah, DOS_CADENA
  mov dx, dosPt
  int 21h
  mov ax, [resLo]
  call impHex16
  ret

; ---- impHex16: imprime AX como cuatro digitos hexadecimales ----
impHex16:
  push ax
  mov al, ah
  call impHex8                  ; byte alto
  pop ax
  call impHex8                  ; byte bajo
  ret

; ---- impHex8: imprime AL como dos digitos hexadecimales ----
impHex8:
  push ax
  push dx
  push ax
  shr al, 4                     ; nibble alto
  call digito
  pop ax
  and al, 0Fh                   ; nibble bajo
  call digito
  pop dx
  pop ax
  ret
digito:
  add al, "0"
  cmp al, "9"
  jbe .imp
  add al, 7                     ; saltar de "9" a "A"
.imp:
  mov dl, al
  mov ah, DOS_CAR
  int 21h
  ret
