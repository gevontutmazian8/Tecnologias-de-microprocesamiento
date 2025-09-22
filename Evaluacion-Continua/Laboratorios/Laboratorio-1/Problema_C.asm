.include "m328pdef.inc"

.cseg
.org 0x0000

;Inicializamos el Stack Pointer
ldi r16, high(RAMEND)
out SPH, r16
ldi r16, low(RAMEND)
out SPL, r16


;Seteamos los pines de salida
ldi r16, 0b11110000
out DDRB, r16

ldi r16, 0b00001111
out DDRD, r16

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


main: ; Porgrama pricipal
	ldi r16, 255
	ldi r30, low(Tabla * 2)
    ldi r31, high(Tabla * 2)

	Bucle:		
		lpm r17, Z+ ; r17 guardara los valores del LUT

		rcall Imprimir
		rcall Retardo

		dec r16
		brne Bucle  ;Se incia de 0
	rjmp main ;Se repite el bucle

Imprimir:
	mov r18, r17
	andi r18, 0b11110000
	out PORTB, r18

	mov r18, r17
	andi r18, 0b00001111
	out PORTD, r18
	ret

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
	
.org 0x0100 ;Utilizacion de LUT para almacenar todos los datos
Tabla: 
	.db 73,74,75,75,74,73,73,73,73,72,71,69,68,67,67,67 ;16
	.db 68,68,67,65,62,61,59,57,56,55,55,54,54,54,55,55 ;16
	.db	55,55,55,55,54,53,51,50,49,49,52,61,77,101,132  ;15
	.db 169,207,238,255,254,234,198,154,109,68,37,17,5  ;13
	.db 0,1,6,13,20,28,36,45,52,57,61,64,65,66,67,68,68 ;17
	.db 69,70,71,71,71,71,71,71,71,71,72,72,72,73,73,74 ;16
	.db 75,75,76,77,78,79,80,81,82,83,84,86,88,91,93,96 ;16
	.db 98,100,102,104,107,109,112,115,118,121,123,125  ;12
	.db 126,127,127,127,127,127,126,125,124,121,119,116 ;12
	.db 113,109,105,102,98,95,92,89,87,84,81,79,77,76,75;15
	.db 74,73,72,70,69,68,67,67,67,68,68,68,69,69,69,69 ;16
	.db 69,69,69,70,71,72,73,73,74,74,75,75,75,75,75,75 ;16
	.db 74,74,73,73,73,73,72,72,72,71,71,71,71,71,71,71 ;16
	.db 70,70,70,69,69,69,69,69,70,70,70,69,68,68,67,67 ;16
	.db 67,67,66,66,66,65,65,65,65,65,65,65,65,64,64,63 ;16
	.db 63,64,64,65,65,65,65,65,65,65,64,64,64,64,64,64 ;16
	.db 64,64,65,65,65,66,67,68,69,71,72,73				;12 = 256
