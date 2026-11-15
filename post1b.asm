; post1b.asm - REP MOVSW + MOVSB: copia optimizada por palabras
; Autora: Maria Fernanda Becerra Coronel (1152509)
; Compilar: nasm -f bin post1b.asm -o post1b.com
ORG 100h

DOS_CAR      equ 02h            ; INT 21h: imprimir caracter en DL
DOS_CADENA   equ 09h            ; INT 21h: imprimir cadena DS:DX terminada en "$"
DOS_SALIR    equ 4Ch            ; INT 21h: terminar programa
LONG_CAD     equ 13             ; longitud impar a proposito: 6 words + 1 byte

section .data
  origen  db "HOLA, MUNDO!",0
  destino times LONG_CAD db 0
  msgCop  db "Copiado con MOVSW: $"
  msgW    db "Words copiadas: $"
  msgB    db "  Byte sobrante: $"
  msgOk   db "Verificacion: destino identico al origen$"
  msgMal  db "Verificacion: destino DIFERENTE del origen$"
  crlf    db 0Dh,0Ah,"$"
  nWords  dw 0
  nSuelto dw 0

section .text
start:
  mov ax, ds
  mov es, ax
  mov si, origen
  mov di, destino
  mov cx, LONG_CAD              ; longitud total
  cld

  mov ax, cx
  shr cx, 1                     ; CX = 13 / 2 = 6 words
  mov [nWords], cx
  rep movsw                     ; copiar 6 words (12 bytes)

  and ax, 1                     ; habia byte impar? (13 AND 1 = 1)
  mov [nSuelto], ax
  jz  .copiado
  movsb                         ; copiar el byte sobrante (posicion 13)
.copiado:

  ; Mostrar destino
  mov ah, DOS_CADENA
  mov dx, msgCop
  int 21h
  mov si, destino
  call impZ
  mov ah, DOS_CADENA
  mov dx, crlf
  int 21h

  ; Mostrar cuantas words y bytes sueltos se movieron
  mov ah, DOS_CADENA
  mov dx, msgW
  int 21h
  mov ax, [nWords]
  call impDec
  mov ah, DOS_CADENA
  mov dx, msgB
  int 21h
  mov ax, [nSuelto]
  call impDec
  mov ah, DOS_CADENA
  mov dx, crlf
  int 21h

  ; Verificar byte a byte que destino == origen (los 13 bytes)
  mov si, origen
  mov di, destino
  mov cx, LONG_CAD
  cld
  repe cmpsb
  mov dx, msgOk
  je  .mostrar
  mov dx, msgMal
.mostrar:
  mov ah, DOS_CADENA
  int 21h
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
