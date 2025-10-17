/*
 * main.c
 *
 * Created: 10/14/2025 11:21:54 AM
 *  Author: David
 */ 

#define F_CPU 16000000UL

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdio.h>
#include <math.h>


#include "bin/UART.h"
#include "bin/PWM.h"
#include "bin/LEDS.h"
#include "bin/LDR.h"

/*
Pines:
	-A0: LDR
	-B2: LED Rojo
	-B3: LED Verde
	-B4: LED Azul
	
	-B5: Servomotor
*/

//  ----------------------------PROTOTIPOS----------------------------
void MyInit();
void LED_Init();
uint32_t LecuraMedia();
void Scan();
uint8_t DistanciaMinima(uint16_t r, uint16_t g, uint16_t b);


 uint16_t RGB[3];
 
 /*
 Orden de la matriz:
 1- Rosado
 2- Rojo
 3- Amarillo
 4- Verde
 5- Cyan
 6- Violeta
 */
 
 uint16_t RGBList[6][3]= {
	 {82, 100, 143},
	 {75, 102, 153},
	 {73, 83 , 147},
	 {87, 89 , 150},
	 {87, 89 , 133},
	 {90, 98, 140},
	 };
 // --------------------------FUNCION PRINCIPAL----------------------
int main() {
	MyInit();
		
	while(1){
		Scan();	
		DistanciaMinima(RGB[0], RGB[1], RGB[2]);
	}
	return 0;
}


 // --------------------------FUNCIONES------------------------

void MyInit(){
	PWM_Init();
	USART_Init();
	PWM_Init();
	LDR_Init();
	LED_Init();
}

uint32_t LecuraMedia(){
	//Se toma 20 medidas y se las promedia
	uint32_t Medidas = 0;
	for (uint8_t i = 0;  i < 39; i++)
	{
		Medidas += LDR_read(0);
		_delay_ms(10);
	}
	Medidas = Medidas / 40;
	return Medidas;
	};


void LED_Init(){
	DDRB |= (1 << PB2) | (1 << PB3) | (1 << PB4);  // Pines como salida
	PORTB |= (1 << PB2) | (1 << PB3) | (1 << PB4);
}

 void Scan(){
	 		char String[6];
	 		PORTB &= ~(1 << PB2);
	 		_delay_ms(1000);
	 		RGB[0] = LecuraMedia();
	 		PORTB |= (1 << PB2);
	 		
	 		PORTB &= ~(1 << PB3);
	 		_delay_ms(1000);
	 		RGB[1] = LecuraMedia();
	 		PORTB |= (1 << PB3);
	 		
	 		PORTB &= ~(1 << PB4);
	 		_delay_ms(1000);
	 		RGB[2] = LecuraMedia();
	 		PORTB |= (1 << PB4);
	 		
	 		sprintf(String, "%d", RGB[0]);
	 		USART_Enviar_String("Red: ");
	 		USART_Enviar_String(String);
	 		
	 		sprintf(String, "%d", RGB[1]);
	 		USART_Enviar_String("	Green: ");
	 		USART_Enviar_String(String);
	 		
	 		sprintf(String, "%d", RGB[2]);
	 		USART_Enviar_String("	Blue: ");
	 		USART_Enviar_String(String);
	 		
	 		
	 		USART_Enviar_String("\n");
 }
 
uint8_t DistanciaMinima(uint16_t r, uint16_t g, uint16_t b){
    uint8_t IndiceMenor = 0;
    
    // Se calcula el que tiene menor distancia (como si fuera una matriz tridimencional)
    int16_t dr0 = (int16_t)r - (int16_t)RGBList[0][0];
    int16_t dg0 = (int16_t)g - (int16_t)RGBList[0][1];
    int16_t db0 = (int16_t)b - (int16_t)RGBList[0][2];
    uint32_t ValorMenor = dr0*dr0 + dg0*dg0 + db0*db0;
    
    for(uint8_t i = 1; i < 6; i++){
        int16_t dr = (int16_t)r - (int16_t)RGBList[i][0];
        int16_t dg = (int16_t)g - (int16_t)RGBList[i][1];
        int16_t db = (int16_t)b - (int16_t)RGBList[i][2];
        uint32_t DistanciaActual = dr*dr + dg*dg + db*db;
        
        if (DistanciaActual < ValorMenor){
            ValorMenor = DistanciaActual;
            IndiceMenor = i;
        }
    }
    
    switch (IndiceMenor){
        case 0:
            USART_Enviar_String("El color es Rosado");
			setMatrix(200,1,106);
            break;
        case 1:
            USART_Enviar_String("El color es Rojo");
			setMatrix(214,0,0); 
			PWM_Move(5);
			_delay_ms(1000);
            break;
        case 2:
            USART_Enviar_String("El color es Amarillo");
			setMatrix(253,226,0); 
			PWM_Move(45);
            _delay_ms(1000);
			break;
        case 3:
            USART_Enviar_String("El color es Verde");
			setMatrix(79,167,3); 
            PWM_Move(100);
            _delay_ms(1000);
			break;
        case 4:
            USART_Enviar_String("El color es Cyan");
			setMatrix(1,247,247);
			PWM_Move(180);
			_delay_ms(1000);
            break;
        case 5:
            USART_Enviar_String("El color es Violeta");
			setMatrix(118,1,193);
            break;
    }
    
    USART_Enviar_String(" | ");
    
    char String[6];
    USART_Enviar_String("La diferencia con la original es de: ");
    
    USART_Enviar_String("("); 
    int16_t temp = (int16_t)r - (int16_t)RGBList[IndiceMenor][0];
    sprintf(String, "%d", temp);
    USART_Enviar_String(String);
    USART_Enviar_String(", ");
    
    temp = (int16_t)g - (int16_t)RGBList[IndiceMenor][1];
    sprintf(String, "%d", temp);
    USART_Enviar_String(String);
    USART_Enviar_String(", ");
    
    temp = (int16_t)b - (int16_t)RGBList[IndiceMenor][2];
    sprintf(String, "%d", temp);
    USART_Enviar_String(String);
    USART_Enviar_String(") ");
    USART_Enviar_String("\n\n");
	return IndiceMenor;
}