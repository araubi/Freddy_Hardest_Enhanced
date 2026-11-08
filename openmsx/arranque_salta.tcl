set throttle off
proc tecla {fila bit t} { keymatrixdown $fila $bit; after time $t "keymatrixup $fila $bit" }
proc log {m} { set f [open s6.txt a]; puts $f "[format %.2f [machine_info time]] $m"; close $f }
debug set_bp 0x5938 {} { log A_PARTES }
debug set_bp 0x40C9 {} { log MENU_PARTES }
debug set_bp 0x2609 {} { log "COPIA entrada=[format %04X [peek16 0x2604]] banco=[peek 0x2603] parche=[peek 0x26F8] lim=[format %02X [peek 0x2606]]" }
debug set_bp 0xEFD2 {} { log EFD2 }
after time 4 { tecla 8 0x01 0.2 }
after time 6 { log espacio; tecla 8 0x01 0.3 }
after time [expr 6+3] { log uno; tecla 0 0x02 0.2 }
after time [expr 6+7] { log uno_juego; tecla 0 0x02 0.2 }
after time [expr 6+15] { log "fin PC=[format %04X [reg PC]] spr=[peek 0x4583] vidas=[peek 0xD974]"; set g [open s6.vram w]; fconfigure $g -translation binary; puts -nonewline $g [debug read_block VRAM 0 0x4000]; close $g }
after time [expr 6+16] exit
