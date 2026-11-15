; post1.asm - REP MOVSB: copia de cadena
; Autora: Maria Fernanda Becerra Coronel (1152509)
; Compilar: nasm -f bin post1.asm -o post1.com
ORG 100h

DOS_CAR      equ 02h            ; INT 21h: imprimir caracter en DL
DOS_CADENA   equ 09h            ; INT 21h: imprimir cadena DS:DX terminada en "$"
DOS_SALIR    equ 4Ch            ; INT 21h: terminar programa
LONG_CAD     equ 13             ; "HOLA, MUNDO!" (12) + terminador nulo
DF_BIT       equ 0400h          ; bit 10 del registro de flags

section .data
  origen  db "HOLA, MUNDO!",0
  destino times LONG_CAD db 0
  msgCop  db "Copiado: $"
  msgSI   db "SI avanzo: $"
  msgDI   db "  DI avanzo: $"
  msgCX   db "  CX final: $"
  msgDF   db "  DF: $"
  crlf    db 0Dh,0Ah,"$"
  finSI   dw 0
  finDI   dw 0
  finCX   dw 0
  finFlg  dw 0

section .text
start:
  ; Preparar ES = DS (en un .COM ya coinciden, pero se hace explicito)
  mov ax, ds
  mov es, ax

  ; Copiar 13 bytes de origen a destino
  mov si, origen
  mov di, destino
  mov cx, LONG_CAD
  cld                           ; DF=0: de baja a alta direccion
  rep movsb

  ; Guardar el estado de los registros justo despues de la copia
  mov [finSI], si
  mov [finDI], di
  mov [finCX], cx
  pushf
  pop word [finFlg]

  ; Mostrar el resultado
  mov ah, DOS_CADENA
  mov dx, msgCop
  int 21h
  mov si, destino
  call impZ
  mov ah, DOS_CADENA
  mov dx, crlf
  int 21h

  ; Mostrar cuanto avanzaron SI y DI, el CX final y el flag DF
  mov ah, DOS_CADENA
  mov dx, msgSI
  int 21h
  mov ax, [finSI]
  sub ax, origen
  call impDec

  mov ah, DOS_CADENA
  mov dx, msgDI
  int 21h
  mov ax, [finDI]
  sub ax, destino
  call impDec

  mov ah, DOS_CADENA
  mov dx, msgCX
  int 21h
  mov ax, [finCX]
  call impDec

  mov ah, DOS_CADENA
  mov dx, msgDF
  int 21h
  mov dl, "0"
  test word [finFlg], DF_BIT
  jz .df_listo
  mov dl, "1"
.df_listo:
  mov ah, DOS_CAR
  int 21h
  mov ah, DOS_CADENA
  mov dx, crlf
  int 21h

  mov ah, DOS_SALIR
  xor al, al
  int 21h

; ---- impZ: imprime la cadena DS:SI terminada en 0 (usa LODSB) ----
impZ:
  push ax
  push dx
  cld
.sig:
  lodsb                         ; AL = [DS:SI], SI avanza
  test al, al
  jz .fin
  mov dl, al
  mov ah, DOS_CAR
  int 21h
  jmp .sig
.fin:
  pop dx
  pop ax
  ret

; ---- impDec: imprime AX (0-65535) en decimal, sin ceros a la izquierda ----
impDec:
  push bx
  push cx
  push dx
  mov bx, 10
  xor cx, cx
.dividir:
  xor dx, dx
  div bx                        ; AX = cociente, DX = digito (resto)
  push dx
  inc cx
  test ax, ax
  jnz .dividir
.imprimir:
  pop dx
  add dl, "0"
  mov ah, DOS_CAR
  int 21h
  loop .imprimir
  pop dx
  pop cx
  pop bx
  ret
