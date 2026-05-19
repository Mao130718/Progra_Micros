/*
 * PWM.h
 *
 * Created: 11/05/2026 00:32:31
 *  Author: María Olga
 */ 

#ifndef PWM_H
#define PWM_H

#include "AVR_CORE.h"

// Se define la cantidad total de servos 
#define NUM_SERVOS 6

// Para inicializar timers y configura pines de salida para los 6 servos
void pwm_init(void);

// Mueve el servo (0-5) al angulo dado (0-180 grados)
void pwm_servo_write(uint8_t idx, uint8_t angulo);

// Devuelve el ultimo angulo enviado al servo 
uint8_t pwm_servo_read(uint8_t idx);

// Mueve todos los servos a la posicion neutra que son 90 grados
void pwm_neutro(void);

#endif /* PWM_H */