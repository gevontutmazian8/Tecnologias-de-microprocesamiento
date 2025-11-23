/*
 * OLED.h
 * 
 * Created: 19/9/2025 
 * Author: David
 */

#ifndef OLED_H
#define OLED_H

#include <stdint.h>

// Direcciones y comandos OLED
#define OLED_ADDRESS 0x3C
#define OLED_COMMAND 0x00
#define OLED_DATA 0x40

// Buffer externo para acceso desde otros módulos
extern uint8_t oled_buffer[8][128];

// ===== FUNCIONES BÁSICAS OLED =====
void OLED_Command(uint8_t cmd);
void OLED_Data(uint8_t data);
void OLED_Init(void);
void OLED_SetPosition(uint8_t page, uint8_t column);
void OLED_Clear(void);
void OLED_Update(void);
void OLED_ClearBuffer(void);

// ===== FUNCIONES DE DIBUJO BÁSICAS =====
void OLED_SetPixel(uint8_t x, uint8_t y, uint8_t state);
void OLED_DrawLine(uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1);
void OLED_DrawCircle(uint8_t x0, uint8_t y0, uint8_t radius);
void OLED_DrawFilledOval(uint8_t x0, uint8_t y0, uint8_t width, uint8_t height);

// ===== FUNCIONES DE ROSTROS PREDEFINIDOS =====
void FailFace();
void HappyFace();
void AngryFace();

int abs(int x);

#endif /* OLED_H */