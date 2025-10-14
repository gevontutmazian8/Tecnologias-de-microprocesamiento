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

#define LED_PIN 6
#define WIDTH 8 
#define HEIGHT 8
#define NUM_LEDS (WIDTH*HEIGHT)  

uint8_t leds[NUM_LEDS][3];


#define BAUD 9600
#define MYUBRR (F_CPU/16/BAUD-1)


#define ADC_PIN 0

// Definición para 50 Hz y Prescaler 256
#define PWM_TOP_50HZ 1249

#define CENTER_PULSE 94   // ~1.5 ms -> (1.5ms * 1250 / 20ms) = 93.75

// ----------------------PROTOTIPOS--------------------------
void sendBit(uint8_t bitVal);
void sendByte(uint8_t byte);
void show (uint8_t (*colors)[3]);
void setLedRGB(uint8_t (*leds)[3], int ledIndex, uint8_t r, uint8_t g, uint8_t b);

void USART_Init();
void USART_Enviar(char data);
char USART_Receive(void);
void USART_Enviar_String(const char* str);

void LDR_Init();
uint16_t LDR_read(uint8_t channel);

int main() {
	PWM_Init();

	while(1) {
		// Mover a 0 grados (extremo izquierdo)
		PWM_Move(0);
		_delay_ms(1000); // Esperar 1 segundo en la posición 0

		// Mover a 180 grados (extremo derecho)
		PWM_Move(180);
		_delay_ms(1000); // Esperar 1 segundo en la posición 180

		// Mover a 90 grados (centro)
		PWM_Move(90);
		_delay_ms(1000); // Esperar 1 segundo en la posición 90
	}
	return 0;
}

//-----------------Funciones de comunicacion con el WS2812B-----------------

void sendBit(uint8_t bitVal){
	if(bitVal){
		//T1H ~0.8us en alto
		PORTD |= (1 << LED_PIN);
		asm volatile (
			"nop\n\t""nop\n\t""nop\n\t""nop\n\t""nop\n\t"
			"nop\n\t""nop\n\t""nop\n\t""nop\n\t"
		);
		PORTD &= ~(1 << LED_PIN);
		//T1L ~0.45 us en alto
		asm volatile (
			"nop\n\t""nop\n\t""nop\n\t""nop\n\t"
		);
	} else {
		//T0H ~0.4us en alto
		PORTD |= (1 << LED_PIN);
		asm volatile(
			"nop\n\t""nop\n\t""nop\n\t"
		);
		PORTD &= ~(1<<LED_PIN);
		//T0L ~0.85us en bajo
		asm volatile(
			"nop\n\t""nop\n\t""nop\n\t""nop\n\t""nop\n\t"
			"nop\n\t""nop\n\t""nop\n\t""nop\n\t""nop\n\t"	
		);

	}
}

void sendByte(uint8_t byte){
	for (uint8_t i = 0; i < 8; i++){
		sendBit(byte & (1<< (7 - i)));
	}
}

void show (uint8_t (*colors)[3]){
	cli();
	for (int i = 0; i < NUM_LEDS; i++){
		sendByte(colors[i][1]);
		sendByte(colors[i][0]);
		sendByte(colors[i][2]);
	}
	sei();
	_delay_us(60);
}

void setLedRGB(uint8_t (*leds)[3], int ledIndex, uint8_t r, uint8_t g, uint8_t b){
	if (ledIndex < 0 || ledIndex >= NUM_LEDS) return;
	leds[ledIndex][0] = r;
	leds[ledIndex][1] = g;
	leds[ledIndex][2] = b;
}


//------------------------Funciones USART---------------------------
void USART_Init() {
	// Configurar baud rate
	UBRR0H = (unsigned char)(MYUBRR >> 8);
	UBRR0L = (unsigned char)(MYUBRR);
	
	// Habilitar receptor y transmisor
	UCSR0B = (1 << RXEN0) | (1 << TXEN0);
	
	// Configurar formato: 8 bits de datos, 1 bit de parada
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

void USART_Enviar(char data) {
	// Esperar a que el buffer de transmision ese te vacio
	while (!(UCSR0A & (1 << UDRE0)));
	
	// Poner dato en el buffer
	UDR0 = data;
}

char USART_Receive(void) {
	// Esperar a que llegue un dato
	while (!(UCSR0A & (1 << RXC0)));
	
	// Devolver dato recibido
	return UDR0;
}

void USART_Enviar_String(const char* str) { //Recibe un string y lo recorre enviando los caracteres 1x1
	while (*str) {
		USART_Enviar(*str);
		str++;
	}
}


//------------------------Funciones LDR---------------------------

void LDR_Init(){
	// REFS0=1, REFS1=0 -> VCC como voltaje de referencia 
	// ADLAR=0 -> Ajuste a la derecha (ADCL tiene LSB, ADCH tiene MSB)
	// MUX3:0=0000 -> Selecciona el canal ADC0
	ADMUX = (1 << REFS0) | (0 << ADLAR) | (0 << MUX0);
	// ADEN=1 -> Habilitar el ADC
	// ADPS2:0=111 -> Preescalador de 128 
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
}
	
uint16_t LDR_read(uint8_t channel) {
	
	ADMUX = (ADMUX & 0xF0) | (channel & 0x0F);
	
	// Iniciar la conversión (ADSC=1)
	ADCSRA |= (1 << ADSC);
	
	// Esperar a que la conversión termine 
	while (ADCSRA & (1 << ADSC));

	// Leer el resultado de 10 bits
	uint16_t resultado = ADCL;
	resultado |= (ADCH << 8); // Combina los 2 bits de ADCH con los 8 de ADCL
	
	return resultado; // Valor de 0 a 1023
}

//------------------------Funciones Servomotor---------------------------


void PWM_Init(){
	DDRB |= (1 << DDB1);
	
	TCCR1A = (1 << COM1A1) | (1 << WGM11);
	TCCR1B = (1 << WGM13) | (1 << WGM12) | (1 << CS12);
	
	ICR1 = PWM_TOP_50HZ;
	
	OCR1A = CENTER_PULSE;
	
}

void PWM_Move(uint8_t Angle) {
	// Para los  0   grados : 1.0ms -> 63  = 1.0ms * 1250 /20ms
	// Para los  180 grados : 2.0ms -> 125 = 2.0ms * 1250 /20ms
	// Para los  90  grados : 1.5ms -> 94  = 1.5ms * 1250 /20ms

	uint16_t pulse_range = 125 - 63; // 62
	uint16_t temp_pulse;
	
	// La fórmula corrige: OCR1A = (Angle / 180) * 62 + 63
	// Usando aritmética de enteros:
	temp_pulse = ((uint16_t)Angle * pulse_range) / 180;
	
	// Sumar el offset mínimo (0 grados)
	OCR1A = (uint8_t)(temp_pulse + 63);
}