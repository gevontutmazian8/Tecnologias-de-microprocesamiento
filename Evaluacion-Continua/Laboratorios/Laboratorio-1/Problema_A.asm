; PROYECTO: Punzonadora con cinta transportadora
; Versión en ensamblador fiel al código en C
; Micro: ATmega328P
; Reloj: 16 MHz

.include "m328Pdef.inc"
.equ F_CPU = 16000000

; ===== Definiciones de estados =====
.equ ESPERA       = 0
.equ ALIMENTACION = 1
.equ POSICIONADO  = 2
.equ PUNZONADO    = 3
.equ DESCARGA     = 4
.equ FIN          = 5

; ===== Pines =====
; Motores / punzón
.equ CINTA_IN1   = 6   ; PD6
.equ CINTA_IN2   = 1   ; PB1
.equ PUNZON_IN1  = 2   ; PB2
.equ PUNZON_IN2  = 3   ; PB3

; LEDs (usamos A0‑A5 → puerto C, bits 0‑5)
.equ LED_LIGERA      = PC0
.equ LED_MEDIA       = PC1
.equ LED_PESADA      = PC2
.equ LED_ESPERA      = PC3
.equ LED_FUNCIONANDO = PC4
.equ LED_FIN         = PC5

; Botones
.equ BTN_INICIO = PD2
.equ BTN_CARGA  = PD7

; ===== Registros que vamos a usar =====
.def estado        = r16     ; guarda en qué estado está la máquina
.def tipoCarga     = r17     ; ligera / media / pesada

; Tiempos (van a tener los valores tipo unsigned long en C, acá uso lo + hi, 16 bits)
.def tAlimON_lo     = r20
.def tAlimON_hi     = r21
.def tAlimOFF_lo    = r22
.def tAlimOFF_hi    = r23
.def tPresion_lo    = r24
.def tPresion_hi    = r25
.def tDescarga_lo   = r26
.def tDescarga_hi   = r27

; Tiempo de inicio de un estado (t0)
.def t0_lo          = r28
.def t0_hi          = r29

; “Millis” sencillo: cuenta milisegundos
.def millis_lo      = r30
.def millis_hi      = r31

; Para el botón de selección de carga: recordamos el estado anterior
.dseg
lastState:
    .byte 1
.cseg

; ===== Vectores de interrupción =====
.org 0x0000
    rjmp RESET

.org TIMER0_OVF_vect
    rjmp ISR_Timer0_OVF

; (Podríamos usar interrupción RX de USART si queremos, no lo deﬁnimos aquí con ISR_RX_vect, usamos polling)

; ===== Reset / Setup inicial =====
RESET:
    ; Configurar pines

    ; Motores como salida
    sbi DDRD, CINTA_IN1
    sbi DDRB, CINTA_IN2
    sbi DDRB, PUNZON_IN1
    sbi DDRB, PUNZON_IN2

    ; LEDs como salida
    ldi r18, (1<<LED_LIGERA)|(1<<LED_MEDIA)|(1<<LED_PESADA)|(1<<LED_ESPERA)|(1<<LED_FUNCIONANDO)|(1<<LED_FIN)
    out DDRC, r18

    ; Botones como entrada con pull-up
    cbi DDRD, BTN_INICIO
    sbi PORTD, BTN_INICIO
    cbi DDRD, BTN_CARGA
    sbi PORTD, BTN_CARGA

    ; Estado inicial
    ldi tipoCarga, 1
    ldi estado, ESPERA

    ; Tiempos defecto (carga ligera)
    ldi tAlimON_lo,   low(3000)
    ldi tAlimON_hi,   high(3000)
    ldi tAlimOFF_lo,  low(2000)
    ldi tAlimOFF_hi,  high(2000)
    ldi tPresion_lo,  low(2000)
    ldi tPresion_hi,  high(2000)
    ldi tDescarga_lo, low(3000)
    ldi tDescarga_hi, high(3000)

    ; Poner millis = 0
    clr millis_lo
    clr millis_hi

    ; lastState inicial: HIGH (porque pull-up hace que esté en 1 cuando no se pulsa)
    ldi r18, 1
    sts lastState, r18

    ; Configurar Timer0 para contar milisegundos
    ; Prescaler /64 → overflow cada ~1.024 ms
    ldi r18, (1<<CS01)|(1<<CS00)
    out TCCR0B, r18
    ; Habilitamos la interrupción de desbordamiento
    ldi r18, (1<<TOIE0)
    out TIMSK0, r18

    sei ; habilitar interrupciones generales

    ; Inicializar USART a 9600 baudios
    rcall USART_init

    ; Mensaje inicial: “Sistema en ESPERA”
    ldi ZL, lo8(msg_Espera)
    ldi ZH, hi8(msg_Espera)
    rcall USART_sendString

main_loop:
    rcall leerEntradas
    rcall leerComandosUSART
    rcall maquinaDeEstados
    rjmp main_loop

; ===== ISR de Timer0 para incrementar millis =====
ISR_Timer0_OVF:
    lds r18, millis_lo
    inc r18
    sts millis_lo, r18
    brne .skip_hi_timer
    lds r18, millis_hi
    inc r18
    sts millis_hi, r18
.skip_hi_timer:
    reti

; ===== USART =====

USART_init:
    ; Configurar baudrate, frame, etc.
    ldi r18, high(103)
    sts UBRR0H, r18
    ldi r18, low(103)
    sts UBRR0L, r18

    ; 8 bits, 1 stop, sin paridad
    ldi r18, (1<<UCSZ01)|(1<<UCSZ00)
    sts UCSR0C, r18

    ; habilitar recepción y transmisión
    ldi r18, (1<<RXEN0)|(1<<TXEN0)
    sts UCSR0B, r18

    ret

USART_sendChar:
    ; manda el carácter que esté en r24
.wait_UDRE:
    lds r18, UCSR0A
    sbrs r18, UDRE0
    rjmp .wait_UDRE
    sts UDR0, r24
    ret

USART_sendString:
    ; manda una cadena terminada en 0 cuyo puntero está en Z
.send_str_loop:
    ld r24, Z+
    tst r24
    breq .done_str
    rcall USART_sendChar
    rjmp .send_str_loop
.done_str:
    ret

; ===== leer comandos seriales =====
leerComandosUSART:
    lds r18, UCSR0A
    sbrs r18, RXC0
    ret        ; no hay dato
    lds r24, UDR0
    ; si es 'A'
    ldi r18, 'A'
    cp r24, r18
    brne .notA
    cpi estado, ESPERA
    brne .notA
    rcall iniciarCiclo
    rjmp .endUSART
.notA:
    ; si es '1'
    ldi r18, '1'
    cp r24, r18
    brne .not1
    ldi tipoCarga, 1
    rcall seleccionarCarga
    rjmp .endUSART
.not1:
    ldi r18, '2'
    cp r24, r18
    brne .not2
    ldi tipoCarga, 2
    rcall seleccionarCarga
    rjmp .endUSART
.not2:
    ldi r18, '3'
    cp r24, r18
    brne .endUSART
    ldi tipoCarga, 3
    rcall seleccionarCarga
.endUSART:
    ret

; ===== lectura de botones =====
leerEntradas:
    ; botón inicio
    sbis PIND, BTN_INICIO
    rjmp .noInicio
    cpi estado, ESPERA
    brne .noInicio
    rcall iniciarCiclo
.noInicio:

    ; botón carga rotativo (flanco descendente + debounce)
    sbis PIND, BTN_CARGA
    rjmp .curHigh
    ldi r18, 0
    rjmp .gotCurrent
.curHigh:
    ldi r18, 1
.gotCurrent:
    lds r19, lastState
    cpi r19, 1
    brne .storeCurrent
    cpi r18, 0
    brne .storeCurrent
    ; detectó que estaba HIGH y ahora LOW → pulso
    rcall changeCarga
    ; antirrebote: espera 250 ms
    rcall delay_ms_250
.storeCurrent:
    sts lastState, r18
    ret

; ===== cambiar tipo de carga =====
changeCarga:
    inc tipoCarga
    cpi tipoCarga, 4
    brlo .cc_ok
    ldi tipoCarga, 1
.cc_ok:
    rcall seleccionarCarga
    ; enviar mensaje según carga
    cpi tipoCarga, 1
    breq .msgLig
    cpi tipoCarga, 2
    breq .msgMed
    cpi tipoCarga, 3
    breq .msgPes
    rjmp .endChange
.msgLig:
    ldi ZL, lo8(msg_CargaLigera)
    ldi ZH, hi8(msg_CargaLigera)
    rcall USART_sendString
    rjmp .endChange
.msgMed:
    ldi ZL, lo8(msg_CargaMedia)
    ldi ZH, hi8(msg_CargaMedia)
    rcall USART_sendString
    rjmp .endChange
.msgPes:
    ldi ZL, lo8(msg_CargaPesada)
    ldi ZH, hi8(msg_CargaPesada)
    rcall USART_sendString
.endChange:
    ret

; ===== rutina iniciar ciclo =====
iniciarCiclo:
    ldi estado, ALIMENTACION
    ; guardar t0 = millis
    lds t0_lo, millis_lo
    lds t0_hi, millis_hi

    ; LEDs: apagar espera, encender funcionando
    cbi PORTC, LED_ESPERA
    sbi PORTC, LED_FUNCIONANDO

    ; mensaje serial “Estado: ALIMENTACION”
    ldi ZL, lo8(msg_EstadoAlimentacion)
    ldi ZH, hi8(msg_EstadoAlimentacion)
    rcall USART_sendString

    ret

; ===== máquina de estados =====
maquinaDeEstados:
    cpi estado, ESPERA
    breq est_ESPERA

    cpi estado, ALIMENTACION
    breq est_ALIMENTACION

    cpi estado, POSICIONADO
    breq est_POSICIONADO

    cpi estado, PUNZONADO
    breq est_PUNZONADO

    cpi estado, DESCARGA
    breq est_DESCARGA

    cpi estado, FIN
    breq est_FIN

    ret

; estado ESPERA
est_ESPERA:
    sbi PORTC, LED_ESPERA
    cbi PORTC, LED_FUNCIONANDO
    cbi PORTC, LED_FIN
    ret

; estado ALIMENTACION
est_ALIMENTACION:
    rcall motorCintaON
    rcall elapsed_ms_16   ; calcula millis − t0 en r24:r25
    ; comparar con tAlimON
    ; ponemos tAlimON en registros r20:r21
    mov r20, tAlimON_lo
    mov r21, tAlimON_hi
    cp r25, r21
    brlt .ae_notYet
    brgt .ae_goNext1
    ; si iguales hi, comparar lo
    cp r24, r20
    brlt .ae_notYet
.ae_goNext1:
    rcall motorCintaOFF
    ldi estado, POSICIONADO
    lds t0_lo, millis_lo
    lds t0_hi, millis_hi
    ; mensaje serial “Estado: POSICIONADO”
    ldi ZL, lo8(msg_EstadoPosicionado)
    ldi ZH, hi8(msg_EstadoPosicionado)
    rcall USART_sendString
    ret
.ae_notYet:
    ret

; estado POSICIONADO
est_POSICIONADO:
    rcall elapsed_ms_16
    mov r20, tAlimOFF_lo
    mov r21, tAlimOFF_hi
    cp r25, r21
    brlt .ep_notYet
    brgt .ep_goNext1
    cp r24, r20
    brlt .ep_notYet
.ep_goNext1:
    ldi estado, PUNZONADO
    lds t0_lo, millis_lo
    lds t0_hi, millis_hi
    ; mensaje serial “Estado: PUNZONADO”
    ldi ZL, lo8(msg_EstadoPunzonado)
    ldi ZH, hi8(msg_EstadoPunzonado)
    rcall USART_sendString
    ret
.ep_notYet:
    ret

; estado PUNZONADO
; fases: baja 1000 ms, mantener presión, subir
est_PUNZONADO:
    rcall elapsed_ms_16
    ; comparar < 1000
    ldi r20, low(1000)
    ldi r21, high(1000)
    cp r25, r21
    brlt .fase_baja
    brgt .fase_check2
    cp r24, r20
    brlt .fase_baja
.fase_check2:
    ; si < 1000 + tPresion
    ; resto = elapsed − 1000
    ; simplifico restando 1000 en lo, hi (considerando rebases)
    ; este trozo puede ser más prolijo si haces 32 bits
    ; aquí lo hago simple para mantener lo mismo
    ; restar lo
    mov r22, r24
    mov r23, r25
    subi r22, low(1000)
    sbci r23, high(1000)
    ; ahora comparar con tPresion
    mov r20, tPresion_lo
    mov r21, tPresion_hi
    cp r23, r21
    brlt .fase_presion
    brgt .fase_check3
    cp r22, r20
    brlt .fase_presion
.fase_check3:
    ; si < 1000 + tPresion + 1000 → subida
    ; otra resta de 1000 (simplificado), comparar
    subi r22, low(1000)
    sbci r23, high(1000)
    mov r20, low(1000)
    mov r21, high(1000)
    cp r23, r21
    brlt .fase_sube
    brgt .fase_toDescarga
    cp r22, r20
    brlt .fase_sube
.fase_toDescarga:
    ldi estado, DESCARGA
    lds t0_lo, millis_lo
    lds t0_hi, millis_hi
    ; mensaje serial “Estado: DESCARGA”
    ldi ZL, lo8(msg_EstadoDescarga)
    ldi ZH, hi8(msg_EstadoDescarga)
    rcall USART_sendString
    ret

.fase_baja:
    rcall punzonON
    ret
.fase_presion:
    rcall punzonON
    ret
.fase_sube:
    rcall punzonOFF
    ret

; estado DESCARGA
est_DESCARGA:
    rcall motorCintaON
    rcall elapsed_ms_16
    mov r20, tDescarga_lo
    mov r21, tDescarga_hi
    cp r25, r21
    brlt .ed_notYet
    brgt .ed_finish
    cp r24, r20
    brlt .ed_notYet
.ed_finish:
    rcall motorCintaOFF
    ldi estado, FIN
    ; mensaje serial “Fin de ciclo”
    ldi ZL, lo8(msg_FinCiclo)
    ldi ZH, hi8(msg_FinCiclo)
    rcall USART_sendString
    ret
.ed_notYet:
    ret

; estado FIN
est_FIN:
    cbi PORTC, LED_FUNCIONANDO
    sbi PORTC, LED_FIN
    ldi estado, ESPERA
    ret

; ===== auxiliares =====

motorCintaON:
    sbi PORTD, CINTA_IN1
    cbi PORTB, CINTA_IN2
    ret

motorCintaOFF:
    cbi PORTD, CINTA_IN1
    cbi PORTB, CINTA_IN2
    ret

punzonON:
    sbi PORTB, PUNZON_IN1
    cbi PORTB, PUNZON_IN2
    ret

punzonOFF:
    cbi PORTB, PUNZON_IN1
    cbi PORTB, PUNZON_IN2
    ret

; ===== debounce: delay de 250 ms =====
delay_ms_250:
    ; guardo un valor de inicio
    lds r18, millis_lo
    lds r19, millis_hi
.delay_loop250:
    rcall elapsed_ms_16
    ldi r20, low(250)
    ldi r21, high(250)
    cp r25, r21
    brlt .loop250_checkLow
    brgt .end250
    cp r24, r20
    brlt .loop250_checkLow
.end250:
    ret
.loop250_checkLow:
    rjmp .delay_loop250

; ===== rutina para calcular elapsed = millis - t0 (16 bits) =====
elapsed_ms_16:
    lds r24, millis_lo
    lds r25, millis_hi
    lds r26, t0_lo
    lds r27, t0_hi
    sub r24, r26
    sbc r25, r27
    ret

; ===== Mensajes en memoria =====
.dseg
msg_Espera:
    .db "Sistema en ESPERA",0
msg_CargaLigera:
    .db "Carga Ligera seleccionada",0
msg_CargaMedia:
    .db "Carga Media seleccionada",0
msg_CargaPesada:
    .db "Carga Pesada seleccionada",0
msg_EstadoAlimentacion:
    .db "Estado: ALIMENTACION",0
msg_EstadoPosicionado:
    .db "Estado: POSICIONADO",0
msg_EstadoPunzonado:
    .db "Estado: PUNZONADO",0
msg_EstadoDescarga:
    .db "Estado: DESCARGA",0
msg_FinCiclo:
    .db "Estado: FIN DE CICLO",0

; ===== Fin =====
