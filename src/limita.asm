; (7-11) Freddy Hardest ROM: código que no cabe antes de SUCIO (1E00h); va en el hueco libre
; de 2500h-25FFh de las dos partes (lo incluyen optim_a.asm y optim_b.asm tras cambia.asm)
; (7-11, araubi) limitador por imágenes por segundo (F img/s con H cuadros por segundo): cada cuadro
; vale F; la imagen sale cuando lo acumulado llega a H, y lo que sobra pasa a la siguiente. Así a
; 60 Hz y 11 img/s se alternan esperas de 5 y 6 cuadros (media 60/11). Si una imagen tarda más de
; la cuenta (scroll, muchas figuras), lo que se pasa (hasta una imagen entera) lo recupera la
; siguiente si va sobrada: la media se acerca a F aunque haya imágenes lentas.
LIM_FPS:
	LD C,50
	LD D,100
	RLCA			; CF = bit 7 (60 Hz)
	JR NC,LF_50
	LD C,60
	LD D,120
LF_50:	RRCA
	AND 3Fh
	LD E,A			; E = imágenes por segundo
	LD HL,LF_RESTO
LF_ESPERA:
	LD A,(CUENTA)
	LD B,A
	LD A,(HL)
	INC B
	JR LF_MIRA
LF_SUMA:
	ADD A,E
	CP D
	JR NC,LF_LLENO		; no se guarda más de una imagen de adelanto
LF_MIRA:
	DJNZ LF_SUMA
	CP C
	JR NC,LF_YA
	CALL SONDEO_S
	JR LF_ESPERA
LF_LLENO:
	LD A,D
LF_YA:	SUB C			; lo que sobra (0 a H)
	LD (HL),A
	XOR A
	LD (CUENTA),A
	RET
LF_RESTO:	DB 0

; RMW2 del original con esperas largas (lo llama G_RMW2 de optim.asm)
G_RMW2B:
	; (7-11) la misma rutina del original (RMW2), con más espera entre la dirección y la lectura o
	; la escritura de la VRAM: el original leía a los 2 NOP y openMSX (too_fast_vram_access real)
	; daba el byte por perdido. Ahora >= 29 T, como pide el proyecto para MSX1.
	LD A,(RMW2-1)
	DEC A
	JR NZ,GR2_1
	LD (RMW2-1),A
	POP BC
	POP BC
	RET
GR2_1:	EX DE,HL
	LD A,E
	OUT (99h),A
	LD A,D
	AND 3Fh
	OUT (99h),A
	EX (SP),HL
	EX (SP),HL
	IN A,(98h)
	AND (HL)
	INC H
	AND (HL)
	DEC H
	PUSH AF
	LD A,E
	OUT (99h),A
	LD A,D
	OUT (99h),A
	POP AF
	EX (SP),HL
	EX (SP),HL
	OUT (98h),A
	EX DE,HL
	RET

; (7-11, araubi: restos y pelo descolocado) La tabla de sprites nueva se escribía en cuanto estaban
; listos los patrones, antes de volcar las celdas, y a cualquier altura del barrido: el pelo iba
; por delante del cuerpo (que aún no estaba en la VRAM) y a veces se veían piezas de dos imágenes.
; Ahora se escribe en el primer punto seguro tras el comienzo del cuadro del VDP (el borde de abajo,
; antes de que el barrido vuelva a la zona de juego) que sigue al volcado de la imagen.
; SAT_EST: 0 nada pendiente, 2 tabla nueva lista pero volcado en curso, 1 tabla nueva a escribir.
SAT_EST:	DB 0
SAT_DIFIERE:			; fin de SPR_VOLCADO (en vez de JP SPR_SAT)
	LD A,2
	LD (SAT_EST),A
	RET
LIM_SAT:			; fin del volcado: la tabla, justo al empezar el cuadro siguiente
	LD HL,SAT_EST
	SRL (HL)		; 2 -> 1
	JP Z,LIMITADOR		; nada pendiente (fuera de la partida)
	CALL SONDEO		; un aviso de cuadro que ya estuviera puesto no vale (sería tarde)
	XOR A
	LD (SAT_PEND),A
LS_1:	CALL SONDEO_S		; espera el comienzo de un cuadro y ahí escribe la tabla (SAT_QUIERE)
	LD A,(HL)		; (SONDEO_S conserva HL = SAT_EST)
	OR A
	JR NZ,LS_1
	JP LIMITADOR		; ese cuadro ya cuenta para el limitador (CUENTA)
SAT_QUIERE:			; desde SONDEO_S al empezar un cuadro: A <> 0 si se reescribe la tabla
	LD A,(SAT_EST)
	DEC A
	JR Z,SQ_SI
	DEC A
	RET Z			; volcado en curso: ni la nueva ni giros con la nueva a medias
	LD A,(QUINTO)		; nada pendiente: giro si hubo quinto sprite
	RET
SQ_SI:	LD (SAT_EST),A
	INC A
	RET
