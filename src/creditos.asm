; Freddy Hardest: créditos «de película» reactivados.
; El original los llamaba desde 654Ch (parte 1), pero la rutina era la del Spectrum (desplazaba
; la pantalla en memoria) y en MSX solo amontonaba el texto: Dinamic quitó la llamada.
; Esta versión sale al terminar la parte 2 (tras «PLAYBOY DE PEGA», antes de volver al menú)
; y los pasa hacia arriba de píxel en píxel mientras suena la música de la presentación de la
; parte 1. Esa música vive en la página 0 de la parte 1, así que se intercambia la página 0
; (0000h-0C1Bh) con una copia de la de la parte 1 y al acabar se deja como estaba.
; Cada carácter tiene dos patrones (parte de arriba y de abajo de la línea desplazada) y hay
; dos juegos (0-125 y 128-253) que se alternan: se rellena el que no se ve y luego se pasa a
; la tabla de nombres que lo usa. Patrones 126, 127, 254 y 255 en blanco.
; (v21) Hasta la v20 se usaba R4=00h y R3=9Fh para que las tres franjas compartieran patrones
; y colores. Hay VDP (clones en FPGA y algún emulador) que no hacen caso de esas máscaras y en
; las franjas 2 y 3 enseñaban lo que quedaba del juego. Ahora las tablas son las normales
; (R3=FFh, R4=03h): los patrones van a las tres franjas, los colores a las tres, y hay cuatro
; tablas de nombres (1800h, 1C00h, 3800h y 3C00h; R2 = 06h + juego + 8 * (k impar)), una por
; juego y paridad de la línea k: las dos de k+1 se escriben poco a poco (6 filas por paso)
; mientras se ven las de k. Los patrones de sprites (3800h) se pisan: la partida los vuelve a
; subir al empezar (SPR_PREPARA, porque FIN_SPR deja SPR_ON a 0).
; Claude para araubi, 2026-10-29 (pasmo o sjasmplus).
MUSICA		EQU 0716h	; arranca la música del menú
MUSICA_PASO	EQU 07B6h	; un paso del reproductor
MUSICA_CALLA	EQU 0779h
HAY_TECLA	EQU 0009h
SAT_VRAM	EQU 1B00h	; R5=36h	; NZ si hay alguna tecla pulsada

	INCLUDE "creditos_org.inc"	; CR_ORG, MENU_DIR, MARCA_DIR (los genera build_rom.py)
	ORG CR_ORG
; --- entrada desde el final de la parte 2 (en lugar de JP MENU en FC42h)
CREDITOS_B:
	DI
	; (v19) la partida usa esta RAM (4000h-4F3Fh se pisa en la última pantalla): el resto del
	; módulo se vuelve a copiar desde la ROM (banco CR_BANCO, en 8000h) antes de usarlo.
	LD A,(2600h)		; C_V1 del copiador: página 1 en el cartucho
	OUT (0A8h),A
	LD A,CR_BANCO
	LD (7000h),A
	LD A,(2601h)		; C_V2: página 2 en el cartucho
	OUT (0A8h),A
	LD HL,8000h+CR_RESTO-CR_ORG
	LD DE,CR_RESTO
	LD BC,CR_FIN_MODULO-CR_RESTO
	LDIR
	LD A,(2602h)		; C_V0: todo RAM
	OUT (0A8h),A
CR_RESTO:
	CALL CR_CAMBIA		; página 0 de la parte 1
CR_SUELTA:
	CALL HAY_TECLA		; espera a que se suelte la tecla del mensaje final
	JR NZ,CR_SUELTA
	CALL CREDITOS
	CALL CR_CAMBIA		; página 0 de la parte 2
	CALL FIN_SPR		; (v19b) el menú, sin los sprites del marcador ni de la partida
	CALL MARCA_DIR		; la VRAM ha cambiado: volcado y colores completos
	JP MENU_DIR
CR_CAMBIA:
	LD HL,0
	LD DE,PAG0_A
	LD BC,0C1Ch
CR_C1:
	LD A,(DE)
	PUSH AF
	LD A,(HL)
	LD (DE),A
	POP AF
	LD (HL),A
	INC HL
	INC DE
	DEC BC
	LD A,B
	OR C
	JR NZ,CR_C1
CR_RET:
	RET

CREDITOS:
	DI
	; (v19b) sprites fuera mientras salen los créditos (la cara del marcador se quedaba):
	; se guarda la tabla de atributos (1B00h) y se deja vacía; al acabar se repone
	LD HL,SAT_VRAM
	CALL VDP_LEE
	LD HL,CR_SAT
	LD B,128
CR_S1:	IN A,(98h)
	LD (HL),A
	INC HL
	DJNZ CR_S1
	LD HL,SAT_VRAM
	CALL VDP_ESCRIBE
	LD A,0D0h
	OUT (98h),A
	; tablas del VDP: nombres a 126 (blanco), colores amarillo sobre negro, patrones en blanco
	LD HL,1800h
	CALL VDP_ESCRIBE
	LD BC,0300h
	LD E,126
	CALL VDP_LLENA
	LD HL,2000h
	CALL VDP_ESCRIBE
	LD BC,1800h		; (v21) colores de las tres franjas
	LD E,COLOR_TEXTO
	CALL VDP_LLENA
	LD HL,0000h
	CALL VDP_ESCRIBE
	LD BC,1800h		; (v21) patrones de las tres franjas
	LD E,0
	CALL VDP_LLENA
	LD HL,3800h		; (v21) las otras dos tablas de nombres
	CALL VDP_ESCRIBE
	LD BC,0800h
	LD E,126
	CALL VDP_LLENA
	LD A,0FFh		; (v21) tablas normales, sin máscaras
	LD C,3
	CALL VDP_REG
	LD A,3
	LD C,4
	CALL VDP_REG
	LD HL,0
	LD (CR_POS),HL
	XOR A
	LD (CR_JUEGO),A
	; tablas de nombres de k=0 (las dos), enteras
	LD B,8
CR_INI:	PUSH BC
	LD A,B
	DEC A
	CALL CR_FILAS6
	POP BC
	DJNZ CR_INI
	CALL MUSICA
CR_BUCLE:
	LD A,(CR_JUEGO)
	XOR 80h
	LD (CR_JUEGO),A
	CALL CR_PATRONES	; el juego que no se ve, para CR_POS
	; tabla de nombres de este juego y de la paridad de k
	LD A,(CR_POS)
	AND 8
	LD C,A			; 8 si k es impar
	LD A,(CR_JUEGO)
	RLCA			; 1 si el juego es el 128-253
	ADD A,C
	ADD A,6
	LD C,2
	CALL VDP_REG
	; 6 filas de las tablas de k+1 (paso j = pos AND 7: 0-3 el juego 0, 4-7 el 128)
	LD A,(CR_POS)
	AND 7
	OR 8			; 8-15: k+1
	CALL CR_FILAS6
	LD BC,(CR_ESPERA)
CR_TIEMPO:
	DEC BC
	LD A,B
	OR C
	JR NZ,CR_TIEMPO
	CALL MUSICA_PASO
	DI
	CALL HAY_TECLA
	JR NZ,CR_FIN
	LD HL,(CR_POS)
	INC HL
	LD (CR_POS),HL
	LD DE,CR_PASOS
	OR A
	SBC HL,DE
	JR NZ,CR_BUCLE
CR_FIN:
	CALL MUSICA_CALLA
	DI
	; deja el VDP como lo espera el juego: tablas normales, todo en negro, nombres 0-255 x3
	LD HL,0000h
	CALL VDP_ESCRIBE
	LD BC,1800h
	LD E,0
	CALL VDP_LLENA
	LD HL,2000h
	CALL VDP_ESCRIBE
	LD BC,1800h
	LD E,0
	CALL VDP_LLENA
	LD HL,1800h
	CALL VDP_ESCRIBE
	LD BC,0300h
CR_IDENT:
	LD A,C
	OUT (98h),A
	INC C
	JR NZ,CR_IDENT
	DJNZ CR_IDENT
	LD HL,3800h		; (v21) patrones de sprites (aquí iban dos tablas de nombres)
	CALL VDP_ESCRIBE
	LD BC,0800h
	LD E,0
	CALL VDP_LLENA
	LD A,6
	LD C,2
	CALL VDP_REG
	LD A,0FFh
	LD C,3
	CALL VDP_REG
	LD A,3
	LD C,4
	CALL VDP_REG
	LD HL,SAT_VRAM		; sprites como estaban
	CALL VDP_ESCRIBE
	LD HL,CR_SAT
	LD B,128
CR_S2:	LD A,(HL)
	OUT (98h),A
	INC HL
	DJNZ CR_S2
	RET

; --- (v21) patrones del juego que no se ve para la posición CR_POS, en las tres franjas.
; GLIFOS: cada glifo con 8 ceros delante (y 8 al final de la tabla). Con o = pos AND 7, la parte
; de arriba son los bytes 8+o..15+o del glifo y la de abajo los o..7+o. OUTI cada 31 ciclos.
CR_PATRONES:
	LD A,(CR_POS)
	AND 7
	LD E,A
	LD D,0
	LD HL,GLIFOS+8
	ADD HL,DE
	LD (CR_ORIGEN),HL
	LD A,(CR_JUEGO)		; 0 o 80h: patrón 0 o 128 (0000h o 0400h)
	RLCA
	RLCA
	RLCA
	LD H,A
	LD L,0
	LD A,3
CR_PB:
	LD (CR_BANDA),A
	PUSH HL
	CALL VDP_ESCRIBE
	LD HL,(CR_ORIGEN)
	LD C,98h
	LD DE,-16
	LD A,N_GLIFOS
CR_P1:
	OUTI
	CP (HL)
	NOP
	NOP
	OUTI
	CP (HL)
	NOP
	NOP
	OUTI
	CP (HL)
	NOP
	NOP
	OUTI
	CP (HL)
	NOP
	NOP
	OUTI
	CP (HL)
	NOP
	NOP
	OUTI
	CP (HL)
	NOP
	NOP
	OUTI
	CP (HL)
	NOP
	NOP
	OUTI
	ADD HL,DE		; -16: la parte de abajo
	NOP
	OUTI
	CP (HL)
	NOP
	NOP
	OUTI
	CP (HL)
	NOP
	NOP
	OUTI
	CP (HL)
	NOP
	NOP
	OUTI
	CP (HL)
	NOP
	NOP
	OUTI
	CP (HL)
	NOP
	NOP
	OUTI
	CP (HL)
	NOP
	NOP
	OUTI
	CP (HL)
	NOP
	NOP
	OUTI
	LD DE,16
	ADD HL,DE		; +16: el glifo siguiente
	LD DE,-16
	DEC A
	JP NZ,CR_P1
	POP HL
	LD A,H
	ADD A,8			; franja siguiente
	LD H,A
	LD A,(CR_BANDA)
	DEC A
	JR NZ,CR_PB
	RET

; --- (v21) 6 filas de una tabla de nombres. A = trozo: bit 3 = k+1 (si no, k), bit 2 = juego
; 128-253, bits 0-1 = cuál de los 4 trozos de 6 filas. La fila r de la pantalla es la línea
; t=k+r del texto (parte de arriba) o, si está vacía, la t+1 (parte de abajo).
CR_FILAS6:
	LD (CR_TROZO),A
	LD A,(2600h)		; C_V1: página 1 en el cartucho
	OUT (0A8h),A
	LD A,CR_BANCO
	LD (7000h),A		; banco de los créditos en 8000h
	LD A,(2601h)		; C_V2: página 2 en el cartucho (el texto está ahí)
	OUT (0A8h),A
	LD HL,(CR_POS)
	SRL H
	RR L
	SRL H
	RR L
	SRL H
	RR L			; HL = k
	LD A,(CR_TROZO)
	BIT 3,A
	JR Z,CR_F1
	INC HL			; k+1
CR_F1:
	; dirección de la tabla: 1800h + 400h * juego + 2000h * (paridad)
	LD A,L
	AND 1
	RRCA
	RRCA
	RRCA			; 20h si impar
	LD B,A
	LD A,(CR_TROZO)
	AND 4			; 4 si juego 128
	ADD A,B
	ADD A,18h
	LD D,A			; parte alta de la tabla
	LD A,(CR_TROZO)
	AND 3
	LD B,A
	ADD A,A
	ADD A,B
	ADD A,A			; primera fila: 6 * trozo
	LD E,A
	PUSH DE
	LD C,A
	LD B,0
	ADD HL,BC		; t de la primera fila
	LD A,E			; dirección VRAM: tabla + 32 * fila
	LD E,0
	SRL A
	RR E
	SRL A
	RR E
	SRL A
	RR E			; A:E = fila * 32
	ADD A,D
	LD D,A
	EX DE,HL
	CALL VDP_ESCRIBE
	EX DE,HL
	POP DE
	LD A,(CR_TROZO)
	AND 4
	RLCA
	RLCA
	RLCA
	RLCA
	RLCA			; 4 -> 80h
	LD (CR_SUMA),A		; 0 o 80h
	LD C,6
CR_N1:
	PUSH HL
	LD DE,CR_LLENAS_R
	ADD HL,DE
	LD A,(HL)		; ¿línea t con texto?
	POP HL
	PUSH HL
	LD D,0
	OR A
	JR NZ,CR_N2
	INC HL			; no: parte de abajo de la t+1
	INC D
CR_N2:
	LD A,(CR_SUMA)
	ADD A,D
	LD D,A			; D = suma para el patrón
	ADD HL,HL
	ADD HL,HL
	ADD HL,HL
	ADD HL,HL
	ADD HL,HL
	LD A,H
	ADD A,CANVAS_R/256
	LD H,A			; CANVAS alineado a 256: una fila no cruza de página
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	INC L
	NOP
	LD A,(HL)
	ADD A,D
	OUT (98h),A
	POP HL
	INC HL
	DEC C
	JP NZ,CR_N1
	LD A,(2602h)		; C_V0: todo RAM
	OUT (0A8h),A
	RET

; --- VDP
VDP_ESCRIBE:		; dirección HL para escribir
	LD A,L
	OUT (99h),A
	LD A,H
	OR 40h
	OUT (99h),A
	RET
VDP_LEE:		; dirección HL para leer
	LD A,L
	OUT (99h),A
	LD A,H
	OUT (99h),A
	RET
VDP_LLENA:		; BC bytes con E
	LD A,E
	OUT (98h),A
	DEC BC
	LD A,B
	OR C
	JR NZ,VDP_LLENA
	RET
VDP_REG:		; registro C = A
	OUT (99h),A
	LD A,C
	OR 80h
	OUT (99h),A
	RET

CR_POS:		DW 0
CR_OFF:		DB 0
CR_JUEGO:	DB 0
CR_ESPERA:	DW 202	; (v21) espera de cada paso (26 ciclos cada vuelta), para ir al paso de la v20 (20,9 s)
CR_BANDA:	DB 0
CR_TROZO:	DB 0
CR_SUMA:	DB 0
CR_ORIGEN:	DW 0
CR_SAT:		DS 128
	INCLUDE "creditos_datos.inc"	; COLOR_TEXTO, GLIFOS, N_GLIFOS, CR_PASOS
PAG0_A:
	INCBIN "pagina0_a.bin"	; 0000h-0C1Bh de la parte 1 (sin ganchos)
CR_FIN_MODULO:
; (v21) desde aquí solo en la ROM (banco CR_BANCO): CR_FILAS6 lo lee por 8000h
	INCLUDE "creditos_rom.inc"	; CR_LLENAS, CANVAS (alineado a 256)
CR_LLENAS_R	EQU CR_LLENAS-CR_ORG+8000h
CANVAS_R	EQU CANVAS-CR_ORG+8000h
