; ===============================================================
; PROYECTO: Punzonadora con cinta transportadora
; Versión en ensamblador AVR para ATmega328P
; Micro: ATmega328P
; Reloj: 16 MHz
; FSM: ESPERA→ALIM→PAUSA→POSICIONADO→BAJA→MANTIENE→SUBE→DESCARGA→FIN
; Timer1 CTC: 1s/tick | Timer0: PWM cinta (OC0A/PD6) | Timer2: PWM punzón (OC2B/PD3 bajar, OC2A/PB3 subir)
; UART 9600-8N1: 'A' start, '1/2/3' tipo de carga. LEDs en PORTC.
; ===============================================================

.include "m328Pdef.inc"
 "m328Pdef.inc"

; -------- Definiciones --------
.equ F_CPU     = 16000000
.equ UBRR_VAL  = 103           ; 9600 @ 16 MHz

; Estados
.equ ESPERA            = 0
.equ CINTA_AVANCE      = 1
.equ CINTA_PAUSA       = 2
.equ POSICIONADO       = 3
.equ PUNZON_BAJANDO    = 4
.equ PUNZON_MANTENIENDO= 5
.equ PUNZON_SUBIENDO   = 6
.equ DESCARGA          = 7
.equ FIN               = 8

; Pines / LEDs
; Cinta
.equ CINTA_IN1_PD = 6          ; PD6 -> OC0A (PWM)
.equ CINTA_IN2_PB = 1          ; PB1 -> DIR/Freno
; Punzón (Timer2)
.equ PUNZON_IN1_PD = 3          ; PD3 -> OC2B (bajar)
.equ PUNZON_IN2_PB = 3          ; PB3 -> OC2A (subir)
; LEDs (PORTC)
.equ LED_LIGERA_PC      = 0
.equ LED_MEDIA_PC       = 1
.equ LED_PESADA_PC      = 2
.equ LED_ESPERA_PC      = 3
.equ LED_FUNCIONANDO_PC = 4
.equ LED_FIN_PC         = 5
; Botón
.equ BTN_INICIO_PD = 2         ; PD2 (INT0 pin físico D2). Usado como GPIO con pull-up.

; Constantes de rampas
.equ STEP_CINTA   = 10
.equ STEP_PUNZON  = 15
.equ DUTY_CINTA   = 200
.equ DUTY_PUNZON  = 220
.equ DUTY_MANTENER= 80

; -------- RAM --------
.dseg
.org 0x0100
estado:            .byte 1
contador_timer:    .byte 1
tipo_carga:        .byte 1

; -------- Vectores --------
.cseg
.org 0x0000  rjmp RESET
.org 0x0016  rjmp TIMER1_COMPA_ISR
.org 0x0024  rjmp USART_RX_ISR
; resto a default
.org 0x0002  rjmp DEFAULT_IRQ
.org 0x0004  rjmp DEFAULT_IRQ
.org 0x0006  rjmp DEFAULT_IRQ
.org 0x0008  rjmp DEFAULT_IRQ
.org 0x000A  rjmp DEFAULT_IRQ
.org 0x000C  rjmp DEFAULT_IRQ
.org 0x000E  rjmp DEFAULT_IRQ
.org 0x0010  rjmp DEFAULT_IRQ
.org 0x0012  rjmp DEFAULT_IRQ
.org 0x0014  rjmp DEFAULT_IRQ
.org 0x0018  rjmp DEFAULT_IRQ
.org 0x001A  rjmp DEFAULT_IRQ
.org 0x001C  rjmp DEFAULT_IRQ
.org 0x001E  rjmp DEFAULT_IRQ
.org 0x0020  rjmp DEFAULT_IRQ
.org 0x0022  rjmp DEFAULT_IRQ
.org 0x0026  rjmp DEFAULT_IRQ
.org 0x0028  rjmp DEFAULT_IRQ
.org 0x002A  rjmp DEFAULT_IRQ
.org 0x002C  rjmp DEFAULT_IRQ
.org 0x002E  rjmp DEFAULT_IRQ
.org 0x0030  rjmp DEFAULT_IRQ
.org 0x0032  rjmp DEFAULT_IRQ

DEFAULT_IRQ:
    reti

; -------- RESET --------
RESET:
    ; Stack Pointer
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16

    ; I/O init
    rcall IO_init

    ; PWM init
    rcall PWM_cinta_init
    rcall PWM_punzon_init

    ; UART init 9600-8N1
    rcall USART_init

    ; Timer1 1s ticks config (CTC presc 256, OCR1A=62500-1)
    rcall TIMER1_init

    ; estado = ESPERA; tipo_carga = 0; contador_timer=0
    ldi r16, ESPERA
    sts estado, r16
    clr r16
    sts tipo_carga, r16
    sts contador_timer, r16

    ; TX "ESPERA"
    ldi ZH, high(MSG_ESPERA<<1)
    ldi ZL, low(MSG_ESPERA<<1)
    rcall USART_send_P

    sei

; -------- MAIN (FSM) --------
MAIN:
    ; load estado into r18
    lds r18, estado
    cpi r18, ESPERA
    breq ST_ESPERA
    cpi r18, CINTA_AVANCE
    breq ST_CINTA_AVANCE
    cpi r18, CINTA_PAUSA
    breq ST_CINTA_PAUSA
    cpi r18, POSICIONADO
    breq ST_POSICIONADO
    cpi r18, PUNZON_BAJANDO
    breq ST_PUNZON_BAJANDO
    cpi r18, PUNZON_MANTENIENDO
    breq ST_PUNZON_MANTENIENDO
    cpi r18, PUNZON_SUBIENDO
    breq ST_PUNZON_SUBIENDO
    cpi r18, DESCARGA
    breq ST_DESCARGA
    cpi r18, FIN
    breq ST_FIN
    rjmp MAIN

; === ESPERA ===
ST_ESPERA:
    ; Si botón (PD2) está presionado (nivel 0), arranca
    in r16, PIND
    sbrc r16, BTN_INICIO_PD     ; si bit es 1 -> no presionado
    rjmp MAIN
    ; Apaga LED_FIN
    in r16, PORTC
    cbr r16, 1<<LED_FIN_PC
    out PORTC, r16
    ; Cambia a CINTA_AVANCE
    ldi r16, CINTA_AVANCE
    sts estado, r16
    ; UART "ALIM"
    ldi ZH, high(MSG_ALIM<<1)
    ldi ZL, low(MSG_ALIM<<1)
    rcall USART_send_P
    ; LED_FUNCIONANDO=1, LED_ESPERA=0
    in r16, PORTC
    sbr r16, 1<<LED_FUNCIONANDO_PC
    cbr r16, 1<<LED_ESPERA_PC
    out PORTC, r16
    rjmp MAIN

; === CINTA_AVANCE ===
ST_CINTA_AVANCE:
    ; DIR adelante (IN2=0)
    in r16, PORTB
    cbr r16, 1<<CINTA_IN2_PB
    out PORTB, r16
    ; Rampa OCR0A: 0->DUTY_CINTA paso STEP_CINTA
    rcall RAMP_CINTA_UP
    ; Programar segundos según tipo_carga: 3/4/5
    lds r16, tipo_carga
    cpi r16, 1
    breq CA_TL
    cpi r16, 2
    breq CA_TM
CA_TP:
    ldi r16, 5
    rjmp CA_SET
CA_TL:
    ldi r16, 3
    rjmp CA_SET
CA_TM:
    ldi r16, 4
CA_SET:
    sts contador_timer, r16
    ; enable OCIE1A
    in r17, TIMSK1
    sbr r17, 1<<OCIE1A
    out TIMSK1, r17

WAIT_CA:
    lds r18, estado
    cpi r18, CINTA_AVANCE
    breq WAIT_CA
    rjmp MAIN

; === CINTA_PAUSA ===
ST_CINTA_PAUSA:
    ; rampa down cinta
    rcall RAMP_CINTA_DOWN
    ; tiempos: 2/2/3
    lds r16, tipo_carga
    cpi r16, 3
    breq CP_PES
    ldi r16, 2
    rjmp CP_SET
CP_PES:
    ldi r16, 3
CP_SET:
    sts contador_timer, r16
    in r17, TIMSK1
    sbr r17, 1<<OCIE1A   ; habilita compare A
    out TIMSK1, r17
WAIT_CP:
    lds r18, estado
    cpi r18, CINTA_PAUSA
    breq WAIT_CP
    rjmp MAIN

; === POSICIONADO ===
ST_POSICIONADO:
    ; UART "POSICIONADO"
    ldi ZH, high(MSG_POS<<1)
    ldi ZL, low(MSG_POS<<1)
    rcall USART_send_P
    ; siguiente
    ldi r16, PUNZON_BAJANDO
    sts estado, r16
    rjmp MAIN

; === PUNZON_BAJANDO ===
ST_PUNZON_BAJANDO:
    ; subir=0 (OCR2A=0)
    ldi r16, 0
    out OCR2A, r16
    ; rampa bajar: OCR2B 0->DUTY_PUNZON
    rcall RAMP_PUNZON_DOWN
    ; 1s mantener en este subestado
    ldi r16, 1
    sts contador_timer, r16
    in r17, TIMSK1
    sbr r17, 1<<OCIE1A
    out TIMSK1, r17
    ; UART "PUNZONADO"
    ldi ZH, high(MSG_PUNZ<<1)
    ldi ZL, low(MSG_PUNZ<<1)
    rcall USART_send_P
WAIT_PB:
    lds r18, estado
    cpi r18, PUNZON_BAJANDO
    breq WAIT_PB
    rjmp MAIN

; === PUNZON_MANTENIENDO ===
ST_PUNZON_MANTENIENDO:
    ; subir=0, bajar=duty bajo (80)
    ldi r16, 0
    out OCR2A, r16
    ldi r16, DUTY_MANTENER
    out OCR2B, r16
    ; tiempos: ligera 2, media 3, pesada 4
    lds r16, tipo_carga
    cpi r16, 1
    breq PM_TL
    cpi r16, 2
    breq PM_TM
PM_TP:
    ldi r16, 4
    rjmp PM_SET
PM_TL:
    ldi r16, 2
    rjmp PM_SET
PM_TM:
    ldi r16, 3
PM_SET:
    sts contador_timer, r16
    in r17, TIMSK1
    sbr r17, 1<<OCIE1A
    out TIMSK1, r17
WAIT_PM:
    lds r18, estado
    cpi r18, PUNZON_MANTENIENDO
    breq WAIT_PM
    rjmp MAIN

; === PUNZON_SUBIENDO ===
ST_PUNZON_SUBIENDO:
    ; bajar=0
    ldi r16, 0
    out OCR2B, r16
    ; rampa subir: OCR2A 0->DUTY_PUNZON
    rcall RAMP_PUNZON_UP
    ; 1 s
    ldi r16, 1
    sts contador_timer, r16
    in r17, TIMSK1
    sbr r17, 1<<OCIE1A
    out TIMSK1, r17
WAIT_PS:
    lds r18, estado
    cpi r18, PUNZON_SUBIENDO
    breq WAIT_PS
    ; frenar suave subir -> 0
    rcall RAMP_PUNZON_UP_DOWN_TO_ZERO
    rjmp MAIN

; === DESCARGA ===
ST_DESCARGA:
    ; cinta adelante y rampa up
    in r16, PORTB
    cbr r16, 1<<CINTA_IN2_PB
    out PORTB, r16
    rcall RAMP_CINTA_UP
    ; tiempos: 3/4/5
    lds r16, tipo_carga
    cpi r16, 1
    breq DC_TL
    cpi r16, 2
    breq DC_TM
DC_TP:
    ldi r16, 5
    rjmp DC_SET
DC_TL:
    ldi r16, 3
    rjmp DC_SET
DC_TM:
    ldi r16, 4
DC_SET:
    sts contador_timer, r16
    in r17, TIMSK1
    sbr r17, 1<<OCIE1A
    out TIMSK1, r17
    ; UART "DESCARGA"
    ldi ZH, high(MSG_DESC<<1)
    ldi ZL, low(MSG_DESC<<1)
    rcall USART_send_P
WAIT_DC:
    lds r18, estado
    cpi r18, DESCARGA
    breq WAIT_DC
    rjmp MAIN

; === FIN ===
ST_FIN:
    ; Stop suave cinta y punzón
    rcall RAMP_CINTA_DOWN
    rcall RAMP_PUNZON_BOTH_ZERO
    ; LEDs: FUNCIONANDO=0, FIN=1, luego volver a ESPERA y apagar FIN
    in r16, PORTC
    cbr r16, 1<<LED_FUNCIONANDO_PC
    sbr r16, 1<<LED_FIN_PC
    out PORTC, r16
    ; TX "FIN"
    ldi ZH, high(MSG_FIN<<1)
    ldi ZL, low(MSG_FIN<<1)
    rcall USART_send_P
    ; estado = ESPERA
    ldi r16, ESPERA
    sts estado, r16
    ; Apaga FIN y prende ESPERA
    in r16, PORTC
    cbr r16, 1<<LED_FIN_PC
    sbr r16, 1<<LED_ESPERA_PC
    out PORTC, r16
    rjmp MAIN

; -------- INIT --------
IO_init:
    ; DDRB: PB1 (salida), PB3 (salida)
    in r16, DDRB
    sbr r16, (1<<CINTA_IN2_PB) | (1<<PUNZON_IN2_PB)
    out DDRB, r16
    ; DDRD: PD6 (salida), PD3 (salida), PD2 (entrada)
    in r16, DDRD
    sbr r16, (1<<CINTA_IN1_PD) | (1<<PUNZON_IN1_PD)
    cbr r16, 1<<BTN_INICIO_PD
    out DDRD, r16
    ; Pull-up botón en PD2 (para no andar con resistencias externas en protoboard)
    in r16, PORTD
    sbr r16, 1<<BTN_INICIO_PD
    out PORTD, r16
    ; LEDs en PORTC como salida
    ldi r16, (1<<LED_LIGERA_PC)|(1<<LED_MEDIA_PC)|(1<<LED_PESADA_PC)|(1<<LED_ESPERA_PC)|(1<<LED_FUNCIONANDO_PC)|(1<<LED_FIN_PC)
    out DDRC, r16
    ; Apaga todo y enciende ESPERA
    clr r16
    out PORTC, r16
    in r16, PORTC
    sbr r16, 1<<LED_ESPERA_PC
    out PORTC, r16
    ; Cinta IN2=0
    in r16, PORTB
    cbr r16, 1<<CINTA_IN2_PB
    out PORTB, r16
    ret

PWM_cinta_init:
    ; Timer0 Fast PWM OC0A (PD6), presc 64 ≈976 Hz
    ldi r16,(1<<WGM01)|(1<<WGM00)|(1<<COM0A1)
    out TCCR0A,r16
    ldi r16,(1<<CS01)|(1<<CS00)
    out TCCR0B,r16
    clr r16
    out OCR0A,r16
    ret

PWM_punzon_init:
    ; Timer2 Fast PWM OC2B/PD3 (baja) y OC2A/PB3 (sube), presc 64
    ldi r16,(1<<WGM21)|(1<<WGM20)|(1<<COM2A1)|(1<<COM2B1)
    out TCCR2A,r16
    ldi r16,(1<<CS22)
    out TCCR2B,r16
    clr r16
    out OCR2A,r16
    out OCR2B,r16
    ret

USART_init:
    ; 9600-8N1 @16MHz (UBRR=103). RX/TX + RX IRQ
    ldi r16,high(UBRR_VAL)
    out UBRR0H,r16
    ldi r16,low(UBRR_VAL)
    out UBRR0L,r16
    ldi r16,(1<<UCSZ01)|(1<<UCSZ00)
    out UCSR0C,r16
    ldi r16,(1<<RXEN0)|(1<<TXEN0)|(1<<RXCIE0)
    out UCSR0B,r16
    ret

TIMER1_init:
    ; CTC a 1s (OCR1A=62499), presc 256. OCIE1A se habilita por fase.
    clr r16
    out TCCR1A,r16
    out TCCR1B,r16
    clr r16
    out TCNT1H,r16
    out TCNT1L,r16
    ldi r16,high(62500-1)
    out OCR1AH,r16
    ldi r16,low(62500-1)
    out OCR1AL,r16
    ldi r16,(1<<WGM12)|(1<<CS12)
    out TCCR1B,r16
    ret

; -------- Rampas & Delay (bloqueantes y simples) --------
; RAMP_CINTA_UP: OCR0A 0->DUTY_CINTA en pasos STEP_CINTA
RAMP_CINTA_UP:
    clr r20
RCU_LOOP:
    cpi r20, DUTY_CINTA
    brsh RCU_DONE
    out OCR0A, r20
    rcall DELAY_5ms
    ldi r21, STEP_CINTA
    add r20, r21
    rjmp RCU_LOOP
RCU_DONE:
    ldi r20, DUTY_CINTA
    out OCR0A, r20
    ret

; RAMP_CINTA_DOWN: OCR0A -> 0
RAMP_CINTA_DOWN:
    in r20, OCR0A
RCD_LOOP:
    tst r20
    breq RCD_DONE
    out OCR0A, r20
    rcall DELAY_5ms
    ldi r21, STEP_CINTA
    sub r20, r21
    brcc RCD_LOOP
    clr r20
    rjmp RCD_LOOP
RCD_DONE:
    clr r20
    out OCR0A, r20
    ret

; RAMP_PUNZON_DOWN: OCR2B 0->DUTY_PUNZON (bajar)
RAMP_PUNZON_DOWN:
    clr r20
RPD_LOOP:
    cpi r20, DUTY_PUNZON
    brsh RPD_DONE
    out OCR2B, r20
    rcall DELAY_5ms
    ldi r21, STEP_PUNZON
    add r20, r21
    rjmp RPD_LOOP
RPD_DONE:
    ldi r20, DUTY_PUNZON
    out OCR2B, r20
    ret

; RAMP_PUNZON_UP: OCR2A 0->DUTY_PUNZON (subir)
RAMP_PUNZON_UP:
    clr r20
RPU_LOOP:
    cpi r20, DUTY_PUNZON
    brsh RPU_DONE
    out OCR2A, r20
    rcall DELAY_5ms
    ldi r21, STEP_PUNZON
    add r20, r21
    rjmp RPU_LOOP
RPU_DONE:
    ldi r20, DUTY_PUNZON
    out OCR2A, r20
    ret

; RAMP_PUNZON_UP_DOWN_TO_ZERO: rampa OCR2A -> 0
RAMP_PUNZON_UP_DOWN_TO_ZERO:
    in r20, OCR2A
RPUD_LOOP:
    tst r20
    breq RPUD_DONE
    out OCR2A, r20
    rcall DELAY_5ms
    ldi r21, STEP_PUNZON
    sub r20, r21
    brcc RPUD_LOOP
    clr r20
    rjmp RPUD_LOOP
RPUD_DONE:
    clr r20
    out OCR2A, r20
    ret

; RAMP_PUNZON_BOTH_ZERO: OCR2A=0, OCR2B=0 con rampas cortas
RAMP_PUNZON_BOTH_ZERO:
    rcall RAMP_PUNZON_UP_DOWN_TO_ZERO
    ; bajar -> 0 también
    in r20, OCR2B
RPBZ_LOOP:
    tst r20
    breq RPBZ_DONE
    out OCR2B, r20
    rcall DELAY_5ms
    ldi r21, STEP_PUNZON
    sub r20, r21
    brcc RPBZ_LOOP
    clr r20
    rjmp RPBZ_LOOP
RPBZ_DONE:
    clr r20
    out OCR2B, r20
    ret

DELAY_5ms:
    ; ~5 ms aprox @16MHz (doble bucle)
    ldi r22,80
D5_OUT:
    ldi r23,200
D5_IN: dec r23
    brne D5_IN
    dec r22
    brne D5_OUT
    ret

; -------- UART helpers --------
; Enviar char en r24
USART_send_char:
    ; espera UDRE0
USC_WAIT:
    in r25, UCSR0A
    sbrs r25, UDRE0
    rjmp USC_WAIT
    out UDR0, r24
    ret

; Enviar string en PROGMEM (Z apunta a la cadena, terminada en 0)
USART_send_P:
    lpm r24, Z+
    tst r24
    breq USP_END
    rcall USART_send_char
    rjmp USART_send_P
USP_END:
    ; enviar '\n'
    ldi r24, 10
    rcall USART_send_char
    ret

; -------- ISRs --------

TIMER1_COMPA_ISR:
    push r16
    push r17
    push r18
    ; if (contador_timer) contador_timer--; if (!0) return; else stop y avanzar
    lds r16, contador_timer
    tst r16
    breq T1_ZERO
    dec r16
    sts contador_timer, r16
    tst r16
    brne T1_DONE
T1_ZERO:
    ; deshabilitar OCIE1A
    in r17, TIMSK1
    cbr r17, 1<<OCIE1A
    out TIMSK1, r17
    ; avanzar FSM según estado actual
    lds r18, estado
    cpi r18, CINTA_AVANCE
    breq T1_TO_PAUSA
    cpi r18, CINTA_PAUSA
    breq T1_TO_POS
    cpi r18, PUNZON_BAJANDO
    breq T1_TO_MANT
    cpi r18, PUNZON_MANTENIENDO
    breq T1_TO_SUBE
    cpi r18, PUNZON_SUBIENDO
    breq T1_TO_DESC
    cpi r18, DESCARGA
    breq T1_TO_FIN
    rjmp T1_DONE
T1_TO_PAUSA:
    ldi r18, CINTA_PAUSA
    sts estado, r18
    rjmp T1_DONE
T1_TO_POS:
    ldi r18, POSICIONADO
    sts estado, r18
    rjmp T1_DONE
T1_TO_MANT:
    ldi r18, PUNZON_MANTENIENDO
    sts estado, r18
    rjmp T1_DONE
T1_TO_SUBE:
    ldi r18, PUNZON_SUBIENDO
    sts estado, r18
    rjmp T1_DONE
T1_TO_DESC:
    ldi r18, DESCARGA
    sts estado, r18
    rjmp T1_DONE
T1_TO_FIN:
    ldi r18, FIN
    sts estado, r18
T1_DONE:
    pop r18
    pop r17
    pop r16
    reti

USART_RX_ISR:
    push r16
    push r17
    push r18
    in r16, UDR0      ; c recibido
    ; 'A' -> arranque
    cpi r16, 'A'
    brne URX_CHECK_123
    ; Apagar LED_FIN
    in r17, PORTC
    cbr r17, 1<<LED_FIN_PC
    out PORTC, r17
    ; estado = CINTA_AVANCE
    ldi r18, CINTA_AVANCE
    sts estado, r18
    ; UART "ALIM"
    ldi ZH, high(MSG_ALIM<<1)
    ldi ZL, low(MSG_ALIM<<1)
    rcall USART_send_P
    ; LED_FUNCIONANDO=1, LED_ESPERA=0
    in r17, PORTC
    sbr r17, 1<<LED_FUNCIONANDO_PC
    cbr r17, 1<<LED_ESPERA_PC
    out PORTC, r17
    rjmp URX_DONE
URX_CHECK_123:
    cpi r16, '1'
    brne URX_CHK2
    ldi r18, 1
    sts tipo_carga, r18
    ; LED: ligera=1, media/pesada=0
    in r17, PORTC
    sbr r17, 1<<LED_LIGERA_PC
    cbr r17, (1<<LED_MEDIA_PC)|(1<<LED_PESADA_PC)
    out PORTC, r17
    rjmp URX_DONE
URX_CHK2:
    cpi r16, '2'
    brne URX_CHK3
    ldi r18, 2
    sts tipo_carga, r18
    in r17, PORTC
    sbr r17, 1<<LED_MEDIA_PC
    cbr r17, (1<<LED_LIGERA_PC)|(1<<LED_PESADA_PC)
    out PORTC, r17
    rjmp URX_DONE
URX_CHK3:
    cpi r16, '3'
    brne URX_DONE
    ldi r18, 3
    sts tipo_carga, r18
    in r17, PORTC
    sbr r17, 1<<LED_PESADA_PC
    cbr r17, (1<<LED_LIGERA_PC)|(1<<LED_MEDIA_PC)
    out PORTC, r17
URX_DONE:
    pop r18
    pop r17
    pop r16
    reti

DEFAULT_IRQ:
    reti

; ------------------ Mensajes en PROGMEM ----------------------------
MSG_ESPERA:    .db "ESPERA",0
MSG_ALIM:      .db "ALIM",0
MSG_POS:       .db "POSICIONADO",0
MSG_PUNZ:      .db "PUNZONADO",0
MSG_DESC:      .db "DESCARGA",0
MSG_FIN:       .db "FIN",0
