/*
 * Pathetic.h
 *
 * Created: 7/11/2025 0:27:54
 *  Author: David
 */ 


#ifndef PATHETIC_H_
#define PATHETIC_H_
#include <avr/pgmspace.h>

extern const uint8_t PROGMEM pathetic[4864];
uint8_t PathGetPixel(uint16_t i);

#endif /* PATHETIC_H_ */