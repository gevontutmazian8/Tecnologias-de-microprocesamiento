.include "m328pdef.inc"

.cseg
.org 0x0000
    rjmp reset
.org 0x0034

.equ F_CPU = 16000000
.equ baud = 9600
.equ bps = (F_CPU/16/baud) - 1

.def temp = r16
.def temp2 = r17

reset:
    ; Stack Pointer
    ldi temp, high(RAMEND)
    out SPH, temp
    ldi temp, low(RAMEND)
    out SPL, temp

    ; === CONFIGURACIÓN UART SIMPLIFICADA ===
    ldi temp, low(bps)
    ldi temp2, high(bps)
    sts UBRR0L, temp
    sts UBRR0H, temp2
    
    ldi temp, (1<<UCSZ01)|(1<<UCSZ00)
    sts UCSR0C, temp
    
    ldi temp, (1<<RXEN0)|(1<<TXEN0)
    sts UCSR0B, temp

    ; === PRUEBA INMEDIATA DE COMUNICACIÓN ===
    ; Enviar caracteres de prueba uno por uno
    ldi temp, 'H'
    rcall putc
    ldi temp, 'O'
    rcall putc
    ldi temp, 'L'
    rcall putc
    ldi temp, 'A'
    rcall putc
    ldi temp, '!'
    rcall putc
    ldi temp, 0x0D  ; CR
    rcall putc
    ldi temp, 0x0A  ; LF
    rcall putc

    ; Mensaje simple
    ldi ZL, low(2*test_message)
    ldi ZH, high(2*test_message)
    rcall enviar_cadena

    ; Loop infinito simple
loop:
    rjmp loop

; --- RUTINAS BÁSICAS ---
putc:
    lds temp2, UCSR0A
    sbrs temp2, UDRE0
    rjmp putc
    sts UDR0, temp
    ret

enviar_cadena:
    lpm temp, Z+
    cpi temp, 0
    breq enviar_cadena_fin
    rcall putc
    rjmp enviar_cadena
enviar_cadena_fin:
    ret

; --- MENSAJE DE PRUEBA ---
test_message:
    .db "TEST OK - Serial funciona", 0x0D, 0x0A, 0

.exit