set throttle off
proc tecla {fila bit t} { keymatrixdown $fila $bit; after time $t "keymatrixup $fila $bit" }
set ::f [open gap.txt w]
debug set_bp 0x5972 {} { puts $::f "[machine_info time] [format %04X [peek16 [expr [reg SP]+0]]]" }
after time 4 { tecla 8 0x01 0.2 }
after time 50 { close $::f; exit }
