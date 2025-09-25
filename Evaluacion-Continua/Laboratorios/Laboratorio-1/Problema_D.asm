.include "m328pdef.inc"


.cseg
.org 0x00

.equ F_CPU = 16000000
.equ baud = 9600
.equ bps = (F_CPU/16/baud) -1

.def temp = r16

; Configuración completa del UART
ldi temp, LOW(bps)
sts UBRR0L, temp
ldi temp, HIGH(bps)
sts UBRR0H, temp

; Habilitar TX y RX
ldi temp, (1<<RXEN0)|(1<<TXEN0)
sts UCSR0B, temp

; Configurar formato: 8-bit data, 1 stop bit, no parity
ldi temp, (1<<UCSZ01)|(1<<UCSZ00)
sts UCSR0C, temp

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


ldi temp, LOW(bps)
ldi r17, HIGH(bps)


main: 
	rcall wait

	rjmp main
Bajar:
	sbi PORTD, PD2
	rcall Retardo
	rcall Retardo
	rcall Retardo
	cbi PORTD, PD2
	ret

Subir:
	sbi PORTD, PD3
	rcall Retardo
	rcall Retardo
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

;PRIMER CUADRANTE
	rcall Bajar
    ldi r18, 100        ; Número de puntos
    ldi r21, 0          ; Índice inicial
    clr r1

Circulo_loop:
    ; Cargar DX
    LDI ZL, LOW(DX * 2)
    LDI ZH, HIGH(DX * 2)
    add ZL, r21
    adc ZH, r1
    lpm r19, Z          ; Cargar byte DX

    ; Cargar DY  
    LDI ZL, LOW(DY * 2)
    LDI ZH, HIGH(DY * 2)
    add ZL, r21
    adc ZH, r1
    lpm r20, Z          ; Cargar byte DY

    ; Procesar 8 bits de DX y DY
    ldi r17, 8
Procesar_bits:
    ; Procesar bit de DX (movimiento en X)
    lsr r19             ; Bit LSB ? Carry
    brcc no_derecha     ; Si Carry=0, no mover
    rcall Derecha       ; Si Carry=1, mover derecha
no_derecha:

    ; Procesar bit de DY (movimiento en Y)  
    lsr r20             ; Bit LSB ? Carry
    brcc no_abajo       ; Si Carry=0, no mover
    rcall Abajo         ; Si Carry=1, mover abajo
no_abajo:

    rcall Retardo       ; Pequeña pausa entre movimientos
    rcall Limpiar       ; Limpiar puertos

    dec r17
    brne Procesar_bits  ; Procesar los 8 bits

    ; Siguiente punto
    
    inc r21
    dec r18
	brne Circulo_loop


;--------------SEGUNDO CUADRANTE
	rcall Bajar
    ldi r18, 100        ; Número de puntos
    ldi r21, 0          ; Índice inicial
    clr r1

Circulo_loop1:
    ; Cargar DX
    LDI ZL, LOW(DX * 2)
    LDI ZH, HIGH(DX * 2)
    add ZL, r21
    adc ZH, r1
    lpm r19, Z          ; Cargar byte DX

    ; Cargar DY  
    LDI ZL, LOW(DY * 2)
    LDI ZH, HIGH(DY * 2)
    add ZL, r21
    adc ZH, r1
    lpm r20, Z          ; Cargar byte DY

    ; Procesar 8 bits de DX y DY
    ldi r17, 8
Procesar_bits1:
    ; Procesar bit de DX (movimiento en X)
    lsr r19             ; Bit LSB ? Carry
    brcc no_derecha1     ; Si Carry=0, no mover
    rcall Arriba       ; Si Carry=1, mover derecha
no_derecha1:

    ; Procesar bit de DY (movimiento en Y)  
    lsr r20             ; Bit LSB ? Carry
    brcc no_abajo1       ; Si Carry=0, no mover
    rcall Derecha         ; Si Carry=1, mover abajo
no_abajo1:

    rcall Retardo       ; Pequeña pausa entre movimientos
    rcall Limpiar       ; Limpiar puertos

    dec r17
    brne Procesar_bits1  ; Procesar los 8 bits

    ; Siguiente punto
    
    inc r21
    dec r18
	brne Circulo_loop1





;--------------TERCERO CUADRANTE
	rcall Bajar
    ldi r18, 100        ; Número de puntos
    ldi r21, 0          ; Índice inicial
    clr r1

Circulo_loop2:
    ; Cargar DX
    LDI ZL, LOW(DX * 2)
    LDI ZH, HIGH(DX * 2)
    add ZL, r21
    adc ZH, r1
    lpm r19, Z          ; Cargar byte DX

    ; Cargar DY  
    LDI ZL, LOW(DY * 2)
    LDI ZH, HIGH(DY * 2)
    add ZL, r21
    adc ZH, r1
    lpm r20, Z          ; Cargar byte DY

    ; Procesar 8 bits de DX y DY
    ldi r17, 8
Procesar_bits2:
    ; Procesar bit de DX (movimiento en X)
    lsr r19             ; Bit LSB ? Carry
    brcc no_derecha2     ; Si Carry=0, no mover
    rcall Izquierda       ; Si Carry=1, mover derecha
no_derecha2:

    ; Procesar bit de DY (movimiento en Y)  
    lsr r20             ; Bit LSB ? Carry
    brcc no_abajo2       ; Si Carry=0, no mover
    rcall Arriba         ; Si Carry=1, mover abajo
no_abajo2:

    rcall Retardo       ; Pequeña pausa entre movimientos
    rcall Limpiar       ; Limpiar puertos

    dec r17
    brne Procesar_bits2  ; Procesar los 8 bits

    ; Siguiente punto
    
    inc r21
    dec r18
	brne Circulo_loop2


;--------------CUARTO CUADRANTE
	rcall Limpiar 
	rcall Izquierda
	rcall Retardo
	rcall Retardo
	rcall Retardo
	rcall Retardo
	rcall Retardo
	rcall Retardo
	rcall Retardo
	rcall Limpiar 

	rcall Bajar
    ldi r18, 100        ; Número de puntos
    ldi r21, 0          ; Índice inicial
    clr r1

Circulo_loop3:
    ; Cargar DX
    LDI ZL, LOW(DX * 2)
    LDI ZH, HIGH(DX * 2)
    add ZL, r21
    adc ZH, r1
    lpm r19, Z          ; Cargar byte DX

    ; Cargar DY  
    LDI ZL, LOW(DY * 2)
    LDI ZH, HIGH(DY * 2)
    add ZL, r21
    adc ZH, r1
    lpm r20, Z          ; Cargar byte DY

    ; Procesar 8 bits de DX y DY
    ldi r17, 8
Procesar_bits3:
    ; Procesar bit de DX (movimiento en X)
    lsr r19             ; Bit LSB ? Carry
    brcc no_derecha3     ; Si Carry=0, no mover
    rcall Abajo       ; Si Carry=1, mover derecha
no_derecha3:

    ; Procesar bit de DY (movimiento en Y)  
    lsr r20             ; Bit LSB ? Carry
    brcc no_abajo3       ; Si Carry=0, no mover
    rcall Izquierda         ; Si Carry=1, mover abajo
no_abajo3:

    rcall Retardo       ; Pequeña pausa entre movimientos
    rcall Limpiar       ; Limpiar puertos

    dec r17
    brne Procesar_bits3  ; Procesar los 8 bits

    ; Siguiente punto
    
    inc r21
    dec r18
	brne Circulo_loop3

	rcall Limpiar 
	rcall Abajo
	rcall Retardo
	rcall Retardo
	rcall Retardo
	rcall Retardo
	rcall Subir
	rcall Limpiar

	

    ret

Retardo:
    sbis TIFR1, TOV1
    rjmp Retardo

    ldi temp, (1<<TOV1)  
    out TIFR1, temp   

    ldi temp, HIGH(65350)
    sts TCNT1H, temp
    ldi temp, LOW(65350)
    sts TCNT1L, temp
    ret

RetardoT:
	ldi temp, HIGH(43000)
    sts TCNT1H, temp
    ldi temp, LOW(43000)
    sts TCNT1L, temp
	rcall Retardo
	ret

RetardoT1:
	ldi temp, HIGH(25023)
    sts TCNT1H, temp
    ldi temp, LOW(25023)
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
	 .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 128, 0, 0, 0, 64, 0, 0, 4, 0, 0, 4, 0, 0, 8, 0, 0, 128, 0, 8, 0, 2, 0, 1, 0, 0, 128, 0, 128, 1, 0, 2, 0, 4, 0, 16, 0, 128, 2, 0, 16, 0, 128, 8, 0, 64, 4, 0, 64, 4, 0, 64, 8, 1, 0, 16, 2, 0, 64, 8, 1, 0, 32, 8, 1, 0, 32, 8, 1, 0, 64, 16, 2, 0, 128, 32, 8, 1, 0, 64, 16, 4, 1
DY:
	.db 0, 32, 8, 2, 0, 128, 16, 4, 1, 0, 64, 8, 2, 0, 128, 16, 4, 0, 128, 16, 4, 0, 128, 16, 2, 0, 64, 8, 0, 128, 16, 2, 0, 32, 2, 0, 32, 2, 0, 16, 1, 0, 8, 0, 64, 1, 0, 8, 0, 32, 0, 64, 0, 128, 1, 0, 1, 0, 0, 128, 0, 64, 0, 16, 0, 1, 0, 0, 16, 0, 0, 32, 0, 0, 32, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1