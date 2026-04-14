/*
 * PWM1.c
 *
 * Created: 13/04/2026 23:03:43
 *  Author: María Olga
 */
 
#include "PWM1.h"

void initPWM1(uint8_t salidaA, uint8_t salidaB, uint8_t modo, uint8_t prescaler)
{
	// Se configuran salidas
	DDRB |= (1<<DDB1) | (1<<DDB2);
	TCCR1A = 0;
	TCCR1B = 0;
	TCNT1  = 0;
	
	// Configuración para OC1A
	if (salidaA == no_invertido)
	{
		TCCR1A |= (1<<COM1A1);	
	}
	else
	{
		TCCR1A |= (1<<COM1A1) | (1<<COM1A0);
	}
	
	// Configuración para OC1B
	if (salidaB == no_invertido)
	{
		TCCR1A |= (1<<COM1B1);
	}
	else
	{
		TCCR1A |= (1<<COM1B1) | (1<<COM1B0);
	}
	
	// Seleccion de modo de PWM (Fast o Phase Correct)
	if (modo == fastPWM)
	{
		TCCR1A |= (1<<WGM11);
		TCCR1B |= (1<<WGM13) | (1<<WGM12);
	}
	else
	{
		TCCR1A |= (1<<WGM11);
		TCCR1B |= (1<<WGM13);
	}
	
	// Se carga TOP para los 50Hz
	ICR1 = ICR1_50Hz;
	
	// Posición inicial del servo
	OCR1A = (servo_min + servo_max) / 2U;
	OCR1B = (servo_min + servo_max) / 2U;
	
	// Selección del Prescaler
	switch (prescaler)
	{
		case prescaler_1:
			TCCR1B |= (1 << CS10);
			break;
		case prescaler_8:
			TCCR1B |= (1 << CS11);
			break;
		case prescaler_64:
			TCCR1B |= (1 << CS11) | (1 << CS10);
			break;
		case prescaler_256:
			TCCR1B |= (1 << CS12);
			break;
		case prescaler_1024:
			TCCR1B |= (1 << CS12) | (1 << CS10);
			break;
		default:	// Como por default casi siempre va a ser de 8
			TCCR1B |= (1 << CS11);
			break;
	}
}
void updateDutyCycle1A(uint16_t ciclo)
{
	OCR1A = ciclo;
}
void updateDutyCycle1B(uint16_t ciclo)
{
	OCR1B = ciclo;
}
void servoAngulo(uint8_t angulo)
{
	if (angulo > 180U) angulo = 180U;
	
	uint16_t ticks = (uint16_t)(servo_min + ((uint32_t)angulo * (servo_max - servo_min)) / 180UL); 
	OCR1A = ticks;
}
