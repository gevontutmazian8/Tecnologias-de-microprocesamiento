/*
 * LEDS.h
 *
 * Created: 14/10/2025 16:54:10
 *  Author: David
 */ 


#ifndef LEDS_H_
#define LEDS_H_

void setMatrix(uint8_t r, uint8_t g, uint8_t b);
void show (uint8_t (*colors)[3]);
void setLedRGB(uint8_t (*leds)[3], int ledIndex, uint8_t r, uint8_t g, uint8_t b);


#endif /* LEDS_H_ */