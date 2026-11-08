# Freddy Hardest Enhanced: technical documentation

[Español](../es/DOCUMENTACION.md) · **English** · [日本語](../ja/DOCUMENTATION.md)

## 1. The original game

*Freddy Hardest* (Dinamic, 1987) came out on MSX on a two-sided tape: part 1 (the moon surface, with scrolling) and part 2 (the base, with rooms and lifts). Each side loads an almost complete image of the 64 KB of RAM. It is a direct conversion from the Spectrum:

* The game draws into a **1-bit buffer in Spectrum screen format** (4000h-57FFh, with the scoreboard at 5000h-57FFh and the attributes from 5800h).
* Every frame, a routine converts the buffer to SCREEN 2 and copies all of it to VRAM. The attributes go to the colour table through a 128-colour table (2778h in part 1, 28B6h in part 2).
* The part 1 sound effects were made with the keyboard click and busy-wait loops.

The work starts from our own disassembly of both sides of the Spanish release, which reassembles identically. This repository does not include it: `tools/extrae_originales.py` takes the memory image of each part from the user's tapes, and the build patches those images.

## 2. The cartridge

256 KB ASCII16 MegaROM. So that openMSX and BlueMSX recognise it on their own, the ROM writes more to the ASCII16 bank register for 4000h-7FFFh than to those of other mappers.

| Bank | Contents |
|---|---|
| 0 | Start-up (`arranque.asm`): loading screen, intro, parts menu; and the copier (`copiador.asm`, which runs at 2600h) |
| 1-4 | RAM image of part 1, already patched |
| 5-8 | RAM image of part 2, already patched |
| 9-11 | Freddy and enemy sprites, coloured scoreboard records (bank 10) |
| 12 | Memory state at the end of the intro (`intro_estado.bin`), to go straight into the part 1 menu |
| 13 | End credits module |

The copier picks a part and copies its four banks to RAM pages 3, 2, 1 and 0, switching slots through port A8h, as the tape loader did. Then it jumps to the game with page 0 in RAM. This is why an MSX1 with 64 KB is needed.

## 3. Dirty-cell screen update (`optim.asm`)

This is the main speed improvement. Hooks in every routine that writes into the buffer (figures, terrain, scrolling, points, erasing) mark the 8×8 cells they touch in `SUCIO` (16 rows × 32 bytes; bit 0 = this frame, bit 1 = the previous one). The update only sends the cells marked in this frame or the previous one (the previous one is what was erased when restoring the background).

* If the frame does not come from the game loop (intro, menus, ending), it is sent whole.
* If some routine writes VRAM directly, `MARCA_TODO` forces two full updates.
* Colours are compared with a shadow copy and only the changed ones are sent.
* Restoring the background in part 1 copies only the dirty cells instead of 4 KB.
* No VRAM access happens less than 29 cycles after the previous one: the TMS9918 would lose it during the active display. `openmsx/vigila_vram.tcl` checks this.

It was checked by comparing VRAM with the full buffer over thousands of frames of automated play: 0 differences.

**Limiter**: bit 7 of the VDP status register (frame flag) is polled during the update and at safe points (`SONDEO_S`). The fast ROM limits part 1 to 11 frames per second and part 2 to 15. 50/60 Hz is read from 002Bh.

## 4. Sprites (`spr_a.asm`)

* **Freddy**: the body stays in the buffer, with a fixed blue ink 5 in the play area (from Freddy's feet upwards). The head and the blond hair are two sprites per figure, taken from `graficos/freddy_cabeza_1a1.png` (part 1) and `graficos/freddy_b_cabeza_1a1.png` (part 2), with hand-retouched hair.
* **Enemies**: whole single-colour sprites, converted from the game graphics. The conversion is stored in the `*_cache.json` caches, rebuilt at build time (about 40 s the first time).
* **More than four sprites on a line**: if the VDP reports a fifth sprite (`QUINTO`), the table rotates enemy by enemy every frame, so no enemy stays hidden for many frames in a row.
* **Deferred sprite attribute table (SAT)**: the SAT of a frame is written at the start of the first VDP frame after its cells have been sent (`SAT_DIFIERE`, `LIM_SAT`, `SAT_QUIERE`). Written earlier, or mid-scan, pieces of two frames show up.
* **Double-buffered patterns**: each frame writes the patterns into the half of the table (3800h or 3C00h) not in use.
* **Scoreboard face**: the hair and eye whites use SAT slots 0-6, and are only rewritten when they change (`SS_MARC`).

## 5. Coloured scoreboard

`PINTA_MARCADOR` repaints the scoreboard from records in bank 10 (address, byte count, bytes). The records come from `graficos/marcador_nestor.png`: pattern and colour in the face box, and only the colour elsewhere, so the numbers and the ammunition are still the game's own. It is repainted when the game touches the scoreboard (`MARC_SUCIO`).

* The game draws the part 2 shot bar straight into VRAM without touching the attributes. `G_BARRA` (E456h) also stores the colour in the attribute, and at the end of `PINTA_MARCADOR` the cells above the level (E47Eh) go back to black.
* When a game starts, the game sends the original scoreboard (about 45 ms). `G_INTRO` turns the screen off meanwhile, and it comes back on once the scoreboard is in colour.

## 6. Room changes (part 2)

Every room change ends in `ENTRA_SALA` (CCF8h): sideways, and by lift upwards (DA49h) and downwards (DA58h).

* `G_SALA`, in that routine, forgets the figures noted for the old room and leaves a flag (`SALA_NUEVA`).
* `G_LIMPIA`, in `VOL_TODAS`, sees the flag on the first update after the change and empties the sprite table just before sending the first row. Only the scoreboard face stays.
* The new table is written when the update ends. This way the old sprites are seen with the old room and disappear as soon as the new one starts to be drawn.

## 7. Other improvements

* **Sound** (part 1): the click effects move to PSG channel A. A pulse of N cycles is a tone period of N/32, spread over 20 ms frames. The game no longer stops while they play.
* **Keyboard**: every frame, new key presses are kept until the game's next read. In a test with 30 taps of 40 ms, the original saw 9 and now all 30 are seen.
* **Shot** (part 1): the first stretch of the shot started 32 px in front of Freddy and left a gap. Also, the height calculation wrapped around with Freddy high up (6494h), and the shot went through the flying enemy. Both bugs are fixed (`G_TIRO_Y`).
* **Broken letters** at the end of part 1: a bug of the original, which looped 256 times with height 0 and a Y multiple of 8 (`G_TAM`).
* **End of part 1**: "TO BE CONTINUED" 32 pixels higher (the letter routine only draws correctly on whole rows) and the code on the scoreboard monitor (`monitor_clave()` in `build_rom.py`).
* **Credits** (`creditos.asm`): the cast list Dinamic left disabled plays at the end of part 2, with the music of the part 1 intro. It does not use the R3/R4 masks: it writes all three bands and alternates four name tables through R2.
* **Stars** (part 1, `estrellas.asm`): drawn by araubi, fixed and grey, in cells Freddy never steps on (`celdas_pisadas.json`).
* **Start-up** (`arranque.asm`): the intro can be skipped with a key (`G_ESPERA`) and the parts menu does not use the BIOS.

## 8. History

| Version | Changes |
|---|---|
| 29-31 Oct | ROM with both parts, dirty-cell update, PSG, keyboard, hidden credits, 50/60 Hz |
| 4-6 Nov | Freddy and enemies as sprites, ink 5, coloured scoreboard with the face as fixed sprites |
| 7 Nov (v1-v12) | Part 2 with sprites, frames-per-second limiter, shot at the flying enemy, deferred SAT |
| v13-v18 | Hair strands, ideas by Néstor Sancho, ending letters, araubi's stars, new start-up |
| v19-v21 | Credits without hang, without sprites and without R3/R4 masks (they failed on FPGA) |
| v22 | Code on the monitor, TO BE CONTINUED, no original colours on the scoreboard at the start |
| v23-v26 | Sprite clean-up on room changes, shot bar |
| **v1.0** | = v26, the fast ROM |

## 9. Testing

* openMSX 19 with C-BIOS MSX1 and Sony HB-20P. The scripts in `openmsx/` start part 2 (`parte2.tcl`) and measure room changes (`prueba_salas.tcl`), the shot bar (`prueba_barra.tcl`) and VRAM accesses (`vigila_vram.tcl`).
* The mapper was checked against the openMSX and BlueMSX rules.
* A group of testers played the release candidates. Their reports led to v20-v26.
