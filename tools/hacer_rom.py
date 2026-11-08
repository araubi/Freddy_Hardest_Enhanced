#!/usr/bin/env python3
"""Compila Freddy Hardest Enhanced (la ROM rápida de releases/) y comprueba que sale idéntica.
Builds Freddy Hardest Enhanced (the fast ROM in releases/) and checks that it comes out identical.
Freddy Hardest Enhanced (releases/ の高速版 ROM) をビルドし、同一かどうかを確認します。

  python3 tools/extrae_originales.py caraA.cas caraB.cas     # una vez / once / 最初に一度
  python3 tools/hacer_rom.py                                 # -> FreddyHardest_Enhanced.rom

Opciones de src/build_rom.py que se pueden añadir / extra options / 追加オプション:
  --sin-limite   sin limitador de imágenes por segundo / no frame-rate limiter / フレームレート制限なし
"""
import hashlib, os, shutil, subprocess, sys
RAIZ = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
SRC = os.path.join(RAIZ, 'src')
REL = os.path.join(RAIZ, 'releases', 'FreddyHardest_Enhanced_v1.0.rom')
r = subprocess.run([sys.executable, 'build_rom.py', '--cabeza', '--nestor', '--rapida'] + sys.argv[1:], cwd=SRC)
if r.returncode: sys.exit(r.returncode)
sal = os.path.join(RAIZ, 'FreddyHardest_Enhanced.rom')
shutil.move(os.path.join(SRC, 'FreddyHardest_cabeza_rapida.rom'), sal)
h = hashlib.sha1(open(sal, 'rb').read()).hexdigest()
igual = os.path.exists(REL) and h == hashlib.sha1(open(REL, 'rb').read()).hexdigest()
print(f'{sal}\nSHA-1 {h}', '= releases/ (idéntica / identical / 同一)' if igual else '(distinta de releases/ / differs / 異なります)')
