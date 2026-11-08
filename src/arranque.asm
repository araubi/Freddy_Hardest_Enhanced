; Freddy Hardest (Dinamic Software 1987) en MegaROM ASCII16 de 256 KB.
; Banco 0: este arranque (pantalla de carga, presentación de la parte 1, menú de partes y copia a RAM).
; (7-11, araubi) orden: pantalla de carga -> tecla -> presentación de la parte 1 (se salta con otra
; tecla) -> menú de partes (sin BIOS: la parte 1 ya está en la RAM) -> la parte elegida, la 1 directa
; a su menú (el copiador pone lo que habría dejado la presentación).
; Bancos 1-4: imagen de la RAM de la parte 1; bancos 5-8: la de la parte 2.
; El juego necesita los 64 KB de RAM y no usa la BIOS: se copia entero a RAM.
; Claude para araubi, 2026-10-29. Ensamblable con pasmo o sjasmplus.
	INCLUDE "arranque.inc"	; ENTRADA_A, ENTRADA_B (las genera build_rom.py)
CHGMOD	EQU 005Fh
LDIRVM	EQU 005Ch
FILVRM	EQU 0056h
WRTVDP	EQU 0047h
SNSMAT	EQU 0141h
GTSTCK	EQU 00D5h
GTTRIG	EQU 00D8h
KILBUF	EQU 0156h
ENASLT	EQU 0024h
RSLREG	EQU 0138h
EXPTBL	EQU 0FCC1h
SLTTBL	EQU 0FCC5h
FORCLR	EQU 0F3E9h
RG1SAV	EQU 0F3E0h
JIFFY	EQU 0FC9Eh
COPIADOR EQU 2600h
ROMSLOT	EQU 0E000h	; variables en la RAM de la página 3 (aún con BIOS)
RAMSLOT	EQU 0E001h
OPCION	EQU 0E002h
TECLAS	EQU 0E003h
ESPERA	EQU 0E004h

	ORG 4000h
	DB "AB"
	DW INICIO
	DW 0,0,0
	DS 6,0
	JP MENU_PARTES	; 4010h: lo llama C_MENU del copiador
INICIO:
	DI
	LD SP,0F380h
	XOR A
	LD (6000h),A
	INC A
	LD (7000h),A
	; SCREEN 2 en negro
	LD A,15
	LD (FORCLR),A
	LD A,1
	LD (FORCLR+1),A
	LD (FORCLR+2),A
	LD A,2
	CALL CHGMOD
	CALL APAGA
	; pantalla de carga
	LD HL,PANT_PAT
	LD DE,0
	LD BC,1800h
	CALL LDIRVM
	LD HL,PANT_COL
	LD DE,2000h
	LD BC,1800h
	CALL LDIRVM
	CALL ENCIENDE
	DI			; de aquí en adelante, sin interrupciones (los mandos se leen directos)
	LD A,(002Bh)		; bit 7: 1 = 50 Hz, 0 = 60 Hz; leerlo aún con la BIOS en la página 0
	LD (HZ_BIOS),A
	CALL SUELTA
INI_1:	CALL CUADRO		; hasta que se pulse algo
	CALL LEE
	OR A
	JR Z,INI_1
	CALL SUELTA
	CALL NEGRO
	CALL BUSCA_SLOTS
	; copiador a 2600h (la página 0 pasa a RAM)
	LD A,(RAMSLOT)
	AND 3
	LD B,A
	IN A,(0A8h)
	AND 0FCh
	OR B
	OUT (0A8h),A
	LD HL,COPIADOR_ROM
	LD DE,COPIADOR
	LD BC,COPIADOR_FIN-COPIADOR_ROM
	LDIR
	; valores del puerto A8h
	LD A,(RAMSLOT)
	AND 3
	LD B,A
	ADD A,A
	ADD A,A
	OR B
	LD B,A
	ADD A,A
	ADD A,A
	ADD A,A
	ADD A,A
	OR B
	LD (COPIADOR+2),A	; todo RAM
	LD D,A
	LD A,(ROMSLOT)
	AND 3
	LD E,A
	ADD A,A
	ADD A,A
	LD B,A
	LD A,D
	AND 0F3h
	OR B
	LD (COPIADOR+0),A	; página 1 en la ROM
	LD A,E
	RLCA
	RLCA
	RLCA
	RLCA
	LD B,A
	LD A,D
	AND 0CFh
	OR B
	LD (COPIADOR+1),A	; página 2 en la ROM
	LD HL,LIMITE_DIR
	LD (COPIADOR+7),HL
	LD A,(HZ_BIOS)		; bit 7 del limitador: 1 = máquina de 60 Hz (31-10); se queda en C_LIM
	CPL
	AND 80h
	LD (COPIADOR+6),A
	; la parte 1 con su presentación: al acabar (o con una tecla) vuelve a MENU_PARTES
	XOR A
	LD HL,ENTRADA_INTRO
	JP PON_PARTE

; --- (7-11) menú de partes, después de la presentación de la parte 1. Sin BIOS: la RAM ya es la de
; la parte 1 (y la página 1 es este cartucho). Se entra por 4010h desde C_MENU (copiador).
MENU_PARTES:
	DI
	LD SP,0F380h
	IM 1
	CALL CALLA
	LD HL,MODO_SC2
	CALL V_MODO		; SCREEN 2 como la deja la BIOS, con la pantalla apagada
	LD HL,0
	LD BC,1800h
	XOR A
	CALL V_LLENA
	LD HL,2000h
	LD BC,1800h
	LD A,11h
	CALL V_LLENA
	LD HL,1800h		; nombres: 0..255 en los tres tercios
	CALL V_ESC
	LD BC,3
MP_N:	XOR A
MP_N1:	OUT (98h),A
	NOP
	NOP
	INC A
	JR NZ,MP_N1
	DEC C
	JR NZ,MP_N
	LD HL,1B00h		; sin sprites
	CALL V_ESC
	LD A,208
	OUT (98h),A
	LD HL,TXT_MENU
	CALL TEXTOS
	XOR A
	LD (OPCION),A
	CALL MARCA
	LD BC,0E001h		; pantalla encendida
	CALL V_REG
	CALL SUELTA
MENU_BUCLE:
	CALL CUADRO
	CALL LEE
	OR A
	JR Z,MENU_BUCLE
	CP 3
	JR Z,MENU_ELIGE		; disparo
	CP 4
	JR Z,MENU_UNO
	CP 5
	JR Z,MENU_DOS
	; arriba o abajo: cambia
	LD A,(OPCION)
	XOR 1
	LD (OPCION),A
	CALL MARCA
	CALL SUELTA
	JR MENU_BUCLE
MENU_UNO:
	XOR A
	JR MENU_FIJA
MENU_DOS:
	LD A,1
MENU_FIJA:
	LD (OPCION),A
	CALL MARCA
MENU_ELIGE:
	CALL SUELTA
	CALL NEGRO
	LD A,(OPCION)
	OR A
	LD A,1			; parte 1: directa a su menú, con lo que deja la presentación
	LD HL,ENTRADA_DIRECTA
	JR Z,PON_PARTE
	XOR A
	LD HL,ENTRADA_B
; A = 1 si hay que poner el estado de tras la presentación (solo la parte 1 directa)
; HL = entrada; la parte sale de la entrada: ENTRADA_B es la parte 2, las demás la 1
PON_PARTE:
	LD (C_PARCHE_RAM),A
	LD (COPIADOR+4),HL
	LD DE,ENTRADA_B
	OR A
	SBC HL,DE
	LD A,1
	LD DE,LIM_A
	JR NZ,PON_P1
	LD A,5
	LD DE,LIM_B
PON_P1:	LD (COPIADOR+3),A
	LD A,(COPIADOR+6)	; bit 7: máquina de 60 Hz
	RLCA
	LD A,E			; 50 Hz
	JR NC,PON_LIM
	LD A,D			; 60 Hz: el bit 7 del limitador avisa al juego (31-10)
	OR 80h
PON_LIM:
	LD (COPIADOR+6),A
	JP COPIADOR+9
C_PARCHE_RAM EQU 26F8h	; C_PARCHE del copiador

; --- busca los slots de la ROM (página 1) y de la RAM (la de la página 3) y deja los
; subslots preparados: los de la RAM, todos en el subslot de la página 3
BUSCA_SLOTS:
	CALL RSLREG
	RRCA
	RRCA
	AND 3
	LD C,A
	LD B,0
	LD HL,EXPTBL
	ADD HL,BC
	LD A,(HL)
	AND 80h
	OR C
	LD C,A
	LD HL,SLTTBL
	LD A,C
	AND 3
	ADD A,L
	LD L,A
	LD A,(HL)
	AND 0Ch
	OR C
	LD (ROMSLOT),A
	CALL RSLREG
	RLCA
	RLCA
	AND 3
	LD C,A
	LD B,0
	LD HL,EXPTBL
	ADD HL,BC
	LD A,(HL)
	AND 80h
	OR C
	LD C,A
	LD HL,SLTTBL
	LD A,C
	AND 3
	ADD A,L
	LD L,A
	LD A,(HL)
	AND 0C0h
	RRCA
	RRCA
	RRCA
	RRCA
	OR C
	LD (RAMSLOT),A
	; página 2: primero la ROM (subslot del cartucho) y luego la RAM
	LD A,(ROMSLOT)
	LD H,80h
	CALL ENASLT
	LD A,(RAMSLOT)
	LD H,80h
	CALL ENASLT
	DI
	LD A,(RAMSLOT)
	BIT 7,A
	RET Z
	RRCA
	RRCA
	AND 3
	LD B,A
	ADD A,A
	ADD A,A
	OR B
	LD B,A
	ADD A,A
	ADD A,A
	ADD A,A
	ADD A,A
	OR B
	LD (0FFFFh),A		; la página 3 es de la RAM: es su registro de subslot
	RET

; --- pantalla
APAGA:
	LD A,(RG1SAV)
	AND 0BFh
	JR PON_R1
ENCIENDE:
	LD A,(RG1SAV)
	OR 40h
PON_R1:
	LD B,A
	LD C,1
	JP WRTVDP

; --- VDP sin BIOS (en el menú de partes la BIOS ya no está): escrituras separadas >= 29 ciclos
V_ESC:	LD A,L			; dirección HL para escribir
	OUT (99h),A
	LD A,H
	AND 3Fh
	OR 40h
	OUT (99h),A
	RET
V_REG:	LD A,B			; registro C = B
	OUT (99h),A
	LD A,C
	OR 80h
	OUT (99h),A
	RET
V_MODO:	LD C,0			; registros 0-7 desde (HL)
VM_1:	LD B,(HL)
	CALL V_REG
	INC HL
	INC C
	LD A,C
	CP 8
	JR NZ,VM_1
	RET
MODO_SC2: DB 02h,0A0h,06h,0FFh,03h,36h,07h,0F1h	; R1 = A0h: pantalla apagada (luego E0h, como CHGMOD)
V_LLENA:			; HL = VRAM, BC = bytes, A = valor
	LD E,A
	CALL V_ESC
VL_1:	LD A,E
	OUT (98h),A
	DEC BC
	LD A,B
	OR C
	JR NZ,VL_1
	RET
V_COPIA:			; HL = origen, DE = VRAM, B = bytes (1-255)
	EX DE,HL
	CALL V_ESC
	EX DE,HL
VC_1:	LD A,(HL)
	OUT (98h),A
	INC HL
	DJNZ VC_1
	RET
; pantalla en negro y encendida, como al terminar la carga
NEGRO:
	LD BC,0A001h
	CALL V_REG
	LD HL,0
	LD BC,1800h
	XOR A
	CALL V_LLENA
	LD HL,2000h
	LD BC,1800h
	XOR A
	CALL V_LLENA
	LD BC,0E001h
	JP V_REG
; PSG callado
CALLA:	LD B,3
	LD C,8
CA_1:	LD A,C
	OUT (0A0h),A
	XOR A
	OUT (0A1h),A
	INC C
	DJNZ CA_1
	RET
; espera el aviso de fin de imagen del VDP (sin interrupciones)
CUADRO:	IN A,(99h)
	RLCA
	JR NC,CUADRO
	RET

; textos: [fila][columna][color][n][códigos del juego]... 0FFh = fin
TEXTOS:
	LD A,(HL)
	CP 0FFh
	RET Z
	INC HL
	LD D,A			; fila
	LD E,(HL)		; columna
	INC HL
	LD A,(HL)		; color
	INC HL
	LD B,(HL)		; longitud
	INC HL
	LD (TX_COLOR),A
TX_1:	PUSH BC
	PUSH DE
	PUSH HL
	LD L,(HL)
	LD H,0
	ADD HL,HL
	ADD HL,HL
	ADD HL,HL
	LD BC,FUENTE
	ADD HL,BC		; patrón del carácter
	LD A,E
	ADD A,A
	ADD A,A
	ADD A,A
	LD E,A			; DE = fila*256 + columna*8
	PUSH DE
	LD B,8
	CALL V_COPIA
	POP HL
	LD DE,2000h
	ADD HL,DE
	LD A,(TX_COLOR)
	LD BC,8
	CALL V_LLENA
	POP HL
	POP DE
	POP BC
	INC HL
	INC E
	DJNZ TX_1
	JR TEXTOS
TX_COLOR EQU 0E005h
HZ_BIOS	EQU 0E006h	; copia de 002Bh (31-10: antes se leía con la página 0 ya en RAM)

; pinta las dos opciones: la elegida en blanco, la otra en amarillo oscuro
MARCA:
	LD A,(OPCION)
	OR A
	LD A,0F1h
	LD D,0A1h
	JR Z,MARCA_1
	LD A,0A1h
	LD D,0F1h
MARCA_1:
	PUSH DE
	LD HL,2000h+10*256+9*8
	LD BC,14*8
	CALL V_LLENA
	POP AF
	LD HL,2000h+12*256+9*8
	LD BC,14*8
	JP V_LLENA

; lee mandos sin BIOS: 0 nada, 1 arriba, 2 abajo, 3 disparo, 4 tecla 1, 5 tecla 2
LEE:
	LD A,0
	CALL FILA
	BIT 1,A
	LD B,4
	JR Z,LEE_SI
	BIT 2,A
	LD B,5
	JR Z,LEE_SI
	LD A,8
	CALL FILA
	BIT 0,A			; ESPACIO
	LD B,3
	JR Z,LEE_SI
	BIT 5,A
	LD B,1
	JR Z,LEE_SI
	BIT 6,A
	LD B,2
	JR Z,LEE_SI
	LD A,7
	CALL FILA
	BIT 7,A			; RETURN
	LD B,3
	JR Z,LEE_SI
	LD A,15			; joystick 1: puerto A del PSG
	OUT (0A0h),A
	IN A,(0A2h)
	AND 0BFh
	OR 03h
	OUT (0A1h),A
	LD A,14
	OUT (0A0h),A
	IN A,(0A2h)
	BIT 4,A			; disparo
	LD B,3
	JR Z,LEE_SI
	BIT 0,A
	LD B,1
	JR Z,LEE_SI
	BIT 1,A
	LD B,2
	JR Z,LEE_SI
	XOR A
	RET
LEE_SI:
	LD A,B
	RET
FILA:	LD B,A			; fila A del teclado (PPI)
	IN A,(0AAh)
	AND 0F0h
	OR B
	OUT (0AAh),A
	IN A,(0A9h)
	RET
SUELTA:
	CALL CUADRO
	CALL LEE
	OR A
	JR NZ,SUELTA
	RET

	INCLUDE "textos_rom.inc"	; TXT_MENU
FUENTE:
	INCBIN "fuente.bin"
COPIADOR_ROM:
	INCBIN "copiador.bin"
COPIADOR_FIN:
	; para que los emuladores reconozcan el mapeador ASCII16 (nunca se ejecuta)
	LD (77FFh),A
	LD (77FFh),A
	LD (77FFh),A
	LD (77FFh),A
	LD (77FFh),A
	LD (77FFh),A
PANT_PAT:
	INCBIN "pantalla_pat.bin"
PANT_COL:
	INCBIN "pantalla_col.bin"
	DS 8000h-$,0FFh
