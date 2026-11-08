# prueba_salas.tcl - limpieza de sprites al cambiar de sala (parte 2): Freddy anda a la derecha y en cada
# cuadro se apunta cuántos sprites hay en la tabla (los 7 primeros son la cara del marcador) y un resumen
# de la fila de arriba de la pantalla. Al cambiar de sala los sprites de la partida deben irse justo antes
# de que cambie la pantalla y volver con la sala nueva ya volcada.
# sprite clean-up on room changes / 部屋の切り替え時のスプライト消去の確認
# Uso: openmsx -machine C-BIOS_MSX1 -cart FreddyHardest_Enhanced.rom -script parte2.tcl -script prueba_salas.tcl
# Licencia / license / ライセンス: MIT
set ::f 0
proc cada {} {
  incr ::f
  binary scan [debug read_block VRAM 0x1B00 128] cu* s
  set n 0
  for {set i 0} {$i<32} {incr i} { set y [lindex $s [expr {$i*4}]]; if {$y==208} break; if {$y<192 || $y>=224} {incr n} }
  binary scan [debug read_block VRAM 0x0000 0x100] cu* bb
  set h 0; set k 1; foreach b $bb {set h [expr {($h + $b*$k) & 0xFFFFFF}]; incr k}
  puts stderr "f=$::f t=[format %.3f [machine_info time]] pantalla=$h sprites=$n"
  after frame cada
}
after time 51 {keymatrixdown 8 0x80; after frame cada}
after time 70 exit
