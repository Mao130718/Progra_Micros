/*
 * Laboratorio6_UART.c
 *
 * Created: 27/04/2026 22:36:05
 * Author: María Olga Joachin
 * Description: Hacer uso de UART, con leds y potenciometro
 */
/****************************************/
// POSTLABORATORIO
// Encabezado (Libraries)
#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdlib.h>
#include "UART/UART.h"

volatile uint8_t dato_recibido = 0;
volatile char    caracter_rx   = 0;
/****************************************/
// Function prototypes


/****************************************/
// Main Function
//  Menú
void printMenu(void)
{
	writeString("\r\n----- MENU -----\r\n");
	writeString("1. Leer Potenciometro\r\n");
	writeString("2. Enviar Ascii\r\n");
	writeString("Seleccione una opcion: ");
}

//  ADC
void initADC(void)
{
	// REFS0=1: referencia AVCC
	// ADLAR=1: resultado ajustado a la izquierda (ADCH, 8 bits)
	// MUX2:0 = 101 canal ADC5 (pin A5)
	ADMUX  = (1<<REFS0) | (1<<ADLAR) | (1<<MUX2) | (1<<MUX0);

	// ADEN=1: enciende ADC
	// ADPS2..0=111: prescaler 128 ? 125 kHz a 16 MHz
	ADCSRA = (1<<ADEN) | (1<<ADPS2) | (1<<ADPS1) | (1<<ADPS0);
}

//  Main
int main(void)
{
	cli();

	// Puerto B como salida — bits 0-5 (pines D8-D13)
	DDRB |= (1<<DDB0)|(1<<DDB1)|(1<<DDB2)|(1<<DDB3)|(1<<DDB4)|(1<<DDB5);
	PORTB &= ~0x3F;

	// Puerto C como salida — bits 0-1 (pines A0, A1)
	DDRC |= (1<<DDC0)|(1<<DDC1);
	PORTC &= ~0x03;

	initUART();
	initADC();
	sei();

	printMenu();

	uint8_t estado = 0;

	while (1)
	{
		if (dato_recibido == 1)
		{
			dato_recibido = 0;
			char letra = caracter_rx;

			//  Estado 0: selección de menu
			if (estado == 0)
			{
				if (letra == '1')
				{
					writeString("1\r\n");

					// Disparar conversion ADC
					ADCSRA |= (1<<ADSC);
					while (ADCSRA & (1<<ADSC)); // espera fin de conversion
					uint8_t valorADC = ADCH;    // 8 bits (ADLAR=1)

					// Mostrar valor en LEDs:
					// Bits 0-5  Puerto B (D8-D13)
					PORTB = (PORTB & 0xC0) | (valorADC & 0x3F);
					// Bits 6-7  Puerto C bits 0-1 (A0, A1)
					PORTC = (PORTC & 0xFC) | ((valorADC >> 6) & 0x03);

					// Imprimir valor en decimal
					char buffer[5];
					itoa(valorADC, buffer, 10);
					writeString(">> Lectura del potenciometro: ");
					writeString(buffer);
					writeString("\r\n");

					printMenu();
				}
				else if (letra == '2')
				{
					writeString("2\r\n");
					writeString(">> Escriba cualquier tecla para mostrarla en LEDs: ");
					estado = 1;
				}
				else
				{
					writeString("\r\n>> Opcion invalida\r\n");
					printMenu();
				}
			}

			//  Estado 1: recibir tecla ASCII
			else if (estado == 1)
			{
				if (letra != '\n' && letra != '\r')
				{
					writeChar(letra);   // eco
					writeString("\r\n");

					// Bits 0-5  Puerto B
					PORTB = (PORTB & 0xC0) | (letra & 0x3F);
					// Bits 6-7 Puerto C bits 0-1
					PORTC = (PORTC & 0xFC) | ((letra >> 6) & 0x03);

					estado = 0;
					printMenu();
				}
			}

		}
	}
}

// ISR
ISR(USART_RX_vect)
{
	caracter_rx   = UDR0;
	dato_recibido = 1;
}



//PRELABORATORIO Y LABORATORIO	
//#include <avr/io.h>
//#include <avr/interrupt.h>
//#include "UART/UART.h"
//
//int main(void)
//{
//	cli();
//
//	// Puerto B como salida — bits 0-5 (pines D8 a D13)
//	DDRB |= (1<<DDB0)|(1<<DDB1)|(1<<DDB2)|(1<<DDB3)|(1<<DDB4)|(1<<DDB5);
//
//	// Puerto C como salida
//	DDRC |= (1<<DDD0)|(1<<DDD1);
//
//	// Apagar todos los LEDs al arrancar
//	PORTB &= ~0x3F;
//	PORTC &= ~0xFF;
//
//	initUART();
//	sei();
//
//	// Prelab enviar desde micro
//	writeChar('A');
//	// Laboratorio
//	//writeString("Hola mundo");
//
//	while (1)
//	{
//		// Todo se maneja en la ISR
//	}
//}
//
//// segunda parte mandando
//ISR(USART_RX_vect)
//{
//	char rx = UDR0;
//
//	// Eco: devuelve el carácter exacto a la terminal
//	writeChar(rx);
//
//	// Ignorar Enter para no borrar los LEDs del caracter anterior
//	if (rx != '\n' && rx != '\r')
//	{
//		// bits del 0 al 5 del puerto B
//		PORTB = (PORTB & 0xC0) | (rx & 0x3F);
//
//		// bits A1 y A2 del puerto C
//		PORTC = (PORTC & 0xF9) | ((rx >> 5) & 0x06);
//	}
//}
//
//