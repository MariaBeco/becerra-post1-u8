; post1e.asm - LODSB + STOSB: copia con transformacion a mayusculas
; Autora: Maria Fernanda Becerra Coronel (1152509)
; Compilar: nasm -f bin post1e.asm -o post1e.com
ORG 100h

DOS_CAR      equ 02h            ; INT 21h: imprimir caracter en DL
DOS_CADENA   equ 09h            ; INT 21h: imprimir cadena DS:DX terminada en "$"
DOS_SALIR    equ 4Ch            ; INT 21h: terminar programa
LONG_CAD     equ 13             ; "hola, mundo!" (12) + terminador nulo
DIF_MAYUS    equ 20h            ; 'a' - 'A' = 61h - 41h

section .data
  origen  db "hola, mundo!",0
  destino times LONG_CAD db 0
  msgOri  db "Origen:       $"
  msgCop  db "Transformado: $"
  crlf    db 0Dh,0Ah,"$"

section .text
start:
  mov ax, ds
  mov es, ax

  mov si, origen
  mov di, destino
  mov cx, LONG_CAD
  cld

.bucle:
  lodsb                         ; AL = [DS:SI], SI avanza automaticamente
  cmp al, 'a'
  jb .escribir                  ; AL < 'a': no es minuscula, no se transforma
  cmp al, 'z'
  ja .escribir                  ; AL > 'z': no es minuscula, no se transforma
  sub al, DIF_MAYUS             ; 'a'-'z' -> 'A'-'Z'
.escribir:
  stosb                         ; [ES:DI] = AL, DI avanza automaticamente
  loop .bucle

  mov ah, DOS_CADENA
  mov dx, msgOri
  int 21h
  mov si, origen
  call impZ
  mov ah, DOS_CADENA
  mov dx, crlf
  int 21h

  mov ah, DOS_CADENA
  mov dx, msgCop
  int 21h
  mov si, destino
  call impZ
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
