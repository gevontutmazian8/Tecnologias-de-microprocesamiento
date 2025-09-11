
;============================================================
; Laboratorio: Control de matriz de LEDs con UART en ATmega328P
; Función: Muestra un mensaje desplazable o una figura (carita feliz) según entrada UART
;============================================================
; Cumple con:
; 1. Desplazamiento de mensaje "HELLO WORLD!" hacia la izquierda
; 2. UART muestra mensaje de bienvenida y menú
; 3. Usuario elige entre mensaje o figura
; 4. Velocidad ajustable
; 5. Código comentado para mantenimiento
;============================================================

.include "m328pdef.inc"

;------------------------
; Definiciones
;------------------------
.def temp     = r16
.def delay    = r17
.def index    = r18
.def col_cnt  = r19
.def uart_in  = r20
.def font_ptr = r21

.equ MSG_LEN = 12       ; Largo del mensaje

.org 0x00
rjmp RESET

;------------------------
; Datos: Mensaje y Fuente de caracteres
;------------------------
MSG: .db "HELLO WORLD!"

FONT:
; H
.db 0x7F, 0x08, 0x08, 0x08, 0x7F
; E
.db 0x7F, 0x49, 0x49, 0x49, 0x41
; L
.db 0x7F, 0x40, 0x40, 0x40, 0x40
; L
.db 0x7F, 0x40, 0x40, 0x40, 0x40
; O
.db 0x3E, 0x41, 0x41, 0x41, 0x3E
; espacio
.db 0x00, 0x00, 0x00, 0x00, 0x00
; W
.db 0x7F, 0x02, 0x04, 0x02, 0x7F
; O
.db 0x3E, 0x41, 0x41, 0x41, 0x3E
; R
.db 0x7F, 0x09, 0x19, 0x29, 0x46
; L
.db 0x7F, 0x40, 0x40, 0x40, 0x40
; D
.db 0x7F, 0x41, 0x41, 0x41, 0x3E
; !
.db 0x00, 0x00, 0x5F, 0x00, 0x00

;------------------------
; RESET
;------------------------
RESET:
    ; Inicializa stack
    ldi temp, LOW(RAMEND)
    out SPL, temp
    ldi temp, HIGH(RAMEND)
    out SPH, temp

    ; Inicializa puertos y UART
    rcall init_ports
    rcall uart_init

    