# parte2.tcl - arranca la ROM y entra en una partida de la parte 2 (sin clave): base de las pruebas.
# starts the ROM and enters a part 2 game (no code): base for the tests / ROM を起動してパート 2 を開始
# Uso / usage / 使い方: openmsx -machine C-BIOS_MSX1 -cart FreddyHardest_Enhanced.rom -script parte2.tcl
# Licencia / license / ライセンス: MIT
set save_settings_on_exit off
set throttle off
proc tecla {fila bit t} { after time $t "keymatrixdown $fila $bit"; after time [expr {$t+0.3}] "keymatrixup $fila $bit" }
tecla 8 1 9          ;# ESPACIO: salta la presentación / skips the intro
tecla 8 1 18
tecla 0 4 27         ;# 2: parte 2 en el menú de partes / part 2
after time 45 {poke 0xCB75 1}   ;# sin clave / skip the code
tecla 0 2 45         ;# 1: empezar / start
