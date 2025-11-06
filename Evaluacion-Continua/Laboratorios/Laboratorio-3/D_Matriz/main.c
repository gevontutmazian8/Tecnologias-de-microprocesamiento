#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>
#include <stdlib.h>
#include "MyLib/LEDS.h"
#include "MyLib/ADC.h"

#define BOTON_PIN 2
#define CHANNEL_1 0
#define CHANNEL_2 1
#define MAX_COORD 7 // La coordenada maxima es 7 (para 8x8)

uint16_t Promedio(uint8_t channel);

int main(void)
{
	// Configuracion inicial de pines y perifericos
	DDRD &= ~(1 << BOTON_PIN); // D2 como entrada
	PORTD |= (1 << BOTON_PIN);  // Pull-up en D2
	ADC_Init();
	initLEDs();
	
	// Semilla para rand() usando el ADC
	srand(ADC_read(CHANNEL_1));
	
	int8_t x = 3;
	int8_t y = 3;
	uint16_t joy_x, joy_y;
	
	uint8_t r = 100, g = 0, b = 0;
	int Random;
	
	while(1)
	{
		// Leer y promediar los valores del joystick
		joy_x = Promedio(CHANNEL_1);
		joy_y = Promedio(CHANNEL_2);
		
		// Eje X: Derecha
		if (joy_x >= 950 && x < MAX_COORD)
		{
			x++;
			setMatrix(0,0,0);
		}
		// Eje X: Izquierda
		else if (joy_x <= 100 && x > 0)
		{
			x--;
			setMatrix(0,0,0);
		}

		// Eje Y: Abajo 
		if (joy_y >= 950 && y < MAX_COORD)
		{
			y++;
			setMatrix(0,0,0);
		}
		// Eje Y: Arriba
		else if (joy_y <= 100 && y > 0)
		{
			y--;
			setMatrix(0,0,0);
		}

		if (!(PIND & (1 << BOTON_PIN)))
		{
			// Debounce 
			_delay_ms(50);
			
			// Generar colores aleatorios 
			r = rand() % 200;
			g = rand() % 200;
			b = rand() % 200;
		}
		
		uint8_t led_index = (y * 8) + x; 
		setLedRGB(leds, led_index, r, g ,b);
		show(leds);
		
		// Pequeño retraso para limitar la velocidad de movimiento
		_delay_ms(50);
	}
}

// La funcion Promedio es correcta y eficiente
uint16_t Promedio(uint8_t channel){
	uint16_t Resultado = 0;
	
	for (uint8_t i = 0; i < 16; i++)
	{
		Resultado += ADC_read(channel);
		_delay_ms(20); 
	}
	
	// Division por 16  usando desplazamiento de bits 
	uint16_t ResultadoFinal = (uint16_t)(Resultado >> 4);
	return ResultadoFinal;
}