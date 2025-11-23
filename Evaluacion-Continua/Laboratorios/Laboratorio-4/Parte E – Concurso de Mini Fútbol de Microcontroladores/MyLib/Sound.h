/*
 * Sound.h
 *
 * Created: 12/11/2025 2:24:02
 *  Author: David
 */ 


#ifndef SOUND_H_
#define SOUND_H_

#include <avr/pgmspace.h>

extern const uint8_t PROGMEM OhMyGod[5892];
uint8_t getAmplitudOhMyGod(uint16_t Position);


extern const uint8_t PROGMEM DogFirst[6253];
uint8_t getAmplitudDogFirst(uint16_t Position);

extern const uint8_t PROGMEM DogVacio[743];
uint8_t getAmplitudVacio(uint16_t Position);

extern const uint8_t PROGMEM DogSecond[6915];
uint8_t getAmplitudSecond(uint16_t Position);
#endif /* SOUND_H_ */