#define F_CPU 16000000UL

#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>
#include <util/delay.h>

// Definición de pines para los LEDs
#define LED1 PD2
#define LED2 PD3
#define LED3 PD4
#define LED4 PD5
#define LED5 PD6

// Prototipos de funciones
void configurar_puertos(void);
void configurar_timer1(void);
void encender_leds(void);
void apagar_leds(void);

// Variables globales
volatile uint8_t modo_actual = 0;
volatile uint16_t contador_segundos = 0;
volatile uint8_t cambio_pendiente = 0;

ISR(TIMER1_COMPA_vect) {
	contador_segundos++;
	
	if (contador_segundos >= 30) { // 30 segundos exactos
		contador_segundos = 0;
		cambio_pendiente = 1;
	}
}

void configurar_timer1(void) {
	// Timer1 para 1 segundo exacto con 16MHz
	TCCR1A = 0;
	TCCR1B = (1 << WGM12) | (1 << CS12) | (1 << CS10); // CTC, prescaler 1024
	OCR1A = 15624; // 16MHz/1024/15625 = 1Hz (1 segundo)
	TIMSK1 = (1 << OCIE1A);
}

void configurar_puertos(void) {
	DDRD |= (1 << LED1) | (1 << LED2) | (1 << LED3) | (1 << LED4) | (1 << LED5);
	encender_leds(); // Encender todos al inicio
}

void encender_leds(void) {
	PORTD |= (1 << LED1) | (1 << LED2) | (1 << LED3) | (1 << LED4) | (1 << LED5);
}

void apagar_leds(void) {
	PORTD &= ~((1 << LED1) | (1 << LED2) | (1 << LED3) | (1 << LED4) | (1 << LED5));
}

int main(void) {
	configurar_puertos();
	configurar_timer1();
	sei();
	
	// Los LEDs empiezan ENCENDIDOS
	encender_leds();
	
	while(1) {
		// Verificar si pasaron 30 segundos
		if (cambio_pendiente) {
			cambio_pendiente = 0;
			modo_actual = (modo_actual + 1) % 4;
			
			// Cambiar estado de LEDs según el modo
			if (modo_actual == 0) {
				apagar_leds(); 
				} else {
				encender_leds();
			}
		}
		
		// Ejecutar el modo actual
		switch(modo_actual) {
			case 0: // MODO ACTIVO - LEDs APAGADOS 30s
			// Permanecer activo - NO entrar en sleep
			_delay_ms(100);
			break;
			
			case 1: // IDLE - LEDs ENCENDIDOS 30s
			set_sleep_mode(SLEEP_MODE_IDLE);
			sleep_enable();
			sleep_cpu();
			sleep_disable();
			break;
			
			case 2: // ADC NOISE REDUCTION - LEDs ENCENDIDOS 30s
			set_sleep_mode(SLEEP_MODE_ADC);
			sleep_enable();
			sleep_cpu();
			sleep_disable();
			break;
			
			case 3: // POWER DOWN - LEDs ENCENDIDOS 30s
			set_sleep_mode(SLEEP_MODE_PWR_DOWN);
			sleep_enable();
			sleep_cpu();
			sleep_disable();
			break;
		}
	}
	
	return 0;
}