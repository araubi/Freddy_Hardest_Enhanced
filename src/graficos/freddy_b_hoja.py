"""(7-11) Hoja 1:1 de Freddy en la parte 2, en el formato de freddy_cabeza_1a1.png (figuras arriba, separadas
por 4 px de gris 60,60,60). Las figuras que son iguales que en la parte 1 copian el retoque de araubi; las nuevas
salen con el pelo puesto a ojo (5 primeras filas con píxeles) para que araubi las retoque.
Uso: python3 freddy_b_hoja.py imagen_A.bin imagen_B.bin hoja_parte1.png salida.png"""
import sys
from PIL import Image
FREDDY_A=[0x9C40,0x9CBA,0x9D34,0x9DAE,0x9E28,0x9EA2,0x9F1C,0x9F96,0xE4C0,0xE53A,0xE5B4,0xE656,0xE6D0,0xD6D8]
FREDDY_B=[0x997E,0x9A00,0x9A7A,0x9AF4,0x9B6E,0x9BC0,0x9C12,0x9C8C,0x9D06,0x9D88,0x9E1A,0x9EAC,0x9F26,0x9FA0,0xA01A,0xA094,0xA10E,0xA1B0,0xA22A,0x84E2,0x855C,0x988A,0x9904]
CUERPO=(125,118,252); PELO=(212,193,84); SEP=(60,60,60)
def main(fa,fb,hoja,sal,orig_a=None):
    A=open(fa,'rb').read(); B=open(fb,'rb').read(); H1=Image.open(hoja).convert('RGB')
    OA=open(orig_a,'rb').read() if orig_a else A
    def g(M,a): w=M[a]&0x7f; h=M[a+1]; return w,h,bytes(M[a+2:a+2+w*h])
    xa={}; x=0
    for a in FREDDY_A: xa[a]=x; x+=(A[a]&0x7f)*8+4
    H=max(B[a+1] for a in FREDDY_B)
    W=sum((B[a]&0x7f)*8+4 for a in FREDDY_B)-4
    im=Image.new('RGB',(W,H),SEP); x0=0; nuevas=[]
    for b in FREDDY_B:
        w,h,d=g(B,b); par=[a for a in FREDDY_A if g(OA,a)[2]==d]
        for y in range(h):
            for xx in range(w*8):
                if par: p=H1.getpixel((xa[par[0]]+xx,y))
                else:
                    filas=[yy for yy in range(h) if any(d[yy*w:(yy+1)*w])]; top=filas[0]
                    v=d[y*w+xx//8]>>(7-xx%8)&1
                    p=(PELO if y<=top+4 else CUERPO) if v else (0,0,0)
                im.putpixel((x0+xx,y),p)
        if not par: nuevas.append(b)
        x0+=w*8+4
    im.save(sal); return nuevas
if __name__=='__main__': print([hex(n) for n in main(*sys.argv[1:])])
