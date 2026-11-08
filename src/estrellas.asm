; (7-11, ideas de Néstor Sancho) estrellas de la parte 1 en gris. Con --nestor las estrellas ya no se
; mueven con el scroll y build_rom.py las coloca (E1C8h, posiciones de araubi). La zona de arriba (filas
; 0-12) va siempre en tinta 5 (AT_TINTA). Celdas «fijas» (EST_FIJAS: ni Freddy, ni la nave, ni nada
; las pisa nunca, medido en openMSX recorriendo la fase): E1h (gris) cada 8 imágenes, sin mirar nada.
; Celdas «a mirar» (EST_MIRA: alguna vez les pasa algo por encima): en cada imagen se compara el búfer
; con sus estrellas, E1h si solo están ellas y 51h si hay algo más (se manda solo si cambia).
; Va en la RAM de 5800h de la parte 1 (libre e intacta durante el juego).
	INCLUDE "estrellas.inc"	; LIM_SAT, SPR_ON (lo escribe build_rom.py)

; (7-11, araubi: letras rotas al final de la parte 1, «no pasa siempre») Fallo del original en EEAAh
; (rectángulo de color de un objeto en el búfer de atributos 8500h): alto en filas = alto / 8, más 1 si
; la Y no es múltiplo de 8. Con alto < 8 y Y múltiplo de 8 salen 0 filas, y DJNZ da 256 vueltas: pinta
; 4 bytes cada 32 desde 8500h hasta A4FFh y rompe, entre otras cosas, las letras de 8CA0h. Pasa en la
; escena de la nave (la figura que encoge de 6 en 6, D258h) si acaba con Y = 40h y alto 2. Sustituye
; LD BC,(EEA6h) en EECCh; D = Y del objeto.
G_TAM:
	LD BC,(0EEA6h)
	LD A,B
	CP 8
	RET NC
	LD A,D
	AND 7
	RET NZ
	LD B,8			; una fila
	RET
ESTRELLAS:
	LD A,(SPR_ON)		; solo en partida
	OR A
	JP Z,LIM_SAT
	LD HL,EST_CUENTA
	INC (HL)
	IF EST_NM
	LD IX,EST_MIRA		; DW búfer (línea 0 de la celda), DW VRAM de color con escritura, DB x 8, DB color puesto
	LD B,EST_NM
ES_1:	PUSH BC
	LD L,(IX+0)
	LD H,(IX+1)
	PUSH IX
	POP DE
	INC DE
	INC DE
	INC DE
	INC DE
	LD C,0E1h		; sola: gris
	LD B,8
ES_2:	LD A,(DE)
	CP (HL)
	JR Z,ES_3
	LD C,51h		; con algo más: la tinta 5 de la zona
ES_3:	INC DE
	LD A,L
	ADD A,32
	LD L,A
	DJNZ ES_2
	LD A,(EST_CUENTA)
	AND 7
	JR Z,ES_MANDA
	LD A,C
	CP (IX+12)
	JR Z,ES_SIG
ES_MANDA:
	LD (IX+12),C
	LD A,(IX+2)
	OUT (99h),A
	LD A,(IX+3)
	OUT (99h),A
	LD A,C
	LD B,8
ES_4:	OUT (98h),A		; 11 + 4 + 4 + 13 = 32 ciclos entre escrituras
	NOP
	NOP
	DJNZ ES_4
ES_SIG:	LD DE,13
	ADD IX,DE
	POP BC
	DJNZ ES_1
	ENDIF
	LD A,(EST_CUENTA)
	AND 7
	JP NZ,LIM_SAT
	IF EST_NF
	LD HL,EST_FIJAS		; DW VRAM de color de la celda, con el bit de escritura
	LD B,EST_NF
ES_5:	LD A,(HL)
	OUT (99h),A
	INC HL
	LD A,(HL)
	OUT (99h),A
	INC HL
	LD C,B
	LD B,8
	LD A,0E1h		; gris
ES_6:	OUT (98h),A		; 32 ciclos entre escrituras
	NOP
	NOP
	DJNZ ES_6
	LD B,C
	DJNZ ES_5
	ENDIF
	JP LIM_SAT
EST_CUENTA:	DB 0

; --- (7-11, araubi) arranque nuevo: pantalla de carga -> presentación (se salta con una tecla) -> menú
; de partes del banco 0 -> la parte elegida. El arranque entra en la parte 1 por G_ENT_INTRO.
INTRO_MENU:	DB 0	; 1 = al acabar la presentación, al menú de partes (no al del juego)
G_ENT_INTRO:
	LD A,1
	LD (INTRO_MENU),A
	JP 0094h		; la entrada de siempre: presentación
; EFD2h (menú del juego: CALL EFC4h): tras la presentación, al menú de partes
G_MENUP:
	LD A,(INTRO_MENU)
	OR A
	JP Z,0EFC4h
A_PARTES:
	DI
	XOR A
	LD (INTRO_MENU),A	; (el PSG lo calla MENU_PARTES)
	JP 26E0h		; C_MENU del copiador (página 0): pone el cartucho en la página 1
; esperas de la presentación (DEC BC / LD A,B / OR C / JR NZ, 26 ciclos por vuelta): el mismo tiempo
; (vuelta de 44 ciclos, BC x 9/16) mirando cada 256 vueltas si se pulsa algo para saltarla
G_ESPERA:
	PUSH HL
	LD A,B
	OR C
	JR NZ,GE_0
	LD BC,9000h		; 65536 x 9/16
	JR GE_1
GE_0:	LD H,B
	LD L,C
	SRL H
	RR L			; BC / 2
	LD B,H
	LD C,L
	SRL H
	RR L
	SRL H
	RR L
	SRL H
	RR L			; BC / 16
	ADD HL,BC
	LD B,H
	LD C,L
	LD A,B
	OR C
	JR NZ,GE_1
	INC C
GE_1:	DEC BC
	LD A,C
	OR A
	CALL Z,G_TECLA_I
	LD A,B
	OR C
	JR NZ,GE_1
	POP HL
	RET
G_TECLA_I:			; ESPACIO, RETURN o disparo del joystick 1: fuera la presentación
	LD A,(INTRO_MENU)
	OR A
	RET Z
	LD A,I			; P/V = interrupciones activas (la música de la presentación)
	PUSH AF
	DI
	CALL GT_LEE
	POP HL
	JR NZ,A_PARTES		; (A_PARTES deja DI)
	BIT 2,L			; P/V
	RET Z
	EI
	RET
GT_LEE:	IN A,(0AAh)		; NZ = pulsado
	AND 0F0h
	OR 8
	OUT (0AAh),A
	IN A,(0A9h)
	CPL
	AND 01h			; ESPACIO
	RET NZ
	IN A,(0AAh)
	AND 0F0h
	OR 7
	OUT (0AAh),A
	IN A,(0A9h)
	CPL
	AND 80h			; RETURN
	RET NZ
	LD A,15
	OUT (0A0h),A
	IN A,(0A2h)
	AND 0BFh
	OR 03h
	OUT (0A1h),A
	LD A,14
	OUT (0A0h),A
	IN A,(0A2h)
	CPL
	AND 10h			; disparo
	RET

; (7-11, araubi) altura del disparo (gancho en 6494h). El original hacía A = Y del disparo - 40 sin
; mirar el acarreo: con Freddy en lo alto (en las rocas flotantes, Y del disparo < 40) la resta daba
; la vuelta (p. ej. 34 - 40 = 250) y ningún enemigo cumplía, así que el disparo atravesaba al volador
; (el ojo con muelle, Y = 32) aunque le diera en la cabeza. Vuelve con acarreo si no le da.
G_TIRO_Y:
	LD A,(633Bh)
	SUB 28h
	JR C,TY_ALTO		; disparo por encima de la línea 40: sin límite por arriba
	CP B
	CCF
	RET C			; el enemigo está 40 o más por encima
TY_ALTO:
	LD A,(633Bh)
	ADD A,8
	CP B			; acarreo: el enemigo empieza más de 8 por debajo
	RET

; (7-11) más sitios de la presentación donde mirar la tecla de saltarla: el fundido de 69F7h (una
; llamada a 0021h por byte: se mira cada 16) y la escena de la nave (CALL 7705h en 767Bh)
G_W21:	PUSH AF			; 0021h usa A
	LD A,(GW_CUENTA)
	INC A
	LD (GW_CUENTA),A
	AND 15
	CALL Z,G_TECLA_P
	POP AF
	JP 0021h
GW_CUENTA:	DB 0
G_W7705:
	CALL G_TECLA_P
	JP 7705h
G_WEB0E:			; la escena de la nave pinta el suelo (CALL EB0Eh en 75EBh y 7603h)
	CALL G_TECLA_P
	JP 0EB0Eh
; borrados de pantalla de la presentación (L6573h -> 0012h, casi medio segundo): mirar antes y después
G_W48:	CALL G_TECLA_P	; (el borrado de pantalla de 0048h, igual)
	CALL 0048h
	JR G_TECLA_P
G_W12:	CALL G_TECLA_P
	CALL 0012h
G_TECLA_P:			; G_TECLA_I sin tocar AF ni HL
	PUSH AF
	PUSH HL
	CALL G_TECLA_I
	POP HL
	POP AF
	RET
