/*
 * PWM.c
 *
 * Created: 11/11/2025 21:43:04
 *  Author: David
 */ 

#include "PWM.h"

// ==================== DEFINICIÓN DE PINES ====================
/*
 * Pines CORREGIDOS:
 * - Sonido:    Pin 9  (PB1) - OC1A
 * - Motor 1:   Pin 3  (PD3) - OC2B  
 * - Motor 2:   Pin 11 (PB3) - OC2A
 * 
 * Pines de dirección:
 * - MOTOR1_IN1: Pin 5 (PD5)
 * - MOTOR1_IN2: Pin 6 (PD6) 
 * - MOTOR2_IN1: Pin 7 (PD7)
 * - MOTOR2_IN2: Pin 8 (PB0)
 */

// ==================== INICIALIZACIÓN GENERAL ====================
void pwm_init_all(void) {
    motors_init();  // Primero motores (Timer2)
    sound_init();   // Luego sonido (Timer1)
}

// ==================== FUNCIONES DE SONIDO ====================
void sound_init(void) {
    // Configurar pin de sonido como salida (Pin 9 - PB1 - OC1A)
    DDRB |= (1 << DDB1);
    
    // Timer1 para audio - Fast PWM 8-bit, no invertido
    TCCR1A = (1 << COM1A1) | (1 << WGM10);  // OC1A no invertido, Fast PWM 8-bit
    TCCR1B = (1 << WGM12) | (1 << CS10);    // Fast PWM, no prescaler
    
    OCR1A = 0;  // Silencio inicial
}

void sound_play(uint8_t amplitude) {
    OCR1A = amplitude;  // 0-255 directo al PWM
}

// ==================== FUNCIONES PARA MOTORES ====================
void motors_init(void) {
    // Configurar pines PWM de motores como salidas
    DDRD |= (1 << DDD3);   // Pin 3  - PD3 - OC2B - Motor 1
    DDRB |= (1 << DDB3);   // Pin 11 - PB3 - OC2A - Motor 2
    
    // Configurar pines de dirección como salidas
    DDRD |= (1 << MOTOR1_IN1) | (1 << MOTOR1_IN2) | (1 << MOTOR2_IN1);  // Pines 5,6,7
    DDRB |= (1 << MOTOR2_IN2);  // Pin 8
    
    // Timer2 - Fast PWM dual para ambos motores, no invertido
    TCCR2A = (1 << COM2A1) | (1 << COM2B1) | (1 << WGM21) | (1 << WGM20);
    // COM2A1: OC2A no invertido (Pin 11)
    // COM2B1: OC2B no invertido (Pin 3)  
    // WGM21|WGM20: Fast PWM
    
    TCCR2B = (1 << CS22);  // Prescaler 64 -> ~490Hz 
    
    // Apagar motores inicialmente
    OCR2A = 0;  // Motor 2 velocidad 0 (Pin 11)
    OCR2B = 0;  // Motor 1 velocidad 0 (Pin 3)
    
    // Poner motores en STOP
    motor1_set(MOTOR_STOP, 0);
    motor2_set(MOTOR_STOP, 0);
}

void motor1_set(uint8_t direction, uint8_t speed) {
    if (speed > 100) speed = 100;
    
    // Configurar dirección del Motor 1 (Pines 5 y 6)
    switch (direction) {
        case MOTOR_FORWARD:
            PORTD |= (1 << MOTOR1_IN1);   // IN1 = HIGH
            PORTD &= ~(1 << MOTOR1_IN2);  // IN2 = LOW
            break;
        case MOTOR_BACKWARD:
            PORTD &= ~(1 << MOTOR1_IN1);  // IN1 = LOW
            PORTD |= (1 << MOTOR1_IN2);   // IN2 = HIGH
            break;
        case MOTOR_STOP:
        default:
            PORTD &= ~(1 << MOTOR1_IN1);  // IN1 = LOW
            PORTD &= ~(1 << MOTOR1_IN2);  // IN2 = LOW
            speed = 0;
            break;
    }
    
    // Configurar velocidad PWM (0-255) - Pin 3 (OC2B)
    uint8_t duty = (255 * speed) / 100;
    OCR2B = duty;
}

void motor2_set(uint8_t direction, uint8_t speed) {
    if (speed > 100) speed = 100;
    
    // Configurar dirección del Motor 2 (Pines 7 y 8)
    switch (direction) {
        case MOTOR_FORWARD:
            PORTD |= (1 << MOTOR2_IN1);   // IN1 = HIGH
            PORTB &= ~(1 << MOTOR2_IN2);  // IN2 = LOW
            break;
        case MOTOR_BACKWARD:
            PORTD &= ~(1 << MOTOR2_IN1);  // IN1 = LOW
            PORTB |= (1 << MOTOR2_IN2);   // IN2 = HIGH
            break;
        case MOTOR_STOP:
        default:
            PORTD &= ~(1 << MOTOR2_IN1);  // IN1 = LOW
            PORTB &= ~(1 << MOTOR2_IN2);  // IN2 = LOW
            speed = 0;
            break;
    }
    
    // Configurar velocidad PWM (0-255) - Pin 11 (OC2A)
    uint8_t duty = (255 * speed) / 100;
    OCR2A = duty;
}

void motors_stop(void) {
    motor1_set(MOTOR_STOP, 0);
    motor2_set(MOTOR_STOP, 0);
}

void motors_set(uint8_t dir1, uint8_t speed1, uint8_t dir2, uint8_t speed2) {
    motor1_set(dir1, speed1);
    motor2_set(dir2, speed2);
}
