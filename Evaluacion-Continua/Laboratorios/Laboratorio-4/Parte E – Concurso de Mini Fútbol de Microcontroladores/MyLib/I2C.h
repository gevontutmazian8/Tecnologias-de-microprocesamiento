/*
 * I2C.h
 *
 * Created: 19/9/2025 0:56:28
 *  Author: David
 */ 
#include <stdint.h> 

#ifndef I2C_H_
#define I2C_H_

void I2C_Init(void);
void I2C_Start(void);
void I2C_Stop(void);
void I2C_Write(uint8_t data);
uint8_t I2C_Read();

#endif /* I2C_H_ */