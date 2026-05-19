/*
 * AVR_CORE.c
 *
 * Created: 11/05/2026 00:32:08
 *  Author: María Olga
 */ 

/****************************************/
// Encabezado (Libraries)
#include "AVR_CORE.h"

// TIMER0 - millis
/* Se configura en modo CTC, el timer se reinicia autmaticamente al llegar al OCR0A
Existe un preescaler de 64, por lo que cada tick es de 4µs, el OCR0A de 249*/
volatile uint32_t _ms_counter = 0;

void timer0_ms_init(void) {
    TCCR0A = (1 << WGM01);                       // Modo CTC           
    TCCR0B = (1 << CS01) | (1 << CS00);          // Preescaler /64     
    OCR0A  = 249;                                // 16MHz/64/1000 - 1 
    TIMSK0 = (1 << OCIE0A);                      // Habilitar ISR     
    sei();
}

/****************************************/
// Interrupt routines
// La ISR se ejecuta cada 1ms y hace que se incremente el contador
ISR(TIMER0_COMPA_vect) {
    _ms_counter++;
}

/****************************************/
// NON-Interrupt subroutines
// UART 
/* Son 8 bits de datos (sin paridad), se utilizo una paridad de 9600 */
void uart_init(uint32_t baud) {
	uint16_t ubrr = (uint16_t)((F_CPU / (16UL * baud)) - 1);
	UBRR0H = (uint8_t)(ubrr >> 8);					// Byte alto del baudrate
	UBRR0L = (uint8_t)(ubrr);						// Byte bajo del baudrate
	UCSR0A = 0;                              		// Limpiar flags
	UCSR0B = (1 << TXEN0) | (1 << RXEN0);			// Se habilita TX y RX
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);			// 8 bist de datos
}

/* Enviar un caracter, se espera que el buffer este libre*/
void uart_putc(char c) {
    while (!(UCSR0A & (1 << UDRE0)));
    UDR0 = (uint8_t)c;
}

/* Se enviar una cadena de texto*/
void uart_puts(const char *s) {
    while (*s) uart_putc(*s++);
    uart_putc('\r');
    uart_putc('\n');
}

/* Se envia un numero entero sin signo (0 a 255) */
void uart_put_uint8(uint8_t val) {
    char buf[4];
    uint8_t i = 0;
    if (val == 0) { uart_putc('0'); return; }
    while (val > 0) { buf[i++] = '0' + (val % 10); val /= 10; }
    while (i--) uart_putc(buf[i]);
}

/* Se recibe un caracter y espera a que llegue uno nuevo*/
char uart_getc(void) {
    while (!(UCSR0A & (1 << RXC0)));
    return (char)UDR0;
}

/* Se verifica si hay datos disponibles en el buffer de recepción*/
uint8_t uart_available(void) {
    return (UCSR0A & (1 << RXC0)) ? 1 : 0;
}

// ADC — 10-bit, referencia AVcc (5V)
/* Se utiliza un tamao de 10 bits por lo que puede ir de 0 a 1023
El preescaler es de 128 por lo que la frecuencia a utilizar es de 125kHz*/
void adc_init(void) {
    DDRC &= ~(1 << DDC0);   // A0 - POT párpados superiores 
    DDRC &= ~(1 << DDC1);   // A1 - POT párpados inferiores 
    DDRC &= ~(1 << DDC2);   // A2 - POT vertical            
    DDRC &= ~(1 << DDC3);   // A3 - POT horizontal          

	// Configuración del ADC
    ADMUX  = (1 << REFS0);
    ADCSRA = (1 << ADEN)
           | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
}

/* Leer canal de ADC (0 a 7) y se devuelve el valor de 10 bits*/
uint16_t adc_read(uint8_t canal) {
    ADMUX  = (ADMUX & 0xF0) | (canal & 0x07);	// se selecciona el canal
    ADCSRA |= (1 << ADSC);						// Se incia la conversion
    while (ADCSRA & (1 << ADSC));				// Espera al resultado
    return ADC;									// Se devuelve el resultado
}