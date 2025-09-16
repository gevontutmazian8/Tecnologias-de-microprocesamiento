; PROYECTO: Punzonadora con cinta transportadora
; Versión en ensamblador AVR para ATmega328P
; Micro: ATmega328P
; Reloj: 16 MHz

.include "m328Pdef.inc"
.equ F_CPU = 16000000

; ===== Definiciones de estados =====
.equ ESPERA = 0
.equ CINTA_AVANCE = 1
.equ CINTA_PAUSA = 2
.equ POSICIONADO = 3
.equ PUNZON_BAJANDO = 4
.equ PUNZON_MANTENIENDO = 5
.equ PUNZON_SUBIENDO = 6
.equ DESCARGA = 7
.equ FIN = 8

; ===== Pines =====
; Motores / punzón
.equ CINTA_IN1 = PD6
.equ CINTA_IN2 = PB1
.equ PUNZON_IN1 = PB2
.equ PUNZON_IN2 = PB3

; LEDs (puerto C, bits 0-5)
.equ LED_LIGERA = PC0
.equ LED_MEDIA = PC1
.equ LED_PESADA = PC2
.equ LED_ESPERA = PC3
.equ LED_FUNCIONANDO = PC4
.equ LED_FIN = PC5

; Botones
.equ BTN_INICIO = PD2

; Registros de uso general
.def estado = r16
.def tipo_carga = r17
.def contador_timer = r18
.def temp = r19
.def usart_data = r20
.def msj_data = r21

; ===== INICIALIZACIÓN Y VECTORES DE INTERRUPCIÓN =====
.org 0x0000
rjmp RESET

.org 0x0014
rjmp TIM1_COMPA_ISR

.org 0x002A
rjmp USART_RX_ISR

RESET:
; Configurar Stack Pointer
ldi temp, high(RAMEND)
out SPH, temp
ldi temp, low(RAMEND)
out SPL, temp

; Configurar puertos como salida para motores y LEDs
sbi DDRD, CINTA_IN1
sbi DDRB, CINTA_IN2
sbi DDRB, PUNZON_IN1
sbi DDRB, PUNZON_IN2

sbi DDRC, LED_LIGERA
sbi DDRC, LED_MEDIA
sbi DDRC, LED_PESADA
sbi DDRC, LED_ESPERA
sbi DDRC, LED_FUNCIONANDO
sbi DDRC, LED_FIN

; Limpiar todos los puertos de salida
clr temp
out PORTB, temp
out PORTC, temp
out PORTD, temp

; Configurar pines de entrada
cbi DDRD, BTN_INICIO
sbi PORTD, BTN_INICIO ; Pull-up

; Configurar USART
ldi temp, high(103)
sts UBRR0H, temp
ldi temp, low(103)
sts UBRR0L, temp
ldi temp, (1<<RXEN0)|(1<<TXEN0)|(1<<RXCIE0)
sts UCSR0B, temp
ldi temp, (1<<UCSZ01)|(1<<UCSZ00)
sts UCSR0C, temp

; Configurar Timer1
ldi temp, (1<<CS12)
sts TCCR1B, temp
ldi temp, high(62500-1)
sts OCR1AH, temp
ldi temp, low(62500-1)
sts OCR1AL, temp

sei

; Inicializar variables de estado y carga
ldi estado, ESPERA
clr tipo_carga ; 0=ninguna, 1=ligera, 2=media, 3=pesada

sbi PORTC, LED_ESPERA
rcall TX_ESPERA
rjmp MAIN_LOOP

; ===== BUCLE PRINCIPAL (MÁQUINA DE ESTADOS) =====
MAIN_LOOP:
cpi estado, ESPERA
brne CHECK_CINTA_AVANCE
rjmp ESPERA_STATE
CHECK_CINTA_AVANCE:
cpi estado, CINTA_AVANCE
brne CHECK_CINTA_PAUSA
rjmp CINTA_AVANCE_STATE
CHECK_CINTA_PAUSA:
cpi estado, CINTA_PAUSA
brne CHECK_POSICIONADO
rjmp CINTA_PAUSA_STATE
CHECK_POSICIONADO:
cpi estado, POSICIONADO
brne CHECK_PUNZON_BAJANDO
rjmp POSICIONADO_STATE
CHECK_PUNZON_BAJANDO:
cpi estado, PUNZON_BAJANDO
brne CHECK_PUNZON_MANTENIENDO
rjmp PUNZON_BAJANDO_STATE
CHECK_PUNZON_MANTENIENDO:
cpi estado, PUNZON_MANTENIENDO
brne CHECK_PUNZON_SUBIENDO
rjmp PUNZON_MANTENIENDO_STATE
CHECK_PUNZON_SUBIENDO:
cpi estado, PUNZON_SUBIENDO
brne CHECK_DESCARGA
rjmp PUNZON_SUBIENDO_STATE
CHECK_DESCARGA:
cpi estado, DESCARGA
brne CHECK_FIN
rjmp DESCARGA_STATE
CHECK_FIN:
cpi estado, FIN
brne MAIN_LOOP
rjmp FIN_STATE


ESPERA_STATE:
; Se mantiene en este estado hasta recibir un comando de inicio
; La lógica del pulsador físico o USART se maneja en las interrupciones
sbis PIND, BTN_INICIO
rjmp START_BUTTON_PRESS
rjmp MAIN_LOOP

START_BUTTON_PRESS:
ldi estado, CINTA_AVANCE
rcall TX_ALIMENTACION
sbi PORTC, LED_FUNCIONANDO
cbi PORTC, LED_ESPERA
rjmp MAIN_LOOP

CINTA_AVANCE_STATE:
; Inicia el avance de la cinta con el tiempo de la carga
cpi tipo_carga, 1
brne ALIM_MEDIA_STATE
ldi contador_timer, 3 ; Carga ligera: 3s
rjmp START_CINTA_TIMER

ALIM_MEDIA_STATE:
cpi tipo_carga, 2
brne ALIM_PESADA_STATE
ldi contador_timer, 4 ; Carga media: 4s
rjmp START_CINTA_TIMER

ALIM_PESADA_STATE:
ldi contador_timer, 5 ; Carga pesada: 5s

START_CINTA_TIMER:
sbi PORTD, CINTA_IN1
cbi PORTB, CINTA_IN2
; sbi TIMSK1, OCIE1A
lds temp, TIMSK1
ori temp, (1<<OCIE1A)
sts TIMSK1, temp
rjmp MAIN_LOOP

CINTA_PAUSA_STATE:
; Inicia la pausa de la cinta con el tiempo de la carga
cpi tipo_carga, 1
brne PAUSA_MEDIA_STATE
ldi contador_timer, 2 ; Carga ligera: 2s
rjmp START_PAUSA_TIMER

PAUSA_MEDIA_STATE:
cpi tipo_carga, 2
brne PAUSA_PESADA_STATE
ldi contador_timer, 2 ; Carga media: 2s
rjmp START_PAUSA_TIMER

PAUSA_PESADA_STATE:
ldi contador_timer, 3 ; Carga pesada: 3s

START_PAUSA_TIMER:
cbi PORTD, CINTA_IN1
cbi PORTB, CINTA_IN2
; sbi TIMSK1, OCIE1A
lds temp, TIMSK1
ori temp, (1<<OCIE1A)
sts TIMSK1, temp
rjmp MAIN_LOOP

POSICIONADO_STATE:
; Espera el siguiente comando o fin del ciclo
rcall TX_POSICIONADO
; Asumimos que el punzonado inicia automáticamente
ldi estado, PUNZON_BAJANDO
rjmp MAIN_LOOP

PUNZON_BAJANDO_STATE:
sbi PORTB, PUNZON_IN1
cbi PORTB, PUNZON_IN2
ldi contador_timer, 1 ; 1s de descenso
; sbi TIMSK1, OCIE1A
lds temp, TIMSK1
ori temp, (1<<OCIE1A)
sts TIMSK1, temp
rcall TX_PUNZONADO
rjmp MAIN_LOOP

PUNZON_MANTENIENDO_STATE:
cbi PORTB, PUNZON_IN1
cbi PORTB, PUNZON_IN2
cpi tipo_carga, 1
brne MANTENIENDO_MEDIA_STATE
ldi contador_timer, 2 ; Carga ligera: 2s
rjmp START_PUNZON_TIMER

MANTENIENDO_MEDIA_STATE:
cpi tipo_carga, 2
brne MANTENIENDO_PESADA_STATE
ldi contador_timer, 3 ; Carga media: 3s
rjmp START_PUNZON_TIMER

MANTENIENDO_PESADA_STATE:
ldi contador_timer, 4 ; Carga pesada: 4s

START_PUNZON_TIMER:
; sbi TIMSK1, OCIE1A
lds temp, TIMSK1
ori temp, (1<<OCIE1A)
sts TIMSK1, temp
rjmp MAIN_LOOP

PUNZON_SUBIENDO_STATE:
cbi PORTB, PUNZON_IN1
sbi PORTB, PUNZON_IN2
ldi contador_timer, 1 ; 1s de ascenso
; sbi TIMSK1, OCIE1A
lds temp, TIMSK1
ori temp, (1<<OCIE1A)
sts TIMSK1, temp
rjmp MAIN_LOOP

DESCARGA_STATE:
; Inicia la descarga de la pieza
sbi PORTD, CINTA_IN1
cbi PORTB, CINTA_IN2
cpi tipo_carga, 1
brne DESC_MEDIA_STATE
ldi contador_timer, 3 ; Carga ligera: 3s
rjmp START_DESCARGA_TIMER

DESC_MEDIA_STATE:
cpi tipo_carga, 2
brne DESC_PESADA_STATE
ldi contador_timer, 4 ; Carga media: 4s
rjmp START_DESCARGA_TIMER

DESC_PESADA_STATE:
ldi contador_timer, 5 ; Carga pesada: 5s

START_DESCARGA_TIMER:
; sbi TIMSK1, OCIE1A
lds temp, TIMSK1
ori temp, (1<<OCIE1A)
sts TIMSK1, temp
rcall TX_DESCARGA
rjmp MAIN_LOOP

FIN_STATE:
cbi PORTD, CINTA_IN1
cbi PORTB, CINTA_IN2
cbi PORTB, PUNZON_IN1
cbi PORTB, PUNZON_IN2
cbi PORTC, LED_FUNCIONANDO
sbi PORTC, LED_FIN
rcall TX_FIN
ldi estado, ESPERA
rjmp MAIN_LOOP

; ===== SUBRUTINAS DE COMUNICACIÓN USART =====
TX_ESPERA:
ldi usart_data, 'E'
rcall USART_SEND_CHAR
ldi usart_data, 'S'
rcall USART_SEND_CHAR
ldi usart_data, 'P'
rcall USART_SEND_CHAR
ldi usart_data, 'E'
rcall USART_SEND_CHAR
ldi usart_data, 'R'
rcall USART_SEND_CHAR
ldi usart_data, 'A'
rcall USART_SEND_CHAR
ldi usart_data, 0x0A
rcall USART_SEND_CHAR
ret

TX_ALIMENTACION:
ldi usart_data, 'A'
rcall USART_SEND_CHAR
ldi usart_data, 'L'
rcall USART_SEND_CHAR
ldi usart_data, 'I'
rcall USART_SEND_CHAR
ldi usart_data, 'M'
rcall USART_SEND_CHAR
ldi usart_data, 0x0A
rcall USART_SEND_CHAR
ret

TX_POSICIONADO:
ldi usart_data, 'P'
rcall USART_SEND_CHAR
ldi usart_data, 'O'
rcall USART_SEND_CHAR
ldi usart_data, 'S'
rcall USART_SEND_CHAR
ldi usart_data, 'I'
rcall USART_SEND_CHAR
ldi usart_data, 'C'
rcall USART_SEND_CHAR
ldi usart_data, 'I'
rcall USART_SEND_CHAR
ldi usart_data, 'O'
rcall USART_SEND_CHAR
ldi usart_data, 'N'
rcall USART_SEND_CHAR
ldi usart_data, 'A'
rcall USART_SEND_CHAR
ldi usart_data, 'D'
rcall USART_SEND_CHAR
ldi usart_data, 'O'
rcall USART_SEND_CHAR
ldi usart_data, 0x0A
rcall USART_SEND_CHAR
ret

TX_PUNZONADO:
ldi usart_data, 'P'
rcall USART_SEND_CHAR
ldi usart_data, 'U'
rcall USART_SEND_CHAR
ldi usart_data, 'N'
rcall USART_SEND_CHAR
ldi usart_data, 'Z'
rcall USART_SEND_CHAR
ldi usart_data, 'O'
rcall USART_SEND_CHAR
ldi usart_data, 'N'
rcall USART_SEND_CHAR
ldi usart_data, 'A'
rcall USART_SEND_CHAR
ldi usart_data, 'D'
rcall USART_SEND_CHAR
ldi usart_data, 'O'
rcall USART_SEND_CHAR
ldi usart_data, 0x0A
rcall USART_SEND_CHAR
ret

TX_DESCARGA:
ldi usart_data, 'D'
rcall USART_SEND_CHAR
ldi usart_data, 'E'
rcall USART_SEND_CHAR
ldi usart_data, 'S'
rcall USART_SEND_CHAR
ldi usart_data, 'C'
rcall USART_SEND_CHAR
ldi usart_data, 'A'
rcall USART_SEND_CHAR
ldi usart_data, 'R'
rcall USART_SEND_CHAR
ldi usart_data, 'G'
rcall USART_SEND_CHAR
ldi usart_data, 'A'
rcall USART_SEND_CHAR
ldi usart_data, 0x0A
rcall USART_SEND_CHAR
ret

TX_FIN:
ldi usart_data, 'F'
rcall USART_SEND_CHAR
ldi usart_data, 'I'
rcall USART_SEND_CHAR
ldi usart_data, 'N'
rcall USART_SEND_CHAR
ldi usart_data, 0x0A
rcall USART_SEND_CHAR
ret

USART_SEND_CHAR:
lds temp, UCSR0A
sbrs temp, UDRE0
rjmp USART_SEND_CHAR
sts UDR0, usart_data
ret

; ===== INTERRUPCIONES =====
TIM1_COMPA_ISR:
dec contador_timer
brne TIM1_EXIT

; El contador llegó a cero, cambiar de estado
; cbi TIMSK1, OCIE1A
lds temp, TIMSK1
andi temp, ~(1<<OCIE1A)
sts TIMSK1, temp

; Lógica para el siguiente estado
cpi estado, CINTA_AVANCE
breq ALIMENTACION_COMPLETADA

cpi estado, CINTA_PAUSA
breq POSICIONADO_ENTRADA

cpi estado, PUNZON_BAJANDO
breq PUNZON_MANTENIENDO_ENTRADA

cpi estado, PUNZON_MANTENIENDO
breq PUNZON_SUBIENDO_ENTRADA

cpi estado, PUNZON_SUBIENDO
breq DESCARGA_ENTRADA

cpi estado, DESCARGA
breq FIN_ENTRADA

rjmp TIM1_EXIT

ALIMENTACION_COMPLETADA:
ldi estado, CINTA_PAUSA
rjmp MAIN_LOOP

POSICIONADO_ENTRADA:
ldi estado, POSICIONADO
rjmp MAIN_LOOP

PUNZON_MANTENIENDO_ENTRADA:
ldi estado, PUNZON_MANTENIENDO
rjmp MAIN_LOOP

PUNZON_SUBIENDO_ENTRADA:
ldi estado, PUNZON_SUBIENDO
rjmp MAIN_LOOP

DESCARGA_ENTRADA:
ldi estado, DESCARGA
rjmp MAIN_LOOP

FIN_ENTRADA:
ldi estado, FIN
rjmp MAIN_LOOP

TIM1_EXIT:
reti

USART_RX_ISR:
lds usart_data, UDR0
cpi usart_data, 'A'
brne CHECK_CARGA
ldi estado, CINTA_AVANCE
rcall TX_ALIMENTACION
sbi PORTC, LED_FUNCIONANDO
cbi PORTC, LED_ESPERA
reti

CHECK_CARGA:
cpi usart_data, '1'
breq CARGA_LIGERA
cpi usart_data, '2'
breq CARGA_MEDIA
cpi usart_data, '3'
breq CARGA_PESADA
reti

CARGA_LIGERA:
ldi tipo_carga, 1
cbi PORTC, LED_MEDIA
cbi PORTC, LED_PESADA
sbi PORTC, LED_LIGERA
reti

CARGA_MEDIA:
ldi tipo_carga, 2
cbi PORTC, LED_LIGERA
cbi PORTC, LED_PESADA
sbi PORTC, LED_MEDIA
reti

CARGA_PESADA:
ldi tipo_carga, 3
cbi PORTC, LED_LIGERA
cbi PORTC, LED_MEDIA
sbi PORTC, LED_PESADA
reti