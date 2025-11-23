/*
 * PWM.h
 *
 * Created: 11/11/2025 21:43:19
 *  Author: David
 */ 


#ifndef PWM_H_
#define PWM_H_

#define  F_CPU 16000000UL
#include <avr/io.h>
#include <util/delay.h>

// ==================== DEFINICIÓN DE PINES ====================
// Pines PWM (Timer1 y Timer2)
#define PWM_SOUND  9   // PB1 - OC1A - Sonido
#define PWM_MOTOR1 10  // PB2 - OC1B - Motor 1
#define PWM_MOTOR2 11  // PB3 - OC2A - Motor 2

// Pines de dirección para motores (Pines 5,6,7,8)
#define MOTOR1_IN1  5  // PD5 - Dirección motor 1
#define MOTOR1_IN2  6  // PD6 - Dirección motor 1
#define MOTOR2_IN1  7  // PD7 - Dirección motor 2
#define MOTOR2_IN2  PB0  // PB0 - Dirección motor 2

// Estados de motor
#define MOTOR_FORWARD  2
#define MOTOR_BACKWARD 1
#define MOTOR_STOP     0

// ==================== PROTOTIPOS DE FUNCIONES ====================
// Inicialización
void pwm_init_all(void);

// Funciones para sonido
void sound_init(void);
void sound_play(uint8_t amplitude);

// Funciones para motores
void motors_init(void);
void motor1_set(uint8_t direction, uint8_t speed);
void motor2_set(uint8_t direction, uint8_t speed);
void motors_stop(void);
void motors_set(uint8_t dir1, uint8_t speed1, uint8_t dir2, uint8_t speed2);



#endif /* PWM_H_ */