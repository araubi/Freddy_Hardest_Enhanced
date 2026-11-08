#!/usr/bin/env python3
"""Saca de TUS cintas de Freddy Hardest (Dinamic 1987, MSX) lo que este repositorio no incluye, y de la ROM
de releases/ el estado de la presentación (banco 12). Comprueba el MD5 de las cintas y el SHA-1 de todo.
Extracts from YOUR Freddy Hardest tapes what this repository does not include, and from the ROM in
releases/ the intro state (bank 12). The tapes are checked by MD5 and every file by SHA-1.
このリポジトリに含まれないものを手持ちの Freddy Hardest のテープ (2 面) から、イントロの状態 (バンク 12)
を releases/ の ROM から取り出し、テープは MD5、すべてのファイルは SHA-1 で確認します。

  python3 tools/extrae_originales.py caraA.cas caraB.cas [--rom releases/FreddyHardest_Enhanced_v1.0.rom]

Deja / writes / 出力: originales/freddy_a.bin, freddy_b.bin (imagen de la memoria de cada parte / memory
image of each part / 各パートのメモリイメージ), pantalla_carga.scr, tabla_color.bin, intro_estado.bin.
"""
import argparse, hashlib, os, sys

RAIZ = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
ORIG = os.path.join(RAIZ, 'originales')
CAS_HDR = bytes([0x1F, 0xA6, 0xDE, 0xBA, 0xCC, 0x13, 0x7D, 0x74])
MD5 = {'A': '015ceaf1a52c19e401ff35c910fbb971', 'B': 'ad818760051d46bbcdcffde3ff49bed4'}
SHA1 = {
    'freddy_a.bin': 'd9289b11a9c372ce38dcdd932577d795419794d4', 'freddy_b.bin': 'c0980bd35c8ea1191eab1927e086d5ffeea979f5', 'pantalla_carga.scr': '2a447c227b8f2e973c40644a5b13e481eb86b3dd',
    'tabla_color.bin': 'e1b254e65da5128f2ba36fd34b298629b5365775', 'intro_estado.bin': '09ab8afdea70e18398df08926e8fa03ce1a1c5a9',
}
sha1 = lambda d: hashlib.sha1(d).hexdigest()

def bloques(cas):
    pos, i = [], 0
    while (j := cas.find(CAS_HDR, i)) >= 0:
        pos.append(j + 8); i = j + 8
    return [cas[p:(pos[k + 1] - 8 if k + 1 < len(pos) else len(cas))] for k, p in enumerate(pos)]

def binario(b):
    ini, fin = b[0] | b[1] << 8, b[2] | b[3] << 8
    return ini, b[6:6 + fin - ini + 1]

def cara(ruta, L):
    cas = open(ruta, 'rb').read()
    if hashlib.md5(cas).hexdigest() != MD5[L]:
        sys.exit(f'{ruta}: no es la cinta esperada (cara {L}, MD5 {MD5[L]}) / not the expected tape / 想定したテープではありません')
    bl = bloques(cas)
    img = bytearray(0x10000)
    # bloques 5, 7, 9 y 11: cargador propio + trozo del juego (como src/build.py del desensamblado)
    cargas = {5: (0xBB00, 0x0000, 0x0C1C), 7: (0x93A8, 0x6200, 0x9470), 11: (0x93A8, 0x9470, 0xDA49),
              9: (0x93A8, 0xDA49, 0xFEA3 if L == 'B' else 0xFFE1)}
    for n, (org, d, f) in cargas.items():
        ini, datos = binario(bl[n])
        assert ini == org, (L, n, hex(ini))
        img[d:f] = datos[len(datos) - (f - d) - (1 if n == 5 else 0):len(datos) - (1 if n == 5 else 0)]
    # cargador de 9E98h: lleva la tabla de colores (que copia a 2778h / 28B6h) y la pantalla de carga
    ini, carga = binario(bl[3])
    assert ini == 0x9E98
    tab = carga[232:232 + 0x80]
    img[(0x28B6 if L == 'B' else 0x2778):(0x28B6 if L == 'B' else 0x2778) + 0x80] = tab
    return img, tab, carga[232 + 0x80:232 + 0x80 + 6912]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('caraA'); ap.add_argument('caraB')
    ap.add_argument('--rom', default=os.path.join(RAIZ, 'releases', 'FreddyHardest_Enhanced_v1.0.rom'))
    a = ap.parse_args()
    os.makedirs(ORIG, exist_ok=True)
    out = {}
    for L, ruta in (('A', a.caraA), ('B', a.caraB)):
        img, tab, scr = cara(ruta, L)
        out[f'freddy_{L.lower()}.bin'] = bytes(img)
        if L == 'A':
            out['tabla_color.bin'] = tab
            out['pantalla_carga.scr'] = scr
    rom = open(a.rom, 'rb').read()
    est = rom[12 * 0x4000:13 * 0x4000]
    k = 0
    while int.from_bytes(est[k + 2:k + 4], 'little'):
        k += 4 + int.from_bytes(est[k + 2:k + 4], 'little')
    out['intro_estado.bin'] = est[:k + 4]
    for nom, dat in out.items():
        if SHA1[nom].startswith('@'):
            print(f'{nom}: {len(dat)} bytes, SHA-1 {sha1(dat)}')
        elif sha1(dat) != SHA1[nom]:
            sys.exit(f'{nom}: SHA-1 distinto / different SHA-1 / SHA-1 が一致しません')
        open(os.path.join(ORIG, nom), 'wb').write(dat)
    print('originales/ listo / ready / 完了')

if __name__ == '__main__':
    main()
