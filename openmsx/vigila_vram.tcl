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
	message "Esta versión de openMSX no tiene VDP.too_fast_vram_access_callback: solo se aplica too_fast_vram_access real" warning
}
