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

#define LED_PIN 6
#define WIDTH 8
#define HEIGHT 8
#define NUM_LEDS (WIDTH*HEIGHT)

uint8_t leds[NUM_LEDS][3];

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

void show (uint8_t (*colors)[3]){
	cli();
	for (int i = 0; i < NUM_LEDS; i++){
		sendByte(colors[i][1]);
		sendByte(colors[i][0]);
		sendByte(colors[i][2]);
	}
	sei();
	_delay_us(60);
}

void setLedRGB(uint8_t (*leds)[3], int ledIndex, uint8_t r, uint8_t g, uint8_t b){
	if (ledIndex < 0 || ledIndex >= NUM_LEDS) return;
	leds[ledIndex][0] = r;
	leds[ledIndex][1] = g;
	leds[ledIndex][2] = b;
}

void setMatrix(uint8_t r, uint8_t g, uint8_t b){
	for (uint8_t i = 0; i < NUM_LEDS; i++)
	{
		setLedRGB(leds, i, r, g, b);
	}
	show(leds);
	
}