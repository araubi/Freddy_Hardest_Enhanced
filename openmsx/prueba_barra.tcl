# prueba_barra.tcl - barra de disparos de la parte 2 tras cambiar de sala: vacía la barra con la propia
# rutina del juego (E47Ch=1, E47Dh=0, E47Fh=1), anda a la derecha y apunta el nivel (E47Eh) y los colores de
# la barra (fila 17, columnas 13-17). Las celdas por encima del nivel tienen que seguir en negro (11h).
# shot bar after a room change / 部屋を移動した後の弾丸バーの確認
# Uso: openmsx -machine C-BIOS_MSX1 -cart FreddyHardest_Enhanced.rom -script parte2.tcl -script prueba_barra.tcl
# Licencia / license / ライセンス: MIT
set ::prev ""
proc cada {} {
  binary scan [debug read_block memory 0xE47C 4] H* he
  binary scan [debug read_block VRAM 0x3168 40] H* hv
  if {"$he $hv" ne $::prev} { puts stderr "t=[format %.2f [machine_info time]] E47C=$he colores=$hv"; set ::prev "$he $hv" }
  after frame cada
}
after time 52 {after frame cada}
after time 53 {poke 0xE47C 1; poke 0xE47D 0; poke 0xE47F 1}
after time 56 {keymatrixdown 8 0x80}
after time 66 exit
