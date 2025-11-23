/*
 * I2C.c
 *
 * Created: 19/9/2025 0:56:12
 *  Author: David
 */ 
#define F_CPU 16000000UL
#include <avr/io.h>
#include <stdint.h> 

#define F_CPU 16000000UL // Frecuencia del Atmega328p (16MHz)
#define F_SCL 500000UL   // Frecuencia I2C (100kHz)


void I2C_Init(void) {						// Configurar velocidad del bus I2C
	TWBR = ((F_CPU / F_SCL) - 16) / 2;		// Formula despejada a partir de la formula presente en la Pag.222 del datasheet del atmega328p
	TWSR = 0x00;						    // Preescaler 1:1
}

void I2C_Start(void) {									//Iniciamos la comunicacion seteando los valores del registro de control TWCR Pag.221
	TWCR = (1 << TWINT) | (1 << TWSTA) | (1 << TWEN);   //Se habilita el modulo TWI, Borra la bandera de interrucion y habilita la condicion de inicio pag.255
	while (!(TWCR & (1 << TWINT)));
}

void I2C_Stop(void) {
	TWCR = (1 << TWINT) | (1 << TWSTO) | (1 << TWEN);
	while (TWCR & (1 << TWSTO)); // Esperar que se complete el stop
}

void I2C_Write(uint8_t data) {				//Recibe un dato tipo entero de 8 bits sin signo
	TWDR = data;							//Se mueve el dato en TWDR
	TWCR = (1 << TWINT) | (1 << TWEN);		// Se envia el dato
	while (!(TWCR & (1 << TWINT)));			// Se espera un feedback
}

uint8_t I2C_Read() {
	TWCR = (1 << TWINT) | (1 << TWEN);
	while (!(TWCR & (1 << TWINT)));
	return TWDR;
}
