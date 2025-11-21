#ifndef I2C_H
#define I2C_H

#include <avr/io.h>

// Definiciones de estados I2C
#define I2C_START 0x08
#define I2C_REP_START 0x10
#define I2C_MT_SLA_ACK 0x18
#define I2C_MT_DATA_ACK 0x28
#define I2C_MR_SLA_ACK 0x40
#define I2C_MR_DATA_ACK 0x50
#define I2C_MR_DATA_NACK 0x58

void I2C_Init(void);
void I2C_Start(void);
void I2C_Stop(void);
uint8_t I2C_Write(uint8_t data);
uint8_t I2C_Read(uint8_t ack);
uint8_t I2C_GetStatus(void);
uint8_t I2C_CheckStatus(uint8_t expected);

#endif