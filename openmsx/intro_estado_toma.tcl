set throttle off
proc tecla {fila bit t} { keymatrixdown $fila $bit; after time $t "keymatrixup $fila $bit" }
after time 3 { tecla 8 0x01 0.2 }
after time 6 { tecla 8 0x01 0.2 }
proc vuelca {n} { set f [open $n w]; fconfigure $f -translation binary; puts -nonewline $f [debug read_block "Main RAM" 0 0x10000]; close $f }
set ::b1 [debug set_bp 0x0094 {} { vuelca ram0094.bin; set s [open pila.txt a]; puts $s "0094 SP=[format %04X [reg SP]]"; close $s; debug remove_bp $::b1 }]
set ::b2 [debug set_bp 0xEFD2 {} { vuelca ramEFD2.bin; set s [open pila.txt a]; puts $s "EFD2 SP=[format %04X [reg SP]] [format %04X [peek16 [reg SP]]] [format %04X [peek16 [expr [reg SP]+2]]]"; close $s; debug remove_bp $::b2 }]
after time 70 exit
