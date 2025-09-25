; ===============================================================
; PROYECTO: Punzonadora con cinta transportadora (UNO-F5)
; MCU: ATmega328P @16 MHz – avrasm2
; FSM: ESPERA→ALIM→PAUSA→POSICIONADO→BAJA→MANTIENE→SUBE→DESCARGA→FIN
; Timer1 CTC: 1 s/tick | Cinta: PWM HW OC0A (D6) + DIR D9 | Punzón: PWM HW OC2B (D3) y OC0B (D5)
; UART 9600-8N1 ('A' start, '1/2/3' carga). LEDs en PORTC.
; Nota: Elegí M2 para CINTA (D6,D9) y M1 para PUNZÓN (D3,D5) para no chocar con Timer1.
; ===============================================================

.include "m328Pdef.inc"

; -------- Definiciones --------
.equ F_CPU     = 16000000
.equ UBRR_VAL  = 103           ; 9600 @ 16 MHz

; Estados
.equ ESPERA=0, CINTA_AVANCE=1, CINTA_PAUSA=2, POSICIONADO=3
.equ PUNZON_BAJANDO=4, PUNZON_MANTENIENDO=5, PUNZON_SUBIENDO=6, DESCARGA=7, FIN=8

; Pines / LEDs
; Cinta (M2): D6 PWM, D9 DIR
.equ CINTA_PWM_PD6 = 6         ; PD6 -> OC0A
.equ CINTA_DIR_PB1 = 1         ; PB1 -> DIR

; Punzón (M1): D3 (OC2B bajar), D5 (OC0B subir)
.equ PUNZON_BAJAR_PD3 = 3      ; PD3 -> OC2B
.equ PUNZON_SUBIR_PD5 = 5      ; PD5 -> OC0B

; LEDs (PORTC)
.equ LED_LIGERA_PC=0, LED_MEDIA_PC=1, LED_PESADA_PC=2
.equ LED_ESPERA_PC=3, LED_FUNCIONANDO_PC=4, LED_FIN_PC=5

; Botón
.equ BTN_INICIO_PD = 2         ; PD2 con pull-up

; Rampas / duty
.equ STEP_CINTA=10, STEP_PUNZON=15
.equ DUTY_CINTA=200, DUTY_PUNZON=220, DUTY_MANTENER=80

; -------- RAM --------
.dseg
.org 0x0100
estado:         .byte 1
contador_timer: .byte 1
tipo_carga:     .byte 1

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
    ; SP
    ldi r16, high(RAMEND)   ; SPH/SPL
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16

    rcall IO_init
    rcall PWM_cinta_init
    rcall PWM_punzon_init
    rcall USART_init
    rcall TIMER1_init       ; 1 s tick (CTC)

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
    lds r18, estado
    cpi r18, ESPERA            ; dispatch
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

; === ESPERA === (botón o 'A')
ST_ESPERA:
    in r16, PIND
    sbrc r16, BTN_INICIO_PD
    rjmp MAIN
    ; arranca
    in r16, PORTC
    cbr r16, 1<<LED_FIN_PC
    out PORTC, r16
    ldi r16, CINTA_AVANCE
    sts estado, r16
    ldi ZH, high(MSG_ALIM<<1)
    ldi ZL, low(MSG_ALIM<<1)
    rcall USART_send_P
    in r16, PORTC
    sbr r16, 1<<LED_FUNCIONANDO_PC
    cbr r16, 1<<LED_ESPERA_PC
    out PORTC, r16
    rjmp MAIN

; === CINTA_AVANCE === (rampa up y 3/4/5 s)
ST_CINTA_AVANCE:
    ; DIR adelante
    in r16, PORTB
    cbr r16, 1<<CINTA_DIR_PB1
    out PORTB, r16
    ; rampa OCR0A (D6)
    rcall RAMP_CINTA_UP
    ; tiempos
    lds r16, tipo_carga
    cpi r16, 1
    breq CA_TL
    cpi r16, 2
    breq CA_TM
    ldi r16, 5
    rjmp CA_SET
CA_TL: ldi r16, 3
    rjmp CA_SET
CA_TM: ldi r16, 4
CA_SET:
    sts contador_timer, r16
    in r17, TIMSK1
    sbr r17, 1<<OCIE1A
    out TIMSK1, r17
WAIT_CA:
    lds r18, estado
    cpi r18, CINTA_AVANCE
    breq WAIT_CA
    rjmp MAIN

; === CINTA_PAUSA === (rampa down y 2/2/3 s)
ST_CINTA_PAUSA:
    rcall RAMP_CINTA_DOWN
    lds r16, tipo_carga
    cpi r16, 3
    breq CP_PES
    ldi r16, 2
    rjmp CP_SET
CP_PES: ldi r16, 3
CP_SET:
    sts contador_timer, r16
    in r17, TIMSK1
    sbr r17, 1<<OCIE1A
    out TIMSK1, r17
WAIT_CP:
    lds r18, estado
    cpi r18, CINTA_PAUSA
    breq WAIT_CP
    rjmp MAIN

; === POSICIONADO === (anuncia y pasa a bajar)
ST_POSICIONADO:
    ldi ZH, high(MSG_POS<<1)
    ldi ZL, low(MSG_POS<<1)
    rcall USART_send_P
    ldi r16, PUNZON_BAJANDO
    sts estado, r16
    rjmp MAIN

; === PUNZON_BAJANDO === (subir=0, rampa bajar, 1 s)
ST_PUNZON_BAJANDO:
    ; subir=0 (OCR0B=0 en D5)
    ldi r16, 0
    out OCR0B, r16
    ; rampa bajar por OCR2B (D3)
    rcall RAMP_PUNZON_DOWN
    ldi r16, 1
    sts contador_timer, r16
    in r17, TIMSK1
    sbr r17, 1<<OCIE1A
    out TIMSK1, r17
    ldi ZH, high(MSG_PUNZ<<1)
    ldi ZL, low(MSG_PUNZ<<1)
    rcall USART_send_P
WAIT_PB:
    lds r18, estado
    cpi r18, PUNZON_BAJANDO
    breq WAIT_PB
    rjmp MAIN

; === PUNZON_MANTENIENDO === (duty bajo, 2/3/4 s)
ST_PUNZON_MANTENIENDO:
    ; subir=0, bajar≈30%
    ldi r16, 0
    out OCR0B, r16
    ldi r16, DUTY_MANTENER
    out OCR2B, r16
    ; tiempos
    lds r16, tipo_carga
    cpi r16, 1
    breq PM_TL
    cpi r16, 2
    breq PM_TM
    ldi r16, 4
    rjmp PM_SET
PM_TL: ldi r16, 2
    rjmp PM_SET
PM_TM: ldi r16, 3
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

; === PUNZON_SUBIENDO === (rampa subir, 1 s, luego a 0)
ST_PUNZON_SUBIENDO:
    ; bajar=0
    ldi r16, 0
    out OCR2B, r16
    ; rampa subir por OCR0B (D5)
    rcall RAMP_PUNZON_UP
    ldi r16, 1
    sts contador_timer, r16
    in r17, TIMSK1
    sbr r17, 1<<OCIE1A
    out TIMSK1, r17
WAIT_PS:
    lds r18, estado
    cpi r18, PUNZON_SUBIENDO
    breq WAIT_PS
    ; freno suave subir -> 0
    rcall RAMP_PUNZON_UP_TO_ZERO
    rjmp MAIN

; === DESCARGA === (cinta rampa up y 3/4/5 s)
ST_DESCARGA:
    in r16, PORTB
    cbr r16, 1<<CINTA_DIR_PB1
    out PORTB, r16
    rcall RAMP_CINTA_UP
    lds r16, tipo_carga
    cpi r16, 1
    breq DC_TL
    cpi r16, 2
    breq DC_TM
    ldi r16, 5
    rjmp DC_SET
DC_TL: ldi r16, 3
    rjmp DC_SET
DC_TM: ldi r16, 4
DC_SET:
    sts contador_timer, r16
    in r17, TIMSK1
    sbr r17, 1<<OCIE1A
    out TIMSK1, r17
    ldi ZH, high(MSG_DESC<<1)
    ldi ZL, low(MSG_DESC<<1)
    rcall USART_send_P
WAIT_DC:
    lds r18, estado
    cpi r18, DESCARGA
    breq WAIT_DC
    rjmp MAIN

; === FIN === (rampas a 0, LEDs, vuelve a ESPERA)
ST_FIN:
    rcall RAMP_CINTA_DOWN
    rcall RAMP_PUNZON_BOTH_ZERO
    in r16, PORTC
    cbr r16, 1<<LED_FUNCIONANDO_PC
    sbr r16, 1<<LED_FIN_PC
    out PORTC, r16
    ldi ZH, high(MSG_FIN<<1)
    ldi ZL, low(MSG_FIN<<1)
    rcall USART_send_P
    ldi r16, ESPERA
    sts estado, r16
    in r16, PORTC
    cbr r16, 1<<LED_FIN_PC
    sbr r16, 1<<LED_ESPERA_PC
    out PORTC, r16
    rjmp MAIN

; -------- INIT --------
IO_init:
    ; DDRB: PB1 (DIR cinta) salida
    in r16, DDRB
    sbr r16, (1<<CINTA_DIR_PB1)
    out DDRB, r16
    ; DDRD: PD6 (OC0A), PD5 (OC0B), PD3 (OC2B) salida; PD2 entrada
    in r16, DDRD
    sbr r16, (1<<CINTA_PWM_PD6)|(1<<PUNZON_SUBIR_PD5)|(1<<PUNZON_BAJAR_PD3)
    cbr r16, 1<<BTN_INICIO_PD
    out DDRD, r16
    ; Pull-up botón
    in r16, PORTD
    sbr r16, 1<<BTN_INICIO_PD
    out PORTD, r16
    ; LEDs out
    ldi r16,(1<<LED_LIGERA_PC)|(1<<LED_MEDIA_PC)|(1<<LED_PESADA_PC)|(1<<LED_ESPERA_PC)|(1<<LED_FUNCIONANDO_PC)|(1<<LED_FIN_PC)
    out DDRC, r16
    ; LEDs: ESPERA on
    clr r16
    out PORTC, r16
    in r16, PORTC
    sbr r16, 1<<LED_ESPERA_PC
    out PORTC, r16
    ; DIR inicial cinta = 0
    in r16, PORTB
    cbr r16, 1<<CINTA_DIR_PB1
    out PORTB, r16
    ret

PWM_cinta_init:
    ; Timer0 Fast PWM: OC0A (D6) y OC0B (D5) habilitados, presc 64 (~976 Hz)
    ldi r16,(1<<WGM01)|(1<<WGM00)|(1<<COM0A1)|(1<<COM0B1)
    out TCCR0A,r16
    ldi r16,(1<<CS01)|(1<<CS00)
    out TCCR0B,r16
    clr r16
    out OCR0A,r16     ; cinta
    out OCR0B,r16     ; punzón subir
    ret

PWM_punzon_init:
    ; Timer2 Fast PWM: OC2B (D3) habilitado, presc 64 (~976 Hz)
    ldi r16,(1<<WGM21)|(1<<WGM20)|(1<<COM2B1)
    out TCCR2A,r16
    ldi r16,(1<<CS22)
    out TCCR2B,r16
    clr r16
    out OCR2B,r16     ; punzón bajar
    ret

USART_init:
    ; 9600-8N1
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
    ; CTC 1 s (OCR1A=62499), presc 256. Interrupción se habilita por fase.
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

; -------- Rampas & Delay --------
; Cinta (OCR0A)
RAMP_CINTA_UP:
    clr r20
RCU_LOOP:
    cpi r20,DUTY_CINTA
    brsh RCU_DONE
    out OCR0A,r20
    rcall DELAY_5ms
    ldi r21,STEP_CINTA
    add r20,r21
    rjmp RCU_LOOP
RCU_DONE:
    ldi r20,DUTY_CINTA
    out OCR0A,r20
    ret

RAMP_CINTA_DOWN:
    in r20,OCR0A
RCD_LOOP:
    tst r20
    breq RCD_DONE
    out OCR0A,r20
    rcall DELAY_5ms
    ldi r21,STEP_CINTA
    sub r20,r21
    brcc RCD_LOOP
    clr r20
    rjmp RCD_LOOP
RCD_DONE:
    clr r20
    out OCR0A,r20
    ret

; Punzón: bajar = OCR2B (D3), subir = OCR0B (D5)
RAMP_PUNZON_DOWN:
    clr r20
RPD_LOOP:
    cpi r20,DUTY_PUNZON
    brsh RPD_DONE
    out OCR2B,r20
    rcall DELAY_5ms
    ldi r21,STEP_PUNZON
    add r20,r21
    rjmp RPD_LOOP
RPD_DONE:
    ldi r20,DUTY_PUNZON
    out OCR2B,r20
    ret

RAMP_PUNZON_UP:
    clr r20
RPU_LOOP:
    cpi r20,DUTY_PUNZON
    brsh RPU_DONE
    out OCR0B,r20
    rcall DELAY_5ms
    ldi r21,STEP_PUNZON
    add r20,r21
    rjmp RPU_LOOP
RPU_DONE:
    ldi r20,DUTY_PUNZON
    out OCR0B,r20
    ret

RAMP_PUNZON_UP_TO_ZERO:
    in r20,OCR0B
RPZ1:
    tst r20
    breq RPZ2
    out OCR0B,r20
    rcall DELAY_5ms
    ldi r21,STEP_PUNZON
    sub r20,r21
    brcc RPZ1
    clr r20
    rjmp RPZ1
RPZ2:
    clr r20
    out OCR0B,r20
    ret

RAMP_PUNZON_BOTH_ZERO:
    ; subir -> 0
    rcall RAMP_PUNZON_UP_TO_ZERO
    ; bajar -> 0
    in r20,OCR2B
RPB1:
    tst r20
    breq RPB2
    out OCR2B,r20
    rcall DELAY_5ms
    ldi r21,STEP_PUNZON
    sub r20,r21
    brcc RPB1
    clr r20
    rjmp RPB1
RPB2:
    clr r20
    out OCR2B,r20
    ret

DELAY_5ms:
    ; ~5 ms aprox @16MHz
    ldi r22,80
D5_OUT:
    ldi r23,200
D5_IN: dec r23
    brne D5_IN
    dec r22
    brne D5_OUT
    ret

; -------- UART helpers --------
USART_send_char:
USC_WAIT:
    in r25,UCSR0A
    sbrs r25,UDRE0
    rjmp USC_WAIT
    out UDR0,r24
    ret

USART_send_P:
    lpm r24,Z+
    tst r24
    breq USP_END
    rcall USART_send_char
    rjmp USART_send_P
USP_END:
    ldi r24,10
    rcall USART_send_char
    ret

; -------- ISRs --------
TIMER1_COMPA_ISR:
    push r16
    push r17
    push r18
    lds r16,contador_timer
    tst r16
    breq T1_ZERO
    dec r16
    sts contador_timer,r16
    tst r16
    brne T1_DONE
T1_ZERO:
    in r17,TIMSK1
    cbr r17,1<<OCIE1A
    out TIMSK1,r17
    lds r18,estado
    cpi r18,CINTA_AVANCE    ; transiciones
    breq T1_TO_PAUSA
    cpi r18,CINTA_PAUSA
    breq T1_TO_POS
    cpi r18,PUNZON_BAJANDO
    breq T1_TO_MANT
    cpi r18,PUNZON_MANTENIENDO
    breq T1_TO_SUBE
    cpi r18,PUNZON_SUBIENDO
    breq T1_TO_DESC
    cpi r18,DESCARGA
    breq T1_TO_FIN
    rjmp T1_DONE
T1_TO_PAUSA:       ldi r18,CINTA_PAUSA         ; ALIM -> PAUSA
                   sts estado,r18
                   rjmp T1_DONE
T1_TO_POS:         ldi r18,POSICIONADO
                   sts estado,r18
                   rjmp T1_DONE
T1_TO_MANT:        ldi r18,PUNZON_MANTENIENDO
                   sts estado,r18
                   rjmp T1_DONE
T1_TO_SUBE:        ldi r18,PUNZON_SUBIENDO
                   sts estado,r18
                   rjmp T1_DONE
T1_TO_DESC:        ldi r18,DESCARGA
                   sts estado,r18
                   rjmp T1_DONE
T1_TO_FIN:         ldi r18,FIN
                   sts estado,r18
T1_DONE:
    pop r18
    pop r17
    pop r16
    reti

USART_RX_ISR:
    push r16
    push r17
    push r18
    in r16,UDR0
    cpi r16,'A'
    brne URX_123
    ; start
    in r17,PORTC
    cbr r17,1<<LED_FIN_PC
    out PORTC,r17
    ldi r18,CINTA_AVANCE
    sts estado,r18
    ldi ZH,high(MSG_ALIM<<1)
    ldi ZL,low(MSG_ALIM<<1)
    rcall USART_send_P
    in r17,PORTC
    sbr r17,1<<LED_FUNCIONANDO_PC
    cbr r17,1<<LED_ESPERA_PC
    out PORTC,r17
    rjmp URX_DONE
URX_123:
    cpi r16,'1'
    brne U2
    ldi r18,1
    sts tipo_carga,r18
    in r17,PORTC
    sbr r17,1<<LED_LIGERA_PC
    cbr r17,(1<<LED_MEDIA_PC)|(1<<LED_PESADA_PC)
    out PORTC,r17
    rjmp URX_DONE
U2: cpi r16,'2'
    brne U3
    ldi r18,2
    sts tipo_carga,r18
    in r17,PORTC
    sbr r17,1<<LED_MEDIA_PC
    cbr r17,(1<<LED_LIGERA_PC)|(1<<LED_PESADA_PC)
    out PORTC,r17
    rjmp URX_DONE
U3: cpi r16,'3'
    brne URX_DONE
    ldi r18,3
    sts tipo_carga,r18
    in r17,PORTC
    sbr r17,1<<LED_PESADA_PC
    cbr r17,(1<<LED_LIGERA_PC)|(1<<LED_MEDIA_PC)
    out PORTC,r17
URX_DONE:
    pop r18
    pop r17
    pop r16
    reti

; -------- Mensajes PROGMEM --------
MSG_ESPERA: .db "ESPERA",0
MSG_ALIM:   .db "ALIM",0
MSG_POS:    .db "POSICIONADO",0
MSG_PUNZ:   .db "PUNZONADO",0
MSG_DESC:   .db "DESCARGA",0
MSG_FIN:    .db "FIN",0
