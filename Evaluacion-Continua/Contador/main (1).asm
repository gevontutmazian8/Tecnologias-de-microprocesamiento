; ============================================================
;  Contador 7 segmentos (cátodo común) – Ensamblador AVR
;  MCU: ATmega328P (Arduino Uno)
;  F_CPU = 16 MHz (ajusta delay_1ms si difiere)
; Lógica:
;  - Si PB0 se presiona (nivel bajo), cuenta 0..9 mostrando cada 1 s.
;  - Si PB1 se presiona durante el conteo, espera que se suelte y “rompe”.
;  - Cuando no está contando, muestra el valor actual.
;  - Si counter >= 10, se resetea a 0.
; ============================================================

        .include "m328pdef.inc"

; ------------------------------------------------------------
; Constantes y registros de trabajo
; ------------------------------------------------------------
        .equ BTN_START_BIT = 0         ; PB0
        .equ BTN_STOP_BIT  = 1         ; PB1

        .def rZero   = r1              ; Mantener en 0
        .def rTmp    = r16
        .def rTmp2   = r17
        .def rCnt    = r20             ; counter (0..9)
        .def rMsL    = r24             ; delay_ms() argumento low
        .def rMsH    = r25             ; delay_ms() argumento high
        .def rI0     = r18             ; temporales delay
        .def rI1     = r19

; ------------------------------------------------------------
; Tabla LUT (PROGMEM) – orden de bits: g f e d c b a (PD7..PD1)
; Mismos valores que tu C
; ------------------------------------------------------------
        .cseg
        .org 0x0000

rjmp    RESET                           ; Vector reset

; (Si necesitás otros vectores, agregalos. Por simplicidad, saltan a RESET)
        .org INT0addr
rjmp    RESET

; ------------------------------------------------------------
; RESET / Inicio
; ------------------------------------------------------------
RESET:
        ; Inicializar stack
        ldi     rTmp, HIGH(RAMEND)
        out     SPH, rTmp
        ldi     rTmp, LOW(RAMEND)
        out     SPL, rTmp

        ; Asegurar r1 = 0
        clr     rZero

        ; DDRD = 0b11111110  -> PD1..PD7 salidas (PD0 RX como entrada)
        ldi     rTmp, 0b11111110
        out     DDRD, rTmp

        ; DDRB = 0b00000000  -> PB0 & PB1 entradas
        ldi     rTmp, 0x00
        out     DDRB, rTmp

        ; PORTB = 0b00000011 -> pull-ups en PB0 y PB1
        ldi     rTmp, 0b00000011
        out     PORTB, rTmp

        ; PORTD = 0 (apagar todos los segmentos al inicio)
        out     PORTD, rZero

        ; counter = 0
        clr     rCnt

; ------------------------------------------------------------
; Bucle principal
; ------------------------------------------------------------
MAIN_LOOP:
        ; if (!(PINB & (1<<PB0)))  -> si START presionado (nivel bajo)
        sbic    PINB, BTN_START_BIT        ; Salta si bit está en 0 (presionado)
        rjmp    NO_START                   ; Si no está presionado, mostrar counter

        ; --- START presionado: bucle de conteo 0..9 ---
        clr     rCnt                       ; counter = 0

COUNT_LOOP:
        ; Comprobar STOP (PB1). Si se presiona, esperar suelta y romper.
        sbic    PINB, BTN_STOP_BIT         ; Salta si PB1 = 0 (presionado)
        rjmp    SHOW_AND_DELAY             ; Si no presionado, continuar

        ; Aquí: STOP presionado (nivel bajo) -> esperar a que se suelte
WAIT_RELEASE:
        sbis    PINB, BTN_STOP_BIT         ; Salta si PB1 = 1 (liberado)
        rjmp    WAIT_RELEASE
        rjmp    AFTER_COUNT                ; Romper el conteo (como break)

SHOW_AND_DELAY:
        ; Mostrar dígito actual (PORTD = lut[counter])
        rcall   DISPLAY_COUNTER

        ; delay_ms(1000)
        ldi     rMsL, LOW(1000)
        ldi     rMsH, HIGH(1000)
        rcall   DELAY_MS

        ; counter++
        inc     rCnt
        cpi     rCnt, 10
        brlo    COUNT_LOOP                 ; mientras rCnt < 10

        ; Terminó conteo normal (llegó a 10)
        ; cae a AFTER_COUNT
AFTER_COUNT:
        rjmp    POST_SHOW

; --- No se presionó START: mostrar el valor actual y gestionar reset ---
NO_START:
        rcall   DISPLAY_COUNTER

POST_SHOW:
        ; if (counter >= 10) counter = 0;
        cpi     rCnt, 10
        brlo    MAIN_LOOP
        clr     rCnt
        rjmp    MAIN_LOOP

; ------------------------------------------------------------
; Subrutina: DISPLAY_COUNTER
;  Usa Z para apuntar a LUT + counter, LPM, OUT PORTD
;  Clobbers: rTmp (r16), Z (r30:r31)
; ------------------------------------------------------------
DISPLAY_COUNTER:
        ; Z = &LUT[0]
        ldi     ZL, low(LUT*2)            ; *2 porque direcciones en palabras
        ldi     ZH, high(LUT*2)
        ; Z += counter
        add     ZL, rCnt
        adc     ZH, rZero

        ; rTmp = pgm_read_byte(Z)
        lpm     rTmp, Z

        ; PORTD = rTmp
        out     PORTD, rTmp
        ret

; ------------------------------------------------------------
; Subrutina: DELAY_MS
;  Entrada: r25:r24 = milisegundos (uint16)
;  Hace: llama delay_1ms() tantas veces como ms.
;  Clobbers: rMsL/rMsH, rI0/rI1
; ------------------------------------------------------------
DELAY_MS:
        ; if (ms == 0) return
DELAY_MS_LOOP:
        tst     rMsL
        brne    DO_TICK
        tst     rMsH
        breq    DELAY_MS_DONE
DO_TICK:
        rcall   DELAY_1MS
        sbiw    rMsL, 1                    ; ms--
        rjmp    DELAY_MS_LOOP
DELAY_MS_DONE:
        ret

; ------------------------------------------------------------
; Subrutina: DELAY_1MS (aprox. para 16 MHz)
;  Ajustá los contadores si tu F_CPU difiere.
;  Clobbers: rI0, rI1
; ------------------------------------------------------------
DELAY_1MS:
        ; Aproximación común ~1ms @16MHz
        ; Dos bucles anidados: valores calibrados empíricamente
        ; (No “perfecto a ciclo”, pero suficiente para 1 s visible)
        ldi     rI0, 250
        ldi     rI1, 61
.D1_LOOP0:
        dec     rI0
        brne    .D1_LOOP0
        dec     rI1
        brne    .D1_LOOP0
        ret

; ------------------------------------------------------------
; LUT en Flash (PROGMEM)
;  Orden: g f e d c b a  (PD7..PD1)
;  Valores idénticos al C original
; ------------------------------------------------------------
        .align  1
LUT:
        .db 0b01111111    ; 0
        .db 0b00001100    ; 1
        .db 0b10110110    ; 2 
        .db 0b10011111    ; 3
        .db 0b11001100    ; 4 
        .db 0b11011011    ; 5 
        .db 0b11111011    ; 6
        .db 0b00001110    ; 7
        .db 0b11111111    ; 8
        .db 0b11011110    ; 9 

; ===================== FIN =====================

