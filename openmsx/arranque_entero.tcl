set throttle off
proc tecla {fila bit t} { keymatrixdown $fila $bit; after time $t "keymatrixup $fila $bit" }
proc log {m} { set f [open full.txt a]; puts $f "[format %.2f [machine_info time]] $m"; close $f }
debug set_bp 0x2609 {} { log "COPIA entrada=[format %04X [peek16 0x2604]] parche=[peek 0x26F8]" }
debug set_bp 0x40C9 {} { log MENU_PARTES }
after time 4 { tecla 8 0x01 0.2 }
after time 52 { set g [open menu.vram w]; fconfigure $g -translation binary; puts -nonewline $g [debug read_block VRAM 0 0x4000]; close $g }
after time 53 { tecla 0 0x02 0.2 }
after time 57 { tecla 0 0x02 0.2 }
after time 70 { log "fin spr=[peek 0x4583]"; set g [open full.vram w]; fconfigure $g -translation binary; puts -nonewline $g [debug read_block VRAM 0 0x4000]; close $g }
after time 71 exit
