/*
 * Laboratorio4_ADC.c
 *
 * Created: 12/04/2026 20:39:47
 * Author: María Olga
 * Description: 
 */
/****************************************/
// Encabezado (Libraries)
#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdint.h>
/****************************************/

// Tabla de segmentos
static const uint8_t SEG7[16] = {
    0b00111111,0b00000110,0b01011011,0b01001111,
    0b01100110,0b01101101,0b01111101,0b00000111,
    0b01111111,0b01101111,0b01110111,0b01111100,
    0b00111001,0b01011110,0b01111001,0b01110001
};

volatile uint8_t counter = 0;			// valor actual del contador (0-255)
volatile uint8_t adc_value = 0;			// valor leído del ADC
volatile uint8_t adc_high = 0;			// dígitos hexadecimales alto del ADC para mostrar
volatile uint8_t adc_low = 0;			// dígitos hexadecimales bajo del ADC para mostrar
volatile uint8_t disp_sel = 0;			// selecciona qué display (unidad o decena) se debe actualizar en el multiplexado

// Function prototypes
void setup(void) {

    // LEDs contador
    DDRB |= 0x1F;							// PB0-PB4 como salida
    DDRD |= (1<<PD5)|(1<<PD6)|(1<<PD7);		// PD5,PD6,PD7 salida

    // LED comparador
    DDRD |= (1<<PD0);
    PORTD &= ~(1<<PD0);

    // Segmentos
    DDRD |= (1<<PD1)|(1<<PD2)|(1<<PD3)|(1<<PD4);	// segmentos A-D
    DDRC |= (1<<PC2)|(1<<PC3);						// segmentos E, F
    DDRB |= (1<<PB5);								// segmento G

    // Multiplexado (PC4 y PC5)
    DDRC |= (1<<PC4)|(1<<PC5);
    PORTC &= ~((1<<PC4)|(1<<PC5));

    // Botones
    DDRC &= ~((1<<PC0)|(1<<PC1));
    PORTC |= (1<<PC0)|(1<<PC1);

    // ADC en A7 (ADC7)
    ADMUX = (1<<REFS0) | (1<<ADLAR)
          | (1<<MUX2) | (1<<MUX1) | (1<<MUX0);

    ADCSRA = (1<<ADEN)  // Enable ADC
           | (1<<ADIE)  // Interrupt enable
           | (1<<ADPS2) | (1<<ADPS1) | (1<<ADPS0); // Prescaler 128

    ADCSRB = 0;

    // Timer0 (1kHz multiplexado)
    TCCR0A = (1<<WGM01);				// CTC mode
    TCCR0B = (1<<CS01)|(1<<CS00);		// prescaler 64
    OCR0A = 124;						// top = 124
    TIMSK0 = (1<<OCIE0A);				// interrupción en comparación A

    // Interrupciones botones
    PCICR |= (1<<PCIE1);					// habilitar PCINT1 (pines PC0-PC7)
    PCMSK1 |= (1<<PCINT8)|(1<<PCINT9);		// 

    // Iniciar ADC
    ADCSRA |= (1<<ADSC);
}

// Se mapean los 8 bits del contador
void updateLEDs(uint8_t value) {
    PORTB &= ~0x1F;
    PORTD &= ~((1<<PD5)|(1<<PD6)|(1<<PD7));

    PORTB |= (value & 0x1F);
    if(value & (1<<5)) PORTD |= (1<<PD7);
    if(value & (1<<6)) PORTD |= (1<<PD6);
    if(value & (1<<7)) PORTD |= (1<<PD5);
}

//	Toma un dígito y enciende los segmentos correspondientes sin seleccionar aún el display.
void showDigit(uint8_t digit) {
    uint8_t seg = SEG7[digit & 0x0F];

    PORTD = (PORTD & ~((1<<PD1)|(1<<PD2)|(1<<PD3)|(1<<PD4)))
          | ((seg & 0x0F) << 1);

    if(seg & (1<<4)) PORTC |= (1<<PC2);
    else PORTC &= ~(1<<PC2);

    if(seg & (1<<5)) PORTC |= (1<<PC3);
    else PORTC &= ~(1<<PC3);

    if(seg & (1<<6)) PORTB |= (1<<PB5);
    else PORTB &= ~(1<<PB5);
}

void updateCompareLED(void) {
    if(counter >= adc_value) {
        PORTD |= (1<<PD0);
    } else {
        PORTD &= ~(1<<PD0);
    }
}
/****************************************/

// Main Function
int main(void) {
    cli();
    setup();
    sei();

    updateLEDs(counter);
    updateCompareLED();

    while(1) {
        asm volatile("sleep");
    }
}
/****************************************/

// Interrupt routines
ISR(TIMER0_COMPA_vect) {

    // Apagar ambos displays
    PORTC &= ~((1<<PC4)|(1<<PC5));

    if(disp_sel == 0) {
        showDigit(adc_low);
        PORTC |= (1<<PC4);
        disp_sel = 1;
    } else {
        showDigit(adc_high);
        PORTC |= (1<<PC5);
        disp_sel = 0;
    }
}

ISR(ADC_vect) {

    adc_value = ADCH;
    adc_high = (adc_value >> 4) & 0x0F;
    adc_low = adc_value & 0x0F;

    updateCompareLED();

    ADCSRA |= (1<<ADSC);  // reiniciar conversión
}

ISR(PCINT1_vect) {

    static uint8_t last_up = 1;
    static uint8_t last_down = 1;

    uint8_t current_up = (PINC >> PC0) & 1;
    uint8_t current_down = (PINC >> PC1) & 1;

    if(last_up == 1 && current_up == 0) {
        if(counter < 255) counter++;
        updateLEDs(counter);
        updateCompareLED();
    }

    if(last_down == 1 && current_down == 0) {
        if(counter > 0) counter--;
        updateLEDs(counter);
        updateCompareLED();
    }

    last_up = current_up;
    last_down = current_down;
}
