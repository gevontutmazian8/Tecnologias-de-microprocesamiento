#CODIGO PARA EL LED 1

.include "m328pdef.inc"
.org 0x00

;Ajuste del Stack Pointer
ldi r16, HIGH(RAMEND)
out SPH, r16
ldi r16, LOW(RAMEND)
out SPL, r16

;Configuración del temporizador
ldi r16, 0x00
sts TCCR1A, r16
ldi r16, (1<<CS12)|(1<<CS10)
sts TCCR1B, r16
ldi r16, 0
sts TCCR1C, r16
ldi r16, 0
sts TIMSK1, r16

;Inicialización del contador
ldi r16, HIGH(60286)
sts TCNT1H, r16
ldi r16, LOW(60286)
sts TCNT1L, r16

;Configurar PB5 como salida
sbi DDRD, PD5 
sbi DDRD, PD6 
sbi DDRD, PD7 
sbi DDRB, PB0 
sbi DDRB, PB1 
sbi DDRB, PB2 
sbi DDRB, PB3 
sbi DDRB, PB4 

sbi PORTD, PD5
sbi PORTD, PD6
sbi PORTD, PD7
sbi PORTB, PB0
sbi PORTB, PB1
sbi PORTB, PB2
sbi PORTB, PB3
sbi PORTB, PB4

Bucle:
	sbi PORTB, PB4
	cbi PORTD, PD5

	rcall Retardo

	sbi PORTD, PD5
	cbi PORTD, PD6

	rcall Retardo

	sbi PORTD, PD6
	cbi PORTD, PD7

	rcall Retardo

	sbi PORTD, PD7
	cbi PORTB, PB0

	rcall Retardo

	sbi PORTB, PB0
	cbi PORTB, PB1

	rcall Retardo
	
	sbi PORTB, PB1
	cbi PORTB, PB2

	rcall Retardo
	
	sbi PORTB, PB2
	cbi PORTB, PB3

	rcall Retardo
	
	sbi PORTB, PB3
	cbi PORTB, PB4

	rcall Retardo

    rjmp Bucle


Retardo:
    sbis TIFR1, TOV1
    rjmp Retardo

    ldi r16, (1<<TOV1)  
    out TIFR1, r16   

    ldi r16, HIGH(60286)
    sts TCNT1H, r16
    ldi r16, LOW(60286)
    sts TCNT1L, r16

    ret

#CODIGO PARA EL LED 2
.include "m328pdef.inc"
.org 0x00

;Ajuste del Stack Pointer
ldi r16, HIGH(RAMEND)
out SPH, r16
ldi r16, LOW(RAMEND)
out SPL, r16

;Configuración del temporizador
ldi r16, 0x00
sts TCCR1A, r16
ldi r16, (1<<CS12)|(1<<CS10)
sts TCCR1B, r16
ldi r16, 0
sts TCCR1C, r16
ldi r16, 0
sts TIMSK1, r16

;Inicialización del contador
ldi r16, HIGH(60286)
sts TCNT1H, r16
ldi r16, LOW(60286)
sts TCNT1L, r16

;Configurar PB5 como salida
sbi DDRD, PD5 
sbi DDRD, PD6 
sbi DDRD, PD7 
sbi DDRB, PB0 
sbi DDRB, PB1 
sbi DDRB, PB2 
sbi DDRB, PB3 
sbi DDRB, PB4 

sbi PORTD, PD5
sbi PORTD, PD6
sbi PORTD, PD7
sbi PORTB, PB0
sbi PORTB, PB1
sbi PORTB, PB2
sbi PORTB, PB3
sbi PORTB, PB4

Bucle:
	cbi PORTD, PD5
	rcall Retardo
	cbi PORTD, PD6
	rcall Retardo
	cbi PORTD, PD7
	rcall Retardo
	cbi PORTB, PB0
	rcall Retardo
	cbi PORTB, PB1
	rcall Retardo
	cbi PORTB, PB2
	rcall Retardo
	cbi PORTB, PB3
	rcall Retardo	
	cbi PORTB, PB4
	rcall Retardo

	sbi PORTD, PD5
	sbi PORTD, PD6
	sbi PORTD, PD7
	sbi PORTB, PB0
	sbi PORTB, PB1
	sbi PORTB, PB2
	sbi PORTB, PB3
	sbi PORTB, PB4
	rcall Retardo
	rcall Retardo
    rjmp Bucle


Retardo:
    sbis TIFR1, TOV1
    rjmp Retardo

    ldi r16, (1<<TOV1)  
    out TIFR1, r16   

    ldi r16, HIGH(60286)
    sts TCNT1H, r16
    ldi r16, LOW(60286)
    sts TCNT1L, r16

    ret

#CODIGO PARA EL LED 3

.include "m328pdef.inc"
.org 0x00

;Ajuste del Stack Pointer
ldi r16, HIGH(RAMEND)
out SPH, r16
ldi r16, LOW(RAMEND)
out SPL, r16

;Configuración del temporizador
ldi r16, 0x00
sts TCCR1A, r16
ldi r16, (1<<CS12)|(1<<CS10)
sts TCCR1B, r16
ldi r16, 0
sts TCCR1C, r16
ldi r16, 0
sts TIMSK1, r16

;Inicialización del contador
ldi r16, HIGH(60286)
sts TCNT1H, r16
ldi r16, LOW(60286)
sts TCNT1L, r16

;Configurar PB5 como salida
sbi DDRD, PD5 
sbi DDRD, PD6 
sbi DDRD, PD7 
sbi DDRB, PB0 
sbi DDRB, PB1 
sbi DDRB, PB2 
sbi DDRB, PB3 
sbi DDRB, PB4 

sbi PORTD, PD5
sbi PORTD, PD6
sbi PORTD, PD7
sbi PORTB, PB0
sbi PORTB, PB1
sbi PORTB, PB2
sbi PORTB, PB3
sbi PORTB, PB4

Bucle:
	cbi PORTD, PD5
	cbi PORTB, PB4

	rcall Retardo
	
	cbi PORTD, PD6
	cbi PORTB, PB3

	rcall Retardo

	cbi PORTD, PD7
	cbi PORTB, PB2

	rcall Retardo

	cbi PORTB, PB0
	cbi PORTB, PB1

	rcall Retardo

	sbi PORTB, PB0
	sbi PORTB, PB1

	rcall Retardo

	sbi PORTD, PD7
	sbi PORTB, PB2

	rcall Retardo

	sbi PORTD, PD6
	sbi PORTB, PB3

	rcall Retardo
		
	sbi PORTD, PD5
	sbi PORTB, PB4

	rcall Retardo
    rjmp Bucle


Retardo:
    sbis TIFR1, TOV1
    rjmp Retardo

    ldi r16, (1<<TOV1)  
    out TIFR1, r16   

    ldi r16, HIGH(60286)
    sts TCNT1H, r16
    ldi r16, LOW(60286)
    sts TCNT1L, r16

    ret

#led 2
