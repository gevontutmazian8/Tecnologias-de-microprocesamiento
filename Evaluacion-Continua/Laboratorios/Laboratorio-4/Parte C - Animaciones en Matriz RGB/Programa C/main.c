/*
 * main.c
 *
 * Created: 11/7/2025 12:07:37 AM
 *  Author: David
 */ 

#define F_CPU 16000000UL

#include <avr/io.h>
#include <util/delay.h>
#include <avr/pgmspace.h>

#include "MyLibs/Pathetic.h"
#include "MyLibs/SemiFusa.h"
#include "MyLibs/UART.h"
#include "MyLibs/LEDS.h"
//#151517 
uint8_t PaletaColores[][3] = {
	{50, 50, 225}, {96, 125, 102},  {219, 164, 126}, {0, 0, 0}, {255, 255, 255}, {15,15,17}, {10,10,12}, 
	{181, 135, 104}, {176, 131, 101}, {133, 99, 76},   {157, 157, 150}, {212, 212, 212}, {102, 102, 97}, {69, 69, 66}, 
	{255, 231, 0}, {8, 8, 7}, {255, 240, 94}, {255, 235, 41}, {255, 244, 135}, {255, 248, 181}, {33, 33, 32}, {130, 130, 130}, 
	{87, 87, 87}, {200,0,0}
};

// Variables globales para mapeo
uint8_t mapeoZigZagReflejado[256];  // Solo el mapeo reflejado
uint8_t mapeoInicializado = 0;

// PROTOTIPOS
void AnimSemiFusa(uint8_t Position);
void AnimPathetic(uint8_t Position);
void ProbarColores(uint8_t Position);
void inicializarMapeoReflejado();

int main(){
	USART_Init();
	initLEDs();
	inicializarMapeoReflejado();  // Inicializar una vez
	
	uint32_t Time = 0;
	uint8_t currentCommand = 0;
	uint8_t animationState = 0;

	USART_Enviar_String("Sistema iniciado\n");
	USART_Enviar_String("'1' = Primera animacion\n");  // Actualizado
	USART_Enviar_String("'2' = Segunda animacion\n");
	USART_Enviar_String("'t' = Test de colores\n");
	USART_Enviar_String("'0' = Apagar\n");
	
	while (1){
		Time++; 
		
		// Verificar nuevo comando
		if(USART_DatoDisponible()){
			uint8_t newCmd = USART_Receive();
			
			if(newCmd == '0') {
				setMatrix(0,0,0);
				currentCommand = 0;
				animationState = 0;
			} else {
				currentCommand = newCmd;
				animationState = 0;  

				// Ejecutar inmediatamente el primer frame
				switch(currentCommand){
					case 't': ProbarColores(0); break;
					case '1': AnimPathetic(0); break;
					case '2': AnimSemiFusa(0); break;
				}
			}
		}
		
		// Control de animaciones
		if(currentCommand != 0 && Time % 10 == 0){
			switch(currentCommand){
				case 't':
					animationState++;
					if(animationState > 2) animationState = 0;
					ProbarColores(animationState);
					break;
					
				case '1':
					animationState++;
					if(animationState >= 19) animationState = 0;
					AnimPathetic(animationState);
					break;
					
				case '2':
					animationState++;
					if(animationState >= 34) animationState = 0;
					AnimSemiFusa(animationState);
					break;
			}
		}
		
		_delay_ms(10);
		
		if(Time >= 60000) Time = 0;
	}
}

void ProbarColores(uint8_t Position){
	switch (Position){
		case 0:
			setMatrix(255, 0, 0);
			break;
		case 1:
			setMatrix(0, 255, 0);
			break;
		case 2:
			setMatrix(0, 0, 255);	
			break;
	}
}

// Inicializar solo el mapeo reflejado
void inicializarMapeoReflejado() {
	if(mapeoInicializado) return;
	
	uint8_t FILAS = 16;
	uint8_t COLUMNAS = 16;
	
	for (uint8_t fila = 0; fila < FILAS; fila++) {
		for (uint8_t columna = 0; columna < COLUMNAS; columna++) {
			uint16_t posicionLineal = (fila * COLUMNAS) + columna;
			
			// Mapeo REFLEJADO: invertir columnas (espejo horizontal)
			uint8_t columnaReflejada = COLUMNAS - 1 - columna;
			uint8_t posicionFisicaReflejada;
			
			if (fila % 2 == 0) {
				// Filas pares: izquierda a derecha (pero con columnas reflejadas)
				posicionFisicaReflejada = (fila * COLUMNAS) + columnaReflejada;
			} else {
				// Filas impares: derecha a izquierda (pero con columnas reflejadas)
				posicionFisicaReflejada = (fila * COLUMNAS) + (COLUMNAS - 1 - columnaReflejada);
			}
			mapeoZigZagReflejado[posicionLineal] = posicionFisicaReflejada;
		}
	}
	mapeoInicializado = 1;
}

void AnimPathetic(uint8_t Position){
	
	uint8_t r, g, b, indice_color;
	uint16_t frameOffset = 256 * Position;
	
	if(frameOffset + 256 > 4864) {
		frameOffset = 0;
	}
	
	for (uint16_t i = 0; i < 256; i++) {
		uint8_t posicionFisica = mapeoZigZagReflejado[i];  
		indice_color = PathGetPixel(i + frameOffset);
		r = PaletaColores[indice_color][0];
		g = PaletaColores[indice_color][1];
		b = PaletaColores[indice_color][2];
		setLedRGB(posicionFisica, r, g, b);
		if (Position >= 12){
			_delay_ms(2);
		}
	}
	show();
	if (Position == 18)
	{
		_delay_ms(1000);
	}
}

void AnimSemiFusa(uint8_t Position){
	uint8_t r, g, b, indice_color;
	uint16_t frameOffset = 256 * Position; 
	
	
	if(frameOffset + 256 > 8704) {
		frameOffset = 0;
	}
	
	for (uint16_t i = 0; i < 256; i++) {
		uint8_t posicionFisica = mapeoZigZagReflejado[i];
		indice_color = SemiGetPixel(i + frameOffset);
		r = PaletaColores[indice_color][0];
		g = PaletaColores[indice_color][1];
		b = PaletaColores[indice_color][2];
		setLedRGB(posicionFisica, r, g, b);
	}
	show();
	
	if (Position == 33)
	{
		_delay_ms(1000);
	}
}