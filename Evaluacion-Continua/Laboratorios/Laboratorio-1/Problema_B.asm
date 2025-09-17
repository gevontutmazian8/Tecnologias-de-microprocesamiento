; ====================================================
; MATRIZ LED 8x8 CON SCROLL DE TEXTO + UART
; MCU: ATmega328P @ 16MHz
; ====================================================

.include "m328pdef.inc"

; --- Constantes ---
.equ F_CPU   = 16000000
.equ BAUD    = 9600
.equ MYUBRR  = F_CPU/16/BAUD-1
.equ MSG_LEN = 14

; --- Registros temporales ---
.def temp   = r16
.def temp2  = r17
.def row    = r18
.def col    = r19
.def ch     = r20
.def speed  = r21

; --- Variables en RAM ---
.dseg
displayBuffer: .byte 8     ; buffer de 8 columnas (1 byte = 8 filas)

; --- Código ---
.cseg
.org 0x0000
    rjmp init

; ====================================================
; TABLAS EN FLASH
; ====================================================

; --- Fuente 5x8 (solo letras usadas: WELCOMEH) ---
FONT_TABLE:
; Espacio
.db 0x00,0x00,0x00,0x00,0x00
; W
.db 0x7F,0x20,0x08,0x20,0x7F
; E
.db 0x7F,0x49,0x49,0x49,0x41
; L
.db 0x7F,0x40,0x40,0x40,0x40
; C
.db 0x3E,0x41,0x41,0x41,0x22
; O
.db 0x3E,0x41,0x41,0x41,0x3E
; M
.db 0x7F,0x02,0x04,0x02,0x7F
; H
.db 0x7F,0x08,0x08,0x08,0x7F

; --- Imagen corazón ---
HEART:
.db 0x00,0x66,0xFF,0xFF,0xFF,0x7E,0x3C,0x18

; --- Imagen smile ---
SMILE:
.db 0x3C,0x42,0x81,0xA5,0x81,0x99,0x42,0x3C

; --- Mensaje ---
MESSAGE: 
.db ' ', 'W','E','L','C','O','M','E',' ','H','O','M','E',' '

; ====================================================
; INIT
; ====================================================
init:
    ; Filas = PORTD salida
    ldi temp, 0xFF
    out DDRD, temp
    ; Cols = PORTB (PB2..PB5) y PORTC (PC0..PC3) salida
    ldi temp, 0x3C
    out DDRB, temp
    ldi temp, 0x0F
    out DDRC, temp

    ; UART init
    ldi temp, HIGH(MYUBRR)
    out UBRR0H, temp
    ldi temp, LOW(MYUBRR)
    out UBRR0L, temp
    ldi temp, (1<<TXEN0)|(1<<RXEN0)
    out UCSR0B, temp
    ldi temp, (1<<UCSZ01)|(1<<UCSZ00)
    out UCSR0C, temp

    ; Velocidad inicial
    ldi speed, 80

main_loop:
    rcall menu
    rjmp main_loop

; ====================================================
; FUNCIONES
; ====================================================

; --- UART TX ---
uart_tx:
    sbis UCSR0A, UDRE0
    rjmp uart_tx
    out UDR0, temp
    ret

; --- UART RX ---
uart_rx:
    sbis UCSR0A, RXC0
    rjmp uart_rx
    in temp, UDR0
    ret

; --- Print string en Flash ---
uart_print:
    lpm temp, Z+
    tst temp
    breq uart_print_end
    rcall uart_tx
    rjmp uart_print
uart_print_end:
    ret

; ====================================================
; MENU UART
; ====================================================
menu:
    ldi ZH, high(menu_text<<1)
    ldi ZL, low(menu_text<<1)
    rcall uart_print

    rcall uart_rx    ; espera opción
    cpi temp,'1'
    breq opt_scroll
    cpi temp,'2'
    breq opt_heart
    cpi temp,'3'
    breq opt_smile
    cpi temp,'4'
    breq opt_speed
    rjmp menu

opt_scroll:
    rcall scroll_text
    ret

opt_heart:
    ldi ZH, high(HEART<<1)
    ldi ZL, low(HEART<<1)
    rcall draw_image
    rjmp menu

opt_smile:
    ldi ZH, high(SMILE<<1)
    ldi ZL, low(SMILE<<1)
    rcall draw_image
    rjmp menu

opt_speed:
    ; demo: fija velocidad en 100
    ldi speed, 100
    rjmp menu

; ====================================================
; MOSTRAR IMAGEN
; ====================================================
draw_image:
    ldi row,0
draw_img_loop:
    lpm temp, Z+
    sts displayBuffer+row, temp
    inc row
    cpi row,8
    brne draw_img_loop
    rcall refresh_display
    ret

; ====================================================
; REFRESCAR DISPLAY (multiplexado)
; ====================================================
refresh_display:
    ldi row,0
refresh_loop:
    ; apaga todo
    ldi temp,0xFF
    out PORTD,temp
    clr temp
    out PORTB,temp
    out PORTC,temp

    ; selecciona fila
    com temp
    out PORTD,temp

    ; carga datos de columna
    lds temp,displayBuffer+row
    out PORTB,temp   ; simplificado
    ; delay
    rcall delay_ms

    inc row
    cpi row,8
    brne refresh_loop
    ret

; ====================================================
; SCROLL DE TEXTO
; ====================================================
scroll_text:
    ; recorre caracteres del mensaje
    ldi YH, high(MESSAGE)
    ldi YL, low(MESSAGE)

    ldi temp2, MSG_LEN
scroll_char_loop:
    ld ch,Y+
    ; buscar caracter en FONT y cargar en buffer
    ; demo: solo pone letra W
    ldi ZH, high(FONT_TABLE<<1)
    ldi ZL, low(FONT_TABLE<<1)
    rcall draw_image
    rcall delay_ms
    dec temp2
    brne scroll_char_loop
    ret

; ====================================================
; DELAY ms (tosco)
; ====================================================
delay_ms:
    ldi temp,0xFF
d1: ldi temp2,0xFF
d2: dec temp2
    brne d2
    dec temp
    brne d1
    ret

; ====================================================
; TEXTOS DEL MENU
; ====================================================
menu_text:
.db 13,10,"--- Menu ---",13,10
.db "1. Scroll texto",13,10
.db "2. Corazon",13,10
.db "3. Cara feliz",13,10
.db "4. Ajustar velocidad",13,10,0
