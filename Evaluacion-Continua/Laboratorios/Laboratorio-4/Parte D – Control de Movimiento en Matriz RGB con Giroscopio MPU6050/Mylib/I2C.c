#include "I2C.h"

void I2C_Init(void) {
	TWSR = 0x00; // Prescaler = 1
	TWBR = 72;   // ~100kHz con F_CPU = 16MHz
}

void I2C_Start(void) {
	TWCR = (1 << TWINT) | (1 << TWSTA) | (1 << TWEN);
	while (!(TWCR & (1 << TWINT)));
}

void I2C_Stop(void) {
	TWCR = (1 << TWINT) | (1 << TWSTO) | (1 << TWEN);
}

uint8_t I2C_Write(uint8_t data) {
	TWDR = data;
	TWCR = (1 << TWINT) | (1 << TWEN);
	while (!(TWCR & (1 << TWINT)));
	return (TWSR & 0xF8);
}

uint8_t I2C_Read(uint8_t ack) {
	if (ack) {
		TWCR = (1 << TWINT) | (1 << TWEN) | (1 << TWEA);
		} else {
		TWCR = (1 << TWINT) | (1 << TWEN);
	}
	while (!(TWCR & (1 << TWINT)));
	return TWDR;
}

uint8_t I2C_GetStatus(void) {
	return TWSR & 0xF8;
}

uint8_t I2C_CheckStatus(uint8_t expected) {
	return (I2C_GetStatus() == expected);
}