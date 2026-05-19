/*
 * UART.h
 *
 * Created: 11/05/2026 00:30:34
 *  Author: María Olga
 */ 

#ifndef UART_H
#define UART_H

#include "AVR_CORE.h"
#include "PWM.h"
#include "EEPROM.h"

// Inicializa el buffer de comandos y muestra el menu
void uart_cmd_init(void);

// Procesa los bytes disponibles en el buffer 
void uart_cmd_procesar(void);

// Se ejecuta la secuencia de parpadeo de ojos
void uart_cmd_parpadeo(void);

#endif /* UART_H */