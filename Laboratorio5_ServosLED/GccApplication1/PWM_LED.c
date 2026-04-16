/*
 * PWM_LED.c
 *
 * Created: 15/04/2026 21:58:00
 *  Author: María Olga
 */

#include "PWM_LED.h"
#include <avr/interrupt.h>

static volatile uint8_t s_contador = 0;    
static volatile uint8_t s_umbral   = 128;

void PWM_LED_init(void)
{
	/* 1. PD5 (Pin 5) como salida para el LED */
	LED_DDR  |= (1 << LED_PIN);
	LED_PORT &= ~(1 << LED_PIN);   /* Iniciar apagado */
	
	/* 2. Limpiar registros del Timer0 */
	TCCR0A = 0;
	TCCR0B = 0;
	TCNT0  = 0;
	
	TIMSK0 |= (1 << TOIE0);
	TCCR0B |= (1 << CS01);
	sei();
	}
	
void PWM_LED_setUmbral(uint8_t umbral)
	{
		s_umbral = umbral;
	}
	
ISR(TIMER0_OVF_vect)
	{
		if (s_contador == 0)
		{
			/* Inicio del ciclo: poner LED en ALTO */
			LED_PORT |= (1 << LED_PIN);
		}
		
		if (s_contador >= s_umbral)
		{
			/* Se alcanzo el umbral: poner LED en BAJO */
			LED_PORT &= ~(1 << LED_PIN);
		}
		
		s_contador++;   /* uint8_t desborda de 255 a 0 automaticamente */
	}

 
