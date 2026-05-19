/*
 * AVR_CORE.h
 *
 * Created: 11/05/2026 00:31:51
 *  Author: María Olga
 */ 


#ifndef AVR_CORE_H
#define AVR_CORE_H

/****************************************/
// Encabezado (Libraries)
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

// Frecuencia del sistema 
#ifndef F_CPU
#define F_CPU 16000000UL
#endif

// Bool
typedef uint8_t bool;
#define true  1
#define false 0

// Delays
// Funciones para esperar un tiempo determinado 
// Se va a utilizar _delay_ms y _delay_us para aceptar variables
static inline void delay_ms(uint16_t ms) {
    while (ms--) _delay_ms(1);
}
static inline void delay_us(uint16_t us) {
    while (us--) _delay_us(1);
}

// millis()
/* Contador de milisegundos desde que arranco el programa, este se incrementa
en la ISR del Timer0 */
extern volatile uint32_t _ms_counter;
static inline uint32_t millis(void) { return _ms_counter; }
void timer0_ms_init(void);			// Se incializa Timer0 para contar los milisegundos

// UART 
/* Comunicación serial con la PC y Adafruit */
void    uart_init(uint32_t baud);
void    uart_putc(char c);
void    uart_puts(const char *s);
void    uart_put_uint8(uint8_t val);
char    uart_getc(void);
uint8_t uart_available(void);

// ADC 
/* Leer potenciometros conectados, devuelve el valor de 10 bits */
void     adc_init(void);
uint16_t adc_read(uint8_t canal);   /* canal 0-7 → A0-A7 */

// Utilidades 
/* map_val: convierte un valor de un rango a otro, se realiza
un mapeo */
static inline int32_t map_val(int32_t x,
                               int32_t in_min,  int32_t in_max,
                               int32_t out_min, int32_t out_max) {
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

#define constrain(x, lo, hi) \
    ((x) < (lo) ? (lo) : ((x) > (hi) ? (hi) : (x)))

#endif /* AVR_CORE_H */