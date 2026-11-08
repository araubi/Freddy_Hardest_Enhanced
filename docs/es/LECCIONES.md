# Lecciones de Freddy Hardest Enhanced

**Español** · [English](../en/LESSONS.md) · [日本語](../ja/LESSONS.md)

Lo aprendido al pasar a cartucho un juego de MSX1 convertido del Spectrum. Sirve para otros juegos parecidos.

## Velocidad

1. **Celdas sucias, con ganchos en TODAS las rutinas que escriben.** El volcado manda las celdas marcadas en esta imagen o en la anterior. Si una imagen no viene del bucle de juego enganchado (presentación, menús), se vuelca entera. Si alguien escribe la VRAM directamente, se fuerzan dos volcados enteros. El marcado tiene que ser barato (tramos de línea, filas enteras de una vez) o se come lo ganado.
2. **Medir antes de decidir.** Se mide la duración de cada imagen con un punto de parada en una sola etiqueta de fin de volcado, y en las imágenes lentas se muestrea el PC. Así salieron los tirones: efectos de sonido con bucles de espera (la explosión paraba el juego 107 ms).
3. **Del clic del teclado al PSG.** Un pulso de N ciclos es un periodo de tono de N/32. Se reparte en cuadros de 20 ms, con el tono que más suena en cada uno. El tic sale del bit 7 del estado del VDP sondeado, sin interrupciones. Hay que callar el PSG en la pausa.
4. **Limitador** con ese mismo sondeo. En un juego que va a trompicones, limitar por imágenes por segundo da un ritmo más regular que contar cuadros.

## VDP (TMS9918)

5. **Nada a menos de 29 ciclos** entre dos accesos a la VRAM durante la imagen. openMSX no lo avisa por defecto: usar `too_fast_vram_access` y `vigila_vram.tcl` antes de entregar.
6. **No usar el truco de las máscaras de R3/R4 en SCREEN 2** (una sola franja de patrones y colores para toda la pantalla). Algunos VDP de FPGA y emuladores las ignoran: escribir las tres franjas.
7. **Pantalla apagada durante un volcado largo** que se vería a medias (R#1 = A0h), y encenderla cuando ya esté bien.
8. Las rutinas de letras del juego pueden pintar bien solo en filas enteras de 8: mover textos en múltiplos de 8.

## Sprites añadidos a un juego que no los tenía

9. **La tabla de atributos se escribe después de volcar las celdas de la misma imagen y al empezar un cuadro**, con el aviso de cuadro recién leído. Si se escribe antes o a mitad de barrido, el pelo va por delante del cuerpo y se ven piezas de dos imágenes.
10. **Más de cuatro sprites por línea**: girar la tabla de figura en figura, no de sprite en sprite, para que ninguna figura se quede oculta muchos cuadros seguidos.
11. **Limpieza de pantalla a pantalla.** En un juego de salas, quitar los sprites de la partida en la **rutina común de entrada a sala**, no en cada sitio desde el que se cambia de sala: buscar todos los saltos a ella (lados, ascensores o escaleras, teletransportes). El momento es **cuando empieza a cambiar la pantalla**: la rutina de sala deja un aviso y olvida las figuras apuntadas, y el volcado, al ver el aviso, vacía la tabla justo antes de mandar la primera fila. Si se quitan antes, la sala vieja se queda sin sprites mientras se construye la nueva. Si se quitan después, se ven encima de la nueva.
12. Al vaciar la tabla hay que poner a cero también los contadores de lo que la repone. Si no, el giro por el quinto sprite vuelve a escribir los sprites viejos.
13. Otros momentos de limpieza: fin de partida, GAME OVER, textos del final, créditos y menús.

## Repintados en color

14. Si se repinta el marcador con colores propios, cualquier indicador que el juego pinte **directamente en la VRAM** sin tocar sus atributos (aquí la barra de disparos) se pierde al repintar. Hay que guardar también su estado en el atributo, o repintarlo según la variable del juego.

## Cartucho

15. **Imagen de 64 KB por parte**: el banco 0 lleva el menú, y cada parte va en cuatro bancos con su imagen de RAM. Un copiador en una zona libre de la página 0 copia las páginas 3, 2, 1 y 0 cambiando los slots por A8h.
16. Para usar rutinas de la otra parte (la música de la parte 1 en los créditos de la parte 2), cambiar la página 0 por una copia y dejarla como estaba al acabar.
17. Los módulos que viven en RAM durante el final pueden quedar pisados por la partida: recargarlos de la ROM antes de usarlos.

## Ingeniería inversa y pruebas

18. **Sacar los gráficos de la imagen ensamblada**, no de la RAM en plena partida: la presentación vivía en la zona del búfer de pantalla y faltaba una pieza del logo.
19. Las grabaciones `.omr` de openMSX sirven para reproducir avisos de los probadores. Una instantánea en el momento del fallo vale más que la grabación entera.
20. Comprobar que la ROM sale idéntica byte a byte con los dos ensambladores (pasmo y sjasmplus). En sjasmplus, `REPT … ENDM` de pasmo no vale.
21. **Publicar sin los originales**: el repositorio solo lleva lo propio, y una herramienta saca de la copia del usuario lo demás, comprobando MD5 y SHA-1. La compilación desde cero tiene que dar la misma ROM que la publicada.
