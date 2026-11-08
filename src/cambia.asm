; Freddy Hardest ROM - (6-11, araubi) opción «3-IR A PARTE n» en el menú de cada parte: vuelve a
; copiar la otra parte de la ROM con el copiador, que sigue en 2600h-26FFh (con los valores del
; puerto A8h que dejó el arranque). Antes: OTRA_BANCO, OTRA_ENTRADA, OTRA_L50, OTRA_L60 (partes.inc),
; TXT_RUT (rutina del juego que escribe un texto), TXT_SIG (el texto que iba a escribir),
; MENU_JUEGO (opción 1), MENU_SIGUE (PUSH HL / RET NZ del original) y TXT3.
G_TXT3:				; sustituye LD HL,TXT_SIG antes de CALL TXT_RUT
	LD HL,TXT3
	CALL TXT_RUT
	LD HL,TXT_SIG
	RET
G_MENU:				; sustituye JP C,MENU_JUEGO (A = tecla, con CP 2 hecho)
	JP C,MENU_JUEGO
	JP Z,MENU_SIGUE
	CP 3
	JP NZ,MENU_SIGUE
CAMBIA_PARTE:
	DI
	LD A,8			; PSG callado
	OUT (0A0h),A
	XOR A
	OUT (0A1h),A
	LD A,9
	OUT (0A0h),A
	XOR A
	OUT (0A1h),A
	LD A,10
	OUT (0A0h),A
	XOR A
	OUT (0A1h),A
	OUT (99h),A		; sin sprites (1B00h = 208)
	LD A,5Bh
	OUT (99h),A
	LD A,208
	OUT (98h),A
	LD A,OTRA_PARCHE	; (7-11) a la parte 1: directa a su menú, sin la presentación
	LD (26F8h),A		; C_PARCHE
	LD A,OTRA_BANCO
	LD (2603h),A		; C_BANCO
	LD HL,OTRA_ENTRADA
	LD (2604h),HL		; C_ENTRADA
	LD A,(LIMITE)		; bit 7: máquina de 60 Hz
	RLCA
	LD A,OTRA_L50
	JR NC,CP_50
	LD A,OTRA_L60 OR 80h
CP_50:	LD (2606h),A		; C_LIM
	JP 2609h		; COPIA
