#define F_CPU 16000000UL

#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>  
#include "UART.h"

// Configuración para 50Hz con prescaler 256
#define PWM_TOP_50HZ 1249

// Valores de pulso
#define PULSE_0deg   25    
#define PULSE_90deg  78  
#define PULSE_180deg 130 

void PWM_Init() {
    DDRB |= (1 << DDB1);
    TCCR1A = (1 << COM1A1) | (1 << WGM11);
    TCCR1B = (1 << WGM13) | (1 << WGM12) | (1 << CS12);
    ICR1 = PWM_TOP_50HZ;
    OCR1A = PULSE_90deg;
    _delay_ms(100);
}

void PWM_Move(uint8_t angle) {
    uint16_t pulse_width;
    
    if (angle > 180) angle = 180;
    
    // Método DIRECTO
    if (angle <= 0) {
        pulse_width = PULSE_0deg;
    } else if (angle >= 180) {
        pulse_width = PULSE_180deg;
    } else if (angle == 90) {
        pulse_width = PULSE_90deg;
    } else {
        // Interpolación lineal simple
        if (angle < 90) {
            // De 0° a 90°
            pulse_width = PULSE_0deg + ((angle * (PULSE_90deg - PULSE_0deg)) / 90);
        } else {
            // De 90° a 180°
            pulse_width = PULSE_90deg + (((angle - 90) * (PULSE_180deg - PULSE_90deg)) / 90);
        }
    }

    
    OCR1A = pulse_width;
    _delay_ms(100);  //Tiempo para asegurar movimiento
}