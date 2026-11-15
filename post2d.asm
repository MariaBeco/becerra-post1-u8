; post2d.asm - AAA/AAS: ajuste ASCII de BCD desempaquetado
; Autora: Maria Fernanda Becerra Coronel (1152509)
; Compilar: nasm -f bin post2d.asm -o post2d.com
; Suma desempaquetada: 7 + 8 = 15 (AH=1 decena, AL=5 unidades)
; Resta desempaquetada: 13 - 8 = 5
ORG 100h

DOS_CAR      equ 02h            ; INT 21h: imprimir caracter en DL
DOS_CADENA   equ 09h            ; INT 21h: imprimir cadena DS:DX terminada en "$"
DOS_SALIR    equ 4Ch            ; INT 21h: terminar programa
CF_BIT       equ 0001h
DIG_7        equ 07h            ; digitos BCD desempaquetados (nibble alto en 0)
DIG_8        equ 08h
TRECE_DEC    equ 01h            ; "13" desempaquetado: AH=01 (decena)
TRECE_UNI    equ 03h            ;                      AL=03 (unidad)

section .data
  msgSuma  db "AAA: 7 + 8 = $"
  msgResta db "AAS: 13 - 8 = $"
  msgSin   db "   (sin ajuste AL=$"
  msgCon   db ", con ajuste AH:AL=$"
  msgDosP  db ":$"
  msgCF    db ", CF=$"
  msgPar   db ")$"
  crlf     db 0Dh,0Ah,"$"
  sinAjuste db 0
  resAX    dw 0
  flags    dw 0

section .text
start:
  ; --- Suma desempaquetada con AAA ---
  mov ah, DOS_CADENA
  mov dx, msgSuma
  int 21h

  xor ah, ah                    ; AH = 0: AAA suma el acarreo en AH
  mov al, DIG_7
  add al, DIG_8                 ; AL = 07h + 08h = 0Fh (NO es BCD desempaquetado)
  mov [sinAjuste], al
  aaa                           ; AL = 05h (unidades), AH = 01h (decenas), CF=1
  call reportar

  ; --- Resta desempaquetada con AAS: 13 - 8 = 5 ---
  mov ah, DOS_CADENA
  mov dx, msgResta
  int 21h

  mov ah, TRECE_DEC             ; decena de "13"
  mov al, TRECE_UNI             ; unidad de "13"
  sub al, DIG_8                 ; AL = 03h - 08h = FBh (requiere ajuste)
  mov [sinAjuste], al
  aas                           ; AL = 05h, AH = 01h - 1 = 00h, CF=1 (prestamo)
  call reportar

  mov ah, DOS_SALIR
  xor al, al
  int 21h

; ---- reportar: imprime AH:AL como numero decimal y el detalle del ajuste ----
; Debe llamarse justo despues de AAA/AAS para capturar CF.
reportar:
  pushf
  pop word [flags]
  mov [resAX], ax

  ; Resultado en decimal: la decena solo si no es cero
  mov ax, [resAX]
  test ah, ah
  jz .unidad
  mov dl, ah
  add dl, "0"
  mov ah, DOS_CAR
  int 21h
.unidad:
  mov ax, [resAX]
  mov dl, al
  add dl, "0"
  mov ah, DOS_CAR
  int 21h

  ; Detalle: AL antes del ajuste, AH:AL despues y CF
  mov ah, DOS_CADENA
  mov dx, msgSin
  int 21h
  mov al, [sinAjuste]
  call impHex8
  mov ah, DOS_CADENA
  mov dx, msgCon
  int 21h
  mov ax, [resAX]
  mov al, ah
  call impHex8
  mov ah, DOS_CADENA
  mov dx, msgDosP
  int 21h
  mov ax, [resAX]
  call impHex8
  mov ah, DOS_CADENA
  mov dx, msgCF
  int 21h
  mov dl, "0"
  test word [flags], CF_BIT
  jz .cf_listo
  mov dl, "1"
.cf_listo:
  mov ah, DOS_CAR
  int 21h
  mov ah, DOS_CADENA
  mov dx, msgPar
  int 21h
  mov dx, crlf
  int 21h
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
