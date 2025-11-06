/*
 * PWM.h
 *
 * Created: 14/10/2025 16:45:37
 *  Author: David
 */ 

#define F_CPU 16000000UL
#include <avr/io.h>
#include <stdint.h>

// Frecuencia más alta para motor DC (~500Hz - 1kHz)
#define PWM_TOP_MOTOR 1999    // Para ~500Hz con prescaler 64
#define PWM_PRESCALER (1 << CS11) | (1 << CS10)  // Prescaler 64

#define MOTOR_DIR_PIN1 PB0
#define MOTOR_DIR_PIN2 PB2

void PWM_Init(void) {
	DDRB |= (1 << MOTOR_DIR_PIN1) | (1 << MOTOR_DIR_PIN2) | (1 << DDB1);
	
	// Timer1 - Fast PWM, TOP = ICR1, prescaler 64 (~500Hz)
	TCCR1A = (1 << COM1A1) | (1 << WGM11);
	TCCR1B = (1 << WGM13) | (1 << WGM12) | (1 << CS11) | (1 << CS10);
	
	ICR1 = PWM_TOP_MOTOR;
	OCR1A = 0;
}

void PWM_SetDutyPercent(uint8_t percent) {
	if (percent > 100) percent = 100;
	
	// Rango completo - el doble de duty cycle efectivo
	uint16_t max_duty = PWM_TOP_MOTOR;
	OCR1A = (max_duty * percent) / 100;
}

void Motor_SetDirection(uint8_t dir) {
	switch(dir) {
		case 0:  // Frenar
		PORTB &= ~((1 << MOTOR_DIR_PIN1) | (1 << MOTOR_DIR_PIN2));
		break;
		case 1:  // Adelante
		PORTB |= (1 << MOTOR_DIR_PIN1);
		PORTB &= ~(1 << MOTOR_DIR_PIN2);
		break;
		case 2:  // Atrás
		PORTB |= (1 << MOTOR_DIR_PIN2);
		PORTB &= ~(1 << MOTOR_DIR_PIN1);
		break;
	}
}

void PWM_Disable(void) {
	TCCR1A &= ~(1 << COM1A1);
	OCR1A = 0;
	PORTB &= ~(1 << PB1);
}

void PWM_Enable(void) {
	TCCR1A |= (1 << COM1A1);
}