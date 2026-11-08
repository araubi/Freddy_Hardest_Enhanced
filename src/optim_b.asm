; Freddy Hardest, parte 2: direcciones del juego para optim.asm y sitio del módulo.
BUFER		EQU 6200h	; búfer de la zona de juego (32 x 128)
FONDO		EQU 7200h	; (no se usa en la parte 2)
TERR1_HL	EQU 0
TERR2_HL	EQU 0
DIR_BUFER	EQU 0
COPIA_BLOQUE	EQU 0
FIG_ANCHO	EQU 0
RESTAURA_ORIGINAL EQU 0
LLENA_SIGUE	EQU 0300h
RMW1		EQU 0
RMW2		EQU 01AEh
TABLA_COLOR	EQU 28B6h
ATR_ORIGEN	EQU 045Bh
ATR_BC		EQU 045Fh
ATR_BASE	EQU 7400h
FIG_TAM		EQU 0F78Ch
LISTA_REPON	EQU 0F792h
TABLA_IX	EQU 0BC4Ch
MANDOS		EQU 0D7A5h
SUCIO		EQU 1E00h
FILAS		EQU 2000h
ATR_MAL		EQU 2100h
SOMBRA_ATR	EQU 2200h

	ORG 0C40h
TINTA_FIJA	EQU 0
PARTE_B		EQU 1
	INCLUDE "optim.asm"
; mandos como en 0227h (teclado OR joystick)
MANDOS_AHORA:
	CALL 0546h
	PUSH AF
	LD A,1
	CALL 056Bh
	CALL 0599h
	POP BC
	OR B
	RET
	INCLUDE "spr_a.asm"	; (7-11) sprites también en la parte 2
SONIDO_TIC:		; la parte 2 no tiene efectos con espera larga
SND_CALLA_YA:
	RET
	DS SUCIO-$,0
	DS 512,0
	DS 16,0
	DS ATR_MAL-$,0
	DS 24,1
	DS SOMBRA_ATR-$,0
	DS 768,0
OPTIM_FIN:
; (6-11) de aquí a 25FFh (el copiador sigue en 2600h): libre en las dos partes
; (6-11) menú: «3-IR A PARTE 1»
TXT_RUT		EQU 0CA10h
TXT_SIG		EQU 0C9F4h
MENU_JUEGO	EQU 00D8h
MENU_SIGUE	EQU 00CFh
	INCLUDE "partes.inc"
	INCLUDE "cambia.asm"
	INCLUDE "limita.asm"
TXT3:	DB 58h,60h,14,1Dh,25h,09h,12h,00h,01h,00h,10h,01h,12h,14h,05h,00h,1Bh	; 3-IR A PARTE 1
	DS 2600h-$,0
