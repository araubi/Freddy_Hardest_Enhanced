# Lessons from Freddy Hardest Enhanced

[Español](../es/LECCIONES.md) · **English** · [日本語](../ja/LESSONS.md)

What was learned turning into a cartridge an MSX1 game converted from the Spectrum. Useful for similar games.

## Speed

1. **Dirty cells, with hooks in EVERY routine that writes.** The update sends the cells marked in this frame or the previous one. If a frame does not come from the hooked game loop (intro, menus), it is sent whole. If someone writes VRAM directly, two full updates are forced. Marking must be cheap (line spans, whole rows at once) or it eats the gain.
2. **Measure before deciding.** Time each frame with a breakpoint on a single end-of-update label, and sample the PC during the slow frames. That is how the stutters were found: sound effects with busy-wait loops (the explosion stopped the game for 107 ms).
3. **From keyboard click to PSG.** A pulse of N cycles is a tone period of N/32. Spread it over 20 ms frames, with the tone that sounds most in each one. The tick comes from polling bit 7 of the VDP status, with no interrupts. Silence the PSG during pause.
4. **Limiter** with that same polling. In a game whose frame time varies a lot, limiting frames per second gives a steadier pace than counting VDP frames.

## VDP (TMS9918)

5. **Nothing closer than 29 cycles** between two VRAM accesses during the active display. openMSX does not warn by default: use `too_fast_vram_access` and `vigila_vram.tcl` before releasing.
6. **Do not use the R3/R4 mask trick in SCREEN 2** (a single band of patterns and colours for the whole screen). Some FPGA VDPs and emulators ignore the masks: write all three bands.
7. **Turn the screen off during a long update** that would show half-done (R#1 = A0h), and turn it on when it is right.
8. The game's letter routines may only draw correctly on whole 8-pixel rows: move texts in multiples of 8.

## Sprites added to a game that had none

9. **Write the attribute table after sending the cells of the same frame, at the start of a VDP frame**, with the frame flag just read. Written earlier or mid-scan, the hair runs ahead of the body and pieces of two frames show up.
10. **More than four sprites on a line**: rotate the table figure by figure, not sprite by sprite, so no figure stays hidden for many frames in a row.
11. **Clean-up from screen to screen.** In a room-based game, remove the game sprites in the **common room-entry routine**, not at each place that changes room: find every jump to it (sides, lifts or stairs, teleports). The moment is **when the screen starts to change**: the room routine leaves a flag and forgets the noted figures, and the update, on seeing the flag, empties the table just before sending the first row. Removed earlier, the old room is left without sprites while the new one is built. Removed later, they show on top of the new room.
12. When emptying the table, also reset the counters of whatever refills it. Otherwise the fifth-sprite rotation writes the old sprites back.
13. Other clean-up moments: game end, GAME OVER, ending texts, credits and menus.

## Colour repaints

14. If you repaint the scoreboard with your own colours, any indicator the game draws **straight into VRAM** without touching its attributes (here the shot bar) is lost on repaint. Store its state in the attribute as well, or repaint it from the game's variable.

## Cartridge

15. **A 64 KB image per part**: bank 0 holds the menu, and each part goes in four banks with its RAM image. A copier in a free area of page 0 copies pages 3, 2, 1 and 0, switching slots through A8h.
16. To use routines from the other part (the part 1 music in the part 2 credits), swap page 0 for a copy and put it back afterwards.
17. Modules that live in RAM during the ending can be overwritten by the game: reload them from ROM before using them.

## Reverse engineering and testing

18. **Take the graphics from the assembled image**, not from RAM during play: the intro lived in the screen buffer area and a piece of the logo was missing.
19. openMSX `.omr` recordings help reproduce testers' reports. A savestate at the moment of the bug is worth more than the whole recording.
20. Check the ROM comes out byte-identical with both assemblers (pasmo and sjasmplus). In sjasmplus, pasmo's `REPT … ENDM` does not work.
21. **Publish without the originals**: the repository holds only your own work, and a tool takes the rest from the user's copy, checking MD5 and SHA-1. A build from scratch must give the same ROM as the published one.
