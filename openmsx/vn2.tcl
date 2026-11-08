# vigila_vram.tcl - comprobación de accesos a VRAM demasiado rápidos (MSX1, TMS9918/9929)
# Uso en openMSX:  openmsx -machine Sony_HB-20P -cart MiJuego.rom -script vigila_vram.tcl
# Deja en la consola y en vigila_vram.log el PC de cada OUT/IN a 98h que el VDP real perdería.
# Licencia: MIT (herramienta propia del proyecto).

set too_fast_vram_access real   ;# accesos demasiado rápidos se pierden, como en el aparato
set limitsprites on             ;# 4 sprites por línea, como en el aparato

set ::vigila_cuenta 0
set ::vigila_log [open "vigila_vram.log" w]

proc vigila_rapido {} {
	incr ::vigila_cuenta
	set pc [format %04X [reg PC]]
	set linea [machine_info time]
	if {$::vigila_cuenta <= 200} {
		puts $::vigila_log "acceso VRAM demasiado rápido #$::vigila_cuenta  PC=$pc  t=$linea"
		flush $::vigila_log
		message "VRAM demasiado rápida en PC=$pc" warning
	}
}

# El nombre del ajuste depende del VDP de la máquina (normalmente "VDP").
if {[catch {set VDP.too_fast_vram_access_callback vigila_rapido}]} {
	message "sin callback" warning
}
set throttle off
proc tecla {fila bit t} { keymatrixdown $fila $bit; after time $t "keymatrixup $fila $bit" }
after time 20 { tecla 8 0x01 0.2 }
after time 23 { tecla 8 0x01 0.3 }; foreach t {27 31 35 40 45 50 55} { after time $t "tecla 0 0x02 0.2" }
expr {srand(7)}
set ::teclas {{8 0x80} {8 0x10} {8 0x20} {8 0x40} {8 0x01}}
proc azar {} {
  foreach t $::teclas { keymatrixup [lindex $t 0] [lindex $t 1] }
  set r [expr rand()]
  if {$r < 0.7} { keymatrixdown 8 0x80 } elseif {$r<0.8} { keymatrixdown 8 0x10 }
  foreach t [lrange $::teclas 2 end] { if {rand() < 0.3} { keymatrixdown [lindex $t 0] [lindex $t 1] } }
  after time 0.7 azar
}
proc reinicio {} { tecla 0 0x02 0.15; after time 15 reinicio }
set ::nr 0; debug set_bp 0x25B8 {} { incr ::nr }
after time 60 { azar; reinicio; set ::nr 0 }
foreach t {80 100 120 140 160} { after time $t "screenshot -raw $::env(SAL)_$t.png" }
after time 180 { set f [open $::env(SAL).nr w]; puts $f "$::nr imagenes en 120 s"; close $f; close $::vigila_log; exit }
