/*
 * PWM2.h
 *
 * Created: 15/04/2026 21:37:16
 *  Author: María Olga
 */ 


#ifndef PWM2_H_
#define PWM2_H_

#include <avr/io.h>
#include <stdint.h>
 
#define no_invertido   0U
#define invertido      1U
 
#define fastPWM        1U
#define phasePWM       0U
 
#define prescaler_1    1U
#define prescaler_8    2U
#define prescaler_64   3U
#define prescaler_256  4U
#define prescaler_1024 5U
 
#define servo2_min      16U
#define servo2_mid	    23U
#define servo2_max      31U
 
void initPWM2(uint8_t salidaA, uint8_t salidaB, uint8_t modo, uint8_t prescaler);
void servoAngulo2A(uint8_t angulo);
void servoAngulo2B(uint8_t angulo);

#endif /* PWM2_H_ */