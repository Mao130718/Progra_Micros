/*
 * Laboratorio5_Servos.c
 *
 * Created: 16/04/2026 00:25:03
 * Author: María Olga Joachín
 * Description: Funcionameitno de dos servos y la intensidad de un LED utilizando PWM y ADC
 */
/****************************************/
// Encabezado (Libraries)

#define F_CPU 16000000UL
#include <avr/io.h>
#include <util/delay.h>
#include "PWM1.h"
#include "PWM2.h"
#include "PWM_LED.h"

/****************************************/
// Function prototypes
void setup(void);
void initADC(void);
uint16_t readADC(uint8_t channel);

/****************************************/
// Main Function
int main(void)
{
	uint16_t adcVal = 0;
	uint8_t angulo = 0;
	uint8_t brillo = 0; 
	
	setup();
	initADC();
	
	initPWM1(no_invertido, no_invertido, fastPWM, prescaler_8);
	initPWM2(no_invertido, no_invertido, fastPWM, prescaler_1024);
	PWM_LED_init();
	
	while(1)
	{
		adcVal = readADC(0);
		angulo = (uint8_t)(((uint32_t)adcVal * 180UL) / 1023UL);
		servoAngulo1A(angulo);
		
		adcVal = readADC(1);
		angulo = (uint8_t)(((uint32_t)adcVal * 180UL) / 1023UL);
		servoAngulo1B(angulo);
		
		adcVal = readADC(2);
		angulo = (uint8_t)(((uint32_t)adcVal * 180UL) / 1023UL);
		servoAngulo2A(angulo);
		
		adcVal = readADC(3);
		brillo = (uint8_t)(adcVal>>2);
		PWM_LED_setUmbral(brillo);
		
		_delay_ms(20);
	}
}

/****************************************/
// NON-Interrupt subroutines
void setup(void)
{
	CLKPR = (1<<CLKPCE);
	CLKPR = 0;
}

void initADC(void)
{
	ADMUX = (1<<REFS0);
	
	ADCSRA = (1<<ADEN) | (1<<ADPS2) |(1<<ADPS1) |(1<<ADPS0);
	ADCSRA |= (1<<ADSC);
	
	while (ADCSRA & (1<<ADSC));
}

uint16_t readADC(uint8_t channel)
{
	ADMUX = (ADMUX & 0xF0) | (channel & 0x07);
	_delay_us(10);
	
	ADCSRA |= (1 << ADSC);
	while (ADCSRA & (1 << ADSC));
	
	return ADC;
}

/****************************************/
// Interrupt routines
