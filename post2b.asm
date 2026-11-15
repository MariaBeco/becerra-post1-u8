; post2b.asm - DAA y DAS: suma y resta BCD empaquetada
; Autora: Maria Fernanda Becerra Coronel (1152509)
; Compilar: nasm -f bin post2b.asm -o post2b.com
ORG 100h

DOS_CAR      equ 02h            ; INT 21h: imprimir caracter en DL
DOS_CADENA   equ 09h            ; INT 21h: imprimir cadena DS:DX terminada en "$"
DOS_SALIR    equ 4Ch            ; INT 21h: terminar programa
CF_BIT       equ 0001h

; Operandos BCD empaquetados (un digito decimal por nibble)
BCD_47       equ 47h
BCD_38       equ 38h
BCD_99       equ 99h
BCD_01       equ 01h
BCD_73       equ 73h
BCD_28       equ 28h
BCD_20       equ 20h
; Resultados esperados
ESP_SUMA     equ 85h            ; 47 + 38 = 85
ESP_ACARREO  equ 00h            ; 99 + 01 = 1|00 (CF=1)
ESP_RESTA    equ 45h            ; 73 - 28 = 45
ESP_RESTA2   equ 19h            ; 20 - 01 = 19

section .data
  bcd1    db BCD_47
  bcd2    db BCD_38
  resultado db 0
  sinAjuste db 0
  flags   dw 0
  msgSum  db "BCD suma: 47 + 38 = $"
  msgAca  db "BCD suma: 99 + 01 = $"
  msgDas1 db "DAS: 73 - 28 = $"
  msgDas2 db "DAS: 20 - 01 = $"
  msgSin  db "   (sin ajuste: $"
  msgCF   db ", CF=$"
  msgPar  db ")$"
  msgOk   db "  OK$"
  msgErr  db "  ERROR$"
  crlf    db 0Dh,0Ah,"$"

section .text
start:
  ; ---------- 47 + 38 con DAA ----------
  mov al, [bcd1]
  add al, [bcd2]                ; AL = 47h + 38h = 7Fh (NO es BCD valido)
  mov [sinAjuste], al
  daa                           ; ajustar: AL = 85h
  mov dx, msgSum
  mov bl, ESP_SUMA
  call reportar

  ; ---------- 99 + 01 con DAA: acarreo al siguiente byte ----------
  mov al, BCD_99
  add al, BCD_01                ; AL = 9Ah
  mov [sinAjuste], al
  daa                           ; AL = 00h, CF=1 (el "1" de 100 sale por CF)
  mov dx, msgAca
  mov bl, ESP_ACARREO
  call reportar

  ; ---------- 73 - 28 con DAS ----------
  mov al, BCD_73
  sub al, BCD_28                ; AL = 4Bh (NO BCD valido)
  mov [sinAjuste], al
  das                           ; AL = 45h
  mov dx, msgDas1
  mov bl, ESP_RESTA
  call reportar

  ; ---------- 20 - 01 con DAS: prestamo del nibble alto ----------
  mov al, BCD_20
  sub al, BCD_01                ; AL = 1Fh (nibble bajo Fh > 9)
  mov [sinAjuste], al
  das                           ; AL = 19h, CF=0
  mov dx, msgDas2
  mov bl, ESP_RESTA2
  call reportar

  mov ah, DOS_SALIR
  xor al, al
  int 21h

; ---- reportar: DX = mensaje, AL = resultado ajustado, BL = esperado ----
; Debe llamarse justo despues de DAA/DAS para capturar CF.
reportar:
  pushf
  pop word [flags]
  mov [resultado], al
  mov ah, DOS_CADENA
  int 21h                       ; imprime el mensaje recibido en DX

  mov al, [resultado]           ; los dos digitos BCD (nibble alto y bajo)
  call impHex8

  mov ah, DOS_CADENA
  mov dx, msgSin
  int 21h
  mov al, [sinAjuste]
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

  mov dx, msgOk
  cmp [resultado], bl
  je .veredicto
  mov dx, msgErr
.veredicto:
  mov ah, DOS_CADENA
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
