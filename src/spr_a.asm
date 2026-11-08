; ---------------------------------------------------------------- sprites (parte 1)
; Freddy sale con sprites del VDP en vez de pintarse con máscara en el búfer. Desde el 4-11-2026
; (noche) solo Freddy, en los colores de graficos/freddy_colores.png de araubi; los enemigos vuelven
; al búfer (con --enemigos también salen en sprites, de un color por tipo).
; - PINTA_FIGURA (ECB0h) salta a SPR_FIG: si la figura está en SPR_TABLA y la imagen la está
;   haciendo el bucle de juego (MODO), se apunta en FIGS y no se pinta en el búfer.
; - Cada figura tiene en la ROM (bancos 9 en adelante) su lista de sprites de 16 x 16 de un color
;   (la prepara build_rom.py con spr_freddy.py, sin pasar de 4 por línea) y sus patrones, con
;   espejo. Al volcar, la lista se copia a la página 0 (LBUF) y los patrones van a la VRAM (hueco n
;   de 3800h) solo si el hueco no tenía ya ese mismo patrón.
; - Freddy va siempre el primero en la tabla de atributos (no parpadea nunca); los demás detrás,
;   girados un puesto por cuadro solo cuando el VDP avisa de quinto sprite (SPR_SAT).
; - Se recorta a la zona de juego: columnas 8-247 y líneas 0-127, como el búfer.
; Claude para araubi, 2026-11-04 (pasmo o sjasmplus).

	IF PARTE_B
	INCLUDE "spr_opc_b.inc"	; (7-11) parte 2: sus figuras, la misma cara del marcador
; RAM de la parte 2 (probada libre en partida): variables en 4F80h-4FC5h (las de la parte 1 + 0A00h)
FIGS		EQU 5B00h
SATBUF		EQU 5B80h
CACHE		EQU 5900h
CACHE1		EQU 5800h
RAMV		EQU 0A00h
	ELSE
	INCLUDE "spr_opc.inc"	; MASCARA (lo escribe build_rom.py)
FIGS		EQU 4600h	; 8 figuras x 16 bytes
SATBUF		EQU 4680h	; 32 x 4
CACHE		EQU 4800h	; 32 x 8: qué patrón tiene cada hueco (mitad 0 de los patrones)
CACHE1		EQU 4700h	; lo mismo para la mitad 1
RAMV		EQU 0
	ENDIF
MITADP		EQU 459Eh+RAMV	; mitad de los patrones en la que se escribe esta imagen (0/1)
CACHE_H		EQU 459Fh+RAMV	; página de su caché
FIGN		EQU 4580h+RAMV
NSPR		EQU 4581h+RAMV
ROT		EQU 4582h+RAMV
SPR_ON		EQU 4583h+RAMV
NFILAS		EQU 4588h+RAMV
TY		EQU 458Ah+RAMV	; línea de pantalla del bloque
MASKL		EQU 458Bh+RAMV
MASKR		EQU 458Ch+RAMV
TMP_X		EQU 458Eh+RAMV	; 2
CLAVE		EQU 45C0h+RAMV	; 6
FNUM		EQU 4593h+RAMV
TMP_PAT		EQU 4594h+RAMV	; 2
MITAD		EQU 4596h+RAMV
NLN		EQU 4597h+RAMV	; celdas de color: n.º en la lista nueva
OLN		EQU 4598h+RAMV	; y en la vieja
SC_COL		EQU 4599h+RAMV
SC_F0		EQU 459Ah+RAMV
SC_F1		EQU 459Bh+RAMV
SC_C0		EQU 459Ch+RAMV
SC_C1		EQU 459Dh+RAMV
OLI		EQU 4900h	; 64 x 2: celda (fila*32 + columna) de las que tienen color de enemigo
OLC		EQU 4980h	; 64: su color
NLI		EQU 4A00h
NLC		EQU 4A80h
CELA		EQU 4C00h	; 512: color de enemigo puesto en cada celda (0 = el de siempre)
CELB		EQU 4E00h	; 512: el que toca en esta imagen
NFIJOS		EQU 4590h+RAMV	; sprites de Freddy (fijos al principio de la tabla)
PASO		EQU 4591h+RAMV	; 80h = pasada de Freddy, 0 = enemigos
FINI		EQU 45A0h+RAMV	; 8: primer sprite de cada enemigo en SATBUF
NFENE		EQU 45A8h+RAMV	; figuras que giran (enemigos, y Freddy con FREDDY_GIRA) con sprites en esta imagen
ROTF		EQU 45A9h+RAMV	; enemigo que va primero en la tabla

G_FIG_X		EQU 0EE93h
G_FIG_Y		EQU 0EE95h
G_FIG_GRAF	EQU 0EE96h
G_FIG_ESPEJO	EQU 0EE9Ah
G_FIG_MEDIDAS	EQU 0EE9Bh
G_FIG_XREL	EQU 0EE86h	; HL = FIG_X - X_PANTALLA
PINTA_SIGUE	EQU 0ECB3h

	IF PARTE_B
; (7-11) parte 2: PINTA_FIGURA (F562h) salta aquí. Posición en FIG_POS (x, y con signo), orientación
; deseada en F97Ah; el gráfico se voltea en su sitio, así que el espejo es F97Ah XOR la orientación
; con la que se hicieron los sprites (bit 5 de la entrada de SPR_TABLA).
B_FIG_GRAF	EQU 0F78Ah
B_FIG_MEDIDAS	EQU 0F78Ch
B_FIG_POS	EQU 0F81Ah
B_FIG_ORIENT	EQU 0F97Ah
SPR_FIG:
	LD A,(MODO)
	OR A
	JR Z,SF_NORMAL
	LD HL,(B_FIG_GRAF)
	LD DE,SPR_TABLA
SFT_1:	LD A,(DE)
	LD C,A
	INC DE
	LD A,(DE)
	DEC DE
	LD B,A
	OR C
	JR Z,SF_NORMAL
	LD A,C
	CP L
	JR NZ,SFT_2
	LD A,B
	CP H
	JR Z,SF_APUNTA
SFT_2:	LD A,E
	ADD A,8
	LD E,A
	JR NC,SFT_1
	INC D
	JR SFT_1
SF_NORMAL:
	LD BC,(B_FIG_MEDIDAS)
	JP 0F566h
SF_APUNTA:
	LD A,(FIGN)
	CP 8
	RET NC
	INC A
	LD (FIGN),A
	DEC A
	PUSH IX
	PUSH DE
	ADD A,A
	ADD A,A
	ADD A,A
	ADD A,A
	LD E,A
	LD D,0
	LD IX,FIGS
	ADD IX,DE
	POP DE
	LD (IX+0),E
	LD (IX+1),D
	INC DE
	INC DE
	LD A,(DE)
	LD (IX+8),A		; bit 7: Freddy, bit 5: orientación de los sprites
	LD B,A
	INC DE
	INC DE
	INC DE
	INC DE
	INC DE
	LD A,(DE)
	LD (IX+9),A
	LD (MITAD),A
	LD HL,(B_FIG_POS)
	LD (IX+2),L
	LD (IX+3),0
	LD (IX+4),H
	LD HL,(B_FIG_MEDIDAS)
	RES 7,L
	LD (IX+5),L
	LD (IX+6),H
	LD A,B
	RLCA
	RLCA
	RLCA
	AND 1
	LD B,A
	LD A,(B_FIG_ORIENT)
	XOR B
	AND 1
	LD (IX+7),A
	POP IX
	LD A,(MITAD)
	INC A			; 0FFh: entera en el búfer (Freddy) y encima sus sprites
	JP Z,SF_NORMAL
	IF MASCARA		; (7-11, araubi) enemigo: además su máscara negra en el búfer (el juego la pinta con
	LD HL,(B_FIG_GRAF)	; el gráfico a cero; el volteo va por F97Bh y FIG_MASCARA, así que no se toca)
	PUSH HL
	LD HL,CEROS
	LD (B_FIG_GRAF),HL
	CALL SF_NORMAL
	POP HL
	LD (B_FIG_GRAF),HL
	ENDIF
	RET			; enemigo: solo sprites
	ELSE
SPR_FIG:		; en lugar de LD A,(0EE9Ah) al principio de PINTA_FIGURA
	LD A,(MODO)
	OR A
	JR Z,SF_NORMAL
	LD HL,(G_FIG_GRAF)
	LD DE,SPR_TABLA		; ¿es una figura con sprites?
SFT_1:	LD A,(DE)
	LD C,A
	INC DE
	LD A,(DE)
	DEC DE
	LD B,A
	OR C
	JR Z,SF_NORMAL
	LD A,C
	CP L
	JR NZ,SFT_2
	LD A,B
	CP H
	JR Z,SF_APUNTA
SFT_2:	LD A,E
	ADD A,8
	LD E,A
	JR NC,SFT_1
	INC D
	JR SFT_1
SF_NORMAL:
	LD A,(G_FIG_ESPEJO)
	JP PINTA_SIGUE
SF_APUNTA:		; DE = su entrada de SPR_TABLA
	LD A,(FIGN)
	CP 8
	RET NC
	INC A
	LD (FIGN),A
	DEC A
	PUSH IX
	PUSH DE
	ADD A,A
	ADD A,A
	ADD A,A
	ADD A,A
	LD E,A
	LD D,0
	LD IX,FIGS
	ADD IX,DE
	POP DE
	LD (IX+0),E
	LD (IX+1),D
	INC DE
	INC DE
	LD A,(DE)
	LD (IX+8),A		; bit 7: Freddy (va delante y no parpadea), bit 6: mitad de arriba en el búfer
	INC DE
	INC DE
	INC DE
	INC DE
	INC DE
	LD A,(DE)		; color de la mitad de arriba (0 = todo en sprites)
	LD (IX+9),A
	LD (MITAD),A
	CALL G_FIG_XREL
	LD (IX+2),L
	LD (IX+3),H
	LD A,(G_FIG_Y)
	LD (IX+4),A
	LD HL,(G_FIG_MEDIDAS)
	LD (IX+5),L
	LD (IX+6),H
	LD A,(G_FIG_ESPEJO)
	OR A
	JR Z,SFA_1
	LD A,1
SFA_1:	LD (IX+7),A
	POP IX
	LD A,(MITAD)		; enemigo a medias: la mitad de arriba se pinta en el búfer
	OR A
	JR Z,SFA_2
	INC A			; 0FFh: entera en el búfer, como el original, y encima sus sprites
	JP Z,SF_NORMAL
	LD HL,(G_FIG_MEDIDAS)
	PUSH HL
	SRL H
	LD (G_FIG_MEDIDAS),HL
	CALL SF_NORMAL
	POP HL
	LD (G_FIG_MEDIDAS),HL
	RET
SFA_2:
	IF MASCARA		; además pinta la máscara negra en el búfer: el mismo dibujo con el gráfico a cero
	LD HL,(G_FIG_GRAF)
	PUSH HL
	LD HL,CEROS
	LD (G_FIG_GRAF),HL
	CALL SF_NORMAL
	POP HL
	LD (G_FIG_GRAF),HL
	ENDIF
	RET
	ENDIF

; al volcar: convierte las figuras apuntadas en sprites
SPR_VOLCADO:
	LD A,(VOL_JUEGO)
	OR A
	JP NZ,SV_JUEGO
	XOR A			; fuera del juego: se esconden
	LD (FIGN),A
	CALL SC_OLVIDA		; y los colores de los enemigos se dan por perdidos
	LD A,(SPR_ON)
	OR A
	JR Z,SV_FUERA
	CALL ATR_TODOS		; fuera de la partida, los colores de siempre
	CALL SPR_ESCONDE
	LD A,1
	LD (MARC_SUCIO),A
SV_FUERA:	; (6-11) fuera de la partida (presentación, muerte, fin) el marcador también va en color
	LD A,MARC_PRUEBA AND 0FFh
	OUT (99h),A
	LD A,MARC_PRUEBA/256
	OUT (99h),A
	NOP
	NOP
	NOP
	IN A,(98h)
	CP MARC_PRUEBA_O	; el byte de prueba de la cara, el original o el de araubi (en los menús,
	JR Z,SVF_1		; esa celda tiene otras cosas)
	CP MARC_PRUEBA_N
	JR Z,SVF_1
	LD A,(OJO_ON)		; no hay marcador: fuera sus sprites
	OR A
	RET Z
	XOR A
	LD (OJO_ON),A
	JP SS_VACIO
SVF_1:	LD A,(OJO_ON)
	OR A
	JR Z,SVF_2		; acaba de aparecer
	LD A,(MARC_SUCIO)
	OR A
	RET Z
SVF_2:	CALL PINTA_MARCADOR
	LD A,(OJO_ON)
	OR A
	RET Z
	CALL SUBE_MARC
	JP SS_VACIO
; (6-11) al empezar la partida el juego dibuja el marcador original y hace la presentación (nave
; que se estrella) sin volcados: aquí se pone el marcador en color
; (8-11, tester de araubi) el volcado del marcador (0018h, unos 45 ms) dejaba ver un par de imágenes sus
; colores originales antes de pintarlo en color: ahora va en F1BAh (parte 1; CBBAh en la 2), en lugar de CALL 0018h, con la
; pantalla apagada (R#1 = A0h). SV_FUERA la vuelve a encender (SUBE_MARC pone R#1 = E2h) ya en color.
G_INTRO:
	LD A,0A0h
	OUT (99h),A
	LD A,81h
	OUT (99h),A
	CALL 0018h
	PUSH AF
	PUSH BC
	PUSH DE
	PUSH HL
	XOR A
	LD (OJO_ON),A
	CALL SV_FUERA
	POP HL
	POP DE
	POP BC
	POP AF
	RET
; (8-11) también en la parte 2 (CBBAh): allí el marcador original se veía unos 0,3 s
; (6-11) LLENA_VRAM (HL = dirección con escritura, BC bytes): si llena la celda de prueba de la
; cara del marcador (borrado de pantalla para los menús), sus sprites se quitan ya
LLENA_MARC:
	PUSH AF
	PUSH HL
	LD A,H
	AND 3Fh
	LD H,A
	LD A,(OJO_ON)
	OR A
	JR Z,LM_FIN
	PUSH DE
	LD DE,MARC_PRUEBA+1
	EX DE,HL
	OR A
	SBC HL,DE		; HL = prueba+1 - inicio
	JR C,LM_NO		; empieza después
	JR Z,LM_NO
	DEC HL
	OR A
	SBC HL,BC
	JR NC,LM_NO		; acaba antes
	XOR A
	LD (OJO_ON),A
	LD A,1
	LD (MARC_SUCIO),A
	LD (MARC_CUENTA),A	; (7-11) 1B00h cambia aquí: SPR_SAT reescribe los del marcador
	XOR A
	OUT (99h),A
	LD A,5Bh
	OUT (99h),A
	LD A,(SPR_ON)		; en la partida, SPR_SAT lo rehace; fuera, solo el final
	OR A
	JR NZ,LM_NO
	LD A,208
	OUT (98h),A
LM_NO:	POP DE
LM_FIN:	POP HL
	POP AF
	RET
	IF PARTE_B = 0
; (6-11) letra de 8 x 8 en la VRAM (sustituye L0221: la dirección con L0385 y 7 OUT seguidos). Con
; las escrituras tan juntas, el VDP del MSX1 (y openMSX, que lo imita) perdía bytes durante la imagen:
; el mensaje del final de la parte 1 salía con restos. Aquí se espera entre byte y byte.
G_TEXTO:
	EX DE,HL
	PUSH AF
	PUSH BC
	EX DE,HL
	CALL 0455h		; dirección del Spectrum -> VRAM
	CALL G_BYTE		; DE = VRAM, HL = letra; manda el byte bajo
	LD A,D
	OR 40h
	OUT (99h),A
	LD B,8
GT_1:	EX (SP),HL
	EX (SP),HL
	LD A,(HL)
	OUT (98h),A
	INC HL
	DJNZ GT_1
	POP BC
	POP AF
	INC DE			; como al salir de L0221
	DEC BC
	LD B,0
	RET
	ENDIF
; esconde los sprites de la partida (quedan los del marcador)
SPR_ESCONDE:
	XOR A
	LD (SPR_ON),A
	LD (NSPR),A
	LD (NFENE),A
	JP SS_VACIO
	IF PARTE_B
; (7-11, araubi) fin de partida en la parte 2 (F123h): la pantalla de GAME OVER y la espera hasta el menú
; van sin volcados, y quedaban los sprites de la última imagen y los del marcador
G_FIN_P2:
	PUSH AF
	CALL SPR_ESCONDE
	XOR A
	LD (OJO_ON),A
	LD (FIGN),A		; y las figuras apuntadas de la última imagen (el GAME OVER sí hace un volcado)
	CALL SS_VACIO
	POP AF
	JP 0E51Ch		; lo que había: CALL E51Ch
; (8-11, araubi: «hay que controlar la limpia de sprites de pantalla a pantalla») ENTRA_SALA (CCF8h)
; es la entrada común de todos los cambios de sala (a los lados, por el ascensor arriba y abajo).
; v25 quitaba aquí los sprites, pero la sala vieja se quedaba unos 15 cuadros sin ellos mientras se
; construía la nueva. Ahora aquí solo se apunta (SALA_NUEVA) y se olvidan las figuras apuntadas de la
; sala vieja; los sprites se quitan en G_LIMPIA, al empezar el volcado de la sala nueva.
G_SALA:
	PUSH AF
	XOR A
	LD (FIGN),A
	INC A
	LD (SALA_NUEVA),A
	POP AF
	LD B,0			; lo que había
	LD DE,(0D3B5h)
	RET
SALA_NUEVA:	DB 0
; (VOL_TODAS, antes de mandar la primera fila) primer volcado tras un cambio de sala: fuera los sprites
; de la partida que hay en la VRAM (los de la sala vieja). Las listas nuevas no se tocan: SAT_EST está
; en 2 (volcado en curso: sin giros) y LIM_SAT escribe la tabla nueva al acabar el volcado.
G_LIMPIA:
	LD A,(SALA_NUEVA)
	OR A
	RET Z
	XOR A
	LD (SALA_NUEVA),A
	LD A,(VOL_JUEGO)
	OR A
	JP NZ,SS_VACIO
	JP SPR_ESCONDE		; fuera de la partida (SPR_VOLCADO ya los quitó si estaban)
; (8-11, araubi) barra de disparos (E443h): el juego pinta el color de la celda en la VRAM sin tocar el
; atributo; se guarda también en el atributo (HL), para que cualquier repintado de colores la respete
G_BARRA:
	LD (HL),A
	JP 0060h
; (F177h) el GAME OVER redibuja la sala con sus enemigos y hace un volcado: antes de la espera hasta
; el menú se vuelven a quitar
G_FIN_P2B:
	CALL SPR_ESCONDE
	XOR A
	LD (OJO_ON),A
	LD (FIGN),A
	CALL SS_VACIO
	LD BC,01F4h		; lo que había
	RET
	ENDIF
	IF PARTE_B = 0
; (6-11) textos del final de la parte 1 y de fin de partida: se escriben directos en la VRAM y
; los sprites de la última imagen los tapaban
G_FIN_A:
	CALL SPR_ESCONDE
	LD HL,0D81Ah
	RET
; (8-11) G_FIN_B ya no hace falta: FB75h llama a G_FIN_A (TO BE CONTINUED en D81Ah)
; (6-11) rectángulos de color de los objetos (ATRIB_A_COLOR): en las filas de tinta fija, tinta 5.
; Sustituye LD A,H / OR 60h / OUT (99h),A del bucle; el color está en la pila (PUSH AF).
G_ATR_FILA:
	LD A,H
	OR 60h
	OUT (99h),A
	IF TINTA_FIJA
	LD A,(SPR_ON)
	OR A
	RET Z
	LD A,H
	CP FILA_PIES+1
	RET NC
	PUSH HL
	LD HL,5
	ADD HL,SP
	LD A,(HL)
	AND 0Fh
	OR 50h
	LD (HL),A
	POP HL
	ENDIF
	RET
	ENDIF
SV_JUEGO:
	LD A,(SPR_ON)
	OR A
	CALL Z,SPR_PREPARA
	; doble búfer de patrones: cada imagen se escriben en la mitad (3800h o 3C00h) que la tabla
	; de atributos no está usando, y al escribir la tabla nueva se pasa a ella. Si no, entre la
	; copia de los patrones y la tabla nueva se veía un cuadro con las piezas descolocadas.
	LD A,(MITADP)
	XOR 1
	LD (MITADP),A
	LD A,CACHE/256
	JR Z,SVJ_1
	LD A,CACHE1/256
SVJ_1:	LD (CACHE_H),A
	LD A,(MARC_SUCIO)	; el juego tocó el marcador o sus colores: se vuelve a pintar como el de araubi
	OR A
	CALL NZ,PINTA_MARCADOR
	PUSH IX
	PUSH IY
	XOR A
	LD (NSPR),A
	LD (NFIJOS),A
	LD (NFENE),A
	LD (NJOBS),A
	LD HL,JOBS
	LD (JOB_PTR),HL
	LD A,(FIGN)
	OR A
	JR Z,SV_FIN
	LD A,80h		; primera pasada: Freddy (con pelo), fijo y delante
	LD (PASO),A
SV_PASADA:
	LD A,(FIGN)
	LD B,A
	LD IX,FIGS
SV_FIG:
	PUSH BC
	LD A,(PASO)
	XOR (IX+8)
	AND 80h
	JR NZ,SV_OTRA		; no es de esta pasada
	IF FREDDY_GIRA = 0	; Freddy fijo delante: solo se apuntan los enemigos
	LD A,(PASO)
	OR A
	JR NZ,SV_LLAMA
	ENDIF
	CALL SV_FINI		; enemigo: se apunta dónde empiezan sus sprites
	LD A,(NSPR)
	LD (HL),A
	CALL SPR_FIGURA
	CALL SV_FINI
	LD A,(NSPR)
	CP (HL)
	JR Z,SV_OTRA		; no puso ningún sprite
	LD HL,NFENE
	INC (HL)
	JR SV_OTRA
SV_LLAMA:
	CALL SPR_FIGURA
SV_OTRA:
	LD DE,16
	ADD IX,DE
	POP BC
	DJNZ SV_FIG
	LD A,(PASO)
	OR A
	JR Z,SV_FIN
	IF FREDDY_GIRA		; (5-11, tinta 5) Freddy tiene el cuerpo en el búfer: sus sprites (pelo y
	XOR A			; piel) entran en el giro como un enemigo más, para que ningún enemigo
	ELSE			; se quede oculto detrás de él
	LD A,(NSPR)
	ENDIF
	LD (NFIJOS),A
	XOR A
	LD (PASO),A
	JR SV_PASADA
SV_FIN:
	CALL SPR_COLORES
	XOR A
	LD (FIGN),A
	INC A
	LD (SPR_ON),A
	CALL SPR_JOBS
	POP IY
	POP IX
	JP SAT_DIFIERE		; (7-11) la tabla nueva se escribe al empezar el cuadro tras el volcado

SV_FINI:		; HL = FINI + NFENE
	LD A,(NFENE)
	ADD A,FINI AND 0FFh
	LD L,A
	LD H,FINI/256
	RET

SPR_PREPARA:
	CALL ATR_TODOS		; al entrar en la partida se mandan todas las filas (con la tinta fija)
	LD A,1
	LD (MARC_SUCIO),A
	XOR A
	LD (OJO_ON),A
	CALL SUBE_MARC
	JP SPP_SIGUE
SUBE_MARC:
	LD A,MARC_VPAT AND 0FFh	; patrones de la cara del marcador: huecos 32-NMARC..31
	OUT (99h),A
	LD A,MARC_VPAT/256 OR 40h
	OUT (99h),A
	LD HL,MARC_PATS
	LD BC,NMARC*32
SPP_O:	LD A,(HL)
	OUT (98h),A
	INC HL
	DEC BC
	LD A,B
	OR C
	JR NZ,SPP_O
	LD A,0E2h		; sprites de 16 x 16 (como R#1 de SCREEN 2, más el bit de tamaño)
	OUT (99h),A
	LD A,81h
	OUT (99h),A
	RET
SPP_SIGUE:
	LD HL,CACHE1		; ningún hueco tiene nada (las dos mitades: 4700h-48FFh)
	LD B,0
SPP_1:	LD (HL),0
	INC HL
	LD (HL),0
	INC HL
	DJNZ SPP_1
CALC_P12:	; A8h con las páginas 1 y 2 en el cartucho (las deja el copiador en A8_RAM/A8_P1/A8_P2)
	LD A,(A8_RAM)
	AND 0C3h
	LD C,A
	LD A,(A8_P1)
	AND 0Ch
	OR C
	LD C,A
	LD A,(A8_P2)
	AND 30h
	OR C
	LD (A8_P12),A
	RET

; una figura (IX): su lista de sprites (8 bytes cada uno, en la ROM junto a sus patrones):
; +0 dy, +1 dx, +2 dx con espejo (con signo), +3 color, +4/5 patrón, +6/7 patrón con espejo
SPR_FIGURA:
	LD L,(IX+0)
	LD H,(IX+1)
	INC HL
	INC HL
	INC HL
	LD A,(HL)		; banco
	LD (FBANCO),A
	INC HL
	LD E,(HL)
	INC HL
	LD D,(HL)		; lista en la ROM
	INC HL
	LD A,(HL)		; n.º de sprites
	OR A
	RET Z
	LD (FNUM),A
	ADD A,A
	ADD A,A
	ADD A,A
	LD C,A
	LD B,0
	EX DE,HL
	LD DE,LBUF		; la lista se copia a la página 0 con las páginas 1 y 2 en el cartucho
	LD A,(A8_P12)
	OUT (0A8h),A
	LD A,(FBANCO)
	LD (7000h),A
	LDIR
	LD A,(A8_RAM)
	OUT (0A8h),A
	LD IY,LBUF
SFG_1:	CALL SPR_ENTRADA
	LD DE,8
	ADD IY,DE
	LD HL,FNUM
	DEC (HL)
	JR NZ,SFG_1
	RET

SPR_ENTRADA:
	LD A,(NSPR)
	CP 32-NMARC		; los últimos huecos son los de la cara del marcador
	RET NC
	LD A,(IY+0)
	ADD A,(IX+4)
	RET C
	CP 128
	RET NC
	LD (TY),A
	LD B,A
	LD A,128
	SUB B
	CP 16
	JR C,SE_1
	LD A,16
SE_1:	LD (NFILAS),A
	LD A,(IX+7)
	OR A
	LD A,(IY+1)
	LD E,(IY+4)
	LD D,(IY+5)
	JR Z,SE_2
	LD A,(IY+2)
	LD E,(IY+6)
	LD D,(IY+7)
SE_2:	LD (TMP_PAT),DE
	LD E,A
	LD D,0
	BIT 7,A
	JR Z,SE_3
	DEC D
SE_3:	LD L,(IX+2)
	LD H,(IX+3)
	ADD HL,DE
	LD (TMP_X),HL
	; recorte a las columnas 8-247: H = máscara de los 8 de la izquierda, L = de la derecha
	EX DE,HL
	LD HL,0FFFFh
	LD A,D
	OR A
	JR NZ,SM_LENTO
	LD A,E
	CP 8
	JR C,SM_LENTO
	CP 233
	JR C,SM_FIN
SM_LENTO:
	LD A,D			; muy lejos (más de 256 a cualquier lado): fuera
	INC A
	CP 2
	RET NC
	LD HL,0
	LD B,16
SM_1:	ADD HL,HL
	LD A,D
	OR A
	JR NZ,SM_NO
	LD A,E
	CP 8
	JR C,SM_NO
	CP 248
	JR NC,SM_NO
	INC L
SM_NO:	INC DE
	DJNZ SM_1
	LD A,H
	OR L
	RET Z
SM_FIN:	LD A,H
	LD (MASKL),A
	LD A,L
	LD (MASKR),A
	; clave: patrón, banco, filas, recortes
	LD HL,CLAVE
	LD DE,(TMP_PAT)
	LD (HL),E
	INC L
	LD (HL),D
	INC L
	LD A,(FBANCO)
	LD (HL),A
	INC L
	LD A,(NFILAS)
	LD (HL),A
	INC L
	LD A,(MASKL)
	LD (HL),A
	INC L
	LD A,(MASKR)
	LD (HL),A
	LD A,(NSPR)
	ADD A,A
	ADD A,A
	ADD A,A
	LD E,A
	LD A,(CACHE_H)
	LD D,A
	LD HL,CLAVE
	LD B,6
SK_CMP:	LD A,(DE)
	CP (HL)
	JR NZ,SB_NUEVO
	INC E
	INC L
	DJNZ SK_CMP
	JR SB_SAT		; el hueco ya tiene este patrón
SB_NUEVO:
	LD A,(NSPR)
	ADD A,A
	ADD A,A
	ADD A,A
	LD E,A
	LD A,(CACHE_H)
	LD D,A
	LD HL,CLAVE
	LD BC,6
	LDIR
	; trabajo: banco, dirección en la ROM, filas, recortes, hueco
	LD HL,(JOB_PTR)
	LD A,(FBANCO)
	LD (HL),A
	INC HL
	LD DE,(TMP_PAT)
	LD (HL),E
	INC HL
	LD (HL),D
	INC HL
	LD A,(NFILAS)
	LD (HL),A
	INC HL
	LD A,(MASKL)
	LD (HL),A
	INC HL
	LD A,(MASKR)
	LD (HL),A
	INC HL
	LD A,(MITADP)
	RRCA
	RRCA
	RRCA			; 0 o 32
	LD B,A
	LD A,(NSPR)
	ADD A,B			; hueco: el de la mitad que no se está viendo
	LD (HL),A
	INC HL
	LD (JOB_PTR),HL
	LD HL,NJOBS
	INC (HL)
SB_SAT:
	; atributos en SATBUF + NSPR*4
	LD A,(NSPR)
	LD C,A
	ADD A,A
	ADD A,A
	ADD A,80h		; SATBUF = 4680h
	LD L,A
	LD H,SATBUF/256
	LD A,(TY)
	DEC A
	LD (HL),A
	INC L
	LD DE,(TMP_X)
	LD B,0
	LD A,D
	OR A
	LD A,E
	JR Z,SB_X
	ADD A,32		; X negativa: corrida 32 con el bit EC
	LD B,80h
SB_X:	LD (HL),A
	INC L
	LD A,(MITADP)
	RRCA			; 0 o 128
	PUSH BC
	LD B,A
	LD A,C
	ADD A,A
	ADD A,A
	ADD A,B
	POP BC
	LD (HL),A
	INC L
	LD A,(IY+3)		; color
	OR B
	LD (HL),A
	LD A,C
	INC A
	LD (NSPR),A
	RET

; copia los patrones nuevos de la ROM a la VRAM. Con las páginas 1 y 2 en el cartucho no se
; puede tocar la RAM de 4000h-BFFFh: los trabajos están en la página 0 (JOBS).
SPR_JOBS:
	LD A,(NJOBS)
	OR A
	RET Z
	LD B,A
	LD A,(A8_P12)
	OUT (0A8h),A
	LD IY,JOBS
SJ_1:	PUSH BC
	LD A,(IY+0)
	LD (7000h),A		; banco de la página 2 (ASCII16)
	LD A,(IY+6)		; hueco: 3800h + n * 32
	LD C,A
	RRCA
	RRCA
	RRCA
	AND 0E0h
	OUT (99h),A
	LD A,C
	RRCA
	RRCA
	RRCA
	AND 1Fh
	OR 78h
	OUT (99h),A
	LD L,(IY+1)
	LD H,(IY+2)
	LD D,(IY+3)
	LD C,(IY+4)
	CALL SJ_16
	LD D,(IY+3)
	LD C,(IY+5)
	CALL SJ_16
	LD DE,7
	ADD IY,DE
	POP BC
	DJNZ SJ_1
	LD A,(A8_RAM)
	OUT (0A8h),A
	RET
; 16 bytes de (HL) con AND C; a partir de la fila D, ceros
SJ_16:	LD E,16
SJ_F:	LD A,(HL)
	AND C
	OUT (98h),A
	INC HL
	DEC E
	RET Z
	DEC D
	JR NZ,SJ_F
SJ_0:	XOR A
	OUT (98h),A
	INC HL
	NOP
	NOP
	DEC E
	JR NZ,SJ_0
	RET

; tabla de atributos: primero los NFIJOS de Freddy (no giran: siempre se ven), luego los
; enemigos empezando en ROT y fin (208). ROT solo avanza si el VDP avisó de un quinto sprite
; en alguna línea (QUINTO, lo apunta SONDEO): sin aviso no parpadea nada.
SPR_SAT:
	LD A,(SPR_ON)
	OR A
	RET Z
	CALL SS_MARC		; deja la dirección en el primer hueco de la partida
	LD A,(NFIJOS)
	OR A
	JR Z,SS_ENE
	LD B,A
	LD D,0
SS_FIJ:	CALL SS_UNO
	INC D
	DJNZ SS_FIJ
SS_ENE:	; (5-11) los enemigos se giran de enemigo en enemigo, no de sprite en sprite: con el giro
	; de uno en uno por sprite, un enemigo podía quedarse oculto muchos cuadros seguidos
	LD A,(NFENE)
	OR A
	JR Z,SS_FIN
	LD C,A			; cuántos enemigos
	LD A,(ROTF)
	CP C
	JR C,SS_1
	XOR A
SS_1:	LD E,A
	LD A,(QUINTO)
	OR A
	LD A,E
	JR Z,SS_2		; sin quinto sprite no se gira
	INC A
	CP C
	JR C,SS_2
	XOR A
SS_2:	LD (ROTF),A
	LD E,A			; enemigo que va primero
	XOR A
	LD (QUINTO),A
	LD B,C
SS_FG:	PUSH BC
	LD A,E
	ADD A,FINI AND 0FFh
	LD L,A
	LD H,FINI/256
	LD D,(HL)		; su primer sprite
	INC L
	LD A,E
	INC A
	CP C
	LD A,(HL)		; el primero del siguiente...
	JR C,SS_E1
	LD A,(NSPR)		; ...o el final
SS_E1:	SUB D
	JR Z,SS_E3
	LD B,A
SS_E2:	CALL SS_UNO
	INC D
	DJNZ SS_E2
SS_E3:	INC E
	LD A,E
	CP C
	JR C,SS_E4
	LD E,0
SS_E4:	POP BC
	DJNZ SS_FG
SS_FIN:	LD A,208
	OUT (98h),A
	RET
; (7-11, idea de Néstor Sancho) los sprites de la cara del marcador van los primeros de la tabla
; (huecos 0..NMARC-1) y no se escriben en cada imagen: solo si el marcador aparece o se va, y cada
; 16 imágenes por si acaso. No entran en el giro; están en las líneas del marcador, donde no llega
; ningún sprite de la partida. Sin marcador quedan con Y = 0C0h (debajo de la pantalla).
SS_MARC:
	LD HL,MARC_CUENTA
	DEC (HL)
	JR Z,SM_TODO
	LD A,(OJO_ON)
	LD HL,OJO_SAT
	CP (HL)
	JR NZ,SM_TODO
	LD A,NMARC*4		; 1B00h + NMARC*4 con escritura
	OUT (99h),A
	LD A,5Bh
	OUT (99h),A
	RET
SM_TODO:
	LD A,16
	LD (MARC_CUENTA),A
	LD A,(OJO_ON)
	LD (OJO_SAT),A
	LD C,A
	XOR A
	OUT (99h),A
	LD A,5Bh		; 1B00h con escritura
	OUT (99h),A
	LD HL,MARC_SAT
	LD B,NMARC*4
SMQ_1:	LD A,(HL)
	INC C
	DEC C
	JR NZ,SMQ_2
	LD A,0C0h		; sin marcador: fuera de la pantalla
SMQ_2:	OUT (98h),A
	INC HL
	DJNZ SMQ_1
	RET
MARC_CUENTA:	DB 1
OJO_SAT:	DB 0FFh
; un sprite: el D de SATBUF
SS_UNO:	LD A,D
	ADD A,A
	ADD A,A
	ADD A,80h		; SATBUF = 4680h
	LD L,A
	LD H,SATBUF/256
	LD A,(HL)
	OUT (98h),A
	INC L
	NOP
	NOP
	LD A,(HL)
	OUT (98h),A
	INC L
	NOP
	NOP
	LD A,(HL)
	OUT (98h),A
	INC L
	NOP
	NOP
	LD A,(HL)
	OUT (98h),A
	RET
SS_VACIO:			; sin sprites de la partida (los del marcador se quedan si está dibujado)
	LD A,1
	LD (MARC_CUENTA),A	; se reescriben los del marcador
	CALL SS_MARC
	JP SS_FIN

	IF MASCARA
CEROS:		DS 160,0	; gráfico vacío (hasta 160 bytes: el guardia 937Ch de la parte 2 es 4 x 40)
	ENDIF

	IF PARTE_B = 0
; ---------------------------------------------------------------- colores de los enemigos
; La mitad de arriba de los enemigos se pinta en el búfer; sus celdas de la tabla de colores
; llevan la tinta del enemigo (el fondo de la celda se deja). Se lleva la lista de las celdas
; pintadas para devolverles su color (el de SOMBRA_ATR) cuando el enemigo se va.
SPR_COLORES:
	XOR A
	LD (NLN),A
	LD A,(FIGN)
	OR A
	JR Z,SC_VIEJAS
	LD B,A
	LD IX,FIGS
SC_FIG:	PUSH BC
	LD A,(IX+9)
	OR A
	JR Z,SC_NO
	CP 0FFh			; entera en el búfer: sin color de enemigo...
	JR NZ,SC_SI
	JR SC_NO			; (Freddy: desde las 15:00 la zona entera va en tinta 5, ver AT_TINTA)
SC_SI:	LD HL,SC_ALTO
	LD B,A
	LD A,(IX+6)
	SRL A			; enemigo a medias: solo la mitad de arriba
	LD (HL),A
	LD A,B
	CALL SC_CELDAS
SC_NO:
	LD DE,16
	ADD IX,DE
	POP BC
	DJNZ SC_FIG
SC_VIEJAS:			; las de antes que ya no van: su color de siempre
	LD A,(OLN)
	OR A
	JR Z,SC_NUEVAS
	LD B,A
	LD IX,OLI
	LD IY,OLC
SC_V1:	PUSH BC
	LD E,(IX+0)
	LD D,(IX+1)
	LD HL,CELB
	ADD HL,DE
	LD A,(ATR_TOCADO)	; si se mandaron colores, se repone por si acaso
	OR A
	JR NZ,SC_V2
	LD A,(IY+0)
	CP (HL)
	JR Z,SC_V3		; sigue igual
SC_V2:	LD HL,CELA
	ADD HL,DE
	LD (HL),0
	CALL SC_ORIG
	LD C,A
	CALL SC_OUT
SC_V3:	INC IX
	INC IX
	INC IY
	POP BC
	DJNZ SC_V1
SC_NUEVAS:			; las nuevas que no estaban: tinta del enemigo
	XOR A
	LD (ATR_TOCADO),A
	LD A,(NLN)
	LD (OLN),A
	OR A
	RET Z
	LD B,A
	LD IX,NLI
	LD IY,NLC
	LD HL,OLI
	LD (SC_DEST),HL
SC_N1:	PUSH BC
	LD E,(IX+0)
	LD D,(IX+1)
	LD HL,(SC_DEST)		; pasa a la lista vieja
	LD (HL),E
	INC HL
	LD (HL),D
	INC HL
	LD (SC_DEST),HL
	LD A,(IY+0)
	LD HL,CELB
	ADD HL,DE
	LD (HL),0
	LD HL,CELA
	ADD HL,DE
	CP (HL)
	JR Z,SC_N2		; ya la tiene
	LD (HL),A
	PUSH AF
	CALL SC_ORIG
	AND 0Fh
	LD C,A
	POP AF
	RLCA
	RLCA
	RLCA
	RLCA
	OR C
	LD C,A
	CALL SC_OUT
SC_N2:	INC IX
	INC IX
	INC IY
	POP BC
	DJNZ SC_N1
	LD A,(OLN)		; y los colores, a la lista vieja
	LD C,A
	LD B,0
	LD HL,NLC
	LD DE,OLC
	LDIR
	RET
SC_DEST:	DW 0
SC_ALTO:	DB 0

; fuera del juego: se olvidan sin tocar la VRAM
SC_OLVIDA:
	LD A,(OLN)
	OR A
	RET Z
	LD B,A
	LD HL,OLI
SC_O1:	LD E,(HL)
	INC HL
	LD D,(HL)
	INC HL
	PUSH HL
	LD HL,CELA
	ADD HL,DE
	LD (HL),0
	POP HL
	DJNZ SC_O1
	XOR A
	LD (OLN),A
	RET

; DE = celda: A = su color de siempre (TABLA_COLOR + atributo con signo, como ATRIBUTOS)
SC_ORIG:
	LD HL,SOMBRA_ATR
	ADD HL,DE
	LD A,(HL)
	LD L,A
	LD H,0
	BIT 7,A
	JR Z,SCO_1
	DEC H
SCO_1:	PUSH BC
	LD BC,TABLA_COLOR
	ADD HL,BC
	POP BC
	LD A,(HL)
	RET

; DE = celda, C = color: 8 bytes en la tabla de colores (2000h + fila*256 + columna*8)
SC_OUT:
	LD A,E
	AND 1Fh
	ADD A,A
	ADD A,A
	ADD A,A
	OUT (99h),A
	LD A,E
	RLCA
	RLCA
	RLCA
	AND 7
	LD B,A
	LD A,D
	ADD A,A
	ADD A,A
	ADD A,A
	OR B
	OR 60h
	OUT (99h),A
	LD A,C
	LD B,8
SCU_1:	OUT (98h),A
	NOP
	NOP
	DJNZ SCU_1
	RET

; celdas de la mitad de arriba de la figura IX (en la zona de juego: filas 0-15, columnas 1-30)
SC_CELDAS:
	LD (SC_COL),A
	LD A,(IX+4)
	CP 128
	RET NC
	RRCA
	RRCA
	RRCA
	AND 1Fh
	LD (SC_F0),A
	LD A,(SC_ALTO)		; líneas que se colorean
	OR A
	RET Z
	DEC A
	ADD A,(IX+4)
	JR C,SCC_1
	CP 128
	JR C,SCC_2
SCC_1:	LD A,127
SCC_2:	RRCA
	RRCA
	RRCA
	AND 1Fh
	LD (SC_F1),A
	; columnas: X/8 .. (X + ancho*8 - 1)/8, X con signo
	LD L,(IX+2)
	LD H,(IX+3)
	LD A,H
	OR A
	JR Z,SCC_3
	INC A
	RET NZ			; muy a la derecha
	LD A,1			; X negativa: desde la columna 1
	JR SCC_4
SCC_3:	LD A,L
	RRCA
	RRCA
	RRCA
	AND 1Fh
	JR NZ,SCC_4
	LD A,1
SCC_4:	LD (SC_C0),A
	LD A,(IX+5)
	ADD A,A
	ADD A,A
	ADD A,A
	DEC A
	LD E,A
	LD D,0
	ADD HL,DE
	LD A,H
	OR A
	JR Z,SCC_5
	INC A
	RET Z			; acaba antes de la pantalla
	LD A,30
	JR SCC_6
SCC_5:	LD A,L
	RRCA
	RRCA
	RRCA
	AND 1Fh
	CP 31
	JR C,SCC_6
	LD A,30
SCC_6:	LD (SC_C1),A
	LD HL,SC_C0
	CP (HL)
	RET C
	LD A,(SC_F0)
SCC_F:	LD C,A			; fila
	LD A,(SC_C0)
SCC_C:	LD B,A			; columna
	; celda = fila*32 + columna
	LD A,C
	RRCA
	RRCA
	RRCA
	LD D,A
	AND 0E0h
	OR B
	LD E,A
	LD A,D
	AND 1
	LD D,A
	PUSH BC
	CALL SC_ADD
	POP BC
	LD A,B
	LD HL,SC_C1
	CP (HL)
	INC A			; (INC no toca el acarreo)
	JR C,SCC_C
	LD A,C
	LD HL,SC_F1
	CP (HL)
	INC A
	JR C,SCC_F
	RET

SC_ADD:	LD A,(NLN)
	CP 64
	RET NC
	LD L,A
	INC A
	LD (NLN),A
	LD H,0
	PUSH HL
	ADD HL,HL
	LD BC,NLI
	ADD HL,BC
	LD (HL),E
	INC HL
	LD (HL),D
	POP HL
	LD BC,NLC
	ADD HL,BC
	LD A,(SC_COL)
	LD (HL),A
	LD HL,CELB
	ADD HL,DE
	LD (HL),A
	RET

	ELSE
; (7-11, araubi) parte 2: los enemigos van enteros en sprites. Las celdas que ocupa Freddy (su caja entera)
; llevan tinta 5, respetando el fondo de la celda: así Freddy pinta el fondo al pasar por delante y no al
; revés. Al irse, recuperan su color de siempre (SOMBRA_ATR). Solo se mandan las celdas que cambian.
B_NR0		EQU 45B0h+RAMV	; caja nueva: fila 0, fila 1, columna 0, columna 1 (fila 0 = 0FFh: no hay)
B_OR0		EQU 45B4h+RAMV	; la de la imagen anterior
SPR_COLORES:
	LD A,0FFh
	LD (B_NR0),A
	LD A,(FIGN)
	OR A
	JR Z,SCB_CMP
	LD B,A
	LD IX,FIGS
SCB_1:	LD A,(IX+9)
	INC A
	JR Z,SCB_F		; 0FFh: Freddy
	LD DE,16
	ADD IX,DE
	DJNZ SCB_1
	JR SCB_CMP
SCB_F:	LD A,(IX+2)		; columnas: x/8 .. (x + ancho*8 - 1)/8
	LD C,A
	RRCA
	RRCA
	RRCA
	AND 1Fh
	LD (B_NR0+2),A
	LD A,(IX+5)
	ADD A,A
	ADD A,A
	ADD A,A
	DEC A
	ADD A,C
	JR NC,SCB_2
	LD A,0FFh
SCB_2:	RRCA
	RRCA
	RRCA
	AND 1Fh
	LD (B_NR0+3),A
	LD C,(IX+4)		; filas: y con signo, alto (7-11 15:50, araubi: solo de medio cuerpo hacia arriba)
	LD A,(IX+6)
	SRL A
	LD B,A
	BIT 7,C
	JR Z,SCB_3
	LD A,C			; asoma por arriba
	ADD A,B
	JR NC,SCB_CMP
	OR A
	JR Z,SCB_CMP
	DEC A
	LD E,A
	LD D,0
	JR SCB_4
SCB_3:	LD D,C
	LD A,C
	ADD A,B
	DEC A
	LD E,A
SCB_4:	LD A,E
	CP 128
	JR C,SCB_5
	LD A,127
SCB_5:	RRCA
	RRCA
	RRCA
	AND 1Fh
	LD (B_NR0+1),A
	LD A,D
	RRCA
	RRCA
	RRCA
	AND 1Fh
	LD (B_NR0),A
SCB_CMP:			; las de antes que ya no son de Freddy: su color de siempre
	LD A,(B_OR0)
	CP 0FFh
	JR Z,SCB_PINTA
	LD B,A
SCB_V1:	LD A,(B_OR0+2)
	LD C,A
SCB_V2:	LD HL,B_NR0
	CALL SCB_DENTRO
	JR C,SCB_V3
	PUSH BC
	CALL SCB_CELDA
	CALL SC_ORIG
	LD C,A
	CALL SC_OUT
	POP BC
SCB_V3:	LD A,(B_OR0+3)
	CP C
	JR Z,SCB_V3B
	INC C
	JR SCB_V2
SCB_V3B:	LD A,(B_OR0+1)
	CP B
	JR Z,SCB_PINTA
	INC B
	JR SCB_V1
SCB_PINTA:			; las nuevas (o todas si el juego mandó colores): tinta 5
	LD A,(B_NR0)
	CP 0FFh
	JR Z,SCB_FIN
	LD B,A
SCB_N1:	LD A,(B_NR0+2)
	LD C,A
SCB_N2:	LD A,(ATR_TOCADO)
	OR A
	JR NZ,SCB_N3
	LD HL,B_OR0
	CALL SCB_DENTRO
	JR C,SCB_N4
SCB_N3:	PUSH BC
	CALL SCB_CELDA
	CALL SC_ORIG
	AND 0Fh
	OR 50h
	LD C,A
	CALL SC_OUT
	POP BC
SCB_N4:	LD A,(B_NR0+3)
	CP C
	JR Z,SCB_N4B
	INC C
	JR SCB_N2
SCB_N4B:	LD A,(B_NR0+1)
	CP B
	JR Z,SCB_FIN
	INC B
	JR SCB_N1
SCB_FIN:
	XOR A
	LD (ATR_TOCADO),A
	LD HL,B_NR0
	LD DE,B_OR0
	LD BC,4
	LDIR
	RET
; ¿la celda B (fila), C (columna) está en la caja HL? CY = sí
SCB_DENTRO:
	LD A,(HL)
	CP 0FFh
	JR Z,SCBD_NO
	LD A,B
	CP (HL)
	JR C,SCBD_NO
	INC HL
	LD A,(HL)
	CP B
	JR C,SCBD_NO
	INC HL
	LD A,C
	CP (HL)
	JR C,SCBD_NO
	INC HL
	LD A,(HL)
	CP C
	JR C,SCBD_NO
	SCF
	RET
SCBD_NO:	OR A
	RET
; DE = fila*32 + columna
SCB_CELDA:
	LD A,B
	RRCA
	RRCA
	RRCA
	LD D,A
	AND 0E0h
	OR C
	LD E,A
	LD A,D
	AND 1Fh
	LD D,A
	RET
; fuera del juego: se olvida sin tocar la VRAM
SC_OLVIDA:
	LD A,0FFh
	LD (B_OR0),A
	RET
; DE = celda: A = su color de siempre (TABLA_COLOR + atributo con signo, como ATRIBUTOS)
SC_ORIG:
	LD HL,SOMBRA_ATR
	ADD HL,DE
	LD A,(HL)
	LD L,A
	LD H,0
	BIT 7,A
	JR Z,SCO_1
	DEC H
SCO_1:	PUSH BC
	LD BC,TABLA_COLOR
	ADD HL,BC
	POP BC
	LD A,(HL)
	RET
; DE = celda, C = color: 8 bytes en la tabla de colores (2000h + fila*256 + columna*8)
SC_OUT:
	LD A,E
	AND 1Fh
	ADD A,A
	ADD A,A
	ADD A,A
	OUT (99h),A
	LD A,E
	RLCA
	RLCA
	RLCA
	AND 7
	LD B,A
	LD A,D
	ADD A,A
	ADD A,A
	ADD A,A
	OR B
	OR 60h
	OUT (99h),A
	LD A,C
	LD B,8
SCU_1:	OUT (98h),A
	NOP
	NOP
	DJNZ SCU_1
	RET
	ENDIF
	IF TINTA_FIJA
; (5-11, araubi) en partida, de los pies de Freddy hacia arriba (filas 0..FILA_PIES) la tinta es siempre la 5:
; Freddy va en tiles y así nunca toma el color de una plataforma. Se respeta el fondo de la celda.
AT_TINTA:
	PUSH AF
	LD A,(SPR_ON)		; solo en partida (en el menú y las escenas, los colores del juego)
	OR A
	JR Z,ATT_NO
	LD A,(AT_ALTA)
	CP 60h+FILA_PIES+1
	JR NC,ATT_NO
	POP AF
	AND 0Fh
	OR 50h
	RET
ATT_NO:	POP AF
	RET
; (6-11) Z = esta fila no se mira: en partida, fila de tinta fija y sin aviso de mandarla entera
; (ATR_TODOS la marca al entrar y al salir de la partida, y el juego al rehacer la pantalla)
AT_SALTA:
	LD A,(AT_TODAS)
	OR A
	JR NZ,ATS_NO
	LD A,(SPR_ON)
	OR A
	JR Z,ATS_NO
	LD A,(AT_ALTA)
	CP 60h+FILA_PIES+1
	JR NC,ATS_NO
	XOR A			; Z
	RET
ATS_NO:	OR 1			; NZ
	RET
AT_SALTADA:
	LD BC,32
	ADD HL,BC
	JP AT_FINF
	ENDIF
; ---------------------------------------------------------------- marcador (4-11, araubi)
; Cara de Freddy en color, pistola y esquinas en gris: registros en la ROM (banco MARC_BANCO, los
; prepara build_rom.py desde graficos/marcador.png): DW dirección de la VRAM con escritura, DB n,
; n bytes; DW 0 al final. Solo si el marcador está dibujado (byte de prueba de la cara distinto de 0).
PINTA_MARCADOR:
	XOR A
	LD (MARC_SUCIO),A
	LD A,MARC_PRUEBA AND 0FFh
	OUT (99h),A
	LD A,MARC_PRUEBA/256
	OUT (99h),A
	NOP
	NOP
	NOP
	IN A,(98h)
	LD (OJO_ON),A		; con el marcador dibujado, el ojo también
	OR A
	RET Z
	LD HL,8000h
PM_LISTA_HL:		; (8-11) entrada con HL = otra lista del mismo banco (la clave en el monitor: FB6Ah)
	CALL CALC_P12		; (6-11) también fuera de la partida, antes de SPR_PREPARA (no toca HL)
	OUT (0A8h),A
	LD A,MARC_BANCO
	LD (7000h),A
PM_1:	LD E,(HL)
	INC HL
	LD D,(HL)
	INC HL
	LD A,D
	OR E
	JR Z,PM_FIN
	LD A,E
	OUT (99h),A
	LD A,D
	OUT (99h),A
	LD B,(HL)
	INC HL
PM_2:	LD A,(HL)
	OUT (98h),A
	INC HL
	DJNZ PM_2
	JR PM_1
PM_FIN:	LD A,(A8_RAM)
	OUT (0A8h),A
	IF PARTE_B
; (8-11, araubi) barra de disparos de la parte 2 (fila 17, columnas 14-17 = celdas 2-5): el juego
; la vacía y la recarga escribiendo directamente su color en la VRAM (ATRIB_A_COLOR, celda 2-5
; según el nivel de E47Eh), sin tocar los atributos. Al repintar el marcador en color (p. ej. al
; cambiar de sala) salía llena aunque no quedaran disparos: las celdas por encima del nivel, a negro.
	LD A,(0E47Eh)
	LD C,A
	LD DE,3170h		; colores de la fila 17, columna 14 (celda 2)
	LD B,2
PMB_1:	LD A,C
	CP B
	JR NC,PMB_2		; celda cargada: se queda como en el marcador
	LD A,E
	OUT (99h),A
	LD A,D
	OR 40h
	OUT (99h),A
	PUSH BC
	LD B,8
	LD A,11h
PMB_3:	OUT (98h),A
	NOP
	NOP
	DJNZ PMB_3
	POP BC
PMB_2:	LD A,E
	ADD A,8
	LD E,A
	INC B
	LD A,B
	CP 6
	JR NZ,PMB_1
	ENDIF
	RET

OJO_ON:		DB 0	; el marcador está dibujado: se enseña el ojo
FBANCO:		DB 0	; en la página 0: se lee con la página 1 en el cartucho
NJOBS:		DB 0
JOB_PTR:	DW 0
A8_P12:		DB 0
JOBS:		DS 7*32,0
LBUF:		DS 8*MAXLISTA,0	; lista de la figura que se está convirtiendo
	IF PARTE_B
	INCLUDE "spr_datos_b.inc"
	ELSE
	INCLUDE "spr_datos.inc"
	ENDIF	; SPR_TABLA (la genera build_rom.py)
