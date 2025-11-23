/*
 * main.c
 *
 * Created: 11/8/2025 2:14:22 PM
 *  Author: David
 */ 

#define F_CPU 16000000UL

#include <avr/io.h>
#include <util/delay.h>

#include "MyLib/OLED.h"
#include "MyLib/I2C.h"
#include "MyLib/Millis.h"
#include "MyLib/Sound.h"
#include "MyLib/PWM.h"
#include "MyLib/UART.h"
#include <avr/wdt.h>


// Prototipos 
void Init();


//Funcion Principal
int main(void) {
	Init();
	
	uint32_t last_sample_time = 0;
	uint16_t Sound_Position = 0;
	uint8_t WhichSoundIsPlaying = 0;
	
	uint8_t WhichFaceIHave = 1;
	uint8_t Change = 1;
	
	while(1) {
		uint32_t current_time = micros();
	// ===================== SONIDOS ============================
	
		// =================== OH MY GOD ========================
		/*
			- Si WhichSoundIsPlaying es 1 se reproduce este sonido
			- El sonido es Ohhhh My God
		*/
		if(current_time - last_sample_time >= 200 && WhichSoundIsPlaying == 1) {
			sound_play(getAmplitudOhMyGod(Sound_Position));
			Sound_Position++;
			
			if(Sound_Position >= 5892) {
				sound_play(125);
				Sound_Position = 0;
				WhichSoundIsPlaying = 0;
			}
			
			last_sample_time = current_time;
		}
		
		// =================== Risa Perro ========================
		/*
			- Si WhichSoundIsPlaying es 2 se reproduce este sonido
			- El sonido es Risa de Perro meme
		*/
		if(current_time - last_sample_time >= 200 && WhichSoundIsPlaying == 2) {
			
			if (Sound_Position < 6253)
			{
				sound_play(getAmplitudDogFirst(Sound_Position));			//GENERA LA PRIMERA RISA
			
			} else if (Sound_Position > 6253 && Sound_Position < 6996){
				
				sound_play(getAmplitudVacio(Sound_Position - 6253));		//GENERA SILENCIO 1 
			
			} else if (Sound_Position > 6996 && Sound_Position < 7739)
			{
			
				sound_play(getAmplitudVacio(Sound_Position - 6996));		//GENERA SILENCIO 2
			
			} else if (Sound_Position > 7739 && Sound_Position < 8482)
			{
			
				sound_play(getAmplitudVacio(Sound_Position - 7739));		//GENERA SILENCIO 3
			
			} else if (Sound_Position > 8482 && Sound_Position < 9225)
			{
			
				sound_play(getAmplitudVacio(Sound_Position - 8482));		//GENERA SILENCIO 4
			
			} else if (Sound_Position > 9225 && Sound_Position < 16140)
			{
			
				sound_play(getAmplitudSecond(Sound_Position - 9225));		//GENERA RISA 2
			
			} else if (Sound_Position > 16140 && Sound_Position < 16883)
			{
			
				sound_play(getAmplitudVacio(Sound_Position - 16140));		//GENERA SILENCIO 1
			
			} else if (Sound_Position > 16883 && Sound_Position < 17626)
			{
			
				sound_play(getAmplitudVacio(Sound_Position - 16883));		//GENERA SILENCIO 2
			
			} else if (Sound_Position > 17626 && Sound_Position < 18369)
			{
			
				sound_play(getAmplitudVacio(Sound_Position - 17626));		//GENERA SILENCIO 3
			
			} else if (Sound_Position > 18369 && Sound_Position < 25284)
			{
			
				sound_play(getAmplitudSecond(Sound_Position - 18369));		//GENERA RISA 3
			
			}
			
			Sound_Position++;
			
			if(Sound_Position >= 25284) {
				sound_play(125);
				Sound_Position = 0;
				WhichSoundIsPlaying = 0;
			}
			
			last_sample_time = current_time;
		}
		
	//============================ ROSTROS ======================================
		
		//================================== CARA FELIZ =====================================
		if (Change && WhichFaceIHave == 1) // Si hay algun cambio y el rostro es 1 que la cara sea feliz
		{
			OLED_ClearBuffer();
			HappyFace();
			OLED_Update();
			Change = 0;
		}
		
		//================================== CARA ENOJADO =====================================
		if (Change && WhichFaceIHave == 2) // Si hay algun cambio y el rostro es 1 que la cara sea enojada
		{
			OLED_ClearBuffer();
			AngryFace();
			OLED_Update();
			Change = 0;
		}
		
		//================================== CARA  FAIL =====================================
		if (Change && WhichFaceIHave == 3) // Si hay algun cambio y el rostro es 1 que la cara sea triste
		{
			OLED_ClearBuffer();
			FailFace();
			OLED_Update();
			Change = 0;
		}
		
	//================================== FUNCIONALIDAD BLUETOOTH =====================================
	/*
	Comandos recibidos por BLUETOOTH
		1,2,3,4,5 -> Destinados a la gestion de los rostros ---> Acutalmente el 4 y 5 estan desocupados
		6,7,8,9   -> Destinados a la gestion de sonidos     ---> Acutalmente el 8 y 9 estan desocupados
		
	*/
	if(USART_DatoDisponible())
	{
		char Comando = USART_Receive();
		USART_Enviar(Comando);
		switch (Comando){
			
			// ========= GESTION DE GESTOS ==========
			case 'M':
			Change = 1;
			WhichFaceIHave = 1;
			break;
			
			case 'm':
			Change = 1;
			WhichFaceIHave = 2;
			break;
			
			case 'N':
			Change = 1;
			WhichFaceIHave = 3;
			break;
			
			// ========= GESTION DE SONIDOS ==========
			
			case 'n':
			WhichSoundIsPlaying = 1;
			break;
			
			case 'Y':
			WhichSoundIsPlaying = 2;
			break;
			
			
			// ========= GESTION DE MOTORES ==========
			//====== MOTOR 1 - ADELANTE ====== 
			
			case 'S':
			motor1_set(MOTOR_FORWARD, 0);
			motor2_set(MOTOR_FORWARD, 0);
			break;
			
			case 'F':
			motor1_set(MOTOR_FORWARD, 100);
			motor2_set(MOTOR_FORWARD, 100);
			break;
			
			case 'E':
			motor1_set(MOTOR_FORWARD, 100);
			motor2_set(MOTOR_FORWARD, 50);
			break;
			
			case 'R':
			motor1_set(MOTOR_FORWARD, 100);
			motor2_set(MOTOR_BACKWARD, 100);
			break;
			
			case 'C':
			motor1_set(MOTOR_BACKWARD, 50);
			motor2_set(MOTOR_BACKWARD, 100);
			break;
			
			case 'B':
			motor1_set(MOTOR_BACKWARD, 100);
			motor2_set(MOTOR_BACKWARD, 100);
			break;
			
			
			case 'Q':
			motor2_set(MOTOR_FORWARD, 100);
			motor1_set(MOTOR_FORWARD, 50);
			break;
			
			case 'L':
			motor2_set(MOTOR_FORWARD, 100);
			motor1_set(MOTOR_BACKWARD, 100);
			break;
			
			case 'Z':
			motor2_set(MOTOR_BACKWARD, 50);
			motor1_set(MOTOR_BACKWARD, 100);
			break;
			
		}
	}
	}
	return 0;
}


// ==================== FUNCIONES ====================
void Init(){
	wdt_disable();
	
	I2C_Init();
	
	init_millis();
	
	pwm_init_all();
	USART_Init();
	
	_delay_ms(100); 
	OLED_Init();
	_delay_ms(100); 
	
	OLED_ClearBuffer();
	OLED_Update();
	
}