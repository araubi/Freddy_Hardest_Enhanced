"""Freddy Hardest ROM: reparte cada figura de Freddy (graficos/freddy_colores.png, de araubi) en
sprites de 16 x 16 de un color, con no más de 4 sprites en ninguna línea.
- Cada color es una capa. Una capa se cubre con sprites: se busca por recocido simulado (semilla
  fija, así el resultado es siempre el mismo) la manera con menos líneas de más de 4 y menos sprites.
- Si aun así alguna línea pasa de 4, en esas líneas el color secundario (celeste) pasa a su color
  principal (azul) y se vuelve a buscar; si ya no queda celeste, el color con menos píxeles de la
  línea pasa al azul.
Claude para araubi, 2026-11-04. MIT."""
import random,math
NEGRO,GRIS=(0,0,0),(60,60,60)
TMS=[(0,0,0),(0,0,0),(33,200,66),(94,220,120),(84,85,237),(125,118,252),(212,82,77),(66,235,245),
     (252,85,84),(255,121,120),(212,193,84),(230,206,128),(33,176,59),(201,91,186),(204,204,204),(255,255,255)]
def tms(rgb):
    return min(range(2,16),key=lambda i:sum((a-b)**2 for a,b in zip(TMS[i],rgb)))
SECUNDARIO={5:4}     # celeste -> azul en las líneas que se pasan
PRINCIPAL=4          # si no basta, el color más escaso de la línea pasa al azul
def segs_de(rows,cuts):
    # cuts: lista ordenada de filas donde empieza un tramo nuevo; devuelve tramos (y,last) con píxeles
    h=len(rows); bounds=[0]+cuts+[h]; out=[]
    for a,b in zip(bounds,bounds[1:]):
        ys=[y for y in range(a,b) if rows[y]]
        if ys: out.append((ys[0],ys[-1]))
    return out
def _rects(m,state,rows):
    h=len(m); out=[]
    for c,(cuts,al) in state.items():
        for i,(y,last) in enumerate(segs_de(rows[c],cuts)):
            xs=[x for r in rows[c][y:last+1] for x in r]; lo=min(xs); k=1 if max(xs)-lo<16 else 2
            lo_,hi_=max(0,last-15),y
            if h>=16: hi_=min(hi_,h-16); lo_=min(lo_,hi_)
            ys=round(lo_+(hi_-lo_)*al.get(i,0.0))
            out.append((c,ys,y,last,lo,k))
    return out
def evalua(m,state,rows):
    h=len(m); line=[0]*(h+16); spr=0; ok=True
    for c,(cuts,al) in state.items():
        for i,(y,last) in enumerate(segs_de(rows[c],cuts)):
            if last-y>15: return None
            xs=[x for r in rows[c][y:last+1] for x in r]; k=1 if max(xs)-min(xs)<16 else 2
            lo_,hi_=max(0,last-15),y
            if h>=16: hi_=min(hi_,h-16); lo_=min(lo_,hi_)
            a=al.get(i,0.0); ys=round(lo_+(hi_-lo_)*a)
            for yy in range(ys,ys+16): line[yy]+=k
            spr+=k
    return sum(max(0,v-4) for v in line)*100+sum(max(0,v-3) for v in line)*3+spr   # (4-11) mejor 3 por línea: deja sitio a los enemigos
def sa(m,seed=1,steps=30000):
    rnd=random.Random(seed); h=len(m)
    cols=sorted({v for r in m for v in r}-{0})
    rows={c:[[x for x,v in enumerate(r) if v==c] for r in m] for c in cols}
    st={c:(list(range(16,h,16)),{}) for c in cols}
    cur=evalua(m,st,rows); best=(cur,{c:(v[0][:],dict(v[1])) for c,v in st.items()})
    T=50.0
    for s in range(steps):
        c=rnd.choice(cols); cuts,al=st[c]; old=(cuts[:],dict(al))
        r=rnd.random()
        if r<0.35 and cuts: i=rnd.randrange(len(cuts)); cuts[i]=max(1,min(h-1,cuts[i]+rnd.choice([-3,-2,-1,1,2,3])))
        elif r<0.5: cuts.append(rnd.randrange(1,h))
        elif r<0.6 and cuts: cuts.pop(rnd.randrange(len(cuts)))
        else: al[rnd.randrange(4)]=rnd.random()
        cuts[:]=sorted(set(cuts))
        v=evalua(m,st,rows)
        if v is not None and (v<=cur or rnd.random()<math.exp((cur-v)/T)):
            cur=v
            if v<best[0]: best=(v,{c:(x[0][:],dict(x[1])) for c,x in st.items()})
        else: st[c]=old
        T=max(0.5,T*0.9997)
    return best
def figura(m,semilla=1,pasos=30000):
    """m: filas de índices TMS (0 = vacío). Devuelve (sprites, m retocada, líneas>4, píxeles cambiados).
    sprites: (dy, dx, color, filas) con filas = 16 enteros de 16 bits (bit 15 = x=dx).
    Búsqueda por recocido simulado: cada capa (color) se corta en tramos de hasta 16 filas y cada
    tramo es un sprite (o dos, si pasa de 16 de ancho) que se puede subir o bajar."""
    m=[r[:] for r in m]; cambiados=0
    for it in range(12):
        cols=sorted({v for r in m for v in r}-{0})
        rows={c:[[x for x,v in enumerate(r) if v==c] for r in m] for c in cols}
        cst,st=sa(m,semilla,pasos)
        rects=_rects(m,st,rows)
        line=[0]*(len(m)+16)
        for c,ys,y,last,lo,k in rects:
            for yy in range(ys,ys+16): line[yy]+=k
        if cst<100: break
        n_=0
        for y,r in enumerate(m):
            if line[y]>4:
                for x,v in enumerate(r):
                    if v in SECUNDARIO: r[x]=SECUNDARIO[v]; n_+=1
        if not n_:
            # ya no queda celeste en esas líneas: el color con menos píxeles de cada una pasa al principal
            for y,r in enumerate(m):
                if line[y]>4:
                    cnt={}
                    for v in r:
                        if v and v!=PRINCIPAL: cnt[v]=cnt.get(v,0)+1
                    if cnt:
                        c=min(cnt,key=lambda k:(cnt[k],k))
                        for x,v in enumerate(r):
                            if v==c: r[x]=PRINCIPAL; n_+=1
        cambiados+=n_
        if not n_: break
    sprites=[]
    for c,ys,y,last,lo,k in rects:
        for j in range(k):
            x0=lo+16*j; filas=[]
            for r in range(16):
                yy=ys+r; v=0
                if y<=yy<=last:
                    for x in range(16):
                        if x0+x<len(m[yy]) and m[yy][x0+x]==c: v|=0x8000>>x
                filas.append(v)
            if any(filas): sprites.append((ys,x0,c,filas))
    line=[0]*(len(m)+16)
    for ys,*_ in sprites:
        for yy in range(ys,ys+16): line[yy]+=1
    return sprites,m,sum(v>4 for v in line),cambiados
def figura_cache(m,ruta_cache):
    """Como figura(), pero guarda el resultado (la búsqueda tarda unos segundos por figura)."""
    import json,hashlib
    clave=hashlib.md5(('v2'+json.dumps(m)).encode()).hexdigest()   # v2: coste con 3 por línea
    try: cache=json.load(open(ruta_cache))
    except Exception: cache={}
    if clave not in cache:
        spr,m2,malas,camb=figura(m)
        cache[clave]=[spr,m2,malas,camb]
        json.dump(cache,open(ruta_cache,'w'))
    spr,m2,malas,camb=cache[clave]
    return [tuple(x) for x in spr],m2,malas,camb
def lee_png(ruta,anchos):
    """Figuras seguidas en el PNG, separadas 4 px; devuelve matrices de índices TMS (0 = vacío)."""
    from PIL import Image
    im=Image.open(ruta).convert('RGB'); x0=0; out=[]
    for w,h in anchos:
        out.append([[0 if im.getpixel((x0+x,y)) in (NEGRO,GRIS) else tms(im.getpixel((x0+x,y))) for x in range(w)] for y in range(h)])
        x0+=w+4
    return out
def patron(filas,espejo=False):
    p=bytearray(32)
    for r,v in enumerate(filas):
        if espejo: v=int(f'{v:016b}'[::-1],2)
        p[r]=v>>8; p[16+r]=v&0xFF
    return p
