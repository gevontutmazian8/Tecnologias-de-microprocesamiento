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
ldi r16, HIGH(65500)
sts TCNT1H, r16
ldi r16, LOW(65500)
sts TCNT1L, r16

;Configurar PB5 como salida
sbi DDRD, PD2
sbi DDRD, PD3 
sbi DDRD, PD4 
sbi DDRD, PD5 
sbi DDRD, PD6 
sbi DDRD, PD7 
sbi DDRB, PB0 
sbi DDRB, PB1 

sbi DDRB, PB2
sbi DDRB, PB3
sbi DDRB, PB4 

;Inicializar los pines en 1 
sbi PORTD, PD2
sbi PORTD, PD3
sbi PORTD, PD4
sbi PORTD, PD5
sbi PORTD, PD6
sbi PORTD, PD7
sbi PORTB, PB0
sbi PORTB, PB1

sbi PORTB, PB2
sbi PORTB, PB3
sbi PORTB, PB4

Bucle:
	Bucle:
    rcall CaritaFeliz
    rcall CaritaTriste
    rcall Corazon
    rcall Rombo
    rcall Alien
	rjmp Bucle

CaritaFeliz:
	cbi PORTD, PB4
	cbi PORTD, PB5
	cbi PORTD, PB6
	cbi PORTD, PB7

	rcall Retardo
	rcall Reset

	cbi PORTB, PB2

	cbi PORTD, PD3
	cbi PORTB, PB0

	rcall Retardo
	rcall Reset

	cbi PORTB, PB3

	cbi PORTD, PD2
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTB, PB1

	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB3
	cbi PORTB, PB2

	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD7
	cbi PORTB, PB1

	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4

	cbi PORTD, PD2
	cbi PORTB, PB1

	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4
	cbi PORTB, PB2

	cbi PORTD, PD2
	cbi PORTB, PB1
	cbi PORTD, PD4
	cbi PORTD, PD7

	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4
	cbi PORTB, PB3

	cbi PORTD, PD3
	cbi PORTB, PB0

	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4
	cbi PORTB, PB3
	cbi PORTB, PB2

	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7

	rcall Retardo
	rcall Reset

	ret

CaritaTriste:
	cbi PORTD, PB4
	cbi PORTD, PB5
	cbi PORTD, PB6
	cbi PORTD, PB7

	rcall Retardo
	rcall Reset

	cbi PORTB, PB2

	cbi PORTD, PD3
	cbi PORTB, PB0

	rcall Retardo
	rcall Reset

	cbi PORTB, PB3

	cbi PORTD, PD2
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTB, PB1

	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB3
	cbi PORTB, PB2

	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD7
	cbi PORTB, PB1

	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4

	cbi PORTD, PD2
	cbi PORTB, PB1

	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4
	cbi PORTB, PB2

	cbi PORTD, PD2
	cbi PORTB, PB1
	cbi PORTD, PD4
	cbi PORTD, PD7

	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4
	cbi PORTB, PB3

	cbi PORTD, PD3
	cbi PORTB, PB0

	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4
	cbi PORTB, PB3
	cbi PORTB, PB2

	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7

	rcall Retardo
	rcall Reset
	ret

Corazon:
	cbi PORTD, PD5
	cbi PORTD, PD6

	rcall Retardo
	rcall Reset

	cbi PORTB, PB2

	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD4
	cbi PORTD, PD7

	rcall Retardo
	rcall Reset

	cbi PORTB, PB3

	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7
	cbi PORTB, PB0


	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB3
	cbi PORTB, PB2

	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7
	cbi PORTB, PB0
	cbi PORTB, PB1

	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4

	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7
	cbi PORTB, PB0
	cbi PORTB, PB1

	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4
	cbi PORTB, PB2

	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7
	cbi PORTB, PB0
	cbi PORTB, PB1

	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4
	cbi PORTB, PB3

	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD7
	cbi PORTB, PB0


	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4
	cbi PORTB, PB3
	cbi PORTB, PB2

	cbi PORTD, PD4
	cbi PORTD, PD7

	rcall Retardo
	rcall Reset
	ret

Rombo:
	cbi PORTD, PD5
	cbi PORTD, PD6

	rcall Retardo
	rcall Reset

	cbi PORTB, PB2


	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7

	rcall Retardo
	rcall Reset

	cbi PORTB, PB3

	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7
	cbi PORTB, PB0


	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB3
	cbi PORTB, PB2

	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7
	cbi PORTB, PB0
	cbi PORTB, PB1

	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4

	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7
	cbi PORTB, PB0
	cbi PORTB, PB1

	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4
	cbi PORTB, PB2

	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7
	cbi PORTB, PB0

	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4
	cbi PORTB, PB3

	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7


	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4
	cbi PORTB, PB3
	cbi PORTB, PB2

	cbi PORTD, PD5
	cbi PORTD, PD6

	rcall Retardo
	rcall Reset
	ret

Alien:
	cbi PORTD, PD4
	cbi PORTD, PD7

	rcall Retardo
	rcall Reset

	cbi PORTB, PB2


	cbi PORTD, PD4
	cbi PORTD, PD7
	cbi PORTD, PD2
	cbi PORTB, PB1

	rcall Retardo
	rcall Reset

	cbi PORTB, PB3

	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7
	cbi PORTB, PB0
	cbi PORTB, PB1


	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB3
	cbi PORTB, PB2

	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7
	cbi PORTB, PB0
	cbi PORTB, PB1

	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4

	cbi PORTD, PD2
	cbi PORTD, PD3
	
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTB, PB0
	cbi PORTB, PB1

	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4
	cbi PORTB, PB2

	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7


	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4
	cbi PORTB, PB3

	cbi PORTD, PD4
	cbi PORTD, PD7


	rcall Retardo
	rcall Reset
	
	cbi PORTB, PB4
	cbi PORTB, PB3
	cbi PORTB, PB2

	cbi PORTD, PD4
	cbi PORTD, PD7

	rcall Retardo
	rcall Reset
	
	ret

Retardo:
    sbis TIFR1, TOV1
    rjmp Retardo

    ldi r16, (1<<TOV1)  
    out TIFR1, r16   

    ldi r16, HIGH(65500)
    sts TCNT1H, r16
    ldi r16, LOW(65500)
    sts TCNT1L, r16

    ret

Reset:
	;Inicializar los pines en 1 
	sbi PORTD, PD2
	sbi PORTD, PD3
	sbi PORTD, PD4
	sbi PORTD, PD5
	sbi PORTD, PD6
	sbi PORTD, PD7
	sbi PORTB, PB0
	sbi PORTB, PB1

	sbi PORTB, PB2
	sbi PORTB, PB3
	sbi PORTB, PB4
	ret
