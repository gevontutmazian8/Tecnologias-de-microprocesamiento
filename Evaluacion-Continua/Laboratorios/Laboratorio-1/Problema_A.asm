; ----------------------------
; ATmega328P Assembly para proyecto de Punzonadora con cinta transportadora
; ----------------------------

.include "m328Pdef.inc"     
.equ F_CPU = 16000000       

; Estados
.equ ESPERA       = 0
.equ ALIMENTACION = 1
.equ POSICIONADO  = 2
.equ PUNZONADO    = 3
.equ DESCARGA     = 4
.equ FIN          = 5

; Pines definidos (usando los puertos del ATmega328P)
; Digitales 6,9,10,11 = pines del puerto D
; Analógicos A0-A5 = pines del puerto C
; Botones en D2, D7

; Motores
.equ CINTA_IN1 = 6   ; PD6
.equ CINTA_IN2 = 9   ; PB1 
.equ PUNZON_IN1 = 10 ; PB2
.equ PUNZON_IN2 = 11 ; PB3

; LEDs (A0-A5 → PC0 – PC5)
.equ LED_LIGERA   = PC0
.equ LED_MEDIA    = PC1
.equ LED_PESADA   = PC2
.equ LED_ESPERA   = PC3
.equ LED_FUNCIONANDO = PC4
.equ LED_FIN      = PC5

; Botones
.equ BTN_INICIO = PD2 ; D2
.equ BTN_CARGA  = PD7 ; D7

; Variables en SRAM
.def estado        = r16     ; registro temporal para el estao
.def tipoCarga_reg = r17
.def tmp_lo        = r18     ; uso temporal (lower byte)
.def tmp_hi        = r19     ; uso temporal (higher byte)

; Inicio (reset / setup)
.cseg
.org 0x0000
    rjmp main         ; al arrancar salta al main

; ----------------------------
; Rutina main / setup de puertos
; ----------------------------
main:

    ; --- motores como salida ---
    ; CINTA_IN1 → PD6 → DDRD6
    sbi DDRD, CINTA_IN1

    ; CINTA_IN2 → pin 9 → PB1 → DDRB1
    sbi DDRB, 1      ; CINTA_IN2 es PB1

    ; PUNZON_IN1 → pin 10 → PB2
    sbi DDRB, 2

    ; PUNZON_IN2 → pin 11 → PB3
    sbi DDRB, 3

    ; --- LEDs como salida ---
    ; LEDs están en PC0..PC5
    ldi r30, (1<<PC0)|(1<<PC1)|(1<<PC2)|(1<<PC3)|(1<<PC4)|(1<<PC5)
    out DDRC, r30
