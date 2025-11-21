/*
 * SemiFusa.h
 *
 * Created: 7/11/2025 0:29:31
 *  Author: David
 */ 


#ifndef SEMIFUSA_H_
#define SEMIFUSA_H_
#include <avr/pgmspace.h>
extern const uint8_t PROGMEM semifusa[8704];
uint8_t SemiGetPixel(uint16_t i);

#endif /* SEMIFUSA_H_ */