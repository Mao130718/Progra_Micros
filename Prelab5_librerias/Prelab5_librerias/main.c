/*
 * Prelab5_librerias.c
 *
 * Created: 13/04/2026 13:29:17
 * Author: María Olga Joachin
 * Description: Creación de librerías para el movimiento de servos	
 */
/****************************************/
// Encabezado (Libraries)
#define F_CPU 16000000
#include <avr/io.h>
#include <util/delay.h>
#include "PWM/PWM1.h"

/****************************************/
// Function prototypes
void setup();
void initADC();
uint16_t readADC();

/****************************************/
// Main Function
int main(void)
{
	uint16_t adcval = 0;
	uint8_t angulo = 0;
	
	setup();
	initADC();
	initPWM1(no_invertido, no_invertido, fastPWM, prescaler_8);
	
	while (1)
	{
		
		adcval = readADC();
		angulo = (uint8_t)(((uint32_t)adcval*180UL)/1023UL);
		servoAngulo(angulo);
		_delay_ms(20);
	}
}
/****************************************/
// NON-Interrupt subroutines
void setup()
{
	CLKPR = (1<<CLKPCE);
	CLKPR = 0;
}

void initADC()
{
	// Pin A0 como referencia
	ADMUX = (1<<REFS0);
	
	// Se habilita ADC con prescaler de 128
	ADCSRA = (1<<ADEN) | (1<<ADPS2)	| (1<<ADPS1) | (1<<ADPS0); 
	ADCSRA |= (1<<ADSC);
	while (ADCSRA & (1<<ADSC));
}

uint16_t readADC()
{
	ADCSRA |= (1<<ADSC);
	while (ADCSRA & (1<<ADSC));
	return ADC;
}
/****************************************/
// Interrupt routines