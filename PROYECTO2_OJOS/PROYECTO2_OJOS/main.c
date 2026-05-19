/*
 * PROYECTO2_OJOS.c
 *
 * Created: 11/05/2026 00:24:57
 * Author: María Olga Joachín
 * Description: Ojos robóticos controlados por potenciometros, opera en tres modos
 * Manual, EEPROM y UART.
 */

/****************************************/
// Encabezado (Libraries)
#include "AVR_CORE.h"
#include "PWM.h"
#include "EEPROM.h"
#include "MODOS.h"
#include "UART.h"
/****************************************/
// Function prototypes
// Canales ADC de los 4 potenciómetros 
#define POT_PARP_SUP    0   // PC0: A0 - S0 y S1 párpados superiores
#define POT_PARP_INF    1   // PC1: A1 - S2 y S3 párpados inferiores
#define POT_VERTICAL    2   // PC2: A2 - S4 movimiento vertical
#define POT_HORIZONTAL  3   // PC3: A3 - S5 movimiento horizontal    

// Delay entre posiciones en modo EEPROM 
#define DELAY_EEPROM    800

/****************************************/
// NON-Interrupt subroutines
// Modo manual - lee los valores de movimiento de los potenciometros y mueve los 6 servos
static void modo_manual(void) {
    uint16_t lectura;					  // Valor del ADC
    uint8_t  angulo;                      // Angulo calculado por el servo

    // POT1 (A0): párpados superiores en espejo 
    lectura = adc_read(POT_PARP_SUP);
    angulo  = (uint8_t)map_val(lectura, 0, 1023, 0, 180);
    pwm_servo_write(0, angulo);           // S0 sup izq          
    pwm_servo_write(1, 180 - angulo);     // S1 sup der (espejo) 

    // POT2 (A1): párpados inferiores en espejo
    lectura = adc_read(POT_PARP_INF);
    angulo  = (uint8_t)map_val(lectura, 0, 1023, 0, 180);
    pwm_servo_write(2, 180 - angulo);     // S2 inf izq (espejo) 
    pwm_servo_write(3, angulo);           // S3 inf der          

    // POT3 (A2): movimiento vertical 
    lectura = adc_read(POT_VERTICAL);
    angulo  = (uint8_t)map_val(lectura, 0, 1023, 0, 180);
    pwm_servo_write(4, angulo);           // S4 vertical  

    // POT4 (A3): movimiento horizontal
    lectura = adc_read(POT_HORIZONTAL);
    angulo  = (uint8_t)map_val(lectura, 0, 1023, 0, 180);
    pwm_servo_write(5, angulo);           // S5 horizontal  
}

/****************************************/
// Main Function
int main(void) {

    // Inicialización de las funciones más importantes
    timer0_ms_init();    // Timer0               
    uart_init(9600);     // UART 9600 de baudrate              
    adc_init();          // ADC 10-bit, referencia AVcc      
    pwm_init();          // Timers 1 y 2 + pines de servos   
    modos_init();        // Botón PD2 + LED PB5              
    uart_cmd_init();     // Buffer de comandos UART          

    uart_puts("=== Rostro Animatronico listo ===");
    uart_puts("Modo inicial: MANUAL");

    //Loop principal 
    while (1) {

        modos_actualizar();      // detectar pulsacion del boton   
        modos_led_continuo();    // actualizar LED segun modo      

        switch (modos_obtener()) {

			/* MODO MANUAL: lectura de los potenciometros y mueve servos 
			el delay_ms (50) por lo que cada actualización de los servos 
			son de 50 Hz*/
            case MODO_MANUAL:
                modo_manual();
                delay_ms(20);
                break;
				
			/* MODO EEPROM: reproduce los slots grabados en bucle
			La función verifica el boton internamente para poder 
			interrumpir la reproducción en cualquier momentos*/
            case MODO_EEPROM:
                eeprom_reproducir(DELAY_EEPROM);
                break;
			
			/* MODO UART: Escucha lo comandos mandados y los ejecuta
			Se puede visualizar en Terminte y en Adafruit */
            case MODO_UART:
                uart_cmd_procesar();
                break;

            default:
                break;
        }
    }

    return 0;
}