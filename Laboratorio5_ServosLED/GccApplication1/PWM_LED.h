/*
 * PWM_LED.h
 *
 * Created: 15/04/2026 21:57:47
 *  Author: María Olga
 */ 


#ifndef PWM_LED_H_
#define PWM_LED_H_

#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdint.h>

#define LED_PIN     PD5
#define LED_DDR     DDRD
#define LED_PORT    PORTD

void PWM_LED_init(void);
void PWM_LED_setUmbral(uint8_t umbral);

#endif /* PWM_LED_H_ */