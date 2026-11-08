; Freddy Hardest ROM - copiador. Corre en la RAM de la página 0 (2600h, libre en las dos partes), ya sin BIOS ni
; interrupciones. Lee la imagen del juego de la ROM (ASCII16) y la deja en las cuatro
; páginas de RAM; después salta al juego como lo hacía el arranque de la cinta.
; Claude para araubi, 2026-10-29 (pasmo o sjasmplus).
	ORG 2600h
C_V1:	DB 0		; puerto A8h: página 1 en el cartucho, el resto RAM
C_V2:	DB 0		; puerto A8h: página 2 en el cartucho, el resto RAM
C_V0:	DB 0		; puerto A8h: todo RAM
C_BANCO: DB 0		; primer banco de la imagen (4 bancos: páginas 0, 1, 2 y 3)
C_ENTRADA: DW 0		; dirección de entrada del juego
C_LIM:	DB 0		; cuadros por imagen del limitador
C_LIMDIR: DW 0		; dónde lo espera el juego optimizado (0 = no hay)
C_PARCHE EQU 26F8h	; 1 = poner el estado de tras la presentación (lo ponen el arranque y CAMBIA_PARTE)
PARCHE_BANCO EQU 12
COPIA:
	LD SP,26FEh
	; página 3 (C000h-FFFEh): la ROM se lee por 4000h
	LD A,(C_V1)
	OUT (0A8h),A
	LD A,(C_BANCO)
	ADD A,3
	LD (6000h),A
	LD HL,4000h
	LD DE,0C000h
	LD BC,3FFFh	; FFFFh no: puede ser el registro de subslot
	LDIR
	; página 2 (8000h-BFFFh): la ROM se lee por 4000h
	LD A,(C_BANCO)
	ADD A,2
	LD (6000h),A
	LD HL,4000h
	LD DE,8000h
	LD BC,4000h
	LDIR
	; página 1 (4000h-7FFFh): la ROM se lee por 8000h
	LD A,(C_BANCO)
	INC A
	LD (7000h),A
	LD A,(C_V2)
	OUT (0A8h),A
	LD HL,8000h
	LD DE,4000h
	LD BC,4000h
	LDIR
	; página 0 (0000h-25FFh y 2700h-3FFFh; este copiador está en 2600h-26FFh)
	LD A,(C_V1)
	OUT (0A8h),A
	LD A,(C_BANCO)
	LD (6000h),A
	LD HL,4000h
	LD DE,0
	LD BC,2600h
	LDIR
	LD HL,6700h
	LD DE,2700h
	LD BC,1900h
	LDIR
	; (7-11) entrada directa al menú de la parte 1 sin la presentación: lo que la presentación deja
	; preparado para la partida (tomado en openMSX al llegar a EFD2h) está en el banco PARCHE_BANCO,
	; como [DW dirección, DW bytes, datos]..., DW 0, DW 0. Se lee por 8000h (página 2 del cartucho).
	LD A,(C_PARCHE)
	OR A
	JR Z,C_SINPAR
	LD A,PARCHE_BANCO
	LD (7000h),A
	LD A,(C_V2)
	OUT (0A8h),A
	LD HL,8000h
C_P1:	LD E,(HL)
	INC HL
	LD D,(HL)
	INC HL
	LD C,(HL)
	INC HL
	LD B,(HL)
	INC HL
	LD A,B
	OR C
	JR Z,C_P2
	LDIR
	JR C_P1
C_P2:	LD A,(C_V1)
	OUT (0A8h),A
	LD A,(C_BANCO)
	INC A
	LD (7000h),A	; como lo dejaba la copia de la página 1
C_SINPAR:
	XOR A
	LD (6000h),A	; deja el banco 0 en la página 1, por si acaso
	LD HL,(C_LIMDIR)
	LD A,H
	OR L
	JR Z,C_SINLIM
	LD A,(C_LIM)
	LD (HL),A
	INC HL			; A8_RAM, A8_P1, A8_P2 (sprites de la parte 1: leen sus patrones de la ROM)
	LD A,(C_V0)
	LD (HL),A
	INC HL
	LD A,(C_V1)
	LD (HL),A
	INC HL
	LD A,(C_V2)
	LD (HL),A
C_SINLIM:
	LD A,(C_V0)
	OUT (0A8h),A
	LD HL,(C_ENTRADA)
	LD SP,0FFFFh
	JP (HL)
	DS 26E0h-$,0
; (7-11) desde la presentación de la parte 1 (tecla o final): al menú de partes del banco 0, que
; corre en la página 1 del cartucho sin BIOS. Este trozo está en la página 0 (RAM).
C_MENU:	LD A,(C_V1)
	OUT (0A8h),A
	XOR A
	LD (6000h),A
	JP 4010h	; arranque.asm: JP MENU_PARTES
C_FIN:
