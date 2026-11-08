# Freddy Hardest Enhanced: documentación técnica

**Español** · [English](../en/DOCUMENTATION.md) · [日本語](../ja/DOCUMENTATION.md)

## 1. El juego original

*Freddy Hardest* (Dinamic, 1987) llegó a MSX en una cinta de dos caras: la parte 1 (la superficie de la luna, con scroll) y la parte 2 (la base, por salas y con ascensores). Cada cara carga una imagen casi completa de los 64 KB de RAM. Es una conversión directa del Spectrum:

* El juego dibuja en un **búfer de 1 bit con el formato de pantalla del Spectrum** (4000h-57FFh, con el marcador en 5000h-57FFh y los atributos desde 5800h).
* En cada imagen, una rutina convierte el búfer a SCREEN 2 y lo copia entero a la VRAM, y los atributos pasan a la tabla de colores con una tabla de 128 colores (2778h en la parte 1, 28B6h en la parte 2).
* Los efectos de sonido de la parte 1 se hacían con el clic del teclado y bucles de espera.

El trabajo parte de un desensamblado propio de las dos caras de la edición española, que se vuelve a ensamblar idéntico. Este repositorio no lo incluye: `tools/extrae_originales.py` saca de las cintas del usuario la imagen de memoria de cada parte, y la compilación parchea esas imágenes.

## 2. El cartucho

MegaROM ASCII16 de 256 KB. Para que openMSX y BlueMSX la reconozcan solos, la ROM hace más escrituras al registro de banco de 4000h-7FFFh del ASCII16 que a los de otros mappers.

| Banco | Contenido |
|---|---|
| 0 | Arranque (`arranque.asm`): pantalla de carga, presentación, menú de partes; y el copiador (`copiador.asm`, que corre en 2600h) |
| 1-4 | Imagen de la RAM de la parte 1, ya parcheada |
| 5-8 | Imagen de la RAM de la parte 2, ya parcheada |
| 9-11 | Sprites de Freddy y de los enemigos, registros del marcador en color (banco 10) |
| 12 | Estado de la memoria al acabar la presentación (`intro_estado.bin`), para entrar directamente en el menú de la parte 1 |
| 13 | Módulo de los créditos finales |

El copiador elige una parte y copia sus cuatro bancos a las páginas 3, 2, 1 y 0 de la RAM cambiando los slots por el puerto A8h, como hacía el cargador de la cinta. Después salta al juego con la página 0 en RAM. Por eso hace falta un MSX1 con 64 KB.

## 3. Volcado por celdas sucias (`optim.asm`)

Es la mejora principal de velocidad. Unos ganchos en todas las rutinas que escriben en el búfer (figuras, terreno, scroll, puntos, borrados) marcan las celdas de 8×8 que tocan en `SUCIO` (16 filas × 32 bytes; bit 0 = esta imagen, bit 1 = la anterior). El volcado solo manda las celdas marcadas en esta imagen o en la anterior (la anterior es lo que se borró al restaurar el fondo).

* Si la imagen no viene del bucle de juego (presentación, menús, final), se vuelca entera.
* Si alguna rutina escribe la VRAM directamente, `MARCA_TODO` fuerza dos volcados enteros.
* Los colores se comparan con una sombra y solo se mandan los que cambian.
* Restaurar el fondo en la parte 1 copia solo las celdas sucias, en vez de 4 KB.
* Ningún acceso a la VRAM se hace a menos de 29 ciclos del anterior: el TMS9918 los perdería durante la imagen. `openmsx/vigila_vram.tcl` lo comprueba.

Se comprobó comparando la VRAM con el búfer completo en miles de imágenes de partidas automáticas: 0 diferencias.

**Limitador**: el bit 7 del registro de estado del VDP (aviso de cuadro) se sondea en el volcado y en puntos seguros (`SONDEO_S`). La ROM rápida limita a 11 imágenes por segundo en la parte 1 y a 15 en la parte 2. Los 50/60 Hz se leen de 002Bh.

## 4. Sprites (`spr_a.asm`)

* **Freddy**: el cuerpo sigue en el búfer, con la tinta azul 5 fija en la zona de juego (desde los pies de Freddy hacia arriba). La cabeza y el pelo rubio van en dos sprites por figura, sacados de `graficos/freddy_cabeza_1a1.png` (parte 1) y `graficos/freddy_b_cabeza_1a1.png` (parte 2), con el pelo retocado a mano.
* **Enemigos**: enteros en sprites de un color, convertidos desde los gráficos del juego. La conversión se guarda en las cachés `*_cache.json`, que se rehacen al compilar (unos 40 s la primera vez).
* **Cuando hay más de cuatro sprites en una línea**: si el VDP avisa de un quinto sprite (`QUINTO`), la tabla se gira de enemigo en enemigo en cada cuadro, para que ninguno se quede oculto muchos cuadros seguidos.
* **Tabla de atributos (SAT) diferida**: la SAT de una imagen se escribe al empezar el primer cuadro del VDP después de volcar sus celdas (`SAT_DIFIERE`, `LIM_SAT`, `SAT_QUIERE`). Si se escribe antes, o a mitad del barrido, se ven piezas de dos imágenes.
* **Patrones con doble búfer**: cada imagen escribe los patrones en la mitad de la tabla (3800h o 3C00h) que no se está usando.
* **Cara del marcador**: el pelo y el blanco de los ojos van en los huecos 0-6 de la SAT, y solo se reescriben cuando cambian (`SS_MARC`).

## 5. Marcador en color

`PINTA_MARCADOR` repinta el marcador desde unos registros del banco 10 (dirección, número de bytes, bytes). Los registros salen de `graficos/marcador_nestor.png`: patrón y color en la caja de la cara, y solo el color en lo demás, así que los números y la munición siguen siendo los del juego. Se repinta cuando el juego toca el marcador (`MARC_SUCIO`).

* La barra de disparos de la parte 2 el juego la pinta directamente en la VRAM, sin tocar los atributos. `G_BARRA` (E456h) guarda también el color en el atributo, y al final de `PINTA_MARCADOR` las celdas por encima del nivel (E47Eh) vuelven a negro.
* Al empezar la partida, el juego vuelca el marcador original (unos 45 ms). `G_INTRO` apaga la pantalla mientras tanto, y se enciende cuando ya está en color.

## 6. Cambios de sala (parte 2)

Todos los cambios de sala acaban en `ENTRA_SALA` (CCF8h): los de los lados y los del ascensor hacia arriba (DA49h) y hacia abajo (DA58h).

* `G_SALA`, en esa rutina, olvida las figuras apuntadas de la sala vieja y deja un aviso (`SALA_NUEVA`).
* `G_LIMPIA`, en `VOL_TODAS`, ve el aviso en el primer volcado después del cambio y vacía la tabla de sprites justo antes de mandar la primera fila. Solo se queda la cara del marcador.
* La tabla nueva se escribe al acabar el volcado. Así los sprites viejos se ven con la sala vieja y desaparecen cuando empieza a pintarse la nueva.

## 7. Otras mejoras

* **Sonido** (parte 1): los efectos del clic pasan al canal A del PSG. Un pulso de N ciclos es un periodo de tono de N/32, repartido en cuadros de 20 ms. El juego ya no se para mientras suenan.
* **Teclado**: en cada cuadro se guardan las pulsaciones nuevas hasta la siguiente lectura del juego. En una prueba con 30 toques de 40 ms, el original veía 9 y ahora se ven los 30.
* **Disparo** (parte 1): el primer tramo del disparo empezaba 32 px por delante de Freddy y dejaba un hueco. Además, el cálculo de la altura daba la vuelta con Freddy en lo alto (6494h), y el disparo atravesaba al volador. Los dos fallos están arreglados (`G_TIRO_Y`).
* **Letras rotas** del final de la parte 1: era un fallo del original, que con altura 0 y una Y múltiplo de 8 daba 256 vueltas (`G_TAM`).
* **Final de la parte 1**: «TO BE CONTINUED» 32 píxeles más arriba (la rutina de letras solo pinta bien en filas enteras) y la clave en el monitor del marcador (`monitor_clave()` en `build_rom.py`).
* **Créditos** (`creditos.asm`): el reparto que Dinamic dejó desactivado sale al acabar la parte 2, con la música de la presentación de la parte 1. No usa las máscaras de R3/R4: escribe las tres franjas y alterna cuatro tablas de nombres con R2.
* **Estrellas** (parte 1, `estrellas.asm`): dibujadas por araubi, fijas y en gris, en celdas que Freddy no pisa (`celdas_pisadas.json`).
* **Arranque** (`arranque.asm`): la presentación se salta con una tecla (`G_ESPERA`) y el menú de partes no usa la BIOS.

## 8. Historia

| Versión | Cambios |
|---|---|
| 29-31 oct | ROM con las dos partes, volcado por celdas sucias, PSG, teclado, créditos ocultos, 50/60 Hz |
| 4-6 nov | Freddy y enemigos en sprites, tinta 5, marcador en color con la cara en sprites fijos |
| 7 nov (v1-v12) | Parte 2 con sprites, limitador por imágenes por segundo, disparo al volador, SAT diferida |
| v13-v18 | Mechones del pelo, ideas de Néstor Sancho, letras del final, estrellas de araubi, arranque nuevo |
| v19-v21 | Créditos sin cuelgue, sin sprites y sin máscaras de R3/R4 (fallaban en FPGA) |
| v22 | Clave en el monitor, TO BE CONTINUED, marcador sin colores originales al empezar |
| v23-v26 | Limpieza de sprites en los cambios de sala y barra de disparos |
| **v1.0** | = v26, la ROM rápida |

## 9. Pruebas

* openMSX 19 con C-BIOS MSX1 y Sony HB-20P. Los scripts de `openmsx/` arrancan la parte 2 (`parte2.tcl`) y miden los cambios de sala (`prueba_salas.tcl`), la barra de disparos (`prueba_barra.tcl`) y los accesos a la VRAM (`vigila_vram.tcl`).
* El mapper se ha comprobado con las reglas de openMSX y BlueMSX.
* Un grupo de probadores jugó las versiones candidatas. Sus avisos dieron la v20-v26.
