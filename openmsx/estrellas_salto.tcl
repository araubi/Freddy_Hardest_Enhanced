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
foreach t {35 40 45 50 55} { after time $t "tecla 0 0x02 0.2" }
proc azar {} { keymatrixdown 8 0x80; if {rand()<0.5} {keymatrixdown 8 0x20} else {keymatrixup 8 0x20}; if {rand()<0.3} {keymatrixdown 8 0x01} else {keymatrixup 8 0x01}; after time 0.4 azar }
set ::f [open buf_t2800.bin w]; fconfigure $::f -translation binary
set ::g [open pos_t2800.txt w]
proc muestra {} { if {[peek 0x4583]} { puts -nonewline $::f [debug read_block "Main RAM" 0x6500 0x0D00]; puts $::g "[peek16 0xD927]" }; poke 0xD974 5; after time 0.1 muestra }
after time 60 { poke16 0xD927 2800; after time 1 {azar; muestra} }
after time 400 { close $::f; close $::g; exit }
