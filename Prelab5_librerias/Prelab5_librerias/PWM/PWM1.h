/*
 * PWM1.h
 *
 * Created: 13/04/2026 22:47:52
 *  Author: María Olga
 */ 


#ifndef PWM1_H_
#define PWM1_H_

#include <avr/io.h>
#include <stdint.h>

#define invertido	 1U
#define no_invertido 0U

#define fastPWM  1U
#define phasePWM 0U

#define prescaler_1	   1U
#define prescaler_8	   2U
#define prescaler_64   3U
#define prescaler_256  4U
#define prescaler_1024 5U

#define ICR1_50Hz	3999U
#define servo_min	2000U		// 1ms para 0°
#define servo_max	4000U		// 2ms para 180°


void initPWM1(uint8_t salidaA, uint8_t salidaB, uint8_t modo, uint8_t prescaler);
void updateDutyCycle1A(uint16_t ciclo);
void updateDutyCycle1B(uint16_t ciclo);
void servoAngulo(uint8_t angulo);

#endif /* PWM1_H_ */