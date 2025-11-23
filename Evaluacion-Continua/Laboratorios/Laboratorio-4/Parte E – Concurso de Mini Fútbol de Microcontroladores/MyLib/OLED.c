/*
 * OLED.c - Versión corregida sin warnings
 */

#define F_CPU 16000000UL

#include <avr/io.h>
#include <util/delay.h>
#include "I2C.h" 
#include "OLED.h"  

// Buffer para la pantalla (128x64 píxeles, organizado en 8 páginas de 128 bytes)
uint8_t oled_buffer[8][128];

// ===== FUNCIONES BÁSICAS OLED =====

void OLED_Command(uint8_t cmd) {
    I2C_Start();
    I2C_Write(OLED_ADDRESS << 1);
    I2C_Write(OLED_COMMAND);
    I2C_Write(cmd);
    I2C_Stop();
}

void OLED_Data(uint8_t data) {
    I2C_Start();
    I2C_Write(OLED_ADDRESS << 1);
    I2C_Write(OLED_DATA);
    I2C_Write(data);
    I2C_Stop();
}

void OLED_Init(void) {
    OLED_Command(0xAE);
    OLED_Command(0xD5);
    OLED_Command(0x80);
    OLED_Command(0xA8);
    OLED_Command(0x3F);
    OLED_Command(0xD3);
    OLED_Command(0x00);
    OLED_Command(0x40);
    OLED_Command(0x8D);
    OLED_Command(0x14);
    OLED_Command(0x20);
    OLED_Command(0x00);
    OLED_Command(0xA1);
    OLED_Command(0xC8);
    OLED_Command(0xDA);
    OLED_Command(0x12);
    OLED_Command(0x81);
    OLED_Command(0xCF);
    OLED_Command(0xD9);
    OLED_Command(0xF1);
    OLED_Command(0xDB);
    OLED_Command(0x40);
    OLED_Command(0xA4);
    OLED_Command(0xA6);
    OLED_Command(0x2E);
    OLED_Command(0xAF);
}

void OLED_SetPosition(uint8_t page, uint8_t column) {
    OLED_Command(0xB0 + page);
    OLED_Command(0x00 + (column & 0x0F));
    OLED_Command(0x10 + ((column >> 4) & 0x0F));
}

void OLED_Clear(void) {
    for (uint8_t page = 0; page < 8; page++) {
        OLED_SetPosition(page, 0);
        for (uint8_t col = 0; col < 128; col++) {
            OLED_Data(0x00);
        }
    }
}

// ===== FUNCIONES DE DIBUJO =====

void OLED_SetPixel(uint8_t x, uint8_t y, uint8_t state) {
    if (x >= 128 || y >= 64) return;
    
    uint8_t page = y / 8;
    uint8_t bit_mask = 1 << (y % 8);
    
    if (state) {
        oled_buffer[page][x] |= bit_mask;
    } else {
        oled_buffer[page][x] &= ~bit_mask;
    }
}

int abs(int x) {
    return (x < 0) ? -x : x;
}

void OLED_DrawLine(uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1) {
    int dx = abs((int)x1 - (int)x0);
    int dy = abs((int)y1 - (int)y0);
    int sx = (x0 < x1) ? 1 : -1;
    int sy = (y0 < y1) ? 1 : -1;
    int err = dx - dy;
    
    while (1) {
        OLED_SetPixel(x0, y0, 1);
        if (x0 == x1 && y0 == y1) break;
        int e2 = 2 * err;
        if (e2 > -dy) {
            err -= dy;
            x0 += sx;
        }
        if (e2 < dx) {
            err += dx;
            y0 += sy;
        }
    }
}

void OLED_DrawFilledOval(uint8_t x0, uint8_t y0, uint8_t width, uint8_t height) {
	int a = width / 2;
	int b = height / 2;
	int a2 = a * a;
	int b2 = b * b;
	int twoa2 = 2 * a2;
	int twob2 = 2 * b2;
	
	int x = 0;
	int y = b;
	int px = 0;
	int py = twoa2 * y;
	
	// Región 1
	int p = b2 - (a2 * b) + (a2 / 4);
	while (px < py) {
		// Dibujar líneas horizontales
		for (int i = -x; i <= x; i++) {
			OLED_SetPixel(x0 + i, y0 + y, 1);
			OLED_SetPixel(x0 + i, y0 - y, 1);
		}
		
		x++;
		px += twob2;
		if (p < 0) {
			p += b2 + px;
			} else {
			y--;
			py -= twoa2;
			p += b2 + px - py;
		}
	}
	
	// Región 2
	p = b2 * (x + 1) * (x + 1) + a2 * (y - 1) * (y - 1) - a2 * b2;
	while (y >= 0) {
		// Dibujar líneas horizontales
		for (int i = -x; i <= x; i++) {
			OLED_SetPixel(x0 + i, y0 + y, 1);
			OLED_SetPixel(x0 + i, y0 - y, 1);
		}
		
		y--;
		py -= twoa2;
		if (p > 0) {
			p += a2 - py;
			} else {
			x++;
			px += twob2;
			p += a2 - py + px;
		}
	}
}


// ===== FUNCIONES DE ACTUALIZACIÓN =====

void OLED_Update(void) {
    for (uint8_t page = 0; page < 8; page++) {
        OLED_SetPosition(page, 0);
        for (uint8_t col = 0; col < 128; col++) {
            OLED_Data(oled_buffer[page][col]);
        }
    }
}

void OLED_ClearBuffer(void) {
    for (uint8_t page = 0; page < 8; page++) {
        for (uint8_t col = 0; col < 128; col++) {
            oled_buffer[page][col] = 0x00;
        }
    }
}

// ===== ROSTROS PREDEFINIDOS =====

void HappyFace(){//64 32 
	
	OLED_DrawFilledOval(24, 27, 24, 36);
	OLED_DrawFilledOval(104, 27, 24, 36);
	
	OLED_DrawLine(64,55,70,50);
	OLED_DrawLine(64,55,58,50);
}

void FailFace(){//64 32
	
	OLED_DrawLine(20,45,40,20);
	OLED_DrawLine(21,45,41,20);
	
	OLED_DrawLine(20,20,40,45);
	OLED_DrawLine(21,20,41,45);
	
	OLED_DrawLine(108,20,88,45);
	OLED_DrawLine(109,20,89,45);	

	OLED_DrawLine(108,45,88,20);
	OLED_DrawLine(109,45,89,20);


	OLED_DrawLine(64,50,70,55);
	OLED_DrawLine(64,50,58,55);
}

void AngryFace(){
	OLED_DrawLine(64,50,70,55);
	OLED_DrawLine(64,50,58,55);

	OLED_DrawFilledOval(34, 30, 14, 23);
	OLED_DrawFilledOval(94, 30, 14, 23);
	
	OLED_DrawFilledOval(34, 30, 14, 23);
	OLED_DrawFilledOval(94, 30, 14, 23);
	
	OLED_DrawLine(29,5,45,15);
	OLED_DrawLine(29,6,45,16);
	
	OLED_DrawLine(83,15,99,5);
	OLED_DrawLine(83,16,99,6);
		
}