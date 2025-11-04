/*
 * LEDS.h
 *
 * Created: 14/10/2025 16:54:10
 *  Author: David
 */ 


#ifndef LEDS_H_
#define LEDS_H_


#define WIDTH 8
#define HEIGHT 8
#define NUM_LEDS (WIDTH*HEIGHT)

uint8_t leds[NUM_LEDS][3];

void initLEDs(void);
void setMatrix(uint8_t r, uint8_t g, uint8_t b);
void show (uint8_t (*colors)[3]);
void setLedRGB(uint8_t (*leds)[3], int ledIndex, uint8_t r, uint8_t g, uint8_t b);


#endif /* LEDS_H_ */