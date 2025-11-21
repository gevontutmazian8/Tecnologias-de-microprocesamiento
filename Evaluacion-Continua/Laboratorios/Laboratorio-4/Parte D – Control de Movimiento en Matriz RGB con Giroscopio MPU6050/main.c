/*
 * main.c
 * Adaptado para matriz 16x16 con conexión en zig-zag
 */ 
#define F_CPU 16000000UL

#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>
#include <stdlib.h>

#include "MyLib/LEDS.h"
#include "Mylib/UART.h"
#include "Mylib/I2C.h"

#define BOTON_PIN 2
#define MATRIX_SIZE 16
#define MAX_COORD (MATRIX_SIZE - 1)

// Direcciones I2C del MPU6050
#define MPU6050_ADDR 0x68
#define MPU6050_ACCEL_XOUT_H 0x3B
#define MPU6050_PWR_MGMT_1 0x6B

// Variables globales para almacenar datos del acelerómetro
int16_t accel_x, accel_y, accel_z;
int8_t x = 7;  // Centro en matriz 16x16
int8_t y = 7;  // Centro en matriz 16x16
uint8_t r = 100, g = 0, b = 0;

// Variables para calibración
int16_t base_x = 0, base_y = 0;
uint8_t calibrated = 0;

// Prototipos de funciones MPU6050
void MPU6050_Init(void);
void MPU6050_ReadAccel(void);
void MPU6050_Calibrate(void);
uint8_t Test_I2C_Comunication(void); 

uint16_t coordenadasALedIndex(int8_t x, int8_t y) {
    // Para matriz 16x16 en patrón serpentín (zig-zag)
    // Las filas pares van de izquierda a derecha (0, 2, 4, ...)
    // Las filas impares van de derecha a izquierda (1, 3, 5, ...)
    
    if (y % 2 == 0) {
        // Filas pares: dirección normal
        return (y * MATRIX_SIZE) + x;
    } else {
        // Filas impares: dirección invertida
        return (y * MATRIX_SIZE) + (MATRIX_SIZE - 1 - x);
    }
}

int main(void)
{
	// Configuración inicial
	DDRD &= ~(1 << BOTON_PIN);
	PORTD |= (1 << BOTON_PIN);
	
	// Inicializar UART primero
	USART_Init();
	_delay_ms(1000);
	USART_Enviar_String("=== SISTEMA 16x16 INICIADO ===\n");
	
	// Inicializar I2C
	I2C_Init();
	_delay_ms(100);
	
	// Testear comunicación I2C
	if (!Test_I2C_Comunication()) {
		USART_Enviar_String("ERROR: Comunicacion I2C fallida\n");
		while(1) {
			// LED rojo de error
			setMatrix(255, 0, 0);
			_delay_ms(500);
			setMatrix(0, 0, 0);
			_delay_ms(500);
		}
	}
	
	// Inicializar MPU6050
	MPU6050_Init();
	initLEDs();
	
	USART_Enviar_String("Sistema listo - Calibrando...\n");
	
	// Calibrar el acelerómetro
	MPU6050_Calibrate();
	
	// Mostrar punto inicial en el centro
	setMatrix(0, 0, 0);
	uint16_t led_index = coordenadasALedIndex(x, y);
	setLedRGB(led_index, r, g, b);
	show();
	
	// Mostrar información de la matriz
	char buffer[80];
	sprintf(buffer, "Matriz 16x16 - Centro: (%d,%d) -> LED %d\n", x, y, led_index);
	USART_Enviar_String(buffer);
	
	USART_Enviar_String("Punto inicial en centro. Mueve el dispositivo.\n");
	
	while(1)
	{
		MPU6050_ReadAccel();
		
		// Calcular diferencias respecto a la posición de calibración
		int16_t diff_x = accel_x - base_x;
		int16_t diff_y = accel_y - base_y;
		
		// Umbrales para movimiento - AJUSTAR SEGÚN PRUEBAS
		#define UMBRAL_MOVIMIENTO 10000
		
		uint8_t moved = 0;
		int8_t new_x = x;
		int8_t new_y = y;
		
		// Control de movimiento basado en la inclinación
		if (diff_x > UMBRAL_MOVIMIENTO && x < MAX_COORD) {
			new_x++;
			USART_Enviar_String("-> Izquierda\n");
			moved = 1;
		}
		else if (diff_x < -UMBRAL_MOVIMIENTO && x > 0) {
			new_x--;
			USART_Enviar_String("<- Derecha\n");
			moved = 1;
		}
		
		if (diff_y < -UMBRAL_MOVIMIENTO && y < MAX_COORD) {
			new_y++;
			USART_Enviar_String("v Abajo\n");
			moved = 1;
		}
		else if (diff_y > UMBRAL_MOVIMIENTO && y > 0) {
			new_y--;
			USART_Enviar_String("^ Arriba\n");
			moved = 1;
		}
		
		// Control del botón para cambiar color
		if (!(PIND & (1 << BOTON_PIN))) {
			_delay_ms(50); // Debounce
			
			// Esperar hasta que se suelte el botón
			while (!(PIND & (1 << BOTON_PIN))) {
				_delay_ms(10);
			}
			
			// Generar nuevos colores aleatorios
			r = rand() % 256;
			g = rand() % 256;
			b = rand() % 256;
			
			USART_Enviar_String("Color cambiado\n");
			moved = 1; // Forzar actualización para mostrar nuevo color
		}
		
		// Solo actualizar la matriz si hubo movimiento o cambio de color
		if (moved) {
			// Actualizar coordenadas
			x = new_x;
			y = new_y;
			
			// Limpiar matriz y dibujar el nuevo punto
			setMatrix(0, 0, 0);
			uint16_t led_index = coordenadasALedIndex(x, y);
			setLedRGB(led_index, r, g, b);
			show();
			}
		
		// Retardo para controlar la velocidad de actualización
		_delay_ms(10);
	}
}

uint8_t Test_I2C_Comunication(void)
{
	USART_Enviar_String("Testeando comunicacion I2C...\n");
	
	// Intentar leer el registro WHO_AM_I (debería devolver 0x68)
	I2C_Start();
	I2C_Write(MPU6050_ADDR << 1);
	I2C_Write(0x75); // WHO_AM_I register
	I2C_Start(); // Repeated start
	I2C_Write((MPU6050_ADDR << 1) | 0x01);
	uint8_t whoami = I2C_Read(0);
	I2C_Stop();
	
	char buffer[30];
	sprintf(buffer, "WHO_AM_I = 0x%02X\n", whoami);
	USART_Enviar_String(buffer);
	
	return (whoami == 0x68); // Debería ser 0x68
}

void MPU6050_Calibrate(void)
{
	USART_Enviar_String("Calibrando... (mantener estable)\n");
	
	// Leer varias muestras para promediar
	int32_t sum_x = 0, sum_y = 0;
	uint8_t muestras = 20;
	
	for(uint8_t i = 0; i < muestras; i++) {
		MPU6050_ReadAccel();
		sum_x += accel_x;
		sum_y += accel_y;
		_delay_ms(50);
	}
	
	base_x = sum_x / muestras;
	base_y = sum_y / muestras;
	calibrated = 1;
	
	char buffer[60];
	sprintf(buffer, "Calibrado - Base X:%d Y:%d\n", base_x, base_y);
	USART_Enviar_String(buffer);
}

void MPU6050_Init(void)
{
	// Reset completo
	I2C_Start();
	I2C_Write(MPU6050_ADDR << 1);
	I2C_Write(0x6B); // PWR_MGMT_1
	I2C_Write(0x80); // Device Reset
	I2C_Stop();
	_delay_ms(100);
	
	// Despertar
	I2C_Start();
	I2C_Write(MPU6050_ADDR << 1);
	I2C_Write(0x6B); // PWR_MGMT_1
	I2C_Write(0x00); // Despertar
	I2C_Stop();
	_delay_ms(50);
	
	// Configurar acelerómetro ±2g
	I2C_Start();
	I2C_Write(MPU6050_ADDR << 1);
	I2C_Write(0x1C); // ACCEL_CONFIG
	I2C_Write(0x00); // ±2g
	I2C_Stop();
	_delay_ms(50);
	
	USART_Enviar_String("MPU6050 OK\n");
}

void MPU6050_ReadAccel(void)
{
	uint8_t data[6];
	
	// Lectura de registros
	I2C_Start();
	I2C_Write(MPU6050_ADDR << 1);
	I2C_Write(MPU6050_ACCEL_XOUT_H);
	I2C_Start();
	I2C_Write((MPU6050_ADDR << 1) | 0x01);
	
	for (uint8_t i = 0; i < 6; i++) {
		data[i] = I2C_Read(i < 5);
	}
	I2C_Stop();
	
	// Intercambiar ejes para corregir orientación
	accel_x = (int16_t)((data[4] << 8) | data[5]);  // Z original como X
	accel_y = (int16_t)((data[2] << 8) | data[3]);  // Y se mantiene
	accel_z = -(int16_t)((data[0] << 8) | data[1]); // X original como -Z
}