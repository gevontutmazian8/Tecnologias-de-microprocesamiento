/*
 * ADC.c
 *
 * Created: 14/10/2025 16:58:42
 *  Author: David
 */ 

#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdio.h>
#include <avr/io.h>

void ADC_Init(){
	ADMUX = (1 << REFS0);
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
}

uint16_t ADC_read(uint8_t channel) {
	ADMUX = (ADMUX & 0xF0) | (channel & 0x0F);
	
	ADCSRA |= (1 << ADSC); 
	
	while (ADCSRA & (1 << ADSC)); 
	
	uint16_t resultado = ADCL;
	resultado |= (ADCH << 8);
	
	return resultado;
}

