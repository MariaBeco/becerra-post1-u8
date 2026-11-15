; post1d.asm - REPE CMPSB: comparar cadenas
; Autora: Maria Fernanda Becerra Coronel (1152509)
; Compilar: nasm -f bin post1d.asm -o post1d.com
ORG 100h

DOS_CAR      equ 02h            ; INT 21h: imprimir caracter en DL
DOS_CADENA   equ 09h            ; INT 21h: imprimir cadena DS:DX terminada en "$"
DOS_SALIR    equ 4Ch            ; INT 21h: terminar programa
LONG_CMP     equ 8              ; las tres cadenas miden 8 caracteres

section .data
  cad1    db "NASM x86",0
  cad2    db "NASM x86",0
  cad3    db "NASM ARM",0
  msgC12  db "cad1 vs cad2: $"
  msgC13  db "cad1 vs cad3: $"
  msgIg   db "Iguales.$"
  msgDif  db "Diferentes.$"
  msgPos  db " Primera diferencia en posicion $"
  msgCar  db " ('$"
  msgVs   db "' vs '$"
  msgFin  db "')$"
  crlf    db 0Dh,0Ah,"$"

section .text
start:
  mov ax, ds
  mov es, ax

  ; Caso 1: cad1 vs cad2 (deben ser iguales)
  mov ah, DOS_CADENA
  mov dx, msgC12
  int 21h
  mov si, cad1
  mov di, cad2
  call compararCadenas

  ; Caso 2: cad1 vs cad3 (deben ser diferentes)
  mov ah, DOS_CADENA
  mov dx, msgC13
  int 21h
  mov si, cad1
  mov di, cad3
  call compararCadenas

  mov ah, DOS_SALIR
  xor al, al
  int 21h

; ---- compararCadenas: compara LONG_CMP bytes de DS:SI y ES:DI con REPE CMPSB ----
compararCadenas:
  mov bx, si                    ; inicio de la primera cadena
  mov cx, LONG_CMP
  cld
  repe cmpsb
  je  .iguales

  ; SI y DI quedaron un byte despues del primer caracter distinto
  push si
  push di
  mov ah, DOS_CADENA
  mov dx, msgDif
  int 21h
  mov dx, msgPos
  int 21h
  mov ax, si
  sub ax, bx
  dec ax                        ; posicion base 0
  call impDec
  mov ah, DOS_CADENA
  mov dx, msgCar
  int 21h
  pop di
  pop si
  mov dl, [si-1]
  mov ah, DOS_CAR
  int 21h
  mov ah, DOS_CADENA
  mov dx, msgVs
  int 21h
  mov dl, [es:di-1]
  mov ah, DOS_CAR
  int 21h
  mov ah, DOS_CADENA
  mov dx, msgFin
  int 21h
  jmp .fin

.iguales:
  mov ah, DOS_CADENA
  mov dx, msgIg
  int 21h
.fin:
  mov ah, DOS_CADENA
  mov dx, crlf
  int 21h
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
