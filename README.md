# becerra-post1-u8

**Laboratorio Post-contenido 1, Unidad 8: Operaciones con Cadenas y Aritmética — Programación en NASM sobre DOSBox**
Arquitectura de Computadores · Universidad Francisco de Paula Santander

- **Estudiante:** Maria Fernanda Becerra Coronel
- **Código:** 1152509
- **Docente:** Ing. Jonathan Rey

## Descripción

El laboratorio tiene dos partes que se entregan en este mismo repositorio. En la **Parte 1**, cinco programas recorren las instrucciones de cadena del 8086: `post1.asm` copia un bloque con REP MOVSB, `post1b.asm` hace la misma copia con REP MOVSW más un MOVSB para el byte impar, `post1c.asm` busca caracteres con REPNE SCASB, `post1d.asm` compara cadenas con REPE CMPSB y `post1e.asm` copia una cadena convirtiéndola a mayúsculas con un bucle LODSB/STOSB. En la **Parte 2**, cuatro programas trabajan la aritmética: `post2.asm` suma y resta números de 32 bits con ADC y SBB, `post2b.asm` ajusta sumas y restas BCD empaquetadas con DAA y DAS, `post2c.asm` es una calculadora de un dígito con MUL, DIV y AAM, y `post2d.asm` ajusta sumas y restas BCD desempaquetadas con AAA y AAS. Todos los programas se ensamblaron con NASM y se ejecutaron en DOSBox.

## Estructura del repositorio

```
becerra-post1-u8/
├── post1.asm  / post1.com     Parte 1: REP MOVSB, copia de 13 bytes
├── post1b.asm / post1b.com    Parte 1: REP MOVSW + MOVSB para el byte impar
├── post1c.asm / post1c.com    Parte 1: REPNE SCASB, búsqueda de un carácter
├── post1d.asm / post1d.com    Parte 1: REPE CMPSB, comparación de cadenas
├── post1e.asm / post1e.com    Parte 1: LODSB + STOSB, copia con paso a mayúsculas
├── post2.asm  / post2.com     Parte 2: ADC y SBB, suma y resta de 32 bits
├── post2b.asm / post2b.com    Parte 2: DAA y DAS, BCD empaquetado
├── post2c.asm / post2c.com    Parte 2: calculadora con MUL, DIV y AAM
├── post2d.asm / post2d.com    Parte 2: AAA y AAS, BCD desempaquetado
├── capturas/                  Evidencia de compilación y ejecución
└── README.md
```

## Entorno y compilación

| Elemento | Valor |
|---|---|
| Emulador | DOSBox 0.74-3 |
| Ensamblador | NASM 2.16.03 para DOS (`nasm.exe` con `CWSDPMI.EXE`) |
| Formato de salida | `.COM` plano, `ORG 100h` |

Cada programa se ensambla y ejecuta de la misma forma:

```
nasm -f bin post1.asm -o post1.com
post1.com
```

| Programa | Tamaño del .COM |
|---|---|
| post1.com | 281 bytes |
| post1b.com | 344 bytes |
| post1c.com | 244 bytes |
| post1d.com | 292 bytes |
| post1e.com | 155 bytes |
| post2.com | 412 bytes |
| post2b.com | 313 bytes |
| post2c.com | 456 bytes |
| post2d.com | 278 bytes |

### Constantes y subrutinas

Los programas definen con `equ` los números de función de INT 21h (`DOS_CADENA equ 09h`, `DOS_CAR equ 02h`, `DOS_SALIR equ 4Ch`), las longitudes (`LONG_CAD`, `LONG_CMP`), las máscaras de flags (`CF_BIT equ 0001h`, `DF_BIT equ 0400h`) y todos los operandos de la Parte 2 (`BCD_47 equ 47h`, `A_LO equ 0FFFFh`, `DIG_7 equ 07h`), junto con el resultado esperado de cada operación (`ESP_SUMA equ 85h`). En `post1c.asm` la longitud de la cadena la calcula NASM: `LONG_CAD equ $ - cadena - 1`.

Las subrutinas compartidas son `impZ` (imprime una cadena terminada en 0 recorriéndola con LODSB), `impDec` (imprime AX en decimal con DIV repetido), `impHex8` e `impHex16` (imprimen un byte o una palabra en hexadecimal, separando nibbles con `shr al, 4` y `and al, 0Fh`).

---

# Parte 1: Instrucciones de cadena — Copiar, buscar y comparar

## Registros implícitos y el flag DF

| Instrucción | Lee de | Escribe en / compara con | Usa CX | Condición de parada con prefijo |
|---|---|---|---|---|
| MOVSB / MOVSW | DS:SI | ES:DI | con REP | CX = 0 |
| LODSB | DS:SI | AL | no | (sin prefijo) |
| STOSB | AL | ES:DI | con REP | CX = 0 |
| SCASB | AL | compara con ES:DI | con REPNE | CX = 0 o ZF = 1 (coincidencia) |
| CMPSB | DS:SI | compara con ES:DI | con REPE | CX = 0 o ZF = 0 (diferencia) |

Después de cada elemento, SI y DI avanzan 1 (byte) o 2 (word) si DF = 0, y retroceden si DF = 1. Todos los programas ejecutan `cld` antes de cada instrucción de cadena, en lugar de suponer que DF ya vale 0. En un `.COM`, DOS carga DS y ES con el mismo segmento, pero los programas copian DS en ES de todos modos (`mov ax, ds` / `mov es, ax`), porque ES no se puede cargar con un inmediato y el destino de MOVS, STOS, SCAS y CMPS siempre es ES:DI.

## Paso 1: copia con REP MOVSB (post1.asm)

El programa copia los 13 bytes de `"HOLA, MUNDO!",0` desde `origen` hasta `destino` con una sola instrucción `rep movsb`. Justo después guarda SI, DI, CX y los flags, y los imprime:

```
Copiado: HOLA, MUNDO!
SI avanzo: 13  DI avanzo: 13  CX final: 0  DF: 0
```

SI y DI avanzaron exactamente 13 posiciones y CX llegó a 0, que es la única condición de parada de REP. DF sigue en 0 porque nada lo cambió después del `cld`.

**Corrección respecto a la guía.** El código de la guía (y el de `post1e.asm`, que repite el mismo patrón) imprimía `destino` con INT 21h/AH=09h, pero `destino` termina en 0, no en `$`. DOS seguía imprimiendo la memoria siguiente hasta encontrar un `$`, que estaba al final de `msgCop`, así que en pantalla aparecía `Copiado: HOLA, MUNDO! Copiado:`. La versión del repositorio imprime `destino` con la subrutina `impZ`, que recorre la cadena con LODSB hasta el byte nulo.

## Paso 2: copia por palabras con REP MOVSW (post1b.asm)

La longitud (13) se guarda en AX, `shr cx, 1` deja CX = 6 y `rep movsw` copia 6 words, es decir, 12 bytes. `and ax, 1` deja 1 porque 13 es impar, y un MOVSB final copia el byte 13, que es el terminador nulo. Para confirmar que el resultado es el mismo que el del Paso 1, el programa compara los 13 bytes de `destino` y `origen` con `repe cmpsb`:

```
Copiado con MOVSW: HOLA, MUNDO!
Words copiadas: 6  Byte sobrante: 1
Verificacion: destino identico al origen
```

## Paso 3: búsqueda con REPNE SCASB (post1c.asm)

La subrutina `buscarCaracter` recibe el carácter en AL, apunta DI a `cadena`, carga CX con la longitud y ejecuta `repne scasb`. Si la instrucción termina con ZF = 1, encontró el carácter y DI quedó un byte después de él, por lo que la posición en base 0 es `DI − cadena − 1`. El programa la llama dos veces:

```
Buscar 'd': hallado en posicion 13  (CX restante: 14)
Buscar 'z': No encontrado.
```

Con la `d`, SCASB revisó 14 bytes (posiciones 0 a 13), así que CX bajó de 28 a 14. Con la `z`, recorrió los 28 bytes, CX llegó a 0 con ZF = 0 y el programa tomó el camino de "No encontrado".

**Correcciones respecto a la guía.** La guía definía `longCad equ 29`, pero "Arquitectura de Computadores" tiene 28 caracteres; con 29, SCASB revisaba también el terminador nulo. Además, la guía mostraba como salida esperada "Hallado en posicion: 4", pero la primera `d` está en la posición 13 (`A-r-q-u-i-t-e-c-t-u-r-a-espacio-d`). La rutina de impresión de la guía sumaba 30h a un solo dígito, así que con 13 habría mostrado el carácter `=` (30h + 13 = 3Dh). La versión del repositorio calcula la longitud con `$ - cadena - 1` e imprime la posición con `impDec`, que maneja varios dígitos.

## Paso 4: comparación con REPE CMPSB (post1d.asm)

La subrutina `compararCadenas` compara 8 bytes de DS:SI y ES:DI. Si termina con ZF = 1, las cadenas son iguales. Si termina con ZF = 0, SI y DI quedaron un byte después del primer carácter distinto, y el programa imprime la posición y los dos caracteres:

```
cad1 vs cad2: Iguales.
cad1 vs cad3: Diferentes. Primera diferencia en posicion 5 ('x' vs 'A')
```

"NASM x86" y "NASM ARM" coinciden en `N`, `A`, `S`, `M` y el espacio (posiciones 0 a 4) y difieren en la posición 5, que es el sexto carácter. La guía decía "quinto carácter", pero contando desde 1 la `x` es el sexto; contando desde 0, es la posición 5.

## Paso 5: copia con transformación usando LODSB y STOSB (post1e.asm)

En cada vuelta, LODSB carga un byte de DS:SI en AL y avanza SI; si AL está entre `'a'` y `'z'`, el programa le resta 20h; luego STOSB guarda AL en ES:DI y avanza DI. LOOP decrementa CX y repite hasta copiar los 13 bytes. Los caracteres que no son minúsculas, como la coma, el espacio, el `!` y el nulo final, pasan sin cambio.

```
Origen:       hola, mundo!
Transformado: HOLA, MUNDO!
```

## Decisiones técnicas — Parte 1

### Decisión 1: ¿REP MOVSB o un bucle manual con LODSB/STOSB?

En `post1.asm`, la copia completa es una sola instrucción: el procesador decodifica `rep movsb` una vez y repite internamente la transferencia, decrementando CX y actualizando SI y DI en microcódigo. En `post1e.asm`, cada uno de los 13 bytes pasa por LODSB, dos CMP, uno o dos saltos condicionales, posiblemente un SUB, STOSB y LOOP. Es decir, de seis a siete instrucciones que el procesador debe buscar, decodificar y ejecutar por byte, además de evaluar en cada vuelta las condiciones de salto. REP evita todo ese trabajo repetido: no hay instrucciones nuevas que leer entre un byte y el siguiente, ni saltos que resolver.

Aun así, fue necesario abandonar REP MOVSB en `post1e.asm`. MOVSB lleva el byte directamente de DS:SI a ES:DI sin pasar por ningún registro que el programa pueda ver, de modo que no existe un punto entre la lectura y la escritura donde insertar `cmp al, 'a'` o `sub al, 20h`. LODSB y STOSB dividen la copia en dos mitades y dejan el byte en AL, justo donde el programa puede examinarlo y modificarlo.

Si el laboratorio necesitara copiar una cadena larga sin ninguna transformación, REP MOVSB (o REP MOVSW, como en `post1b.asm`) seguiría siendo la opción correcta. La diferencia de costo crece con la longitud de la cadena, y el bucle manual no aportaría nada a cambio. El bucle LODSB/STOSB se justifica solo cuando cada byte necesita una decisión o un cálculo propio, como pasar a mayúsculas, filtrar caracteres o cifrar.

### Decisión 2: ¿CX fijo en REPE CMPSB/REPNE SCASB o verificación manual del terminador?

REPE CMPSB y REPNE SCASB no saben qué es un terminador nulo: solo se detienen cuando CX llega a 0 o cuando cambia ZF. Si se comparan con CX = 8 una cadena de 5 caracteres, como `"NASM ",0`, y otra de 8, la instrucción compararía los 5 caracteres, luego el byte 0 de la cadena corta contra el sexto carácter de la larga, y si por casualidad fueran iguales seguiría con los bytes que están en memoria después de la cadena corta: la variable siguiente, un mensaje, o incluso código. En `post1d.asm`, por ejemplo, después de `cad1` viene directamente `cad2`. El resultado dependería del contenido de memoria ajena a la cadena: dos cadenas distintas podrían reportarse como iguales, o la posición de la diferencia podría ser falsa. En SCASB el riesgo es el mismo, porque la búsqueda podría "encontrar" el carácter fuera de la cadena.

Para cadenas de longitud desconocida, el bucle de `post1e.asm` se puede adaptar así: cargar un carácter de la primera cadena con LODSB y guardarlo en AH, cargar el carácter de la segunda con otro LODSB (cambiando SI al segundo puntero, o usando `mov al, [es:di]` e `inc di`), compararlos con `cmp al, ah` y salir con "diferentes" si no coinciden. Si coinciden y el carácter es 0, las dos cadenas terminaron a la vez y son iguales. Como la comparación del nulo se hace en cada vuelta, el bucle nunca lee más allá del primer terminador que encuentre en cualquiera de las dos.

En `post1d.asm`, el CX fijo es apropiado porque las tres cadenas son literales del propio programa y miden 8 caracteres, algo que se sabe en tiempo de ensamblado. En ese caso REPE CMPSB es más corto y más rápido que el bucle, y no puede salirse de las cadenas. La misma decisión no sirve para cadenas que llegan del teclado o de un archivo, cuya longitud solo se conoce al ejecutar el programa.

---

# Parte 2: Aritmética de precisión múltiple y BCD

## Instrucciones usadas

| Instrucción | Operación | Flag clave | Programa |
|---|---|---|---|
| ADD / ADC | suma; ADC suma además CF | CF = acarreo | post2 |
| SUB / SBB | resta; SBB resta además CF | CF = préstamo | post2 |
| DAA | ajusta AL a BCD empaquetado tras ADD | AF (nibble bajo), CF (byte completo) | post2b |
| DAS | ajusta AL a BCD empaquetado tras SUB | AF, CF | post2b |
| MUL / DIV | multiplicación y división sin signo de 8 bits | — | post2c |
| AAM | AL → AH = AL / 10, AL = AL mod 10 | — | post2c |
| AAA | ajusta AL a un dígito tras ADD e incrementa AH si hay acarreo | AF, CF | post2d |
| AAS | ajusta AL a un dígito tras SUB y decrementa AH si hay préstamo | AF, CF | post2d |

## Paso 1 y Paso 2: suma y resta de 32 bits con ADC y SBB (post2.asm)

Cada número de 32 bits ocupa dos registros: DX la parte alta y AX la parte baja. Para A = 0001:FFFFh (131071) y B = 0001:0001h (65537):

| Operación | Partes bajas | CF | Partes altas | Resultado |
|---|---|---|---|---|
| A + B | `add ax, bx`: FFFFh + 0001h = 0000h | 1 | `adc dx, cx`: 0001h + 0001h + 1 = 0003h | 0003:0000h = 196608 |
| (A + B) − B | `sub ax, bx`: 0000h − 0001h = FFFFh | 1 | `sbb dx, cx`: 0003h − 0001h − 1 = 0001h | 0001:FFFFh = 131071 |

El programa guarda los flags con `pushf` / `pop` entre la operación baja y la alta. Esto no altera CF, porque POP no modifica flags, y permite imprimir el acarreo o préstamo que recibió ADC o SBB:

```
Suma  0001:FFFF + 0001:0001 = 0003:0000   CF parte baja: 1
Suma OK: 0003:0000
Resta 0003:0000 - 0001:0001 = 0001:FFFF   CF parte baja: 1
Resta OK: 0001:FFFF
```

Si la parte alta usara ADD en lugar de ADC, la suma daría 0002:0000h; si usara SUB en lugar de SBB, la resta daría 0002:FFFFh. En ambos casos se perdería el CF de la parte baja.

## Paso 3 y Paso 4: BCD empaquetado con DAA y DAS (post2b.asm)

Un byte BCD empaquetado guarda dos dígitos decimales, uno por nibble: 47h significa "47". La suma y la resta se hacen en binario y luego DAA o DAS corrigen el resultado. La subrutina `reportar` imprime, para cada caso, el resultado ajustado, el valor de AL antes del ajuste, CF y si el resultado coincide con la constante esperada:

```
BCD suma: 47 + 38 = 85   (sin ajuste: 7F, CF=0)  OK
BCD suma: 99 + 01 = 00   (sin ajuste: 9A, CF=1)  OK
DAS: 73 - 28 = 45   (sin ajuste: 4B, CF=0)  OK
DAS: 20 - 01 = 19   (sin ajuste: 1F, CF=0)  OK
```

| Caso | Binario | Nibble bajo | Nibble alto | Resultado |
|---|---|---|---|---|
| 47h + 38h | 7Fh | F > 9 → +6 = 85h | 8 ≤ 9, sin cambio | 85h, CF = 0 |
| 99h + 01h | 9Ah | A > 9 → +6 = A0h | AL original 9Ah > 99h → +60h = 00h | 00h, CF = 1 |
| 73h − 28h | 4Bh | B > 9 → −6 = 45h | 4 ≤ 9, sin cambio | 45h, CF = 0 |
| 20h − 01h | 1Fh | AF = 1 (préstamo del bit 4) → −6 = 19h | sin préstamo del byte | 19h, CF = 0 |

En el segundo caso, 99 + 01 = 100 no cabe en dos dígitos: AL queda en 00 y el dígito de las centenas sale por CF, listo para que un ADC lo sume al siguiente byte BCD.

## Paso 5: calculadora con MUL, DIV y AAM (post2c.asm)

La calculadora lee cada dígito con INT 21h/AH=01h, que devuelve el ASCII en AL, y le resta 30h para obtener su valor binario. La subrutina `leerDigito` rechaza cualquier tecla fuera de `0`–`9` con el mensaje "Digito no valido.". Luego lee el operador:

- **`*`**: `mul byte [opB]` deja el producto en AX (máximo 81). `imprimirAX` lo convierte a decimal con DIV repetido entre 10 y una pila de dígitos. Después, AAM separa el mismo producto en BCD desempaquetado: para 56, AH = 05 y AL = 06.
- **`/`**: si el divisor es 0, muestra "Division por cero." sin ejecutar DIV, que en ese caso generaría la interrupción 0. Si no, `div byte [opB]` deja el cociente en AL y el resto en AH, y el programa imprime ambos.

```
Primer operando (0-9): 7
Segundo operando (0-9): 8
Operacion (* o /): *
Resultado: 56   (AAM: AH=05 AL=06)
```

**Corrección respecto a la guía.** El código de la guía no ensambla: la etiqueta `pOp` coincide con la instrucción POP, porque NASM no distingue mayúsculas de minúsculas en los mnemónicos, y produce el error "comma, colon, decorator or end of line expected after operand". En el repositorio, la etiqueta se llama `pOper`. Además, los operandos se guardan en las variables `opA`, `opB` y `oper` en lugar de BL, CL y BH, porque `imprimirAX` usa BX y CX.

## Paso 6: BCD desempaquetado con AAA y AAS (post2d.asm)

En BCD desempaquetado, cada byte guarda un solo dígito con el nibble alto en 0, que es justo lo que se obtiene al restar 30h a un dígito ASCII. AAA corrige AL después de una suma y pasa el acarreo a AH; AAS hace lo mismo después de una resta, restando el préstamo de AH:

```
AAA: 7 + 8 = 15   (sin ajuste AL=0F, con ajuste AH:AL=01:05, CF=1)
AAS: 13 - 8 = 5   (sin ajuste AL=FB, con ajuste AH:AL=00:05, CF=1)
```

- **AAA:** 07h + 08h = 0Fh. Como el nibble bajo F es mayor que 9, AAA suma 6 (15h), incrementa AH de 00 a 01, deja AL = 05h y pone CF = AF = 1. AH:AL = 01:05 se lee "15".
- **AAS:** "13" desempaquetado es AH = 01, AL = 03. 03h − 08h = FBh; el nibble bajo B es mayor que 9, así que AAS resta 6 (F5h), decrementa AH de 01 a 00, deja AL = 05h y pone CF = 1. AH:AL = 00:05 se lee "5".

**Corrección respecto a la guía.** La guía ejecutaba AAA sin limpiar AH, y AH todavía valía 09h por la llamada a INT 21h/AH=09h que imprimía el mensaje. AAA lo incrementaba a 0Ah, y al imprimir la decena se veía `:` (30h + 0Ah = 3Ah) en lugar de `1`. La versión del repositorio pone `xor ah, ah` antes de la suma y carga AH = 01h (la decena de "13") antes de la resta, de modo que AAS deja en AH la decena correcta del resultado.

## Decisiones técnicas — Parte 2

### Decisión 3: ¿DAA/DAS o AAA/AAS según el formato del dato?

La elección depende de cuántos dígitos hay en cada byte. DAA y DAS suponen BCD empaquetado: revisan el nibble bajo y también el byte completo, y pueden sumar o restar 06h y 60h, porque tratan los dos nibbles como dígitos decimales. AAA y AAS suponen BCD desempaquetado: solo miran el nibble bajo de AL, pasan el acarreo o préstamo a AH y, al final, ponen el nibble alto de AL en 0.

Por eso, aplicar AAA a un byte empaquetado como 47h ("47") lo destruiría. Por ejemplo, en 47h + 38h = 7Fh, AAA vería el nibble bajo F, sumaría 6, incrementaría AH y dejaría AL = 05h: el resultado sería "1" en AH y "5" en AL, y el dígito de las decenas (el 4 + 3) se perdería al limpiarse el nibble alto. Lo correcto es 85h, que solo DAA produce.

La calculadora de `post2c.asm` obtiene dígitos desempaquetados: lee un ASCII con AH=01h y le resta 30h, lo que deja un valor de 0 a 9 con el nibble alto en 0. Si la calculadora tuviera que sumar dos de esos dígitos directamente, sin MUL ni DIV, la instrucción de ajuste correcta sería AAA, como en `post2d.asm`: el resultado quedaría en AH:AL como decena y unidad, listo para sumar 30h a cada uno e imprimirlos.

Usar DAA en ese caso daría un resultado engañoso. Para 07h + 08h = 0Fh, DAA suma 6 y deja AL = 15h, con CF = 0 y sin tocar AH. El valor 15h es el BCD empaquetado "15", no dos dígitos separados. Si el programa lo tratara como desempaquetado, le sumaría 30h e imprimiría `E` (30h + 15h = 45h) en lugar de "15", y no habría ninguna decena en AH. Además, con DAA cualquier valor del nibble alto se interpreta como un dígito, aunque en un dato desempaquetado ese nibble no tenga significado.

### Decisión 4: ¿ADC de precisión fija o una cadena de ADC en bucle?

`post2.asm` suma 32 bits con exactamente dos instrucciones porque el número cabe en DX:AX. Para un número de N palabras guardado en memoria con la palabra de menor peso primero, la suma se generaliza con un bucle: SI apunta al primer sumando, DI al segundo, BX al resultado y CX = N. Antes del bucle, `clc` deja CF en 0; en cada vuelta se hace `mov ax, [si]`, `adc ax, [di]`, `mov [bx], ax`, se avanzan los tres punteros en 2 y `loop` repite. El CF que deja cada ADC es el acarreo que recibe la palabra siguiente.

Hay que cuidar que nada entre dos ADC cambie CF. MOV y LOOP no lo tocan, pero `add si, 2` sí, así que los punteros se avanzan con `inc si` / `inc si` o con `lea si, [si+2]`, que no modifican CF. Al terminar el bucle, CF indica si el resultado desbordó las N palabras.

La primera palabra, la de menor peso, se suma sin acarreo de entrada porque no hay ninguna palabra anterior que lo produzca. Por eso `post2.asm` usa ADD: con ADC, un CF que hubiera quedado de una operación previa se sumaría por error. En el bucle, `clc` seguido de ADC es equivalente a ADD en la primera vuelta. Todas las palabras siguientes deben usar ADC; con ADD se descartaría el acarreo de la palabra anterior, y la suma 0001:FFFFh + 0001:0001h daría 0002:0000h en lugar de 0003:0000h.

El bucle es más mantenible: el mismo código suma 32, 48, 64 o 1024 bits cambiando solo CX, como hace una biblioteca de números grandes (bignum), y no hay que escribir ni revisar una instrucción ADC por cada palabra. A cambio, es más lento que el código fijo, porque cada palabra paga cargas desde memoria, el avance de punteros y el salto de LOOP, mientras que `post2.asm` solo ejecuta ADD y ADC sobre registros. Es la misma relación que en la Parte 1 entre REP MOVSB, rápido pero rígido, y el bucle LODSB/STOSB, flexible pero con más instrucciones por elemento. Para un tamaño fijo y pequeño conviene el código fijo; para precisión arbitraria, el bucle.

---

# Capturas

Todas las capturas de compilación y ejecución se tomaron en DOSBox 0.74-3 en el equipo de la estudiante, el 15 de noviembre de 2026. Las de código y decisiones se tomaron sobre los archivos del repositorio. Están en la carpeta `capturas/`.

| Checkpoint | Capturas | Qué muestran |
|---|---|---|
| Parte 1 · CP1: REP MOVSB | `p1_cp1_compilacion.png`, `p1_cp1_ejecucion.png` | `post1.com` de 281 bytes; `Copiado: HOLA, MUNDO!` y `SI avanzo: 13  DI avanzo: 13  CX final: 0  DF: 0` |
| Parte 1 · CP2: REP MOVSW | `p1_cp2_compilacion.png`, `p1_cp2_ejecucion.png` | 6 words y 1 byte sobrante, con la verificación `destino identico al origen` |
| Parte 1 · CP3: REPNE SCASB | `p1_cp3_compilacion.png`, `p1_cp3_ejecucion.png` | `d` hallada en la posición 13 con CX restante 14; `z` no encontrada |
| Parte 1 · CP4: REPE CMPSB | `p1_cp4_compilacion.png`, `p1_cp4_ejecucion.png` | cad1 y cad2 iguales; cad1 y cad3 diferentes desde la posición 5 (`x` frente a `A`) |
| Parte 1 · CP5: LODSB/STOSB | `p1_cp5_compilacion.png`, `p1_cp5_ejecucion.png` | `hola, mundo!` copiado como `HOLA, MUNDO!` |
| Parte 1 · CP6: decisiones técnicas | `p1_cp6_decision1.png`, `p1_cp6_decision2.png` | las decisiones 1 y 2 de este README |
| Parte 2 · CP1: suma con ADC | `p2_cp1_compilacion.png`, `p2_cp1_ejecucion.png` | `0003:0000` con CF = 1 en la parte baja y `Suma OK` |
| Parte 2 · CP2: resta con SBB | `p2_cp2_listado.png`, `p2_cp2_ejecucion.png` | el listado de NASM (`post2.lst`) con direcciones y código máquina de ADD/ADC y de SUB/SBB (`sbb dx, cx` = 19CA); la ejecución con `Resta OK: 0001:FFFF` |
| Parte 2 · CP3: DAA | `p2_cp3_compilacion.png`, `p2_cp3_ejecucion.png` | 47 + 38 = 85 (sin ajuste 7F) y 99 + 01 = 00 con CF = 1 |
| Parte 2 · CP4: DAS | `p2_cp4_codigo.png`, `p2_cp4_ejecucion.png` | la instrucción DAS sobre 20h − 01h en el código; 73 − 28 = 45 y 20 − 01 = 19 con OK |
| Parte 2 · CP5: calculadora | `p2_cp5_compilacion.png`, `p2_cp5_multiplicacion.png`, `p2_cp5_division.png`, `p2_cp5_division_cero.png` | 7 × 8 = 56 con AAM (AH=05, AL=06); 9 / 3 = 3 resto 0; 5 / 0 = `Division por cero.` |
| Parte 2 · CP6: AAA/AAS | `p2_cp6_compilacion.png`, `p2_cp6_ejecucion.png` | 7 + 8 = 15 (AH:AL = 01:05) y 13 − 8 = 5 (AH:AL = 00:05), ambas con CF = 1 |
| Parte 2 · CP7: decisiones técnicas | `p2_cp7_decision3.png`, `p2_cp7_decision4.png` | las decisiones 3 y 4 de este README |

# Conclusiones

El laboratorio muestra dos ideas que se repiten en ambas partes. La primera es que el 8086 ofrece instrucciones especializadas muy eficientes, como REP MOVSB y REPE CMPSB o la pareja ADD/ADC para 32 bits, siempre que el problema encaje en su forma fija: una longitud conocida, una copia sin cambios o un tamaño de dato definido. Cuando el problema se sale de esa forma, el programa debe pasar a un bucle explícito con LODSB/STOSB o con ADC encadenado, que es más lento pero permite inspeccionar cada elemento. La segunda es que los registros y flags implícitos son parte del contrato de cada instrucción: DF decide la dirección de las cadenas, CF transporta el acarreo entre palabras y entre bytes BCD, y AH recibe la decena en AAA y AAS. Varios programas de la guía tenían errores reales relacionados con esto: cadenas terminadas en 0 impresas como si terminaran en `$`, una longitud y una posición mal calculadas, una etiqueta que chocaba con POP y un AH sin limpiar antes de AAA. Corregirlos obligó a seguir con cuidado qué deja cada instrucción en cada registro.
