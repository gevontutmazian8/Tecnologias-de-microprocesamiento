/*
 * ADC.c
 *
 * Created: 14/10/2025 16:58:42
 *  Author: David
 */ 

#define F_CPU 16000000UL
#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdio.h>
#include <avr/io.h>

uint16_t ADC_read(uint8_t channel) {
	// Asegurar que el canal sea válido (0-7)
	if (channel > 7) channel = 0;
	
	// Configurar desde cero
	ADMUX = (1 << REFS0) | channel;
	
	// Delay de estabilización del multiplexor
	_delay_us(50);
	
	// Iniciar conversión
	ADCSRA |= (1 << ADSC);
	
	// Esperar fin de conversión
	while (ADCSRA & (1 << ADSC));
	
	// Leer en el orden correcto
	uint16_t resultado = ADCL;
	resultado |= (ADCH << 8);
	
	return resultado;
}

void ADC_Init() {
	// Limpiar registros primero
	ADMUX = 0;
	ADCSRA = 0;
	
	// Configurar referencia AVcc, right-adjusted
	ADMUX = (1 << REFS0);
	
	// Habilitar ADC con prescaler 128
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
	
	// Primera lectura de descarte (estabilización)
	ADC_read(0);
}