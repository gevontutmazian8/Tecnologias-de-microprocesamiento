/*
 * UART.c
 *
 * Created: 28/10/2025 12:30:06
 *  Author: David
 */ 

#define F_CPU 16000000UL

#include <avr/io.h>

#define BAUD 9600
#define MYUBRR (F_CPU/16/BAUD-1)


void UART_Init() {
	// Configurar baud rate
	UBRR0H = (unsigned char)(MYUBRR >> 8);
	UBRR0L = (unsigned char)(MYUBRR);
	
	// Habilitar receptor y transmisor
	UCSR0B = (1 << RXEN0) | (1 << TXEN0);
	
	// Configurar formato: 8 bits de datos, 1 bit de parada
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

void UART_Enviar(char data) {
	// Esperar a que el buffer de transmision ese te vacio
	while (!(UCSR0A & (1 << UDRE0)));
	
	// Poner dato en el buffer
	UDR0 = data;
}

char UART_Receive(void) {
	// Esperar a que llegue un dato
	while (!(UCSR0A & (1 << RXC0)));
	
	// Devolver dato recibido
	return UDR0;
}

void UART_Enviar_String(const char* str) { //Recibe un string y lo recorre enviando los caracteres 1x1
	while (*str) {
		UART_Enviar(*str);
		str++;
	}
}