/*
 * main.c
 *
 * Created: 10/1/2025 12:14:55 AM
 *  Author: David
 */

#define F_CPU 16000000UL  
#define BAUD 9600
#define MYUBRR (F_CPU/16/BAUD-1)  

#define  P_Bajar     PD2
#define  P_Subir     PD3
#define  P_Abajo     PD4
#define  P_Arriba    PD5
#define  P_Izquierda PD6
#define  P_Derecha   PD7

#define  Delay		 15

#include <avr/io.h>
#include <util/delay.h>  

void USART_Init();
void USART_Enviar(char data);
char USART_Receive(void);
void USART_Enviar_String(const char* str);
void InitMov();

void Menu();
void InitMov();
void MovDerecha(uint8_t Pasos);
void MovIzquierda(uint8_t Pasos);
void MovArriba(uint8_t Pasos);
void MovAbajo(uint8_t Pasos);
void Bajar();
void Subir();
void Linea(int Dx, int Dy);


int main(void){
    USART_Init();  
	InitMov();
    Menu();
    
    while(1){
        char Opcion = USART_Receive();
        switch (Opcion)
        {
	        case 'w':
				MovArriba(100);
				break;
	        case 's':
				MovAbajo(100);
				break;
	        case 'a':
				MovDerecha(100);
				break;
	        case 'd':
				MovIzquierda(100);
				break;
				
			case 'q':
				Bajar();
				break;
			case 'e':
				Subir();
				break;
			
			
			case '1':
				Triangulo();
				break;
			case '2':
				Cruz();
				break;
			case '3':
				Circulo();
				Subir();
				break;
			case '4':
				Triangulo();
				_delay_ms(5);
				MovIzquierda(250);
				_delay_ms(5);
				Cruz();
				_delay_ms(5);
				MovIzquierda(250);
				_delay_ms(5);
				Circulo();
				break;
				
			case 'g':
				Gato();
				break;
			case 'r':
				Raton();
				break;
			case 't':
				Gato();
				_delay_ms(5);
				MovDerecha(255);
				_delay_ms(5);
				Raton();
				break;
			
        }
    }
    return 0;
}

//----------------------MENU----------------------------------
void Menu(){
	USART_Enviar_String("-----------------MENU---------------------\n\n");
	USART_Enviar_String("	> w- Mover hacia arriba\n");
	USART_Enviar_String("	> s- Mover hacia abajo\n");
	USART_Enviar_String("	> a- Mover hacia la derecha\n");
	USART_Enviar_String("	> d- Mover hacia la izquierda\n\n");
	
	USART_Enviar_String("	> 1- Dibujar triangulo\n");
	USART_Enviar_String("	> 2- Dibujar cruz\n");
	USART_Enviar_String("	> 3- Dibujar circulo\n");
	USART_Enviar_String("	> 4- Dibujar todo\n\n");
	
	USART_Enviar_String("	> g- Dibujar Gato\n");
	USART_Enviar_String("	> r- Dibujar Raton\n");
	USART_Enviar_String("	> t- Dibujar Gato y Raton\n\n");
	USART_Enviar_String("------------------------------------------");
}

//------------------Funciones USART---------------------------

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
    // Esperar a que el buffer de transmisión esté vacío
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


//---------------Funciones de movimiento-----------------------

void InitMov(){
	DDRD |= (1 << P_Bajar);
	DDRD |= (1 << P_Subir);
	DDRD |= (1 << P_Abajo);
	DDRD |= (1 << P_Derecha);
	DDRD |= (1 << P_Izquierda);
	DDRD |= (1 << P_Arriba);
}

void MovDerecha(uint8_t Pasos){
	//Encendemos el motor
	PORTD |= (1 << P_Derecha);
	
	//Agregamos un delay en base al intervalo minimo permitido por el circuito
	for (Pasos; Pasos > 0; Pasos--)
	{
		_delay_ms(Delay);
	}
	
	//Apagamos el motor
	_delay_ms(5);
	PORTD &= ~(1 << P_Derecha);
	_delay_ms(5);
}

void MovIzquierda(uint8_t Pasos){
	//Encendemos el motor
	PORTD |= (1 << P_Izquierda);
	
	//Agregamos un delay en base al intervalo minimo permitido por el circuito
	for (Pasos; Pasos > 0; Pasos--)
	{
		_delay_ms(Delay);
	}
	//Apagamos el motor
	_delay_ms(5);
	PORTD  &= ~(1 << P_Izquierda);
	_delay_ms(5);
}

void MovArriba(uint8_t Pasos){
	//Encendemos el motor
	PORTD |= (1 << P_Arriba);
	
	//Agregamos un delay en base al intervalo minimo permitido por el circuito
	for (Pasos; Pasos > 0; Pasos--)
	{
		_delay_ms(Delay);
	}
	//Apagamos el motor
	_delay_ms(5);
	PORTD  &= ~(1 << P_Arriba);
	_delay_ms(5);
}

void MovAbajo(uint8_t Pasos){
	//Encendemos el motor
	PORTD |= (1 << P_Abajo);
	
	//Agregamos un delay en base al intervalo minimo permitido por el circuito
	for (Pasos; Pasos > 0; Pasos--)
	{
		_delay_ms(Delay);
	}
	//Apagamos el motor
	_delay_ms(5);
	PORTD  &= ~(1 << P_Abajo);
	_delay_ms(5);
}

void Bajar(){
	//Encendemos el motor
	PORTD |= (1 << P_Bajar);
	
	//Agregamos un delay en base al intervalo minimo permitido por el circuito
	
	for (volatile uint8_t Pasos = 10; Pasos > 0; Pasos--)
	{
		_delay_ms(Delay);
	}
	//Apagamos el motor
	_delay_ms(5);
	PORTD  &= ~(1 << P_Bajar);
}

void Subir(){
	//Encendemos el motor
	PORTD |= (1 << P_Subir);
	
	//Agregamos un delay en base al intervalo minimo permitido por el circuito
	for (volatile uint8_t Pasos = 10; Pasos > 0; Pasos--)
	{
		_delay_ms(Delay);
	}
	//Apagamos el motor
	_delay_ms(5);
	PORTD  &= ~(1 << P_Subir);
}

void Linea(int Dx, int Dy) {	
	int tempDx = Dx;
	int tempDy = Dy;
		
	
	if (tempDx == 0) {  // Línea vertical
		
		if (tempDy > 0) {
			MovArriba(tempDy);
			} else if (tempDy < 0) {
			MovAbajo(-tempDy);
		}
		return;
		} else if (tempDy == 0) {  // Línea horizontal
		
		if (tempDx > 0) {
			MovDerecha(tempDx);
			} else if (tempDx < 0) {
			MovIzquierda(-tempDx);
		}
		return;
	}

	// Para diagonales - Bresenham con ajuste de escala
	int IncX = (tempDx > 0) ? 1 : -1;
	int IncY = (tempDy > 0) ? 1 : -1;
	
	int dx = (tempDx > 0) ? tempDx : -tempDx;
	int dy = (tempDy > 0) ? tempDy : -tempDy;
	
	
	int err = dx - dy;
	int steps = (dx > dy) ? dx : dy;
	
	for (int i = 0; i <= steps; i++) {
		int e2 = 2 * err;
		
		if (e2 > -dy) {
			err -= dy;
			if (IncX > 0) {
				MovDerecha(1);
				} else {
				MovIzquierda(1);
			}
		}
		
		if (e2 < dx) {
			err += dx;
			if (IncY > 0) {
				MovArriba(1);
				} else {
				MovAbajo(1);
			}
		}
	}
}

//--------------------------Figuras-----------------------------------

void Circulo(){
	Bajar();
	
	volatile int8_t Dx[] = {
		-1,  -2, -6, -8, -10, -12, -13, -14, -15, -16,
		-16, -15, -14, -13, -12, -10, -8, -6,  -3,  -1,
		1,   3,  6,  8,  10,  12,  12,  14,  15,  16,
		16,  15,  15,  14,  13,  12,  8,  7,   4,   4
	};
	
	volatile int8_t Dy[] = {
		16,  15,  14,  13,  12,  10,  8,  6,   3,   1,
		-1,  -3, -6, -8, -10, -12, -13, -14, -15, -16,
		-16, -15, -14, -13, -12, -10, -8, -6,  -3,  -1,
		1,   3,  6,  8,  10,  12,  13,  14,  15,  16
	};

	for (uint8_t i = 0; i < 40 ; i++)
	{
		Linea(Dx[i], Dy[i]);
	}
	Subir();
	
}

void Triangulo(){
	Bajar();
	Linea(80,80);
	Linea(80, -79);
	Linea(-210,0);
	Subir();
}

void Cruz(){
	Bajar();
	Linea(30, 0);
	Linea(0, -50);
	
	Linea(50, 0);
	Linea(0, -30);
	Linea(-50, 0);
	
	Linea(0, -100);
	Linea(-28, 0);
	Linea(0, 100);
	
	Linea(-46, 0);
	Linea(0, 30);
	Linea(50, 0);
	
	Linea(0, 53);
	Subir();
}

void Gato(){
	Bajar();
	
	volatile int8_t Dx[] = {-10, -9, -7, -2, -2, -2, -1, -1, 0, 0, 1, 2, 2, 2, 2, 0, 0, -2, -2, 0, 0, -4, -4, -1, -4, -7, -5, -6, -10, -4, -1, 2, 4, 6, 1, 2, 2, 1, 1, 0, -1, -2, -1, -1, -2, -4, -2, -2, -7, -1, -2, -6, -15, -14, -7, -6, -7, -2, -5, -4, -1, 0, 1, 1, 2, 2, 4, 4, 4, 5, 1, 2, 4, 5, 10, 6, 3, 2, 3, 3, 3, 6, 4, 4, 3, 1, 2, -2, -2, -2, -2, -2, -1, 0, 1, 1, 1, 5, 2, 1, 4, 5, 3, 2, 4, 4, 2, 2, 1, 2, 2, 3, 2, 1, 2, 4, 1, 2, 3, 4, 6, 6, 1, 1, 0, 0, 1, 1, 3, 6, 3, 3, 9, 7, 6, 5, 7, 8, 3, 2, 1, 1, 1, 0, 2, 9, 6, 3, 0, 0, 1, 2, 3, 4, 10, 12, 6, 8, 11, 9, 12, 4, 0, -3, -5, -11, -10, -8, -4, -3, -6, -7, -4, -2, 0, 0, -1, -3, -4, -6, -8, -7, -10, -16, -15, -16, -10, -9, 0, 50, 20, 9, 14, 8, 2, 1, 0, 1, 14, 16, 5, 17, 6, 2, -6, -8, -15, -15, -9, -8, -8, -6, -2, 1, 0, -2, -9, -9, -4, -4, -1, 0, 0, 1, 1, 0, -4, -3, -16, -26, -10, -5, -2, 0, -1, -1, -6, -6, -4, -3, -4, -2, 0, -1, -3, -3, -2, -2};
	
	volatile int8_t Dy[] = {1, 2, 2, 1, 2, 3, 3, 3, 2, 2, 2, 2, 1, 1, 1, 1, 1, 8, 8, 0, 0, -12, -12, -2, -7, -6, -2, -1, 3, 5, 6, 6, 4, 2, 1, 9, 14, 11, 11, 13, 22, 15, 3, 4, 7, 15, 8, 8, 25, 3, 3, 7, 20, 28, 20, 24, 27, 2, 3, 7, 3, 7, 3, 1, 2, 1, 1, -1, -3, -6, -2, -3, -8, -10, -23, -17, -8, -4, -3, -2, -1, 0, 0, 0, 0, 0, 1, 1, 1, 2, 4, 5, 6, 7, 7, 1, 1, 2, 1, 0, 3, 6, 4, 2, 2, 1, 0, 1, 1, 4, 5, 11, 5, 0, -1, -8, -4, -15, -13, -13, -12, -18, -8, -15, -3, -5, -20, -4, -6, -7, -3, -2, -6, -5, -6, -6, -13, -22, -14, -15, -16, -33, -33, -1, 0, 11, 11, 16, 8, 46, 58, 19, 11, 9, 14, 8, 1, 0, -2, -5, -13, -15, -4, 0, 1, 8, 6, 2, 0, -1, -5, -13, -15, -33, -15, -22, -73, -14, -9, -8, -8, -4, -4, -3, -2, -1, 0, 1, 0, 5, 5, 4, 13, 16, 11, 35, 82, 15, 39, 8, -2, -11, -1, 3, 11, 8, 6, -1, -5, -8, -16, -33, -25, -61, -29, -13, -19, -6, -3, -7, -5, 4, 4, 4, 4, 23, 65, 19, 36, 26, 9, 9, 6, 23, 23, 7, 16, 12, 8, 13, 17, -20, -19};


	for (uint8_t i = 0; i < 186 ; i++)
	{
		Linea(Dx[i] / 2, Dy[i] / 2);
	}
	Subir();
}

void Raton(){
	Bajar();
	
	volatile int8_t Dx[] = {-9, -7, -9, -7, -19, -26, -26, -9, -11, -8, 1, 3, 1, 0, 1, 13, 6, 5, 25, 2, 0, 2, 2, 3, 3, -6, -10, 0, 3, 2, 0, 4, 4, 6, 4, 2, 0, -1, -2, -1, -3, -7, -3, -15, -2, -2, -2, -1, -1, 0, 0, -1, -1, 0, 0, -2, -9, -11, -2, 1, 12, 23, 26, 11, 2, -1, -2, 0, 0, -1, -4, 1, 4, 6, 1, 1, 1, 2, 2, 5, 5, 1, 1, 0, 2, 13, 2, 0, 0, 2, 2, 4, 4, 4, 4, 0, 0, 4, 4, 0, 0, -11, -19, -13, -14, -2, 0, -1, -5, 5, 8, 7, 3, 1, 6, 16, 6, 7, 27, 8, 2, 6, 5, 2, 1, 1, 0, -1, -6, -18, -6, -2, 2, 2, 1, 0, 3, 10, 2, 1, 4, 13, 11, 15, 5, 2, -1, -2, -2, 0, 1, 6, 12, 16, 15, 2, 0, 1, 1, 4, 11, 4, 8, 3, -1, -4, -5, -6, -6, -2, -2, -23, -24, -1, -1, -2, -2, -1, -1, -1, -3, -3, -2, -1, -1, 0, -1, -40, -40, -40};
	
	volatile int8_t Dy[] = {10, 9, 7, -1, -8, -3, 1, 3, 10, 15, 16, 10, 2, 1, 6, 25, 9, 5, 24, 5, 1, 0, 0, 7, 27, 20, 17, 2, 2, -2, -1, -4, -4, -8, -9, -14, -14, -5, -5, -4, -8, -10, -3, -17, -3, -3, -3, 0, 0, -1, -1, 0, 0, -1, -1, -3, -13, -23, -9, -10, -14, -3, 8, 6, 3, 4, 4, 1, 1, 2, 13, 29, 20, 13, 2, 4, 4, 3, 3, 9, 9, 1, 1, 1, 5, 14, 3, 1, 1, 2, 2, 5, 5, 4, 4, 1, 1, 4, 4, 1, 0, 1, 2, 4, 9, 4, 1, 1, 7, 18, 9, 4, 1, 1, 3, 2, 0, -1, -15, -20, -2, 2, 3, 0, 1, 1, 1, 0, 2, 17, 9, 9, 18, 2, 0, 1, 7, 3, 0, 1, 3, 2, -3, -11, -8, -14, -11, -7, -7, -1, -1, 0, -2, -9, -14, -4, -1, 0, 0, -6, -14, -2, -3, -7, -4, -4, -2, 0, 1, 1, 1, 0, 0, -16, -14, -12, -12, -11, -11, -5, -24, -34, -30, -24, -19, -1, 0, -2, -3, -6};


	for (uint8_t i = 0; i < 190 ; i++)
	{
		Linea(Dx[i]/2, Dy[i]/2);
	}
	Subir();
}
