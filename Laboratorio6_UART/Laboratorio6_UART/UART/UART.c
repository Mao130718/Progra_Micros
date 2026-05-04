/*
 * UART.c
 *
 * Created: 27/04/2026 07:27:47
 *  Author: María Olga Joachin
 */ 

#include "UART.h"

void initUART()
{
    DDRD &= ~(1<<DDD0);   // PD0 RX como entrada
    DDRD |=  (1<<DDD1);   // PD1 TX como salida

    UCSR0A = 0;
    UCSR0B = (1<<RXCIE0)|(1<<RXEN0)|(1<<TXEN0);  // habilita RX, TX e interrupcion
    UCSR0C = (1<<UCSZ01)|(1<<UCSZ00);             // 8 bits, async
    UBRR0  = 103;                                  // 9600 baudios a 16MHz
}

void writeChar(char caracter)
{
    while(!(UCSR0A & (1<<UDRE0)));  // espera buffer libre
    UDR0 = caracter;
}

void writeString(char *string)
{
    for(uint8_t i = 0; string[i] != '\0'; i++)
    {
        writeChar(string[i]);
    }
	writeChar('\r');
	writeChar('\n');
}
///UART