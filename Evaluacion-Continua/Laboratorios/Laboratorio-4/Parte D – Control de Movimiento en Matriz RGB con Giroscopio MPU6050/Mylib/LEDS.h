/*
 * LEDS.h
 *
 * Created: 14/10/2025 16:54:10
 *  Author: David
 */ 


#ifndef LEDS_H_
#define LEDS_H_

#define LED_PIN 6
#define WIDTH 16
#define HEIGHT 16
#define NUM_LEDS (WIDTH*HEIGHT)

// Cambiar a array unidimensional
extern uint8_t leds[NUM_LEDS * 3];

void initLEDs(void);
void setMatrix(uint8_t r, uint8_t g, uint8_t b);
void show(void);  // Sin parámetros
void setLedRGB(int ledIndex, uint8_t r, uint8_t g, uint8_t b);

#endif