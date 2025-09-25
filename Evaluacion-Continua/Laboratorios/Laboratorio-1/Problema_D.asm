.include "m328pdef.inc"


.cseg
.org 0x00

.equ F_CPU = 16000000
.equ baud = 9600
.equ bps = (F_CPU/16/baud) -1

.def temp = r16

ldi temp,LOW(bps)
ldi r17,HIGH(bps)

sts UBRR0L, temp
sts UBRR0H, r17
ldi temp,((1<<RXEN0)|(1<<TXEN0))
sts UCSR0B, temp



;Inicializamos el Stack Pointer
ldi temp, high(RAMEND)
out SPH, temp
ldi temp, low(RAMEND)
out SPL, temp

;Configuración del temporizador
ldi temp, 0x00
sts TCCR1A, temp
ldi temp, (1<<CS12)|(1<<CS10)
sts TCCR1B, temp
ldi temp, 0
sts TCCR1C, temp
ldi temp, 0
sts TIMSK1, temp

;Los reles tienen un retardo maximo de 15ms por lo que, para poder trabajar con ellos debemos de agregar un retardo igual o mayor.
;La frecuencia despues del prescaler es de 15625 Hz, que equivale a 6.4x10^-5 S por ciclo, para llegar a los 15 mS necesitamos 235 Ciclos
;En un registro de 16 bits, necesitamos cargarlo con 
;Inicialización del contador
ldi temp, HIGH(65000)
sts TCNT1H, temp
ldi temp, LOW(65000)
sts TCNT1L, temp

;Seteamos los pines de salida
sbi DDRD, PD2
sbi DDRD, PD3

sbi DDRD, PD4
sbi DDRD, PD5

sbi DDRD, PD6
sbi DDRD, PD7

sbi PORTD, PD3

ldi temp, LOW(bps)
ldi r17, HIGH(bps)


Bajar:
	sbi PORTD, PD2
	ldi temp, 50
	L1:
		rcall Retardo
		dec temp
		brne L1
	cbi PORTD, PD2
	ret

Subir:
	sbi PORTD, PD3
	ldi temp, 50
	L2:
		rcall Retardo
		dec temp
		brne L2
	sbi PORTD, PD2
	rcall Retardo
	cbi PORTD, PD3
	ret 


Abajo:
	sbi PORTD, PD4
	rcall Retardo

	ret

Arriba:
	sbi PORTD, PD5
	rcall Retardo

	ret

Derecha:
	sbi PORTD, PD6
	rcall Retardo

	ret

Izquierda:
	sbi PORTD, PD7
	rcall Retardo

	ret

Limpiar:
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7
	ret



Cruz:
	rcall Bajar
	rcall Abajo

	rcall RetardoT
	rcall Limpiar

	rcall Arriba
	
	rcall RetardoC
	rcall Limpiar

	rcall Derecha

	rcall RetardoC1
	rcall Limpiar

	rcall Izquierda
	
	rcall RetardoC1
	rcall RetardoC1
	rcall Limpiar

	rcall Subir

	rcall RetardoC1
	rcall Limpiar

	ret

Triangulo:

	rcall Bajar

	rcall Abajo
	rcall Izquierda

	rcall RetardoT
	rcall Limpiar

	rcall Derecha

	rcall RetardoT1
	rcall Limpiar
	
	rcall Arriba
	rcall Izquierda

	rcall RetardoT2
	rcall Limpiar
	rcall Subir
	rcall Retardo
	rcall Subir

	ret

Circulo:
	ldi r18, 199
	ldi r21, 0
	clr r1

	
	L4:
		; Cargar el puntero de la tabla 1 en Z
		LDI ZL, LOW(DX * 2)
		LDI ZH, HIGH(DX * 2)

		add ZL, r21
		adc ZH, r1
		clr r1

		
		lpm r19, Z ;DX

		LDI ZL, LOW(DY * 2)
		LDI ZH, HIGH(DY * 2)

		add ZL, r21
		adc ZH, r1
		clr r1
		
		lpm r20, Z ;DY

		ldi r17, 8
		L3:
			lsr r19
			brhc Ly
			rcall Derecha
			rcall Retardo
			rcall Limpiar
			

			Ly:
			lsr r20
			brhc Lf

			rcall Abajo
			rcall Retardo
			rcall Limpiar

			Lf:
			dec r17
			brne L3

		dec r18 ;Decrementa la cantidad de par de puntos
		inc r21 ;Incrementa el indice
		brne L4
	ret

Retardo:
    sbis TIFR1, TOV1
    rjmp Retardo

    ldi temp, (1<<TOV1)  
    out TIFR1, temp   

    ldi temp, HIGH(65000)
    sts TCNT1H, temp
    ldi temp, LOW(65000)
    sts TCNT1L, temp
    ret

RetardoT:
	ldi temp, HIGH(40000)
    sts TCNT1H, temp
    ldi temp, LOW(40000)
    sts TCNT1L, temp
	rcall Retardo
	ret

RetardoT1:
	ldi temp, HIGH(25423)
    sts TCNT1H, temp
    ldi temp, LOW(25423)
    sts TCNT1L, temp
	rcall Retardo
	ret

RetardoT2:
	ldi temp, HIGH(44465)
    sts TCNT1H, temp
    ldi temp, LOW(44465)
    sts TCNT1L, temp
	rcall Retardo
	ret

RetardoP:
	ldi temp, HIGH(0)
    sts TCNT1H, temp
    ldi temp, LOW(0)
    sts TCNT1L, temp
	rcall Retardo
	ret

RetardoC:
	ldi temp, HIGH(50000)
    sts TCNT1H, temp
    ldi temp, LOW(50000)
    sts TCNT1L, temp
	rcall Retardo
	ret

RetardoC1:
	ldi temp, HIGH(60000)
    sts TCNT1H, temp
    ldi temp, LOW(60000)
    sts TCNT1L, temp
	rcall Retardo
	ret
wait:
    rcall getc

    cpi temp, '1'
    breq EjecutarTriangulo
    

	cpi temp, '2'
    breq EjecutarCruz
    
	cpi temp, '3'
    breq EjecutarCirculo
    
	cpi temp, 'T'
	breq EjecutarTodo
	
	cpi temp, '4'
    breq MArriba
    
	cpi temp, '5'
    breq MAbajo

	cpi temp, '6'
    breq MDerecha
    
	cpi temp, '7'
    breq MIzquierda
    rjmp wait

EjecutarTriangulo:
	ldi temp, 'T'
	rcall putc
	ldi temp, 'r'
	rcall putc
    rcall Triangulo
    rjmp wait

EjecutarCruz:

	ldi temp, 'C'
	rcall putc
	ldi temp, 'r'

	rcall putc
    rcall Cruz
    rjmp wait

EjecutarCirculo:

	ldi temp, 'C'
	rcall putc
	ldi temp, 'O'

	rcall putc
    rcall Circulo
    rjmp wait

EjecutarTodo:
    rcall Triangulo
	rcall Derecha
	rcall RetardoP
	rcall Limpiar

	rcall Cruz
	rcall Derecha
	rcall RetardoP
	rcall Limpiar

	rcall Circulo
	rcall Derecha
	rcall RetardoP
	rcall Limpiar

    rjmp wait

MDerecha:
	rcall Derecha
	rcall RetardoP
	rcall Limpiar
	rjmp wait

MIzquierda:
	rcall Izquierda
	rcall RetardoP
	rcall Limpiar
	rjmp wait

MArriba:
	rcall Arriba
	rcall RetardoP
	rcall Limpiar
	rjmp wait

MAbajo:
	rcall Abajo
	rcall RetardoP
	rcall Limpiar
	rjmp wait


putc:
	lds r17, UCSR0A
	sbrs r17, UDRE0
	rjmp putc
	sts UDR0, temp 
	ret

getc:
	lds r17, UCSR0A
	sbrs r17, RXC0 
	rjmp getc
	lds temp, UDR0 ;
	ret



;Utilizacion de LUT para almacenar 200 datos de movimiento en x e y (Almacenadas en 0 y 1 pero pasadas a decimal por poloijidad) 
DX:
	.db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 128, 0, 0, 0, 128, 0, 0, 8, 0, 0, 8, 0, 0, 32, 0, 2, 0, 0, 64, 0, 32, 0, 16, 0, 16, 0, 32, 0, 64, 1, 0, 4, 0, 32, 1, 0, 16, 1, 0, 16, 2, 0, 32, 4
	.db 0, 128, 32, 4, 1, 0, 64, 16, 4, 2, 0, 128, 64, 32, 16, 8, 4, 2, 2, 1, 1, 0, 128, 128, 128, 128, 128, 128, 128, 128, 129, 1, 2, 2, 4, 4, 8, 16, 16, 32, 64, 129, 2, 4, 8, 32, 64, 129, 4, 8, 16, 64, 130
	.db 4, 16, 32, 130, 4, 16, 64, 130, 8, 32, 130, 8, 32, 129, 4, 32, 130, 8, 32, 130, 8, 33, 4, 16, 66, 8, 33, 4, 16, 130, 8, 65, 8, 33, 4, 32, 132, 16, 130, 16, 66, 8, 66, 8, 66, 8, 66, 8, 66, 8, 66, 8, 66
	.db 16, 66, 16, 130, 16, 132, 32, 132, 33, 8, 65, 8, 66, 16, 130, 16, 132, 33, 8, 65, 8, 66, 16, 132, 33, 4, 33, 8, 66, 16, 132, 33

DY:
	.db 4, 33, 8, 66, 16, 132, 32, 132, 33, 8, 66, 16, 130, 16, 132, 33, 8, 65, 8, 66, 16, 130, 16, 132, 33, 4, 33, 8, 65, 8, 66, 8, 66, 16, 66, 16, 66, 16, 66, 16, 66, 16, 66, 16, 66, 8, 65, 8, 33, 4, 32, 132
	.db 16, 130, 16, 65, 8, 32, 132, 16, 66, 8, 32, 132, 16, 65, 4, 16, 65, 4, 32, 129, 4, 16, 65, 4, 16, 65, 2, 8, 32, 65, 4, 8, 32, 65, 2, 8, 16, 32, 129, 2, 4, 16, 32, 64, 129, 2, 4, 8, 8, 16, 32, 32, 64, 64
	.db 128, 129, 1, 1, 1, 1, 1, 1, 1, 1, 0, 128, 128, 64, 64, 32, 16, 8, 4, 2, 1, 0, 64, 32, 8, 2, 0, 128, 32, 4, 1, 0, 32, 4, 0, 64, 8, 0, 128, 8, 0, 128, 4, 0, 32, 0, 128, 2, 0, 4, 0, 8, 0, 8, 0, 4, 0, 2, 0
	.db 0, 64, 0, 4, 0, 0, 16, 0, 0, 16, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1