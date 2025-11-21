/*
 * LEDS.c
 *
 * Created: 14/10/2025 16:54:01
 *  Author: David
 */ 
#define F_CPU 16000000UL
#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>

#include "LEDS.h"

// Array unidimensional - MISMO tamaño pero más eficiente
uint8_t leds[NUM_LEDS * 3] = {0};


void initLEDs(void) {
	DDRD |= (1 << LED_PIN);  // Configurar pin como salida
	PORTD &= ~(1 << LED_PIN); // Estado inicial bajo
	
	setMatrix(0,0,0);
}


void sendBit(uint8_t bitVal){
	if(bitVal){
		//T1H ~0.8us en alto
		PORTD |= (1 << LED_PIN);
		asm volatile (
		"nop\n\t""nop\n\t""nop\n\t""nop\n\t""nop\n\t"
		"nop\n\t""nop\n\t""nop\n\t""nop\n\t"
		);
		PORTD &= ~(1 << LED_PIN);
		//T1L ~0.45 us en alto
		asm volatile (
		"nop\n\t""nop\n\t""nop\n\t""nop\n\t"
		);
		} else {
		//T0H ~0.4us en alto
		PORTD |= (1 << LED_PIN);
		asm volatile(
		"nop\n\t""nop\n\t""nop\n\t"
		);
		PORTD &= ~(1<<LED_PIN);
		//T0L ~0.85us en bajo
		asm volatile(
		"nop\n\t""nop\n\t""nop\n\t""nop\n\t""nop\n\t"
		"nop\n\t""nop\n\t""nop\n\t""nop\n\t""nop\n\t"
		);

	}
}

void sendByte(uint8_t byte){
	for (uint8_t i = 0; i < 8; i++){
		sendBit(byte & (1<< (7 - i)));
	}
}


void show(void){  // Sin parámetro
	cli();
	for (int i = 0; i < NUM_LEDS; i++){
		int base = i * 3;
		sendByte(leds[base + 1]);     // G
		sendByte(leds[base]);         // R
		sendByte(leds[base + 2]);     // B
	}
	sei();
	
	_delay_us(500);
}

void setLedRGB(int ledIndex, uint8_t r, uint8_t g, uint8_t b){
	if (ledIndex < 0 || ledIndex >= NUM_LEDS) return;
	int base = ledIndex * 3;
	leds[base] = r;
	leds[base + 1] = g;
	leds[base + 2] = b;
}

void setMatrix(uint8_t r, uint8_t g, uint8_t b){
	for (uint16_t i = 0; i < NUM_LEDS; i++) {
		setLedRGB(i, r, g, b);
	}
	show();
}