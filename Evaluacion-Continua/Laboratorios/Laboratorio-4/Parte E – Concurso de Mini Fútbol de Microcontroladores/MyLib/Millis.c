/*
 * Millis.c
 *
 * Created: 8/11/2025 20:55:38
 *  Author: David
 */ 

#include "Millis.h"

#include <avr/io.h>
#include <avr/interrupt.h>


volatile uint32_t timer_millis = 0;

void init_millis(void) {
	// Timer0 a 8kHz (125s) - CTC mode
	TCCR0A = (1 << WGM01);          // Modo CTC
	TCCR0B = (1 << CS01);           // Prescaler 8
	OCR0A = 249;                    // 8kHz = 16MHz/(8*(249+1))
	TIMSK0 = (1 << OCIE0A);         // Habilitar interrupción
	
	timer_millis = 0;               // Inicializar contador
}

ISR(TIMER0_COMPA_vect) {
	timer_millis += 125;  // 125 microsegundos por interrupción
}

uint32_t micros(void) {
	uint32_t m;
	cli();
	m = timer_millis;
	sei();
	return m;
}

uint32_t millis(void) {
	return micros() / 1000;  // Convertir a milisegundos
}