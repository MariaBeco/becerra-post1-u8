; post2c.asm - MUL/DIV: calculadora de digitos con conversion ASCII/binaria
; Autora: Maria Fernanda Becerra Coronel (1152509)
; Compilar: nasm -f bin post2c.asm -o post2c.com
ORG 100h

DOS_CAR      equ 02h            ; INT 21h: imprimir caracter en DL
DOS_CADENA   equ 09h            ; INT 21h: imprimir cadena DS:DX terminada en "$"
DOS_SALIR    equ 4Ch            ; INT 21h: terminar programa
DOS_LEER     equ 01h            ; INT 21h: leer caracter con eco -> AL
ASCII_0      equ 30h            ; "0": diferencia entre digito ASCII y binario
OP_MUL       equ 2Ah            ; "*"
OP_DIV       equ 2Fh            ; "/"

section .data
  pA     db "Primer operando (0-9): $"
  pB     db 0Dh,0Ah,"Segundo operando (0-9): $"
  pOper    db 0Dh,0Ah,"Operacion (* o /): $"
  msgR   db 0Dh,0Ah,"Resultado: $"
  msgAam db "   (AAM: AH=$"
  msgAL  db " AL=$"
  msgRst db "   Resto: $"
  msgPar db ")$"
  msgErr db "Division por cero.$"
  msgDig db 0Dh,0Ah,"Digito no valido.$"
  msgOpI db "operacion no valida.$"
  crlf   db 0Dh,0Ah,"$"
  opA    db 0
  opB    db 0
  oper   db 0

section .text
start:
  ; Leer operando A
  mov ah, DOS_CADENA
  mov dx, pA
  int 21h
  call leerDigito
  jc  .digitoMalo
  mov [opA], al

  ; Leer operando B
  mov ah, DOS_CADENA
  mov dx, pB
  int 21h
  call leerDigito
  jc  .digitoMalo
  mov [opB], al

  ; Leer operador
  mov ah, DOS_CADENA
  mov dx, pOper
  int 21h
  mov ah, DOS_LEER
  int 21h                       ; AL = "*" o "/"
  mov [oper], al

  ; Encabezado del resultado
  mov ah, DOS_CADENA
  mov dx, msgR
  int 21h

  cmp byte [oper], OP_MUL
  je  .mul
  cmp byte [oper], OP_DIV
  je  .div
  mov ah, DOS_CADENA
  mov dx, msgOpI
  int 21h
  jmp .fin

.mul:
  mov al, [opA]
  mul byte [opB]                ; AX = AL * opB (sin signo), maximo 81
  push ax
  call imprimirAX               ; conversion binario -> decimal con DIV
  pop ax
  aam                           ; AH = decenas, AL = unidades (BCD desempaquetado)
  push ax
  mov ah, DOS_CADENA
  mov dx, msgAam
  int 21h
  pop ax
  push ax
  mov al, ah
  call impHex8
  mov ah, DOS_CADENA
  mov dx, msgAL
  int 21h
  pop ax
  call impHex8
  mov ah, DOS_CADENA
  mov dx, msgPar
  int 21h
  jmp .fin

.div:
  cmp byte [opB], 0
  je  .divCero
  xor ah, ah                    ; AH = 0: extender AL a AX sin signo
  mov al, [opA]
  div byte [opB]                ; AL = cociente, AH = resto
  push ax
  xor ah, ah
  call imprimirAX               ; imprimir cociente
  mov ah, DOS_CADENA
  mov dx, msgRst
  int 21h
  pop ax
  mov al, ah                    ; resto en AL
  xor ah, ah
  call imprimirAX               ; imprimir resto
  jmp .fin

.divCero:
  mov ah, DOS_CADENA
  mov dx, msgErr
  int 21h
  jmp .fin

.digitoMalo:
  mov ah, DOS_CADENA
  mov dx, msgDig
  int 21h

.fin:
  mov ah, DOS_CADENA
  mov dx, crlf
  int 21h
  mov ah, DOS_SALIR
  xor al, al
  int 21h

; ---- leerDigito: lee un caracter con eco; AL = 0-9 y CF=0, o CF=1 si no es digito ----
leerDigito:
  mov ah, DOS_LEER
  int 21h                       ; AL = ASCII del digito
  cmp al, "0"
  jb  .malo
  cmp al, "9"
  ja  .malo
  sub al, ASCII_0               ; convertir a binario
  clc
  ret
.malo:
  stc
  ret

; ---- imprimirAX: imprime AX como numero decimal usando DIV repetido ----
imprimirAX:
  mov bx, 10
  xor cx, cx
.divide:
  xor dx, dx
  div bx                        ; AX = cociente, DX = digito
  push dx
  inc cx
  test ax, ax
  jnz .divide
.popDigit:
  pop dx
  add dl, ASCII_0
  mov ah, DOS_CAR
  int 21h
  loop .popDigit
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
