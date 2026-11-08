; Freddy Hardest - volcado por celdas sucias (común a las dos partes; las direcciones
; de cada parte vienen en optim_?.inc).
; El juego dibuja en un búfer de 1 bit (32 bytes x 128 líneas) y en cada imagen volcaba
; las 480 celdas a la VRAM. Ahora los ganchos de las rutinas que escriben en el búfer o
; en el fondo marcan las celdas tocadas, y el volcado manda solo las marcadas en esta
; imagen o en la anterior (lo que se borró al restaurar el fondo).
; SUCIO: 16 filas x 32 bytes; bit 0 = marcada en esta imagen, bit 1 = en la anterior.
; Claude para araubi, 2026-10-29 (pasmo o sjasmplus).

; ---------------------------------------------------------------- volcado nuevo
VOLCADO:
	CALL SONDEO
	LD A,(MODO)		; ¿esta imagen se hizo con las rutinas con gancho (bucle de juego)?
	LD (VOL_JUEGO),A
	CALL SPR_VOLCADO	; parte 1: Freddy y enemigos con sprites (4-11)
	LD A,(VOL_JUEGO)
	OR A
	LD A,0
	LD (MODO),A
	JR Z,VOL_ENTERO		; no (presentación, otras escenas): se manda entera
	LD A,(TODO)
	OR A
	JR Z,VOL_NORMAL
	DEC A
	LD (TODO),A
VOL_ENTERO:
	XOR A
	LD (RS_VOLC),A
	LD HL,SUCIO		; todo sucio (otra rutina tocó la VRAM)
	LD B,0
VOL_T1:	SET 0,(HL)
	INC HL
	SET 0,(HL)
	INC HL
	DJNZ VOL_T1
	LD HL,FILAS
	LD B,16
VOL_T2:	SET 0,(HL)
	INC HL
	DJNZ VOL_T2
	JR VOL_TODAS
VOL_NORMAL:
	LD A,1
	LD (RS_VOLC),A
VOL_TODAS:
	IF PARTE_B		; (8-11, araubi) cambio de sala en la parte 2: los sprites de la sala anterior se
	CALL G_LIMPIA		; quitan justo cuando empieza a volcarse la nueva (G_SALA lo apunta en SALA_NUEVA);
	ELSE			; hasta entonces se ven con la sala vieja, y los nuevos llegan tras el volcado (LIM_SAT)
	DS 3,0			; (parte 1: mismo sitio para las variables comunes)
	ENDIF
	LD HL,FILAS
	LD C,0
VOL_FILA:
	CALL SONDEO_S	; punto seguro: aquí se puede reescribir la tabla de sprites
	LD A,(HL)
	OR A
	JP Z,VOL_SIGUE
	AND 1
	ADD A,A
	LD (HL),A
	PUSH HL
	LD A,C
	OR 40h
	LD B,A			; B = byte alto de la VRAM (fila) con escritura
	LD A,C
	ADD A,BUFER/256
	LD H,A			; H = página del búfer de esta fila
	LD A,C			; DE = SUCIO + fila*32 + 1
	RRCA
	RRCA
	RRCA
	LD E,A
	AND 0E0h
	INC A
	LD D,E
	LD E,A
	LD A,D
	AND 1
	ADD A,SUCIO/256
	LD D,A
	; (desenrollado 30 veces: sin REPT, para que valga en sjasmplus y pasmo)
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	LD A,(DE)
	OR A
	CALL NZ,VOL_CELDA
	INC E
	POP HL
VOL_SIGUE:
	INC HL
	INC C
	LD A,C
	CP 16
	JP NZ,VOL_FILA
VOL_FIN_CALL:
	CALL LIM_SAT		; (7-11) ya está la imagen en la VRAM: sus sprites, en el próximo cuadro
VOL_FIN:
	RET
; limitador: en el bucle de juego, cada imagen dura al menos LIMITE cuadros
LIMITADOR:
	LD A,(VOL_JUEGO)
	OR A
	RET Z
	LD A,(LIMITE)
	BIT 6,A			; (7-11) bit 6: los bits 0-5 son imágenes por segundo, no cuadros
	JP NZ,LIM_FPS		; (en limita.asm)
	AND 7Fh			; bit 7 = máquina de 60 Hz
	RET Z
	LD B,A
VOL_ESPERA:
	CALL SONDEO_S		; en cada cuadro nuevo del VDP se gira la tabla de sprites
	LD A,(CUENTA)
	CP B
	JR C,VOL_ESPERA
	XOR A
	LD (CUENTA),A
	RET
; cuenta los cuadros del VDP (bit 7 del registro de estado; leerlo lo borra)
; (5-11) SONDEO_S: lo mismo, en los puntos en que la VRAM no está a medio escribir. Si empezó
; un cuadro nuevo del VDP, reescribe la tabla de sprites (girada): así los enemigos se turnan
; en cada cuadro también en la rápida, y no solo una vez por imagen.
SONDEO_S:
	CALL SONDEO
	PUSH AF
	LD A,(SAT_PEND)
	OR A
	JR Z,SOS_1
	CALL SAT_QUIERE		; (7-11) tabla nueva pendiente, o giro si el VDP avisó de un quinto sprite
	OR A
	JR Z,SOS_1
	XOR A
	LD (SAT_PEND),A
	PUSH BC
	PUSH DE
	PUSH HL
	CALL SPR_SAT
	POP HL
	POP DE
	POP BC
SOS_1:	POP AF
	RET
SONDEO:
	PUSH AF
	IN A,(99h)
	BIT 6,A			; quinto sprite en una línea: los enemigos se turnan (SPR_SAT)
	JR Z,SO_0
	LD (QUINTO),A
SO_0:	RLCA
	JR NC,SO_1
	LD (SAT_PEND),A		; cuadro nuevo: la tabla de sprites se reescribe en el próximo punto seguro
	LD A,(CUENTA)
	INC A
	LD (CUENTA),A
	CALL TIC		; una vez por cuadro del VDP: efectos de sonido y teclado
SO_1:	POP AF
	RET
TIC:
	PUSH BC
	PUSH DE
	PUSH HL
	PUSH IX
	PUSH IY
	; a 60 Hz se salta 1 de cada 6 cuadros: los efectos (y lo que se cuente por cuadros,
	; como las animaciones de un futuro Freddy en sprites) van al ritmo de 50 Hz
	CALL ES_TIC50
	CALL C,SONIDO_TIC
	CALL TECLAS_MUESTRA
	POP IY
	POP IX
	POP HL
	POP DE
	POP BC
	RET

; CF = 1 si este cuadro cuenta como cuadro de 50 Hz (siempre a 50 Hz; 5 de cada 6 a 60 Hz)
ES_TIC50:
	LD A,(LIMITE)
	RLCA
	CCF
	RET C			; 50 Hz
	LD HL,SALTO6
	DEC (HL)
	SCF
	RET NZ
	LD (HL),6
	OR A			; CF = 0: este no cuenta
	RET
SALTO6:	DB 6

; ---------------------------------------------------------------- teclado
; El juego lee los mandos una vez por imagen; lo que se pulsa y se suelta entre dos lecturas
; se perdía. Ahora se mira en cada cuadro del VDP y las pulsaciones nuevas se guardan en
; PULSADAS hasta la siguiente lectura del juego (G_MANDOS). Solo cuentan las nuevas: si una
; tecla ya estaba pulsada en la lectura anterior y se suelta, se suelta enseguida.
TECLAS_MUESTRA:
	CALL MANDOS_AHORA	; A = mandos como los ve el juego
	LD B,A
	; si el juego lleva medio segundo sin leer (presentación, menús), no se guarda nada:
	; un ESPACIO pulsado ahí salía luego como patada al empezar la partida
	LD HL,EDAD
	LD A,(HL)
	CP 25
	JR C,TM_GUARDA
	LD A,B
	LD (VISTAS),A
	XOR A
	LD (PULSADAS),A
	RET
TM_GUARDA:
	INC (HL)
	LD A,(VISTAS)
	CPL
	AND B
	AND 1Fh			; direcciones y disparo
	LD HL,PULSADAS
	OR (HL)
	LD (HL),A
	RET
G_MANDOS:		; en lugar de LD (MANDOS),A tras leer teclado y joystick
	PUSH HL
	LD HL,PULSADAS
	OR (HL)
	LD (HL),0
	LD (VISTAS),A
	LD HL,EDAD
	LD (HL),0
	LD (MANDOS),A
	POP HL
	BIT 5,A			; pausa: que no se quede sonando un efecto
	RET Z
	PUSH AF
	PUSH DE
	CALL SND_CALLA_YA
	POP DE
	POP AF
	RET
; manda la celda: E = su posición en SUCIO, H = página del búfer, B = VRAM alta
VOL_CELDA:
	AND 1
	ADD A,A
	LD (DE),A
	LD A,E
	AND 1Fh
	LD L,A
	ADD A,A
	ADD A,A
	ADD A,A
	OUT (99h),A
	LD A,B
	OUT (99h),A
	; (desenrollado 7 veces: sin REPT, para que valga en sjasmplus y pasmo)
	LD A,(HL)
	OUT (98h),A
	LD A,L
	ADD A,20h
	LD L,A
	LD A,(HL)
	OUT (98h),A
	LD A,L
	ADD A,20h
	LD L,A
	LD A,(HL)
	OUT (98h),A
	LD A,L
	ADD A,20h
	LD L,A
	LD A,(HL)
	OUT (98h),A
	LD A,L
	ADD A,20h
	LD L,A
	LD A,(HL)
	OUT (98h),A
	LD A,L
	ADD A,20h
	LD L,A
	LD A,(HL)
	OUT (98h),A
	LD A,L
	ADD A,20h
	LD L,A
	LD A,(HL)
	OUT (98h),A
	LD A,L
	ADD A,20h
	LD L,A
	LD A,(HL)
	OUT (98h),A
	RET

; ---------------------------------------------------------------- marcar
; MARCA_LINEA: A = línea (se toma 0-127), E = columna (0-31), C = ancho en celdas, B = líneas
; conserva BC, DE, HL
MARCA_LINEA:
	CALL SONDEO_S	; punto seguro: aquí se puede reescribir la tabla de sprites
	PUSH HL
	PUSH DE
	PUSH BC
	AND 7Fh
	LD L,A			; línea
	LD A,B
	OR A
	JR Z,ML_FIN
	LD A,C
	OR A
	JR Z,ML_FIN
	CP 33
	JR C,ML_A
	LD C,32
ML_A:	LD A,L
	ADD A,B
	DEC A			; última línea (si pasa de 127 da la vuelta)
	RRCA
	RRCA
	RRCA
	AND 1Fh
	LD D,A
	LD A,L
	RRCA
	RRCA
	RRCA
	AND 0Fh
	LD L,A			; fila inicial
	LD A,D
	SUB L
	AND 0Fh
	INC A
	LD B,A			; filas
	LD A,E
	AND 1Fh
	LD E,A			; columna
	ADD A,C
	SUB 32
	JR NC,ML_B
	XOR A
ML_B:	LD D,A			; D = celdas que dan la vuelta a la columna 0
	LD A,C
	SUB D
	LD C,A			; C = celdas desde la columna E
ML_FILA:
	PUSH BC
	LD A,L
	AND 0Fh
	LD L,A
	PUSH HL
	LD H,FILAS/256
	SET 0,(HL)
	RRCA
	RRCA
	RRCA
	LD H,A
	AND 0E0h		; (fila*32) and 0E0h
	PUSH AF
	OR E
	LD L,A
	LD A,H
	AND 1
	ADD A,SUCIO/256
	LD H,A
	LD B,C
ML_C1:	SET 0,(HL)
	INC L
	DJNZ ML_C1
	POP AF
	LD L,A
	LD A,D
	OR A
	JR Z,ML_C3
	LD B,A
ML_C2:	SET 0,(HL)
	INC L
	DJNZ ML_C2
ML_C3:	POP HL
	POP BC
	INC L
	DJNZ ML_FILA
ML_FIN:	POP BC
	POP DE
	POP HL
	RET

; MARCA_DIR: DE = dirección en el búfer o en el fondo (se toma módulo 1000h), C = bytes, B = líneas
MARCA_DIR:
	PUSH DE
	PUSH AF
	LD A,E
	AND 1Fh
	PUSH AF			; columna
	LD A,D
	SUB BUFER/256
	AND 0Fh
	LD D,A
	LD A,E
	SRL D
	RRA
	SRL D
	RRA
	SRL D
	RRA
	SRL D
	RRA
	SRL D
	RRA			; A = línea
	POP DE			; D = columna
	LD E,D
	CALL MARCA_LINEA
	POP AF
	POP DE
	RET

; marca todo para las dos imágenes siguientes y da por perdidos los colores
MARCA_TODO:
	PUSH AF
	LD A,2
	LD (TODO),A
	LD (ATR_PEND),A
	LD (MARC_SUCIO),A
	POP AF
	RET
ATR_TODOS:			; todas las filas de colores a mandar enteras
	PUSH AF
	XOR A
	LD (ATR_PEND),A
	POP AF
	PUSH HL
	PUSH BC
	LD HL,ATR_MAL
	LD B,24
AT_M1:	LD (HL),1
	INC HL
	DJNZ AT_M1
	POP BC
	POP HL
	RET

; ---------------------------------------------------------------- ganchos
; PINTA_FIGURA: en vez de LD (FIG_ANCHO),BC. DE = y,x (píxel); C = bytes; B = líneas
G_FIGURA:
	LD (FIG_ANCHO),BC
	PUSH DE
	PUSH AF
	LD A,E
	RRCA
	RRCA
	RRCA
	AND 1Fh
	LD E,A
	LD A,D
	CALL MARCA_LINEA
	POP AF
	POP DE
	RET
; COPIA_BLOQUE desde la rutina que calcula la dirección
G_DIR_BLOQUE:
	CALL DIR_BUFER
	JP MARCA_DIR
; COPIA_BLOQUE llamada directamente
G_COPIA_BLOQUE:
	CALL MARCA_DIR
	JP COPIA_BLOQUE
; punto invertido (estrellas): XOR (HL) / LD (HL),A / RET
G_PUNTO:
	XOR (HL)
	LD (HL),A
	PUSH AF
	PUSH HL
	PUSH BC
	LD A,H
	SUB BUFER/256
	AND 0Fh
	LD C,A			; fila de celdas
	LD A,L
	AND 1Fh
	LD B,A			; columna
	LD H,FILAS/256
	LD L,C
	SET 0,(HL)
	LD A,C
	RRCA
	RRCA
	RRCA
	LD H,A
	AND 0E0h
	OR B
	LD L,A
	LD A,H
	AND 1
	ADD A,SUCIO/256
	LD H,A
	SET 0,(HL)
	POP BC
	POP HL
	POP AF
	RET
; desplazamiento del terreno (líneas 96-127 del fondo)
G_TERRENO1:
	CALL MARCA_TERRENO
	LD HL,TERR1_HL
	RET
G_TERRENO2:
	CALL MARCA_TERRENO
	LD HL,TERR2_HL
	RET
MARCA_TERRENO:			; filas 12-15 enteras
	PUSH AF
	PUSH BC
	LD HL,FILAS+12
	SET 0,(HL)
	INC L
	SET 0,(HL)
	INC L
	SET 0,(HL)
	INC L
	SET 0,(HL)
	LD HL,SUCIO+12*32
	LD B,128
MT_1:	SET 0,(HL)
	INC L
	DJNZ MT_1
	POP BC
	POP AF
	RET
; RESTAURA_FONDO: a partir de aquí la imagen la hacen rutinas con gancho
G_RESTAURA:
	CALL SONDEO_S	; punto seguro: aquí se puede reescribir la tabla de sprites
	PUSH AF
	LD A,1
	LD (MODO),A
	LD A,(TODO)
	OR A
	JP NZ,RS_ENTERO
	LD A,(RS_VOLC)		; ¿el último volcado fue por celdas?
	OR A
	JP Z,RS_ENTERO
	; solo las celdas marcadas (en la imagen anterior o en esta): por tramos seguidos
	LD C,0			; fila
RS_FILA:
	CALL SONDEO_S	; punto seguro: aquí se puede reescribir la tabla de sprites
	LD A,C
	LD H,FILAS/256
	LD L,A
	LD A,(HL)
	OR A
	JP Z,RS_SIG
	LD A,C
	RRCA
	RRCA
	RRCA
	LD L,A
	AND 0E0h
	INC A
	LD E,A			; columna 1
	LD A,L
	AND 1
	ADD A,SUCIO/256
	LD D,A			; DE = SUCIO + fila*32 + 1
RS_BUSCA:
	LD A,E
	AND 1Fh
	CP 31
	JP Z,RS_SIG
	LD A,(DE)
	OR A
	JR NZ,RS_TRAMO
	INC E
	JP RS_BUSCA
RS_TRAMO:
	LD B,E			; principio
RS_T1:	INC E
	LD A,E
	AND 1Fh
	CP 31
	JR Z,RS_T2
	LD A,(DE)
	OR A
	JR NZ,RS_T1
RS_T2:	PUSH DE
	PUSH BC
	LD A,E
	SUB B
	LD (RS_LARGO),A
	LD A,B
	AND 1Fh
	LD L,A
	LD A,C
	ADD A,FONDO/256
	LD H,A			; HL = fondo, primera línea de la primera celda
	LD A,(RS_LARGO)
	CP 5
	JP NC,RS_LARGO_LDIR
	LD B,A			; tramos cortos: celda a celda, 8 bytes sin LDIR
RS_CEL:	PUSH HL
	LD A,H
	SUB (FONDO-BUFER)/256
	LD D,A
	LD E,L
	; (desenrollado 7 veces: sin REPT, para que valga en sjasmplus y pasmo)
	LD A,(HL)
	LD (DE),A
	LD A,L
	ADD A,32
	LD L,A
	LD E,A
	LD A,(HL)
	LD (DE),A
	LD A,L
	ADD A,32
	LD L,A
	LD E,A
	LD A,(HL)
	LD (DE),A
	LD A,L
	ADD A,32
	LD L,A
	LD E,A
	LD A,(HL)
	LD (DE),A
	LD A,L
	ADD A,32
	LD L,A
	LD E,A
	LD A,(HL)
	LD (DE),A
	LD A,L
	ADD A,32
	LD L,A
	LD E,A
	LD A,(HL)
	LD (DE),A
	LD A,L
	ADD A,32
	LD L,A
	LD E,A
	LD A,(HL)
	LD (DE),A
	LD A,L
	ADD A,32
	LD L,A
	LD E,A
	LD A,(HL)
	LD (DE),A
	POP HL
	INC L
	DJNZ RS_CEL
	POP BC
	POP DE
	JP RS_BUSCA
RS_LARGO_LDIR:
	LD B,8
RS_LIN:	PUSH BC
	PUSH HL
	LD A,H
	SUB (FONDO-BUFER)/256
	LD D,A
	LD E,L
	LD A,(RS_LARGO)
	LD C,A
	LD B,0
	LDIR
	POP HL
	LD A,L
	ADD A,32
	LD L,A
	POP BC
	DJNZ RS_LIN
	POP BC
	POP DE
	JP RS_BUSCA
RS_SIG:
	INC C
	LD A,C
	CP 16
	JP NZ,RS_FILA
	POP AF
	LD HL,FONDO+1000h
	LD DE,BUFER+1000h
	LD BC,0
	RET
RS_ENTERO:
	POP AF
	LD HL,FONDO
	JP RESTAURA_ORIGINAL
; borrado del fondo entero
G_BORRA_FONDO:
	CALL MARCA_TODO
	LD HL,FONDO
	RET
; LLENA_VRAM (sustituye PUSH AF / LD A,L / OUT (99h),A)
G_LLENA:
	CALL MARCA_TODO
	CALL LLENA_MARC		; (6-11) parte 1: si se borra la pantalla, fuera los sprites del marcador
	PUSH AF
	LD A,L
	OUT (99h),A
	JP LLENA_SIGUE
; escritura de un byte con dirección del Spectrum (sustituye EX DE,HL / LD A,E / OUT (99h),A)
G_BYTE:
	EX DE,HL		; DE = dirección de la VRAM
	LD A,D
	AND 10h			; 1000h-17FFh o 3000h-37FFh: el marcador (filas 16-23), que no toca
	CALL Z,MARCA_TODO	; la zona de juego: entonces sin volcado entero
	JR Z,GB_1
	LD (MARC_SUCIO),A	; el marcador: se repinta en color (parte 1)
GB_1:
	LD A,E
	OUT (99h),A
	RET
; bloque de patrones (sustituye LD E,C / LD D,0)
G_BLOQUE_VRAM:
	CALL MARCA_TODO
	LD E,C
	LD D,0
	RET
; ATRIB_A_COLOR (sustituye OR A / LD DE,5800h)
G_ATRIB_RECT:
	PUSH AF
	LD A,1
	LD (ATR_PEND),A
	POP AF
	OR A
	LD DE,5800h
	RET
; lectura y escritura de un byte de VRAM (fundidos)
G_RMW1:
	CALL MARCA_TODO
	JP RMW1
G_RMW2:
	CALL MARCA_TODO
	JP G_RMW2B		; (7-11) en limita.asm

; ---------------------------------------------------------------- colores
; Sustituye a la rutina que pasa filas de atributos del Spectrum a la tabla de colores:
; HL = dirección de la tabla de colores (fila), A = filas, (ATR_ORIGEN) = atributos.
; Solo manda las celdas cuyo atributo cambió desde la última vez.
ATRIBUTOS:
	PUSH IX
	PUSH AF
	LD A,(ATR_PEND)
	OR A
	CALL NZ,ATR_TODOS
	POP AF
	LD C,20h
	LD E,C
	LD D,0
	LD (ATR_BC),BC
	LD B,A
AT_FILA:
	CALL SONDEO_S	; punto seguro: aquí se puede reescribir la tabla de sprites
	PUSH BC
	PUSH HL
	LD A,H
	OR 60h
	LD (AT_ALTA),A
	LD A,L
	LD (AT_BAJA),A
	LD HL,(ATR_ORIGEN)
	PUSH HL
	LD DE,-ATR_BASE
	ADD HL,DE		; desplazamiento en los atributos (0-2FFh)
	ADD HL,HL
	ADD HL,HL
	ADD HL,HL
	LD E,H			; fila de atributos (0-23)
	LD D,ATR_MAL/256
	LD A,(DE)		; ¿esta fila hay que mandarla entera?
	LD (AT_TODAS),A
	XOR A
	LD (DE),A
	POP HL
	PUSH HL
	LD DE,SOMBRA_ATR-ATR_BASE
	ADD HL,DE
	EX DE,HL		; DE = sombra
	POP HL			; HL = atributos
	IF TINTA_FIJA		; (6-11) filas de tinta fija en partida: ni se miran (AT_SALTA en spr_a.asm)
	CALL AT_SALTA
	JP Z,AT_SALTADA
	ELSE
	DS 6,0			; los mismos bytes en las dos partes (LIMITE)
	ENDIF
	LD C,32
	LD B,0			; B = 0: la dirección de la VRAM no está puesta
AT_CELDA:
	LD A,(AT_TODAS)
	OR A
	LD A,(HL)
	JR NZ,AT_MANDA
	EX DE,HL
	CP (HL)
	EX DE,HL
	JR NZ,AT_MANDA
	LD B,0
	JR AT_SIG
AT_MANDA:
	LD (DE),A
	LD (AT_DESP+2),A
	LD A,1
	LD (ATR_TOCADO),A	; aviso: los colores de los enemigos pueden haberse perdido
	LD (MARC_SUCIO),A	; y los del marcador
	LD A,(AT_DESP+2)
	LD (AT_DESP+2),A	; desplazamiento con signo, como el original
	LD A,B
	OR A
	JR NZ,AT_PUESTA
	LD A,32
	SUB C
	ADD A,A
	ADD A,A
	ADD A,A
	PUSH HL
	LD HL,AT_BAJA
	ADD A,(HL)
	OUT (99h),A
	LD A,(AT_ALTA)
	OUT (99h),A
	POP HL
	INC B
AT_PUESTA:
	LD IX,TABLA_COLOR
AT_DESP:
	LD A,(IX+0)
	IF TINTA_FIJA
	CALL AT_TINTA		; (5-11) en la zona de Freddy, siempre tinta 5 (en spr_a.asm)
	ELSE
	DS 3,0			; los mismos bytes: LIMITE tiene que caer igual en las dos partes
	ENDIF
	; (desenrollado 7 veces: sin REPT, para que valga en sjasmplus y pasmo)
	OUT (98h),A
	NOP
	NOP
	NOP
	NOP
	OUT (98h),A
	NOP
	NOP
	NOP
	NOP
	OUT (98h),A
	NOP
	NOP
	NOP
	NOP
	OUT (98h),A
	NOP
	NOP
	NOP
	NOP
	OUT (98h),A
	NOP
	NOP
	NOP
	NOP
	OUT (98h),A
	NOP
	NOP
	NOP
	NOP
	OUT (98h),A
	NOP
	NOP
	NOP
	NOP
	OUT (98h),A
AT_SIG:
	INC HL
	INC DE
	DEC C
	JP NZ,AT_CELDA
AT_FINF:
	LD (ATR_ORIGEN),HL
	POP HL
	INC H
	POP BC
	DEC B
	JP NZ,AT_FILA
	POP IX
	RET
AT_BAJA:	DB 0
AT_ALTA:	DB 0
AT_TODAS:	DB 0
TODO:		DB 2
VOL_JUEGO:	DB 0
CUENTA:		DB 0
ULT_CUENTA:	DB 0
MARC_SUCIO:	DB 1	; hay que repintar el marcador en color (parte 1)
ATR_TOCADO:	DB 0	; ATRIBUTOS mandó colores (los de los enemigos pueden haberse perdido)
SAT_PEND:	DB 0	; empezó un cuadro nuevo y la tabla de sprites no se ha reescrito
QUINTO:		DB 0	; el VDP avisó de un quinto sprite en una línea
LIMITE:		DB 0	; lo pone el arranque de la ROM (cuadros por imagen; 0 = sin límite; bit 7 = 60 Hz)
A8_RAM:		DB 0	; puerto A8h: todo RAM (lo pone el copiador, como los dos siguientes)
A8_P1:		DB 0	; página 1 en el cartucho
A8_P2:		DB 0	; página 2 en el cartucho
MODO:		DB 0
PULSADAS:	DB 0
VISTAS:		DB 0
EDAD:		DB 0		; cuadros desde la última lectura del juego
ATR_PEND:	DB 1
RS_VOLC:	DB 0
RS_LARGO:	DB 0

; ---------------------------------------------------------------- ganchos de la parte 2
; cálculo de la dirección de una figura o bloque (DE = y,x en píxeles ya pasados a celdas)
G_B_DIR:
	LD HL,BUFER
	ADD HL,DE
	PUSH AF
	PUSH BC
	PUSH DE
	EX DE,HL
	LD HL,(FIG_TAM)
	LD A,L
	AND 7Fh
	INC A
	LD C,A
	LD B,H
	CALL MARCA_DIR
	EX DE,HL
	POP DE
	POP BC
	POP AF
	RET
; reposición de lo que había debajo de cada figura (DE destino, C ancho, B líneas)
G_B_REPON:
	LD L,(IX+4)
	JP MARCA_DIR
; principio de la reposición: la imagen es del bucle de juego
G_B_MODO:
	CALL SONDEO_S	; punto seguro: aquí se puede reescribir la tabla de sprites
	LD A,1
	LD (MODO),A
	LD IX,(LISTA_REPON)
	RET
; rutinas que rehacen la pantalla entera
G_TODO_5000:
	CALL MARCA_TODO
	LD HL,5000h
	RET
G_TODO_BUFER:
	CALL MARCA_TODO
	LD HL,BUFER
	RET
G_TODO_IX:
	CALL MARCA_TODO
	LD IX,TABLA_IX
	RET
