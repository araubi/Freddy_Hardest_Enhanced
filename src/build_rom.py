#!/usr/bin/env python3
"""Freddy Hardest (Dinamic 1987): MegaROM ASCII16 de 256 KB con las dos partes.
Uso: python3 build_rom.py --cabeza --nestor --rapida   (Freddy Hardest Enhanced v1.0; necesita pasmo o
sjasmplus en el PATH y los originales que saca tools/extrae_originales.py en originales/)
Banco 0 = arranque (arranque.asm + copiador.asm); bancos 1-4 = RAM de la parte 1; 5-8 = parte 2."""
import json, os,sys,subprocess,shutil,re
AQUI=os.path.dirname(os.path.abspath(__file__))
ORIG=os.path.join(os.path.dirname(AQUI),'originales')   # lo que no se publica: lo saca tools/extrae_originales.py
def original(n):
    r=os.path.join(ORIG,n)
    if not os.path.exists(r): sys.exit(f'Falta {r}: ejecuta antes tools/extrae_originales.py con tus cintas')
    return open(r,'rb').read()
from sc2 import convierte

def asm(fuente,salida,cwd=AQUI):
    """Ensambla y devuelve (bytes, símbolos)."""
    out=os.path.join(cwd,salida); sym=out+'.sym'
    if shutil.which('sjasmplus'):
        r=subprocess.run(['sjasmplus','--nologo','--raw='+out,'--sym='+sym,fuente],cwd=cwd,capture_output=True,text=True)
    else:
        r=subprocess.run(['pasmo','--bin',fuente,out,sym],cwd=cwd,capture_output=True,text=True)
    if r.returncode: sys.exit(fuente+':\n'+r.stdout+r.stderr)
    s={}
    for l in open(sym):
        m=re.match(r'\s*(\w+):?\s+EQU\s+(?:0x|\$|#)?([0-9A-Fa-f]+)H?',l)
        if m: s[m.group(1)]=int(m.group(2),16)
    return open(out,'rb').read(),s

CODIGOS={**{chr(65+i):1+i for i in range(26)},**{str(i):0x1A+i for i in range(1,10)},'0':0x24,'-':0x25,"'":0x2A,'.':0x2B,' ':0x2C,'+':0x26,'=':0x27,':':0x28,'?':0x29}
def cod(t): return [CODIGOS[c] for c in t]

TECLAS_DEF=[(0x7F,8),(0xEF,8),(0xDF,8),(0xBF,8),(0xFE,8)]   # derecha, izquierda, arriba, abajo, disparo
def parchea_teclas(img,tabla):
    for i,(m,f) in enumerate(TECLAS_DEF):
        img[tabla+4*i+2]=m; img[tabla+4*i+3]=f

def lineas_reparto(img):
    """Lee el rollo original (6722h): [x][n][n códigos] o FEh (línea vacía), FFh fin."""
    p=0x6722; L=[]
    while img[p]!=0xFF:
        if img[p]==0xFE: L.append(None); p+=1; continue
        x,n=img[p],img[p+1]; L.append((x,list(img[p+2:p+2+n]))); p+=2+n
    return L
CR_BANCO=13
CR_MODULO=b''
def creditos(A,B,marca,fin_spr=0):
    """Créditos al final de la parte 2 (B): módulo en la RAM libre de B, desde 2A00h."""
    L=lineas_reparto(A)
    # Rollo tal como lo dejó Dinamic (sin nombres añadidos)
    chars=sorted({c for l in L if l for c in l[1] if c not in (0,0x2C,0x26)})
    assert 2*len(chars)<=126
    idx={c:2*k for k,c in enumerate(chars)}
    filas=[None]*24+L+[None]*26   # (v21) una fila vacía más: la tabla que se prepara para k+1 lee hasta k+25
    canvas=bytearray(); llenas=[]
    for l in filas:
        r=[126]*32
        if l:
            for k,c in enumerate(l[1]):
                if c in idx and l[0]+k<32: r[l[0]+k]=idx[c]
        canvas+=bytes(r); llenas.append(1 if l else 0)
    with open(os.path.join(AQUI,'creditos_datos.inc'),'w') as f:
        f.write('COLOR_TEXTO EQU 0B1h\n')
        f.write(f'N_GLIFOS EQU {len(chars)}\nCR_PASOS EQU {8*(len(filas)-26)}\nGLIFOS:\n')
        for c in chars: f.write('\tDB 0,0,0,0,0,0,0,0,'+','.join(f'{x:03X}h' for x in A[0x8618+8*c:0x8620+8*c])+'\n')   # (v21) 8 ceros + el glifo
        f.write('\tDB 0,0,0,0,0,0,0,0\n')
    with open(os.path.join(AQUI,'creditos_rom.inc'),'w') as f:   # (v21) solo en el banco CR_BANCO: se lee por 8000h
        f.write('CR_LLENAS:\n')
        for k in range(0,len(llenas),32): f.write('\tDB '+','.join(str(x) for x in llenas[k:k+32])+'\n')
        f.write('\tDS (($+255)/256)*256-$\t; CANVAS alineado a 256\nCANVAS:\n')
        for k in range(0,len(canvas),32): f.write('\tDB '+','.join(str(x) for x in canvas[k:k+32])+'\n')
    org=0x2A00
    with open(os.path.join(AQUI,'creditos_org.inc'),'w') as f:
        f.write(f'CR_ORG EQU {org:05X}h\nMENU_DIR EQU 0C807h\nCR_BANCO EQU {CR_BANCO}\n')
        f.write(f'MARCA_DIR EQU {marca:05X}h\n' if marca else 'MARCA_DIR EQU CR_RET\n')
        f.write(f'FIN_SPR EQU {fin_spr:05X}h\n' if fin_spr else 'FIN_SPR EQU CR_RET\n')   # (v19b) G_FIN_P2B: sin sprites en el menú
    m,s=asm('creditos.asm','creditos.bin')
    n_ram=s['CR_FIN_MODULO']-org   # (v21) lo de detrás (CR_LLENAS y CANVAS) se queda en la ROM
    assert org+n_ram<=0x4F3C,hex(org+n_ram)     # (v21) no pasar de lo que ocupaba la v20 (4F80h: variables de los sprites)
    assert len(m)<=0x4000
    B[org:org+n_ram]=m[:n_ram]
    global CR_MODULO
    CR_MODULO=bytes(m)   # también en el banco CR_BANCO: se recarga al empezar los créditos
    assert B[0xFC42:0xFC45]==bytes([0xC3,0x07,0xC8])  # JP MENU tras «PLAYBOY DE PEGA»
    B[0xFC42:0xFC45]=bytes([0xC3,s['CREDITOS_B']&255,s['CREDITOS_B']>>8])
    print('creditos',hex(org),'-',hex(org+n_ram),'(RAM);',hex(len(m)),'bytes en el banco',CR_BANCO)
    return s

def parchea(img,sim,lista):
    """lista: (dirección, bytes originales, nuevos bytes o (instrucción, símbolo))"""
    for d,orig,nuevo in lista:
        assert img[d:d+len(orig)]==bytes(orig),(hex(d),img[d:d+len(orig)].hex())
        if isinstance(nuevo,tuple):
            op,s=nuevo; v=sim[s]; nuevo=[op,v&255,v>>8]+[0]*(len(orig)-3)
        img[d:d+len(nuevo)]=bytes(nuevo)
CALL,JP=0xCD,0xC3
GANCHOS_A=[(0x013D,[0x08,0xF5,0xAF],(JP,'VOLCADO')),
    (0xECCD,[0xED,0x43,0xA6,0xEE],(CALL,'G_FIGURA')),
    (0xEE40,[0xCD,0x60,0xEE],(CALL,'G_DIR_BLOQUE')),
    (0xEA9F,[0xCD,0x43,0xEE],(CALL,'G_COPIA_BLOQUE')),
    (0xF893,[0xAE,0x77,0xC9],(JP,'G_PUNTO')),
    (0xEAA5,[0x21,0xFF,0x84],(CALL,'G_TERRENO1')),
    (0xEB37,[0x21,0x00,0x81],(CALL,'G_TERRENO2')),
    (0xF258,[0x21,0x00,0x75],(CALL,'G_BORRA_FONDO')),
    (0x039D,[0xF5,0x7D,0xD3,0x99],(JP,'G_LLENA')),
    (0x038B,[0xEB,0x7B,0xD3,0x99],(CALL,'G_BYTE')),
    (0x04B3,[0x59,0x16,0x00],(CALL,'G_BLOQUE_VRAM')),
    (0x055D,[0xB7,0x11,0x00,0x58],(CALL,'G_ATRIB_RECT')),
    (0x003C,[0xC3,0x6D,0x01],(JP,'G_RMW1')),
    (0x0021,[0xC3,0xC5,0x01],(JP,'G_RMW2')),
    (0xEF1E,[0x21,0x00,0x75],(JP,'G_RESTAURA')),
    (0x050D,[0x0E,0x20,0x59],(JP,'ATRIBUTOS')),
    (0x9546,[0x3A,0x8D,0x95],(JP,'G_SONIDO')),
    (0x024B,[0x32,0x36,0xD9],(CALL,'G_MANDOS'))]
GANCHOS_B=[(0x013B,[0x08,0xF5,0xAF],(JP,'VOLCADO')),
    (0xF683,[0x21,0x00,0x62,0x19,0xC9],(JP,'G_B_DIR')),
    (0xF6FD,[0xDD,0x6E,0x04],(CALL,'G_B_REPON')),
    (0xF6DB,[0xDD,0x2A,0x92,0xF7],(CALL,'G_B_MODO')),
    (0xC810,[0x21,0x00,0x50],(CALL,'G_TODO_5000')),
    (0xD39E,[0x21,0x00,0x62],(CALL,'G_TODO_BUFER')),
    (0xF72F,[0xDD,0x21,0x4C,0xBC],(CALL,'G_TODO_IX')),
    (0x02FC,[0xF5,0x7D,0xD3,0x99],(JP,'G_LLENA')),
    (0x026D,[0xEB,0x7B,0xD3,0x99],(CALL,'G_BYTE')),
    (0x0412,[0x59,0x16,0x00],(CALL,'G_BLOQUE_VRAM')),
    (0x04BC,[0xB7,0x11,0x00,0x58],(CALL,'G_ATRIB_RECT')),
    (0x0021,[0xC3,0xAE,0x01],(JP,'G_RMW2')),
    (0x046C,[0x0E,0x20,0x59],(JP,'ATRIBUTOS')),
    (0x0235,[0x32,0xA5,0xD7],(CALL,'G_MANDOS'))]
def sonidos(A):
    """Efectos 1-6 de la parte 1 (tabla 958Eh: n.º de pasos y pasos A, BC). Cada paso eran A pulsos
    del clic de periodo 26*BC+120 ciclos; en el PSG el periodo de tono es ese /32. Se reparten en
    cuadros de 20 ms tomando en cada cuadro el tono que más suena en él."""
    with open(os.path.join(AQUI,'sonidos.inc'),'w') as f:
        f.write('SND_VOLUMEN EQU 12\nSND_TABLA:\n'+''.join(f'\tDW SND_{n}\n' for n in range(1,7)))
        for n in range(1,7):
            p=A[0x958E+2*n]|A[0x958F+2*n]<<8; q=p+1; pasos=[]
            for k in range(A[p]):
                a,bc=A[q],A[q+1]|A[q+2]<<8; q+=3
                ciclo=26*bc+120; pasos.append((a*ciclo/3579.545,max(1,round(ciclo/32))))
            tot=sum(d for d,_ in pasos); nc=max(1,round(tot/20)); notas=[]
            for c in range(nc):
                a0,a1=c*tot/nc,(c+1)*tot/nc; acum=0; mejor=(-1,0)
                for d,tp in pasos:
                    solape=max(0,min(a1,acum+d)-max(a0,acum)); acum+=d
                    if tp<10: solape/=100      # tonos inaudibles solo si no hay otro
                    if solape>mejor[0]: mejor=(solape,tp)
                tp=mejor[1]
                if notas and notas[-1][0]==tp: notas[-1][1]+=1
                else: notas.append([tp,1])
            f.write(f'SND_{n}:\t; {round(tot,1)} ms\n'+''.join(f'\tDW {tp}\n\tDB {c}\n' for tp,c in notas)+'\tDW 0\n')
# ---- sprites de la parte 1 (4-11-2026). Por defecto solo Freddy, en los colores de
# graficos/freddy_colores.png (araubi); --enemigos pone también los enemigos en sprites.
SPRITES='--sin-sprites' not in sys.argv
NESTOR='--nestor' in sys.argv   # (7-11) ideas de Néstor Sancho: marcador_nestor.png, verde oscuro, estrellas fijas y grises
CABEZA='--cabeza' in sys.argv   # (5-11, araubi) como --tinta5, pero en sprites solo la cabeza (pelo y la piel de debajo); los brazos, en los tiles originales
TINTA5='--tinta5' in sys.argv or CABEZA   # (5-11, araubi) Freddy original en tiles + pelo y piel en sprites, tinta de juego 5, enemigos en sprites (5 -> 11)
ENEMIGOS='--enemigos' in sys.argv or TINTA5     # enemigos enteros en sprites
MITADES='--mitades' in sys.argv   # enemigos con la mitad de abajo en sprites (prueba del 4-11; desde las 22:30 por defecto solo Freddy)
VOLADOR=14                # el volador (D) va entero en sprites
MASCARA='--mascara' in sys.argv   # sprites con la máscara negra del original debajo (prueba de velocidad, 4-11)
SIN_MASCARA_B='--sin-mascara-b' in sys.argv or ('--rapida' in sys.argv and '--mascara-b' not in sys.argv)   # (7-11, araubi) la rápida, sin máscaras en la parte 2   # (7-11) parte 2: enemigos con su máscara negra salvo con esta opción
FREDDY=[0x9C40,0x9CBA,0x9D34,0x9DAE,0x9E28,0x9EA2,0x9F1C,0x9F96,0xE4C0,0xE53A,0xE5B4,0xE656,0xE6D0,0xD6D8]
# (primera cabecera, fin, color): figuras seguidas [ancho][alto][datos]
TIPOS_SPR=[(0xB82C,0xB9B4,13),   # A (colores de araubi, 4-11-2026)
    (0xB9B4,0xBB9C,6),    # B
    (0xBB9C,0xBD84,5),    # C
    (0xBD84,0xBF3C,14),   # D: ojo con muelle
    (0xBF3C,0xC124,12)]   # E: serpientes
BANCO_SPR=9               # bancos 9 en adelante de la ROM: listas y patrones de los sprites
SPR_BANCOS=b''
INFORME_SPR=[]
def marcador_datos(SF):
    """Registros (DW dirección VRAM + 4000h, DB n, n bytes; DW 0 al final) que repintan el marcador
    como graficos/marcador.png (256 x 64, colores TMS). Referencia: graficos/marcador_vram.bin (patrones y
    colores de las filas 16-23 tal como las deja el juego). En la caja de la cara (columnas 2-5, filas
    17-22) se reescriben patrón y color; en el resto, solo el color, con el patrón del juego (así la
    munición y los números siguen siendo del juego).
    Cara (5-11, araubi: «métele sprite para el blanco de los ojos» y «también para el pelo rubio»):
    el pelo amarillo va entero en sprites fijos, y el gris de los tramos de 8 que también tienen rosa
    (ojos, cuello) en otros; los tiles se quedan con rosa, negro y el gris que cabe. Debajo de un
    sprite el tile da igual. Devuelve también la matriz de los sprites (32 x 48, 0 = vacío)."""
    from PIL import Image
    from collections import Counter
    im=Image.open(os.path.join(AQUI,'graficos','marcador_nestor.png' if NESTOR else 'marcador.png')).convert('RGB')
    # (v1.0) la referencia es un volcado de la VRAM del juego original y no se publica: sin ella se usan
    # los registros ya calculados (graficos/marcador_registros*.json, que se rehacen si está)
    rj=os.path.join(AQUI,'graficos','marcador_registros'+('_nestor' if NESTOR else '')+'.json')
    rv=os.path.join(ORIG,'marcador_vram.bin')
    if not os.path.exists(rv):
        j=json.load(open(rj))
        return bytes.fromhex(j['out']),(j['prueba'],tuple(j['prueba_v'])),tuple(j['info']),j['spr']
    ref=open(rv,'rb').read()
    def idx(p):
        i=0 if p==(0,0,0) else SF.tms(p)
        return 1 if i==0 else i
    spr=[[0]*32 for _ in range(48)]       # x 16-47, y 8-55 del PNG
    out=bytearray(); perdidos=0; prueba=None
    for r in range(16,24):
        for c in range(32):
            cara=2<=c<=5 and 17<=r<=22
            pats=[];cols=[];cambia=False
            for l in range(8):
                y=(r-16)*8+l
                a=(r-16)*256+c*8+l; P=ref[a]; C=ref[0x800+a]
                ds=[idx(im.getpixel((c*8+b,y))) for b in range(8)]
                if TINTA5 and C==0xA1: C=0x51     # (7-11) la tinta 6 del juego ya es la 5: las cifras salían azules
                orig=[((C>>4) if P>>(7-b)&1 else (C&15)) or 1 for b in range(8)]
                if ds!=orig: cambia=True
                if cara:
                    t=[d for d in ds if d!=10]
                    if 9 in t: t=[d for d in t if d not in (11,14,15)]   # (7-11, Néstor) blanco y amarillo claro, como el gris
                    for b,d in enumerate(ds):
                        if d==10 or (d in (11,14,15) and d not in t): spr[y-8][c*8+b-16]=d
                    cnt=Counter(t); cnt[1]*=2      # el negro pesa doble (si no, sale rosa donde no hay)
                    top=sorted(cnt,key=lambda k:(-cnt[k],k!=1))[:2]
                    f=top[0] if top else 1; g=top[1] if len(top)>1 else (1 if f!=1 else 9)
                    p=sum(0x80>>b for b,d in enumerate(ds) if d==f)
                    perdidos+=sum(1 for d in t if d not in (f,g))
                    pats.append(p); cols.append((f<<4)|g)
                    if prueba is None and P and p: prueba=0x1000+a; prueba_v=(P,p)
                else:
                    f=Counter(d for b,d in enumerate(ds) if P>>(7-b)&1).most_common(1)
                    g=Counter(d for b,d in enumerate(ds) if not P>>(7-b)&1).most_common(1)
                    f=f[0][0] if f else (C>>4); g=g[0][0] if g else (C&15)
                    perdidos+=sum(1 for b,d in enumerate(ds) if d!=(f if P>>(7-b)&1 else g))
                    cols.append((f<<4)|g)
            if not cambia: continue
            a=0x1000+(r-16)*256+c*8
            if cara: out+=(a|0x4000).to_bytes(2,'little')+bytes([8])+bytes(pats)
            out+=((a+0x2000)|0x4000).to_bytes(2,'little')+bytes([8])+bytes(cols)
    out+=b'\0\0'
    json.dump({'out':bytes(out).hex(),'prueba':prueba,'prueba_v':list(prueba_v),'info':['marcador',len(out),perdidos],'spr':spr},open(rj,'w'))
    return out,(prueba,prueba_v),('marcador',len(out),perdidos),spr
MON_LISTA=0
TXT_TBC='TO BE CONTINUED'
TBC_SUBE=32        # (araubi: «como 30 píxeles») 32 = 4 filas: el texto (0027h) solo sale bien en filas enteras. Y del Spectrum: crece hacia arriba
MON_TEXTO=('CLAVE','897653')
MON_COLOR=0xA1     # amarillo sobre negro, como la clave del original
def monitor_clave(A):
    """(8-11, araubi e idea de un tester) Final de la parte 1: la clave en el monitor del marcador (abajo a
    la derecha; hueco negro de x 184-239, y 136-183), «CLAVE» y «897653» en dos líneas centradas. Se
    reescriben patrón y color de las filas 18-21, columnas 23-29 (en el juego, vacías); las esquinas del
    monitor (filas 17 y 22) no se tocan. Registros como los del marcador (DW dir+4000h, DB n, bytes)."""
    X0,Y0,W,H=184,136,56,48
    gap=6; alto=8*len(MON_TEXTO)+gap*(len(MON_TEXTO)-1); y=Y0+(H-alto)//2
    pix={}
    for t in MON_TEXTO:
        x=X0+(W-8*len(t))//2
        for k,ch in enumerate(t):
            g=A[0x8CA0+8*CODIGOS[ch]:0x8CA8+8*CODIGOS[ch]]
            for l in range(8):
                for b in range(8):
                    if g[l]&(0x80>>b): pix[(x+8*k+b,y+l)]=1
        y+=8+gap
    assert all(144<=py<176 and 184<=px<240 for px,py in pix)
    out=bytearray()
    for r in range(18,22):
        d=0x1000+(r-16)*256+23*8
        pats=bytes(sum(0x80>>b for b in range(8) if pix.get((c*8+b,r*8+l))) for c in range(23,30) for l in range(8))
        out+=(d+0x4000).to_bytes(2,'little')+bytes([len(pats)])+pats
        out+=(d+0x2000+0x4000).to_bytes(2,'little')+bytes([len(pats)])+bytes([MON_COLOR]*len(pats))
    return bytes(out)+b'\0\0'

def marcador_sprites(SF,m):
    """Sprites fijos de la cara: (y del SAT, x, color, patrón)."""
    spr,m2,malas,camb=SF.figura_cache(m,os.path.join(AQUI,'graficos','marcador_nestor_cache.json' if NESTOR else 'marcador_cache.json'))
    assert not camb,('el reparto de la cara cambia colores',malas,camb)
    INFORME_SPR.append(('marcador sprites',len(spr),malas,camb))
    linea=[0]*64
    for dy,dx,c,f in spr:
        for k in range(16):
            if 8+dy+k<64: linea[8+dy+k]+=1
    INFORME_SPR.append(('marcador sprites por línea (máx.)',max(linea)))
    assert max(linea)<=4
    return [(128+8+dy-1,16+dx,c,SF.patron(f)) for dy,dx,c,f in spr]
# recortes a mano de araubi (5-11, 10:10): figura -> qué piel se queda en sprites (x, y en la figura)
CABEZA_RECORTE={1:lambda x,y: 6<=y<=12 and x<=16}   # 2.ª figura: mano de arriba y brazo junto a la cara, a tiles
def cabeza_hoja(A,ruta,medidas,lista=None):
    """graficos/freddy_cabeza_1a1.png (412 x 40, como sprites/freddy_original_1a1.png): las 14 figuras en su caja,
    arriba del todo, separadas por 4 px de gris (60,60,60). Lo que se ve en el juego: amarillo (10) y piel (9)
    van en sprites; cualquier otro color que no sea negro es el dibujo de los tiles (tinta de la zona). El
    gráfico de Freddy en la imagen A se reescribe: un píxel encendido donde hay tile o sprite (así, si el sprite
    parpadea, debajo queda la silueta). La máscara del original no se toca."""
    import spr_freddy as SF
    from PIL import Image
    im=Image.open(ruta).convert('RGB'); x0=0; mats=[]
    for g,(w,h) in zip(lista or FREDDY,medidas):
        m=[]; d=bytearray(w//8*h)
        for y in range(h):
            r=[]
            for x in range(w):
                p=im.getpixel((x0+x,y))
                assert p!=(60,60,60),('gris dentro de la figura',hex(g),x,y)
                c=0 if p==(0,0,0) else SF.tms(p)
                r.append(c if c in (9,10) else 0)
                if c: d[y*(w//8)+x//8]|=0x80>>(x%8)
            m.append(r)
        A[g+2:g+2+len(d)]=d; mats.append(m); x0+=w+4
    return mats
def solo_cabeza(m,i=None):
    """El pelo (10) y la piel (9) que queda a su altura y bajo él: filas desde una encima del pelo hasta 4
    por debajo, columnas del pelo más una a cada lado. El resto de la piel (brazos, manos) se queda en tiles."""
    P=[(x,y) for y,r in enumerate(m) for x,v in enumerate(r) if v==10]
    if not P: return m
    x0=min(x for x,y in P)-1; x1=max(x for x,y in P)+1; y0=min(y for x,y in P)-1; y1=max(y for x,y in P)+4
    f=CABEZA_RECORTE.get(i,lambda x,y: True)
    return [[v if v==10 or (v==9 and x0<=x<=x1 and y0<=y<=y1 and f(x,y)) else 0 for x,v in enumerate(r)] for y,r in enumerate(m)]
def sprites_datos(A):
    """spr_datos.inc (SPR_TABLA) y SPR_BANCOS. Cada figura tiene en la ROM su lista de sprites
    (dy, dx, dx con espejo, color, patrón, patrón con espejo) y detrás sus patrones."""
    global SPR_BANCOS
    import spr_freddy as SF
    medidas=[((A[g]&0x7f)*8,A[g+1]) for g in FREDDY]
    mats=SF.lee_png(os.path.join(AQUI,'graficos','freddy_colores.png'),medidas)
    figs=[]
    if MITADES and '--celeste' not in sys.argv:   # (4-11) en la versión de enemigos a medias, sin celeste: un sprite menos
        mats=[[[4 if v==5 else v for v in r] for r in m] for m in mats]
    if TINTA5: mats=[[[v if v in (9,10) else 0 for v in r] for r in m] for m in mats]
    if CABEZA:
        hoja=os.path.join(AQUI,'graficos','freddy_cabeza_1a1.png')
        if os.path.exists(hoja): mats=cabeza_hoja(A,hoja,medidas)   # (5-11, 14:37) retoque de araubi: manda el PNG
        else: mats=[solo_cabeza(m,i) for i,m in enumerate(mats)]
    for g,m in zip(FREDDY,mats):
        spr,m2,malas,camb=SF.figura_cache(m,os.path.join(AQUI,'graficos','freddy_colores_cache.json'))
        INFORME_SPR.append((g,len(spr),malas,camb,m2))
        figs.append((g,0x80,spr,0xFF if TINTA5 else 0))   # 0FFh: entero en el búfer y además sus sprites
    if ENEMIGOS or MITADES:
        cache=os.path.join(AQUI,'graficos','enemigos_cache.json')
        for a,b,c in TIPOS_SPR:
            if TINTA5 and c==5: c=11
            entero=ENEMIGOS or c==VOLADOR
            g=a
            while g<b:
                w=A[g]&0x7f; h=A[g+1]; d=A[g+2:g+2+w*h]
                px=[[c if d[y*w+x//8]>>(7-x%8)&1 else 0 for x in range(w*8)] for y in range(h)]
                y0=0 if entero else h//2      # mitad de arriba en el búfer, mitad de abajo en sprites
                spr,_,_,_=SF.figura_cache(px[y0:],cache)
                spr=[(dy+y0,dx,cc,f) for dy,dx,cc,f in spr]
                figs.append((g,0 if entero else 0x40,spr,0 if entero else c)); g+=2+w*h
            assert g==b,hex(g)
    bancos=[bytearray()]; tabla=[]; maxl=1
    for g,fl,spr,ct in figs:
        w=(A[g]&0x7f)*8; n=len(spr); maxl=max(maxl,n)
        if len(bancos[-1])+n*72>0x4000: bancos.append(bytearray())
        bk=bancos[-1]; lista=0x8000+len(bk); pats=lista+n*8
        for i,(dy,dx,c,filas) in enumerate(spr):
            dxm=w-dx-16
            bk+=bytes([dy,dx&0xFF,dxm&0xFF,c])+(pats+i*64).to_bytes(2,'little')+(pats+i*64+32).to_bytes(2,'little')
        for dy,dx,c,filas in spr: bk+=SF.patron(filas)+SF.patron(filas,True)
        tabla.append(f'\tDW {g+2:05X}h\n\tDB {fl:03X}h,{BANCO_SPR+len(bancos)-1}\n\tDW {lista:05X}h\n\tDB {n},{ct}')
    # marcador (4-11, araubi): cara de Freddy en color y pistola y esquinas en gris, desde graficos/marcador.png
    marc,(prueba,prueba_v),info,mspr=marcador_datos(SF)
    fijos=marcador_sprites(SF,mspr); n=len(fijos)
    INFORME_SPR.append(info)
    global MON_LISTA
    MON_LISTA=0x8000+len(marc)       # (8-11) registros del monitor con la clave, detrás de los del marcador
    marc=bytes(marc)+monitor_clave(A)
    bancos.append(bytearray(marc)); banco_marc=BANCO_SPR+len(bancos)-1
    assert BANCO_SPR+len(bancos)<=16
    SPR_BANCOS=b''.join(bytes(b)+b'\xFF'*(0x4000-len(b)) for b in bancos)
    global MARC_OPC,MARC_TXT,N_BANCOS_A
    N_BANCOS_A=len(bancos)
    MARC_OPC=f'MARC_BANCO EQU {banco_marc}\nMARC_PRUEBA EQU {prueba:05X}h\nMARC_PRUEBA_O EQU {prueba_v[0]:03X}h\nMARC_PRUEBA_N EQU {prueba_v[1]:03X}h\nNMARC EQU {n}\nMARC_VPAT EQU {0x3800+(32-n)*32:05X}h\n'
    open(os.path.join(AQUI,'spr_opc.inc'),'w').write(f'MASCARA EQU {int(MASCARA)}\nFREDDY_GIRA EQU {int(TINTA5)}\nMAXLISTA EQU {maxl}\nMARC_BANCO EQU {banco_marc}\nMARC_PRUEBA EQU {prueba:05X}h\nMARC_PRUEBA_O EQU {prueba_v[0]:03X}h\nMARC_PRUEBA_N EQU {prueba_v[1]:03X}h\nNMARC EQU {n}\nMARC_VPAT EQU {0x3800+(32-n)*32:05X}h\n')
    MARC_TXT='MARC_SAT:\t; sprites fijos de la cara del marcador (huecos 32-NMARC..31 de la mitad 0)\n'+''.join(f'\tDB {y},{x},{(32-n+i)*4},{c}\n' for i,(y,x,c,p) in enumerate(fijos))+'MARC_PATS:\n'+''.join('\tDB '+','.join(f'{b:03X}h' for b in p)+'\n' for y,x,c,p in fijos)
    with open(os.path.join(AQUI,'spr_datos.inc'),'w') as f:
        f.write('MARC_SAT:\t; sprites fijos de la cara del marcador (huecos 32-NMARC..31 de la mitad 0)\n')
        for i,(y,x,c,p) in enumerate(fijos): f.write(f'\tDB {y},{x},{(32-n+i)*4},{c}\n')
        f.write('MARC_PATS:\n')
        for y,x,c,p in fijos: f.write('\tDB '+','.join(f'{b:03X}h' for b in p)+'\n')
        f.write('SPR_TABLA:\t; gráfico, bit 7 = Freddy / bit 6 = mitad de arriba en el búfer, banco, lista en la ROM, n.º de sprites, color de la mitad de arriba\n'+'\n'.join(tabla)+'\n\tDW 0\n')

# (7-11, araubi) parte 2: Freddy como en la parte 1 (tiles + cabeza y pelo en sprites) y enemigos enteros en
# sprites, sin máscara: guardia 2 (antes 3; 7-11 araubi: verde más oscuro), robot 11, mina 14 (explosiones, disparos e impactos siguen en tiles)
FREDDY_B=[0x997E,0x9A00,0x9A7A,0x9AF4,0x9B6E,0x9BC0,0x9C12,0x9C8C,0x9D06,0x9D88,0x9E1A,0x9EAC,0x9F26,0x9FA0,0xA01A,0xA094,0xA10E,0xA1B0,0xA22A,0x84E2,0x855C,0x988A,0x9904]   # 84E2/855C: animación nueva (G), 7-11; 988A: Freddy de espaldas en el ascensor y 9904 la variante del ordenador, 7-11
ENEMIGOS_B=[(g,2) for g in (0x90A0,0x911A,0x9194,0x920E,0x8FAC,0x9026,0xBF00,0x9302,0x937C,0x941E,0x9288)]+[(0xBF82,11)]+[(g,14) for g in (0x845A,0x847C,0x849E,0x84C0)]
def sprites_datos_b(A0,B):
    """spr_opc_b.inc, spr_datos_b.inc y los bancos de la parte 2 detrás de los de la parte 1 (A0: imagen A original)."""
    global SPR_BANCOS
    import spr_freddy as SF
    sys.path.insert(0,os.path.join(AQUI,'graficos'))
    import freddy_b_hoja
    hoja=os.path.join(AQUI,'graficos','freddy_b_cabeza_1a1.png')
    if not os.path.exists(hoja):
        hoja=os.path.join(AQUI,'graficos','freddy_b_cabeza_1a1_v0.png')
        if not os.path.exists(hoja):
            import tempfile
            ta=os.path.join(tempfile.gettempdir(),'fh_a.bin'); tb=os.path.join(tempfile.gettempdir(),'fh_b.bin')
            open(ta,'wb').write(A0); open(tb,'wb').write(B)
            freddy_b_hoja.main(ta,tb,os.path.join(AQUI,'graficos','freddy_cabeza_1a1.png'),hoja)
    ini={g:(0x20 if B[g]&0x80 else 0) for g in FREDDY_B+[e for e,c in ENEMIGOS_B]}
    medidas=[((B[g]&0x7f)*8,B[g+1]) for g in FREDDY_B]
    mats=cabeza_hoja(B,hoja,medidas,FREDDY_B)
    figs=[]
    for g,m in zip(FREDDY_B,mats):
        spr,m2,malas,camb=SF.figura_cache(m,os.path.join(AQUI,'graficos','freddy_colores_cache.json'))
        INFORME_SPR.append(('B',hex(g),len(spr),malas,camb))
        figs.append((g,0x80|ini[g],spr,0xFF))
    for g,c in ENEMIGOS_B:
        w=B[g]&0x7f; h=B[g+1]; d=B[g+2:g+2+w*h]
        px=[[c if d[y*w+x//8]>>(7-x%8)&1 else 0 for x in range(w*8)] for y in range(h)]
        spr,_,malas,camb=SF.figura_cache(px,os.path.join(AQUI,'graficos','enemigos_cache.json'))
        INFORME_SPR.append(('B',hex(g),len(spr),malas,camb))
        figs.append((g,ini[g],spr,0))
    base=BANCO_SPR+N_BANCOS_A
    bancos=[bytearray()]; tabla=[]; maxl=1
    for g,fl,spr,ct in figs:
        w=(B[g]&0x7f)*8; n=len(spr); maxl=max(maxl,n)
        if len(bancos[-1])+n*72>0x4000: bancos.append(bytearray())
        bk=bancos[-1]; lista=0x8000+len(bk); pats=lista+n*8
        for i,(dy,dx,c,filas) in enumerate(spr):
            dxm=w-dx-16
            bk+=bytes([dy,dx&0xFF,dxm&0xFF,c])+(pats+i*64).to_bytes(2,'little')+(pats+i*64+32).to_bytes(2,'little')
        for dy,dx,c,filas in spr: bk+=SF.patron(filas)+SF.patron(filas,True)
        tabla.append(f'\tDW {g+2:05X}h\n\tDB {fl:03X}h,{base+len(bancos)-1}\n\tDW {lista:05X}h\n\tDB {n},{ct}')
    assert base+len(bancos)<=16
    SPR_BANCOS+=b''.join(bytes(b)+b'\xFF'*(0x4000-len(b)) for b in bancos)
    open(os.path.join(AQUI,'spr_opc_b.inc'),'w').write(f'MASCARA EQU {int(not SIN_MASCARA_B)}\nFREDDY_GIRA EQU 1\nMAXLISTA EQU {maxl}\n'+MARC_OPC)
    with open(os.path.join(AQUI,'spr_datos_b.inc'),'w') as f:
        f.write(MARC_TXT+'SPR_TABLA:\t; parte 2: gráfico, bit 7 = Freddy / bit 5 = orientación de los sprites, banco, lista, n.º, 0FFh = también en el búfer\n'+'\n'.join(tabla)+'\n\tDW 0\n')
ESTRELLAS_NUEVAS=[(38,8),(17,10),(72,12),(150,12),(31,13),(217,13),(31,15),(44,20),(51,20),(192,28),(242,31),(228,36),(34,37),(74,39),(70,45),(212,46),(18,49),(182,53),(35,57),(52,57)]   # (7-11) las de araubi (plantilla_estrellas.png)
# (7-11) celdas (fila, columna) de la zona de arriba que algo pisa alguna vez (openMSX, recorriendo la fase)
ESTRELLAS_PISADAS=json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'celdas_pisadas.json')))
ENTRADA_DIRECTA=0xEFD2   # (7-11) menú de la parte 1 sin la presentación (con intro_estado.bin)
ENTRADA={'A':0x0094,'B':0x00AD}   # entradas de cada parte tras el copiador
def optimiza(img,L):
    if L=='A': open(os.path.join(AQUI,'tinta.inc'),'w').write(f'TINTA_FIJA EQU {int(CABEZA)}\nFILA_PIES EQU 12\t; Freddy no baja de la línea 103\n')
    if L=='A': sonidos(img); sprites_datos(img)
    if L=='B': sprites_datos_b(A_ORIG,img)
    o='B' if L=='A' else 'A'; lo=LIMITES[0 if o=='A' else 1]
    open(os.path.join(AQUI,'partes.inc'),'w').write(f'OTRA_BANCO EQU {1 if o=="A" else 5}\nOTRA_ENTRADA EQU {(ENTRADA_DIRECTA if o=="A" else ENTRADA[o]):05X}h\nOTRA_PARCHE EQU {int(o=="A")}\nOTRA_L50 EQU {lo[0]}\nOTRA_L60 EQU {lo[1]}\n')
    m,s=asm(f'optim_{L.lower()}.asm',f'optim_{L.lower()}.bin')
    org=0x0C40; img[org:org+len(m)]=m
    parchea(img,s,GANCHOS_A if L=='A' else GANCHOS_B)
    # (6-11, araubi) menú: opción 3, ir a la otra parte
    parchea(img,s,[(0xEFF0,[0x21,0x1D,0xF0],(CALL,'G_TXT3')),(0x00BA,[0xDA,0x90,0xF1],(JP,'G_MENU'))] if L=='A' else
                  [(0xC873,[0x21,0xF4,0xC9],(CALL,'G_TXT3')),(0x00CC,[0xDA,0xD8,0x00],(JP,'G_MENU'))])
    if L=='A':   # módulo en 5800h: arreglo de G_TAM siempre; con --nestor, estrellas fijas y grises y hierba verde oscuro
      if NESTOR:
        for d in (0xF38E,0xF3BA,0xF5BD,0xF5E8):     # CALL LF89B / LF8AB: mover las 20 estrellas con el scroll
            assert img[d] == CALL and img[d+2] == 0xF8, hex(d); img[d:d+3]=bytes(3)
        assert img[0x2778+4]==0x21; img[0x2778+4]=0xC1
      celdas={}
      if NESTOR:
        # (7-11, araubi y Néstor) estrellas recolocadas por araubi fuera de las columnas por las que salta
        # Freddy (13-17, hasta la línea 8; medido en openMSX recorriendo la fase): así su color gris
        # puede ir fijo sin mirar nada (estrellas.asm; con la nave del principio en pantalla, tinta 5).
        for k,(x,y) in enumerate(ESTRELLAS_NUEVAS):
            img[0xE1C8+2*k]=x; img[0xE1C9+2*k]=0xAF-y
        for k in range(20):        # tabla E1C8h: X, 0AFh - Y
            x=img[0xE1C8+2*k]; y=0xAF-img[0xE1C9+2*k]
            if y>=(12+1)*8: continue     # solo en las filas de tinta fija
            c=celdas.setdefault((y>>3,x>>3),[0]*8); c[y&7]|=0x80>>(x&7)
      if True:
        # celdas que algo pisa alguna vez (medido en openMSX, fy/tot.npy de la v16): esas se miran
        mira={(r,c) for r,c in ESTRELLAS_PISADAS}
        with open(os.path.join(AQUI,'estrellas.inc'),'w') as f:
            fij=[k for k in sorted(celdas) if k not in mira]; mir=[k for k in sorted(celdas) if k in mira]
            f.write(f"LIM_SAT EQU {s['LIM_SAT']:05X}h\nSPR_ON EQU {s['SPR_ON']:05X}h\nEST_NF EQU {len(fij)}\nEST_NM EQU {len(mir)}\n")
            f.write('\tORG 5800h\n\tJP ESTRELLAS\nEST_FIJAS:\n')
            for r,c in fij: f.write(f"\tDW {0x6000+r*256+c*8:05X}h\n")
            f.write('EST_MIRA:\n')
            for r,c in mir:
                f.write(f"\tDW {0x6500+r*256+c:05X}h,{0x6000+r*256+c*8:05X}h\n\tDB "+','.join(f'{v:03X}h' for v in celdas[(r,c)])+',0\n')
        me,se=asm('estrellas.asm','estrellas.bin')
        assert 0x5800+len(me)<=0x5A00,hex(len(me))
        img[0x5800:0x5800+len(me)]=me
        if NESTOR:
            d=s['VOL_FIN_CALL']; assert img[d]==CALL; img[d+1:d+3]=se['ESTRELLAS'].to_bytes(2,'little')
        # (7-11) arranque nuevo: tras la presentación, al menú de partes (G_MENUP en EFD2h); sus esperas
        # se pueden saltar con una tecla (G_ESPERA en lugar de DEC BC / LD A,B / OR C / JR NZ)
        global EST_SIMB; EST_SIMB=se
        assert img[0xEFD2:0xEFD5]==bytes([CALL,0xC4,0xEF]); img[0xEFD3:0xEFD5]=se['G_MENUP'].to_bytes(2,'little')
        # lo que deja la presentación (intro_estado.bin, tomado en openMSX en EFD2h): la imagen de partida
        # tiene que seguir siendo la de entonces (intro_estado_antes.bin), si no, hay que volver a tomarlo
        ra=os.path.join(ORIG,'intro_estado_antes.bin')
        an=open(ra,'rb').read() if os.path.exists(ra) else bytes(4); k=0
        while True:
            d=int.from_bytes(an[k:k+2],'little'); n=int.from_bytes(an[k+2:k+4],'little'); k+=4
            if not n: break
            assert img[d:d+n]==an[k:k+n], f'intro_estado: la imagen ha cambiado en {d:04X}h'; k+=n
        for d in (0x65A5,0x6680,0x6A30,0x6BC2,0x7CF1):   # 7CF1h: la escena de la nave, se copia a 7565h
            assert img[d:d+5]==bytes([0x0B,0x78,0xB1,0x20,0xFB]),hex(d)
            img[d:d+5]=bytes([CALL])+se['G_ESPERA'].to_bytes(2,'little')+bytes(2)
        assert img[0x6A00:0x6A03]==bytes([CALL,0x21,0x00]); img[0x6A01:0x6A03]=se['G_W21'].to_bytes(2,'little')
        for d in (0x7C8C+0x75EB-0x7500,0x7C8C+0x7603-0x7500):
            assert img[d:d+3]==bytes([CALL,0x0E,0xEB]); img[d+1:d+3]=se['G_WEB0E'].to_bytes(2,'little')
        for d in (0x6522,0x6634,0x6A17):
            assert img[d:d+3]==bytes([CALL,0x48,0x00]); img[d+1:d+3]=se['G_W48'].to_bytes(2,'little')
        assert img[0x6573:0x6576]==bytes([JP,0x12,0x00]); img[0x6574:0x6576]=se['G_W12'].to_bytes(2,'little')
        d=0x7C8C+0x767B-0x7500    # escena de la nave (se copia a 7500h)
        assert img[d:d+3]==bytes([CALL,0x05,0x77]); img[d+1:d+3]=se['G_W7705'].to_bytes(2,'little')
        assert img[0xEECC:0xEED0]==bytes([0xED,0x4B,0xA6,0xEE])
        img[0xEECC:0xEED0]=bytes([CALL,se['G_TAM']&255,se['G_TAM']>>8,0])
    if L=='B':   # (7-11) el mismo fallo del alto 0 (ver G_TAM en estrellas.asm) en la parte 2: F8CBh, alto en F97Fh
        assert img[0xF8CA:0xF8CF]==bytes([0xD1,0xED,0x4B,0x7F,0xF9]) and not any(img[0xFF00:0xFF10])
        img[0xFF00:0xFF0E]=bytes([0xED,0x4B,0x7F,0xF9, 0x78, 0xFE,8, 0xD0, 0x7A, 0xE6,7, 0xC0, 0x06,8])+b''
        img[0xFF0E]=0xC9     # LD BC,(F97Fh) / LD A,B / CP 8 / RET NC / LD A,D / AND 7 / RET NZ / LD B,8 / RET
        img[0xF8CB:0xF8CF]=bytes([CALL,0x00,0xFF,0])
    if L=='B': parchea(img,s,[(0xF562,[0xED,0x4B,0x8C,0xF7],(JP,'SPR_FIG')),
        # (8-11) marcador en color al empezar la partida, con la pantalla apagada mientras se vuelca
        (0xCBBA,[0xCD,0x18,0x00],(CALL,'G_INTRO')),
        # (7-11) fin de partida: fuera los sprites antes de la pantalla de GAME OVER
        (0xF123,[0xCD,0x1C,0xE5],(CALL,'G_FIN_P2')),(0xF177,[0x01,0xF4,0x01],(CALL,'G_FIN_P2B')),
        # (8-11) todo cambio de sala (también por el ascensor): fuera los sprites de la sala anterior
        (0xCCF8,[0x06,0x00,0xED,0x5B,0xB5,0xD3],(CALL,'G_SALA')),
        # (8-11) barra de disparos: el color también en el atributo
        (0xE456,[0xC3,0x60,0x00],(JP,'G_BARRA'))])   # (7-11) sprites en la parte 2
    if L=='A' and SPRITES: parchea(img,s,[(0xECB0,[0x3A,0x9A,0xEE],(JP,'SPR_FIG')),
        # (6-11) textos de fin (THE END, la clave): antes se quitan los sprites de la partida
        (0xFB6A,[0x21,0x1A,0xD8],(CALL,'G_FIN_A')),(0xFB75,[0x21,0xFE,0xD7],(CALL,'G_FIN_A')),
        # (6-11) rectángulos de color de los objetos: tinta 5 en las filas de tinta fija
        (0x057D,[0x7C,0xF6,0x60,0xD3,0x99],(CALL,'G_ATR_FILA')),
        # (6-11) marcador en color ya en la presentación que precede a la partida (8-11: con la pantalla apagada mientras se vuelca)
        (0xF1BA,[0xCD,0x18,0x00],(CALL,'G_INTRO')),
        # (6-11) letras (mensajes, marcador): bytes espaciados para que el VDP no pierda ninguno
        (0x0221,[0xEB,0xCD,0x85,0x03],(JP,'G_TEXTO'))])
    if L=='A':
        # disparo (fallo del original): 64A1h-64D0h comprueba la X; ahora G_TIRO_X
        assert img[0x64A1:0x64AA]==bytes([0x2A,0x3A,0x63,0xED,0x5B,0xA4,0xEE,0x26,0x00])
        g=s['G_TIRO_X']
        img[0x64A1:0x64AA]=bytes([CALL,g&255,g>>8, 0xDA,0xDC,0x64, JP,0xD1,0x64])
        # (7-11) altura del disparo sin dar la vuelta con Freddy en lo alto: G_TIRO_Y
        assert img[0x6494:0x64A1]==bytes([0x3A,0x3B,0x63,0xD6,0x28,0xB8,0x30,0x40,0xC6,0x30,0xB8,0x38,0x3B])
        g=EST_SIMB['G_TIRO_Y']
        img[0x6494:0x64A1]=bytes([CALL,g&255,g>>8, 0x38,0x64DC-0x6499]+[0]*8)
        assert img[0x6393:0x6396]==bytes([0xCD,0x6C,0x64])
        g=s['G_TIRO_MATA']
        img[0x6393:0x6396]=bytes([CALL,g&255,g>>8])
    if L=='A' and SPRITES and MON_LISTA:
        # (8-11, araubi) final de la parte 1: la clave en el monitor del marcador (no arriba) y TO BE
        # CONTINUED 30 píxeles más arriba que el THE END, centrado. En FB6Ah (11 bytes, antes la clave
        # arriba): CALL SPR_ESCONDE / LD HL,MON_LISTA / CALL PM_LISTA_HL / JR FB75h. El texto nuevo va
        # donde estaba «LA CLAVE ES 897653» (D81Ah, ya sin uso) y FB75h llama a G_FIN_A, que da HL=D81Ah.
        assert img[0xFB6A]==CALL and img[0xFB6D:0xFB75]==bytes([0x11,0x08,0xAF,0x06,0x12,CALL,0x7C,0xD9])
        img[0xFB6A:0xFB75]=(bytes([CALL])+s['SPR_ESCONDE'].to_bytes(2,'little')+bytes([0x21])+MON_LISTA.to_bytes(2,'little')
                            +bytes([CALL])+s['PM_LISTA_HL'].to_bytes(2,'little')+bytes([0x18,0x00]))   # JR $+2: sigue en FB75h
        assert img[0xD81A:0xD82C]==bytes(cod('LA')+[0x26]+cod('CLAVE')+[0x26]+cod('ES')+[0x26]+cod('897653'))
        img[0xD81A:0xD81A+len(TXT_TBC)]=bytes(0x26 if c==' ' else CODIGOS[c] for c in TXT_TBC)
        assert img[0xFB75]==CALL and img[0xFB78:0xFB7D]==bytes([0x11,0x64,0x6F,0x06,0x07])
        img[0xFB76:0xFB78]=s['G_FIN_A'].to_bytes(2,'little')
        img[0xFB79]=128-4*len(TXT_TBC); img[0xFB7A]=0x6F+TBC_SUBE; img[0xFB7C]=len(TXT_TBC)
    return s

def imagen(L):
    img=bytearray(original(f'freddy_{L.lower()}.bin')); img+=bytes(65536-len(img))
    return img

OPTIM='--sin-optim' not in sys.argv
# cuadros mínimos por imagen en el bucle de juego: ((parte 1 a 50 Hz, a 60 Hz), (parte 2 ...))
# (7-11, araubi) la rápida, con limitador por imágenes por segundo (40h + img/s): parte 1 a 11, parte 2 a 15
# (--sin-limite: la rápida de antes, sin ningún límite)
LIMITES=(((0,0),(0,0)) if '--sin-limite' in sys.argv else ((0x40+11,)*2,(0x40+15,)*2)) if '--rapida' in sys.argv else ((6,7),(4,5))
def main():
    global A_ORIG
    for n in ('spr_opc_b.inc','spr_datos_b.inc','spr_opc.inc','spr_datos.inc','tinta.inc'):   # pasmo abre los INCLUDE también dentro de un IF falso
        if not os.path.exists(os.path.join(AQUI,n)): open(os.path.join(AQUI,n),'w').write('')
    A=imagen('A'); B=imagen('B'); A_ORIG=bytes(A)
    # teclas por defecto: cursores + ESPACIO (el joystick sigue valiendo)
    parchea_teclas(A,0x05C7); parchea_teclas(B,0x0526)
    if TINTA5:      # tinta de la zona de juego (y del menú del juego): amarillo -> 5
        assert A[0x2778+6]==0xA1; A[0x2778+6]=0x51
        assert B[0x28B6+7]==0xE1; B[0x28B6+7]=0x51   # (7-11, araubi) parte 2: la tinta gris de la base, al azul 5
    # la música de los créditos es la de la página 0 de la parte 1, antes de los ganchos
    open(os.path.join(AQUI,'pagina0_a.bin'),'wb').write(A[0:0x0C1C])
    sb={}
    global LIMITE_DIR
    LIMITE_DIR=0
    if OPTIM:
        sa=optimiza(A,'A'); sb=optimiza(B,'B')
        assert sa['LIMITE']==sb['LIMITE']
        LIMITE_DIR=sa['LIMITE']
    creditos(A,B,sb.get('MARCA_TODO',0),sb.get('G_FIN_P2B',0))
    # 0000h: el arranque de la cinta copiaba bloques que la ROM ya deja en su sitio
    for img,L in ((A,'A'),(B,'B')):
        img[0:3]=bytes([0xC3,ENTRADA[L]&255,ENTRADA[L]>>8])
    # recursos del arranque
    open(os.path.join(AQUI,'fuente.bin'),'wb').write(A[0x8618:0x8618+0x2D*8])
    scr=original('pantalla_carga.scr')
    tab=original('tabla_color.bin')
    p,cc=convierte(scr,tab)
    open(os.path.join(AQUI,'pantalla_pat.bin'),'wb').write(p)
    open(os.path.join(AQUI,'pantalla_col.bin'),'wb').write(cc)
    textos=[(4,9,0xB1,'FREDDY HARDEST'),(10,9,0xA1,'1   PARTE 1   '),(12,9,0xA1,'2   PARTE 2   '),
            (17,7,0xE1,'CURSORES Y ESPACIO'),(22,10,0x51,'DINAMIC 1987')]
    with open(os.path.join(AQUI,'textos_rom.inc'),'w') as f:
        f.write('TXT_MENU:\n')
        for fi,co,col,t in textos:
            f.write(f'\tDB {fi},{co},{col:03X}h,{len(t)}\t; {t}\n\tDB '+','.join(f'{x:03X}h' for x in cod(t))+'\n')
        f.write('\tDB 0FFh\n')
    with open(os.path.join(AQUI,'arranque.inc'),'w') as f:
        f.write(f'ENTRADA_A EQU {ENTRADA["A"]:05X}h\nENTRADA_B EQU {ENTRADA["B"]:05X}h\n')
        la,lb=LIMITES   # (50 Hz, 60 Hz) de cada parte
        f.write(f'LIM_A EQU {la[1]}*256+{la[0]}\nLIM_B EQU {lb[1]}*256+{lb[0]}\n')
        f.write(f'LIMITE_DIR EQU {LIMITE_DIR:05X}h\n')
        f.write(f'ENTRADA_INTRO EQU {EST_SIMB["G_ENT_INTRO"]:05X}h\nENTRADA_DIRECTA EQU {ENTRADA_DIRECTA:05X}h\n')
    asm('copiador.asm','copiador.bin')
    b0,_=asm('arranque.asm','arranque.bin')
    assert len(b0)==0x4000,hex(len(b0))
    rom=bytearray(b0)+A+B
    if OPTIM: rom+=SPR_BANCOS   # (también sin sprites: el marcador en color va ahí)
    assert len(rom)<=12*0x4000
    rom+=b'\xFF'*(12*0x4000-len(rom))
    rom+=original('intro_estado.bin')   # banco 12 (PARCHE_BANCO del copiador)
    assert len(rom)<=13*0x4000 and len(CR_MODULO)<=0x4000
    rom+=b'\xFF'*(13*0x4000-len(rom))
    rom+=CR_MODULO                                                   # banco 13: créditos (CR_BANCO)
    rom+=b'\xFF'*(0x40000-len(rom))
    nombre=os.path.join(AQUI,'FreddyHardest'+('_cabeza' if CABEZA else '_tinta5' if TINTA5 else '')+('_sin_optimizar' if not OPTIM else '_rapida' if '--rapida' in sys.argv else '')+'.rom')
    open(nombre,'wb').write(rom)
    print('ROM',nombre,len(rom))
if __name__=='__main__': main()
