/*
 * LDR.c
 *
 * Created: 14/10/2025 16:58:42
 *  Author: David
 */ 

#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdio.h>
#include <avr/io.h>

void LDR_Init();
uint16_t LDR_read(uint8_t channel);
#define ADC_PIN 0



void LDR_Init(){
	//Habilitamos el pin para lectura ADC
	ADMUX = (1 << REFS0) | (0 << ADLAR) | (0 << MUX0);
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
}

uint16_t LDR_read(uint8_t channel) {
	
	ADMUX = (ADMUX & 0xF0) | (channel & 0x0F);
	
	// Iniciar la conversión 
	ADCSRA |= (1 << ADSC);
	
	// Esperar a que la conversión termine
	while (ADCSRA & (1 << ADSC));

	// Leer el resultado de 10 bits
	uint16_t resultado = ADCL;
	resultado |= (ADCH << 8); // Combina los 2 bits de ADCH con los 8 de ADCL
	
	return resultado; // Valor de 0 a 1023
}