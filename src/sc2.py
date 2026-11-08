"""Pantalla de carga del Spectrum (SCREEN$) -> SCREEN 2 del MSX con la tabla de color del juego."""
def convierte(scr,tabla):
    pat=bytearray(6144); col=bytearray(6144)
    for y in range(192):
        for cx in range(32):
            a=((y&0xC0)<<5)|((y&7)<<8)|((y&0x38)<<2)|cx
            at=scr[6144+(y>>3)*32+cx]
            d=(y>>6)*2048+((y>>3)&7)*256+cx*8+(y&7)
            pat[d]=scr[a]; col[d]=tabla[at&0x7F]
    return bytes(pat),bytes(col)
