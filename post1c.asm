; post1c.asm - REPNE SCASB: buscar un caracter en una cadena
; Autora: Maria Fernanda Becerra Coronel (1152509)
; Compilar: nasm -f bin post1c.asm -o post1c.com
ORG 100h

DOS_CAR      equ 02h            ; INT 21h: imprimir caracter en DL
DOS_CADENA   equ 09h            ; INT 21h: imprimir cadena DS:DX terminada en "$"
DOS_SALIR    equ 4Ch            ; INT 21h: terminar programa
CAR_EXISTE   equ "d"            ; aparece en "de" (posicion 13)
CAR_NO_EXISTE equ "z"           ; no aparece en la cadena

section .data
  cadena  db "Arquitectura de Computadores",0
  LONG_CAD equ $ - cadena - 1   ; 28: longitud sin el nulo, calculada por NASM
  msgBus  db "Buscar '$"
  msgCie  db "': $"
  msgHall db "hallado en posicion $"
  msgCX   db "  (CX restante: $"
  msgPar  db ")$"
  msgNoH  db "No encontrado.$"
  crlf    db 0Dh,0Ah,"$"

section .text
start:
  mov ax, ds
  mov es, ax

  mov al, CAR_EXISTE
  call buscarCaracter
  mov al, CAR_NO_EXISTE
  call buscarCaracter

  mov ah, DOS_SALIR
  xor al, al
  int 21h

; ---- buscarCaracter: busca AL en "cadena" con REPNE SCASB e imprime el resultado ----
buscarCaracter:
  mov bl, al                    ; conservar el caracter buscado
  mov ah, DOS_CADENA
  mov dx, msgBus
  int 21h
  mov dl, bl
  mov ah, DOS_CAR
  int 21h
  mov ah, DOS_CADENA
  mov dx, msgCie
  int 21h

  mov al, bl
  mov di, cadena
  mov cx, LONG_CAD
  cld
  repne scasb
  jne .noHallado                ; ZF=0 al terminar -> no encontrado

  ; Posicion base 0: DI quedo un byte despues del caracter hallado
  mov bx, cx                    ; conservar CX restante
  mov ax, di
  sub ax, cadena
  dec ax
  push ax
  mov ah, DOS_CADENA
  mov dx, msgHall
  int 21h
  pop ax
  call impDec
  mov ah, DOS_CADENA
  mov dx, msgCX
  int 21h
  mov ax, bx
  call impDec
  mov ah, DOS_CADENA
  mov dx, msgPar
  int 21h
  jmp .fin

.noHallado:
  mov ah, DOS_CADENA
  mov dx, msgNoH
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
