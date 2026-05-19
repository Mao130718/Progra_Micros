/*
 * EEPROM.h
 *
 * Created: 11/05/2026 00:33:08
 *  Author: María Olga
 */ 


#ifndef EEPROM_H
#define EEPROM_H

#include "AVR_CORE.h"
#include "PWM.h"

#define MAX_SLOTS    10				// Máximo de posiciones que se pueden grabar
#define EEPROM_BASE   0				// Dirección base en EEPROM donde empieza el almacenamiento

uint8_t eeprom_leer(uint16_t addr);

/* Se escribe un byte solo si el valor cambio */
void eeprom_escribir(uint16_t addr, uint8_t dato);

/* Graba los angulos actuales de los 6 servos en el slot indicado */
uint8_t eeprom_grabar(uint8_t slot, const uint8_t angulos[NUM_SERVOS]);

/* Carga los angulos guardadois en el slot indicado*/
uint8_t eeprom_cargar(uint8_t slot, uint8_t angulos[NUM_SERVOS]);

/* Devuelve cuantos slots hay grabados actualmente */
uint8_t eeprom_total(void);

/* Reproduce todos los slots grabados con delay entre cada uno
   Verifica el boton PD2 para poder interrumpir la reproduccion */
void eeprom_reproducir(uint16_t delay_ms_entre_pos);

/* Borra todos los slots y resetea el contador a 0 */
void eeprom_borrar_todo(void);

#endif /* EEPROM_H */