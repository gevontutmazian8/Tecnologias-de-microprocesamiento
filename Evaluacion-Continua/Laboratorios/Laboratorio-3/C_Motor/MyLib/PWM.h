/*
 * PWM.h
 *
 * Created: 14/10/2025 16:45:37
 *  Author: David
 */ 


#ifndef PWM_H_
#define PWM_H_

#define MOTOR_DIR_PIN1 PB0
#define MOTOR_DIR_PIN2 PB1

// 500Hz: 16MHz / (8 prescaler * 4000) - 1 = 3999
#define PWM_TOP_MOTOR 3999

void Motor_SetDirection(uint8_t dir);
void PWM_SetDutyPercent(uint8_t percent);
void PWM_Init(void);
void PWM_Disable(void);
void PWM_Enable(void);

#endif /* PWM_H_ */