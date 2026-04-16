/*
 * PWM2.c
 *
 * Created: 15/04/2026 21:37:31
 *  Author: María Olga
 */ 

#include "PWM2.h"

void initPWM2(uint8_t salidaA, uint8_t salidaB, uint8_t modo, uint8_t prescaler)
{
    // Limpieza de registros
    TCCR2A = 0;
    TCCR2B = 0;
    TCNT2  = 0;
	
	if (salidaA == no_invertido || salidaA == invertido)
	{
		DDRB |= (1 << DDB3);   // OC2A en PB3
	}
	
	if (salidaB == no_invertido || salidaB == invertido)
	{
		DDRD |= (1 << DDD3);   // OC2B en PD3
	}
 
    // Configuración de OC2A
    if (salidaA == no_invertido)
		TCCR2A |= (1 << COM2A1);
    else if (salidaA == invertido)
		TCCR2A |= (1 << COM2A1) | (1 << COM2A0);
 
    // Configuración de OC2B
    if (salidaB == no_invertido)
		TCCR2A |= (1 << COM2B1);
    else if (salidaB == invertido)
		TCCR2A |= (1 << COM2B1) | (1 << COM2B0);
 
    // Modo PWM  - Fast
     TCCR2A |= (1 << WGM21) | (1 << WGM20); 
	 TCCR2B |= (1 << CS22) | (1 << CS21) | (1 << CS20);               
 
	// Posicionamiento 90°
	OCR2A = servo2_mid;
    OCR2B = servo2_mid;
 
    // Prescaler y arranque del timer 
    switch (prescaler)
    {
        case prescaler_1:
            TCCR2B |= (1 << CS20);
            break;
        case prescaler_8:
            TCCR2B |= (1 << CS21);
            break;
        case prescaler_64:
            TCCR2B |= (1 << CS21) | (1 << CS20);
            break;
        case prescaler_256:
            TCCR2B |= (1 << CS22) | (1 << CS21);
            break;
        case prescaler_1024:
            TCCR2B |= (1 << CS22) | (1 << CS21) | (1 << CS20);
            break;
        default:
            TCCR2B |= (1 << CS22) | (1 << CS21) | (1 << CS20);
            break;
    }
}
 
void servoAngulo2A(uint8_t angulo)
{
    if (angulo > 180U) 
	angulo = 180U;

    uint16_t ticks = 16 + (uint16_t)(15 * angulo) / 180U;
    OCR2A = (uint8_t)ticks;
}

void servoAngulo2B(uint8_t angulo)
{
	if (angulo > 180U)
	angulo = 180U;

	uint16_t ticks = 16 + (uint16_t)(15 * angulo) / 180U;
	OCR2B = (uint8_t)ticks;
}