#ifndef STEPPER_H
#define STEPPER_H

#include <avr/io.h>

// Definición de pines
#define CLK_X PB3
#define DIR_X PB4
#define EN_X  PB5

#define SELENOID  PC0

#define CLK_Y PC3
#define DIR_Y PC4
#define EN_Y  PC5

#define LIMIT_YA PD2
#define LIMIT_YD PD3
#define LED PD5

// Prototipos de funciones públicas
void InitStepper(void);
void Linea(int Dx, int Dy);
void selenoidUp(void);
void selenoidDown(void);

// Variable global
extern volatile int g_moving;

#endif