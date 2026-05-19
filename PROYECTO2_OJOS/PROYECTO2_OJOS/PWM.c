/*
 * PWM.c
 *
 * Created: 11/05/2026 00:32:43
 *  Author: María Olga
 */ 

/****************************************/
// Encabezado (Libraries)
#include "PWM.h"

/****************************************/
// Function prototypes
//	Ángulos actuales de cada servo
static uint8_t _angulos[NUM_SERVOS] = {90, 90, 90, 90, 90, 90};

/* Pulsos en µs para servos software
Los rangos utilizados son  1000us = 0°, 1500us = 90° y 2000us = 180° */ 
static volatile uint16_t _s4_us = 1500;   // S4 vertical   
static volatile uint16_t _s5_us = 1500;   // S5 horizontal 

/* Timer1: cada tick es de 0.5µs 
   Timer2: cada tick de 16µs */
static uint16_t _t1_ticks(uint8_t ang) {
    return (uint16_t)map_val(constrain(ang, 0, 180), 0, 180, 2000, 4000);
}

static uint8_t _t2_ticks(uint8_t ang) {
    return (uint8_t)map_val(constrain(ang, 0, 180), 0, 180, 60, 130);
}

/* Se convierte ángulo a microcsegundos para el PWM*/
static uint16_t _ang_a_us(uint8_t ang) {
    return (uint16_t)map_val(constrain(ang, 0, 180), 0, 120, 400, 2600);
}

/****************************************/
// Interrupt routines
/* ISR — Software PWM para el servo 4 y servo 5
   Se dispara cada 20 ms cuando Timer1 desborda*/
ISR(TIMER1_OVF_vect) {
    /* S4 — Vertical (D6 = PD6) */
    PORTD |=  (1 << PD6);
    delay_us(_s4_us);
    PORTD &= ~(1 << PD6);

    /* S5 — Horizontal (D5 = PD5) */
    PORTD |=  (1 << PD5);
    delay_us(_s5_us);
    PORTD &= ~(1 << PD5);
}

/* pwm_init: Se congfiguran todas las salidas y entradas*/
void pwm_init(void) {
    DDRB |= (1 << DDB1);		 // D9  - S0 párpado sup izq 
    DDRB |= (1 << DDB2);		 // D10 - S1 párpado sup der 
    DDRB |= (1 << DDB3);		 // D11 - S2 párpado inf izq 
    DDRD |= (1 << DDD3);		 // D3  - S3 párpado inf der 
    DDRD |= (1 << DDD5);		 // D5  - S5 horizontal      
    DDRD |= (1 << DDD6);		 // D6  - S4 vertical        

    // Timer 1: Fast PWM, TOP=ICR1, preescaler DE 8 
    TCCR1A = (1 << COM1A1) | (1 << COM1B1) | (1 << WGM11);
    TCCR1B = (1 << WGM13)  | (1 << WGM12)  | (1 << CS11);
    ICR1   = 39999;
    OCR1A = _t1_ticks(90);		 // S0 — párpado superior izquierdo
    OCR1B = _t1_ticks(90);		 // S1 — párpado superior derecho
    TIMSK1 = (1 << TOIE1);

    // Timer 2: Phase Correct PWM 8-bit, preescaler de 256
    TCCR2A = (1 << COM2A1) | (1 << COM2B1) | (1 << WGM20);
    TCCR2B = (1 << CS22)   | (1 << CS21);
    OCR2A = _t2_ticks(90);		 // S2 — párpado inferior izquierdo 
    OCR2B = _t2_ticks(90);		 // S3 — párpado inferior derecho   
    sei();
}

/* pwm_servo_write: mueve un servo al angulo indicado*/
void pwm_servo_write(uint8_t idx, uint8_t angulo) {
    if (idx >= NUM_SERVOS) return;
    angulo = constrain(angulo, 0, 180);
    _angulos[idx] = angulo;

    switch (idx) {
        case 0: OCR1A  = _t1_ticks(angulo); break;  // D9  OC1A 
        case 1: OCR1B  = _t1_ticks(angulo); break;  // D10 OC1B 
        case 2: OCR2A  = _t2_ticks(angulo); break;  // D11 OC2A 
        case 3: OCR2B  = _t2_ticks(angulo); break;  // D3  OC2B 
        case 4: _s4_us = _ang_a_us(angulo); break;  // D6  SW PWM
        case 5: _s5_us = _ang_a_us(angulo); break;  // D5  SW PWM  
        default: break;
    }
}

/* Devuelve el ultimo angulo enviado al servo indicado */
uint8_t pwm_servo_read(uint8_t idx) {
    if (idx >= NUM_SERVOS) return 90;
    return _angulos[idx];
}

/* Mueve todos los servos a 90° para neutralizarlos*/
void pwm_neutro(void) {
    for (uint8_t i = 0; i < NUM_SERVOS; i++) {
        pwm_servo_write(i, 90);
    }
}
