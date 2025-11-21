/*
 * UART.h
 *
 * Created: 14/10/2025 16:34:49
 *  Author: David
 */ 


#ifndef UART_H_
#define UART_H_

void USART_Init();
void USART_Enviar(char data);
char USART_Receive(void);
void USART_Enviar_String(const char* str);
uint8_t USART_DatoDisponible(void);
#endif /* UART_H_ */