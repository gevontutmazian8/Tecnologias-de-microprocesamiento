#define F_CPU 16000000UL

#include "stepper.h"
#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>

#define TIMER_OCR0A_VALUE 250

// Variables globales que utilizaremos en el algoritmo de bresenham
volatile int g_dx = 0, g_dy = 0, g_err = 0, g_steps = 0, g_i = 0;
volatile int g_moving = 0;

//MACROS
// Definimos una funcion minima de paso, cuanto menor sea el delay mas chico sera el paso por ende mas preciso
#define STEP_X() do { \
	PORTB |= (1 << CLK_X); \
	_delay_us(25); \
	PORTB &= ~(1 << CLK_X); \
} while(0)

#define STEP_Y() do { \
	PORTC |= (1 << CLK_Y); \
	_delay_us(25); \
	PORTC &= ~(1 << CLK_Y); \
} while(0)

// Funciones 
static void InitTimer(void) {
	TCCR0A |= (1 << WGM01);
	TCCR0B &= ~(1 << WGM02);
	OCR0A = TIMER_OCR0A_VALUE - 1;
	TIMSK0 |= (1 << OCIE0A);
	TCCR0B |= (1 << CS01) | (1 << CS00);
	sei();
}

void InitStepper(void) {
	DDRB |= (1 << CLK_X) | (1 << DIR_X) | (1 << EN_X);
	DDRC |= (1 << SELENOID) | (1 << CLK_Y) | (1 << DIR_Y) | (1 << EN_Y);
	DDRD &= ~((1 << LIMIT_YA) | (1 << LIMIT_YD));
	DDRD |= (1 << LED);
	
	PORTB &= ~(1 << EN_X);
	PORTC &= ~(1 << EN_Y);
	PORTC &= ~(1 << SELENOID);
	
	InitTimer();
}

void selenoidUp(void) {
	PORTC |= (1 << SELENOID);
}

void selenoidDown(void) {
	PORTC &= ~(1 << SELENOID);
}


ISR(TIMER0_COMPA_vect) {

	if (g_moving == 0) return; //Si g_moving si hay trayectoria

	int e2 = 2 * g_err; //Calculamos el error


	// Terminamos el algoritmo de bresemham.
	// Ejecutamos la parte dinamica del mismo
	if (e2 > -g_dy) { 
		g_err -= g_dy;
		STEP_X();
	}
	
	if (e2 < g_dx) {
		g_err += g_dx;
		STEP_Y();
	}
	
	g_i++;
	
	if (g_i > g_steps) {
		g_moving = 0;
		PORTB &= ~(1 << EN_X);
		PORTC &= ~(1 << EN_Y);
		TCCR0B &= ~((1 << CS02) | (1 << CS01) | (1 << CS00));
	}
}

/*
Al igual que en el laboratorio anterior en este codigo se utiliza el algorirmo de bresenham, implementando una "variacion" o adaptado para 
funcionar con coordenadas relativos, de esa manera evitmaos tener que calcularlo en su interior.
*/
void Linea(int Dx, int Dy) {
	
	if (g_moving) return; // Si ya hay algo en movimiento termina la funcion termina  (sin devolver nada)
	
	if (Dx == 0 && Dy == 0) return; // Si no hay movimeiento relativo termianar la funcion

	if (Dx > 0) { //Estabecemos la direccion en base si dx es positivo o negativo
		PORTB |= (1 << DIR_X);
		} else {
		PORTB &= ~(1 << DIR_X);
	}
	
	if (Dy > 0) { //Estabecemos la direccion en base si dy es positivo o negativo
		PORTC |= (1 << DIR_Y);
		} else {
		PORTC &= ~(1 << DIR_Y);
	}

	// Habilitar motores
	PORTB |= (1 << EN_X);
	PORTC |= (1 << EN_Y);

	// Algoritmo de Bresenham
	g_dx = (Dx > 0) ? Dx : -Dx;
	g_dy = (Dy > 0) ? Dy : -Dy;
	g_err = g_dx - g_dy;
	g_steps = (g_dx > g_dy) ? g_dx : g_dy;
	g_i = 0;

	// Iniciar
	g_moving = 1;
	TCNT0 = 0;
	TCCR0B |= (1 << CS01) | (1 << CS00);
}