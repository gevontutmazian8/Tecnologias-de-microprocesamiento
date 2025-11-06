/*
 * main.c
 * 
 * Created: 10/29/2025 11:32:29 PM
 *  Author: David
 */ 

#define F_CPU 16000000UL

#define CHANNEL_1 0
#define CHANNEL_2 1

// Configuración para control PROPORCIONAL
#define PWM_MINIMO 15        // Mínimo PWM para vencer fricción
#define PWM_MAXIMO 80        // Máximo PWM permitido
#define HYSTERESIS 5        // Zona muerta para evitar oscilaciones
#define DIFERENCIA_MAXIMA 1023 // Diferencia máxima posible (0-1023)

// Parámetros de suavizado
#define RAMPA_ACELERACION 4  // Incremento máximo por ciclo
#define RAMPA_FRENADO 6      // Decremento máximo por ciclo

//				Librerias
#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdio.h>
#include <avr/io.h>

#include "MyLib/ADC.h"
#include "MyLib/UART.h"
#include "MyLib/PWM.h"

//				Prototipos
uint16_t Promedio(uint8_t channel);
uint8_t CalcPWM(int16_t err);
void ControlMotor(int16_t err, uint8_t pwm);

// Variables globales para suavizado
uint8_t pwm_actual = 0;

//				Main
int main(void){
	PWM_Init();
	ADC_Init();
	USART_Init();
	
	uint16_t Vref, Vprod;
	uint8_t PWM;
	int16_t err;
	char buffer_Total[30];
	
	// Inicialización suave del motor
	PWM_Disable();
	Motor_SetDirection(0);
	PWM_SetDutyPercent(0);
	
	while (1){
		_delay_ms(110);
		buffer_Total[0] = '\0';
		
		// Leer potenciómetros con filtrado
		Vref = Promedio(CHANNEL_1);
		_delay_ms(1);
		Vprod = Promedio(CHANNEL_2);
	
		
		// Calcular error con valores filtrados
		err = (int16_t)Vref - (int16_t)Vprod;
		PWM = CalcPWM(err);
		
		// Controlar motor con suavizado
		ControlMotor(err, PWM);

		// Enviar datos por serial
		snprintf(buffer_Total, sizeof(buffer_Total), "%u,%u,%u\n", Vref, Vprod, PWM);
		USART_Enviar_String(buffer_Total);
		
		_delay_ms(100); 
	}
	return 0;
}

//----------------Funciones----------------
uint16_t Promedio(uint8_t channel){
	uint32_t Resultado = 0;
	
	for (uint8_t i = 0; i < 8; i++)
	{
		Resultado += ADC_read(channel);
		_delay_ms(2);
	}
	
	return (uint16_t)(Resultado >> 3);
}

uint8_t CalcPWM(int16_t err) {
	// Tomar valor absoluto del error
	uint16_t error_abs = (err < 0) ? -err : err;
	
	// Si el error está dentro de la zona muerta, retornar 0
	if (error_abs <= HYSTERESIS) {
		return 0;
	}
	
	// Ajustar el error restando la histéresis
	error_abs -= HYSTERESIS;
	
	// Rango útil después de restar histéresis
	uint16_t rango_util = DIFERENCIA_MAXIMA - HYSTERESIS;
	
	// Calcular PWM proporcional al error
	// PWM = PWM_MINIMO + (error * (PWM_MAXIMO - PWM_MINIMO)) / rango_util
	uint32_t pwm_calculado;
	
	// Si el error es muy pequeño, usar PWM mínimo
	if (error_abs < (rango_util / 20)) { // Primera vigésima parte del rango
		pwm_calculado = PWM_MINIMO;
	} else {
		// Cálculo proporcional directo
		pwm_calculado = PWM_MINIMO + (uint32_t)error_abs * (PWM_MAXIMO - PWM_MINIMO) / rango_util;
	}
	
	// Asegurar que no exceda los límites
	if (pwm_calculado < PWM_MINIMO) {
		pwm_calculado = PWM_MINIMO;
	}
	if (pwm_calculado > PWM_MAXIMO) {
		pwm_calculado = PWM_MAXIMO;
	}
	
	return (uint8_t)pwm_calculado;
}


void ControlMotor(int16_t err, uint8_t pwm_deseado) {
	static uint8_t last_pwm = 0;
	static int8_t ultima_direccion = 0;
	int8_t direccion_actual = 0;
	
	// Determinar dirección actual
	if (err < -HYSTERESIS) {
		direccion_actual = -1; // Izquierda
	} else if (err > HYSTERESIS) {
		direccion_actual = 1;  // Derecha
	} else {
		direccion_actual = 0;  // Stop
	}
	
	// Aplicar rampa de aceleración/frenado
	if (pwm_deseado > last_pwm) {
		// Aceleración
		pwm_actual = last_pwm + ((pwm_deseado - last_pwm) > RAMPA_ACELERACION ? 
								RAMPA_ACELERACION : (pwm_deseado - last_pwm));
	} else if (pwm_deseado < last_pwm) {
		// Frenado
		pwm_actual = last_pwm - ((last_pwm - pwm_deseado) > RAMPA_FRENADO ? 
								RAMPA_FRENADO : (last_pwm - pwm_deseado));
	} else {
		pwm_actual = pwm_deseado;
	}
	
	// Control del motor
	if (pwm_actual > 0) {
		PWM_Enable();
		
		if (direccion_actual == -1) {
			Motor_SetDirection(1); // Izquierda
		} else if (direccion_actual == 1) {
			Motor_SetDirection(2); // Derecha
		}
		
		PWM_SetDutyPercent(pwm_actual);
	} else {
		// Motor apagado
		if (last_pwm > 0) {
			PWM_SetDutyPercent(0);
			_delay_ms(2);
		}
		PWM_Disable();
		Motor_SetDirection(0);
		pwm_actual = 0;
	}
	
	last_pwm = pwm_actual;
	ultima_direccion = direccion_actual;
}