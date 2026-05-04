/*
 * UART.h
 *
 * Created: 27/04/2026 07:28:05
 *  Author: María Olga Joachin
 */ 

#ifndef UART_H_
#define UART_H_

#include <avr/io.h>
#include <avr/interrupt.h>

// Prototipos
void initUART();
void writeChar(char caracter);
void writeString(char *string);

#endif /* UART_H_ */