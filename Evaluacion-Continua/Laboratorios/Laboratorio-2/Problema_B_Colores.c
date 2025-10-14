/*
 * main.c
 *
 * Created: 10/14/2025 11:21:54 AM
 *  Author: David
 */ 

#define F_CPU 16000000UL

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdio.h>

#define LED_PIN 6
#define WIDTH 8 
#define HEIGHT 8
#define NUM_LEDS (WIDTH*HEIGHT)  

uint8_t leds[NUM_LEDS][3];

int main(){
	return 0;
}
//Funcion para enviar un bit al WS2812B

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