/*
 * UART.h
 *
 * Created: 28/10/2025 12:30:20
 *  Author: David
 */ 


#ifndef UART_H_
#define UART_H_

void UART_Init();
char UART_Receive(void);
void UART_Enviar_String(const char* str);


#endif /* UART_H_ */