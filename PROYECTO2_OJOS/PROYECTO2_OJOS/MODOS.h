/*
 * MODOS.h
 *
 * Created: 11/05/2026 00:34:02
 *  Author: María Olga
 */ 

#ifndef MODOS_H
#define MODOS_H

#include "AVR_CORE.h"

/* Enumeracion de modos disponibles */
typedef enum {
    MODO_MANUAL = 0,		// Control manual con potenciometros
    MODO_EEPROM = 1,		// Reproducción de las secuencia grabada
    MODO_UART   = 2,		// Control de comandos UART
    MODO_TOTAL  = 3			// 
} Modo;

// Inicializa poines del boton y el LED
void    modos_init(void);

/* Detecta pulsacion del boton y cambia de modo */
uint8_t modos_actualizar(void);    

/* Devuelve el modo activo actualmente */
Modo    modos_obtener(void);

/* Maneja el parpadeo del LED segun el modo activo */
void    modos_led_continuo(void); 

#endif /* MODOS_H */