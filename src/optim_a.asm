; Freddy Hardest, parte 1: direcciones del juego para optim.asm y sitio del módulo.
BUFER		EQU 6500h	; búfer de la zona de juego (32 x 128)
FONDO		EQU 7500h	; fondo limpio (se copia al búfer en cada imagen)
TERR1_HL	EQU 84FFh
TERR2_HL	EQU 8100h
DIR_BUFER	EQU 0EE60h
COPIA_BLOQUE	EQU 0EE43h
FIG_ANCHO	EQU 0EEA6h
LLENA_SIGUE	EQU 03A1h
RMW1		EQU 016Dh
RMW2		EQU 01C5h
TABLA_COLOR	EQU 2778h
ATR_ORIGEN	EQU 04FCh
ATR_BC		EQU 0500h
ATR_BASE	EQU 8500h
RESTAURA_ORIGINAL EQU 0EF21h
FIG_TAM		EQU 0
LISTA_REPON	EQU 0
TABLA_IX	EQU 0
MANDOS		EQU 0D936h
SONIDO_N	EQU 958Dh	; efecto pedido por el juego (1-6)
SUCIO		EQU 1E00h	; 512 bytes
FILAS		EQU 2000h	; 16
ATR_MAL		EQU 2100h	; 24
SOMBRA_ATR	EQU 2200h	; 768 (hasta 24FFh; 26F8h-2777h no se toca)

	ORG 0C40h
	INCLUDE "tinta.inc"	; TINTA_FIJA, FILA_PIES (lo escribe build_rom.py)
PARTE_B		EQU 0
	INCLUDE "optim.asm"
; mandos como en 022Eh (teclado OR joystick, con los bits 3 y 4 cambiados)
MANDOS_AHORA:
	CALL 05E7h
	PUSH AF
	LD A,1
	CALL 060Ch
	CALL 063Ah
	POP BC
	OR B
	LD B,A
	AND 0E7h
	BIT 3,B
	JR Z,MA_1
	SET 4,A
MA_1:	BIT 4,B
	RET Z
	SET 3,A
	RET

; ---------------------------------------------------------------- disparo
; Arreglo de un fallo del original: el disparo avanza en 3 pasos de 32 px y en cada paso mata
; a los enemigos con shot-16 < X <= shot+24 (shot = X del disparo, 64A1h). Mirando a la
; derecha, el primer paso empieza en Freddy+32 y un enemigo entre Freddy+8 y Freddy+16 (pegado,
; pero sin tocarle) no recibía nunca: el disparo seguía y moría el de detrás. Ahora el primer
; paso llega hasta Freddy por los dos lados (hasta la zona en la que el enemigo ya le mata), y los
; siguientes también (29-10 noche: el enemigo de delante se colaba entre dos pasos).
; Vuelve con acarreo si no le da.
G_TIRO_X:
	LD HL,(633Ah)
	LD H,0
	LD DE,(0EEA4h)		; X de la pantalla
	ADD HL,DE
	LD B,H
	LD C,L			; BC = límite izquierdo (el enemigo da si BC < X+16)
	LD DE,24
	ADD HL,DE		; HL = límite derecho (da si X <= HL)
	; en todos los pasos (no solo en el primero) desde Freddy: si no, un enemigo que se acerca
	; puede quedar entre dos pasos y morir antes el de detrás
	LD A,(6339h)
	OR A
	JR Z,TX_DER
	LD HL,(0D927h)		; a la izquierda: hasta Freddy+8
	LD DE,8
	ADD HL,DE
	JR TX_X
TX_DER:
	LD BC,(0D927h)		; a la derecha: desde Freddy-16
TX_X:
	LD E,(IX+3)
	LD D,(IX+4)
	AND A
	SBC HL,DE
	RET C			; X > límite derecho
	LD HL,16
	ADD HL,DE
	AND A
	SBC HL,BC		; X+16-BC
	RET C
	SCF
	RET Z
	; le da: en el original moría el primero de la lista (y FAA5, la de los puntos, le
	; cambia IX, así que los demás ni se miraban), que podía ser el de detrás. Ahora se
	; apunta el más cercano a Freddy y G_TIRO_MATA lo mata al acabar la vuelta.
	LD HL,(0D927h)
	AND A
	SBC HL,DE		; Freddy - X
	JR NC,TX_ABS
	EX DE,HL
	LD HL,0
	AND A
	SBC HL,DE
TX_ABS:	LD DE,(TIRO_DIST)
	EX DE,HL
	AND A
	SBC HL,DE		; mejor distancia - esta
	JR C,TX_NO
	JR Z,TX_NO
	LD (TIRO_DIST),DE
	LD (TIRO_IX),IX
TX_NO:	SCF			; sigue con el siguiente enemigo
	RET
; en lugar de CALL 646Ch (6393h): mira los 6 enemigos y mata solo al más cercano
G_TIRO_MATA:
	LD HL,0FFFFh
	LD (TIRO_DIST),HL
	CALL 646Ch
	LD HL,(TIRO_DIST)
	INC HL
	LD A,H
	OR L
	RET Z			; no le ha dado a nadie
	LD IX,(TIRO_IX)
	INC (IX)
	LD A,1
	LD (6340h),A
	JP 0FAA5h
TIRO_DIST:	DW 0
TIRO_IX:	DW 0

; ---------------------------------------------------------------- efectos de sonido
; El original los hacía con el clic del teclado y bucles de espera (9579h): el juego se paraba
; mientras sonaban (la explosión, 107 ms). Ahora suenan por el canal A del PSG con el mismo
; tono y duración (redondeada a cuadros de 20 ms) mientras el juego sigue.
G_SONIDO:		; en lugar de 9546h
	LD A,(SONIDO_N)
	OR A
	RET Z
	LD HL,SND_TABLA-2
	ADD A,A
	LD E,A
	LD D,0
	ADD HL,DE
	LD E,(HL)
	INC HL
	LD D,(HL)
	LD (SND_PTR),DE
	XOR A
	LD (SONIDO_N),A
	LD A,7
	OUT (0A0h),A
	LD A,0BEh		; solo tono A (puerto A entrada, B salida)
	OUT (0A1h),A
	JR SND_PASO
SONIDO_TIC:
	LD HL,(SND_PTR)
	LD A,H
	OR L
	RET Z
	LD HL,SND_QUEDA
	DEC (HL)
	RET NZ
SND_PASO:		; siguiente nota: DW periodo (0 = fin), DB cuadros
	LD HL,(SND_PTR)
	LD E,(HL)
	INC HL
	LD D,(HL)
	INC HL
	LD A,D
	OR E
	JR Z,SND_CALLA
	XOR A
	OUT (0A0h),A
	LD A,E
	OUT (0A1h),A
	LD A,1
	OUT (0A0h),A
	LD A,D
	OUT (0A1h),A
	LD A,8
	OUT (0A0h),A
	LD A,SND_VOLUMEN
	OUT (0A1h),A
	LD A,(HL)
	INC HL
	LD (SND_QUEDA),A
	LD (SND_PTR),HL
	RET
SND_CALLA_YA:
	LD DE,0
SND_CALLA:
	LD (SND_PTR),DE		; DE = 0
	LD A,8
	OUT (0A0h),A
	XOR A
	OUT (0A1h),A
	RET
SND_PTR:	DW 0
SND_QUEDA:	DB 0
	INCLUDE "sonidos.inc"	; SND_VOLUMEN, SND_TABLA (lo genera build_rom.py)
	INCLUDE "spr_a.asm"
	DS SUCIO-$,0
	DS 512,0
	DS 16,0
	DS ATR_MAL-$,0
	DS 24,1
	DS SOMBRA_ATR-$,0
	DS 768,0
OPTIM_FIN:
; (6-11) de aquí a 25FFh (el copiador sigue en 2600h): libre en las dos partes
; (6-11) menú: «3-IR A PARTE 2»
TXT_RUT		EQU 0F181h
TXT_SIG		EQU 0F01Dh
MENU_JUEGO	EQU 0F190h
MENU_SIGUE	EQU 00BDh
	INCLUDE "partes.inc"
	INCLUDE "cambia.asm"
	INCLUDE "limita.asm"
; (7-11) G_TIRO_Y (altura del disparo) está ahora en estrellas.asm (5800h): aquí no cabía
TXT3:	DB 58h,30h,14,1Dh,25h,09h,12h,26h,01h,26h,10h,01h,12h,14h,05h,26h,1Ch	; 3-IR A PARTE 2
	DS 2600h-$,0
