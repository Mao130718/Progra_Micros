/*
 * MODOS.c
 *
 * Created: 11/05/2026 00:34:57
 *  Author: María Olga
 */

#include "MODOS.h"

static Modo _modo_actual = MODO_MANUAL;
static uint8_t  _estado_ant_boton = 1;

// Variables para parpadeo sin usar delay()
static uint32_t _t_ultimo_parpadeo = 0;
static uint8_t  _led_estado = 0;   

// modos_init: se configuram los pines del boton y el led
void modos_init(void) {
    /* Botón PD2 (D2) como entrada con pull-up interno */
    DDRD  &= ~(1 << DDD2);   // PD2 como entrada
    PORTD |=  (1 << PD2);    // activar pull-up

    // LED PB5 (D13) como salida 
    DDRB  |=  (1 << DDB5);   

    /* Encender LED fijo al inicio (modo MANUAL) */
    PORTB |= (1 << PB5);
    _led_estado = 1;
}

/* modos_actualizar: detecta una pulsación del boton */
uint8_t modos_actualizar(void) {
    uint8_t estado_actual = (PIND >> PD2) & 1;
    uint8_t cambio        = 0;

    // Flanco de bajada: boton presionado 
    if (estado_actual == 0 && _estado_ant_boton == 1) {
        _modo_actual = (Modo)(((uint8_t)_modo_actual + 1) % (uint8_t)MODO_TOTAL);
        cambio       = 1;

        switch (_modo_actual) {
            case MODO_MANUAL:
                uart_puts("[MODO] MANUAL");
                // Encender fijo inmediatamente 
                PORTB |= (1 << PB5);
                _led_estado = 1;
                break;
            case MODO_EEPROM:
                uart_puts("[MODO] EEPROM");
                break;
            case MODO_UART:
                uart_puts("[MODO] UART");
                break;
            default:
                break;
        }

        // Reiniciar temporizador de parpadeo 
        _t_ultimo_parpadeo = millis();
    }

    _estado_ant_boton = estado_actual;
    return cambio;
}

// Devuelve el modo activo actualmente
Modo modos_obtener(void) {
    return _modo_actual;
}

/* modos_led_continuo: parpadeo del LED segun modo activo
MANUAL - LED fijo encendido 
EEPROM - alterna cada 250ms 
UART   - alterna cada 100ms  */
void modos_led_continuo(void) {
    uint32_t ahora    = millis();
    uint16_t intervalo = 0;

    switch (_modo_actual) {

        // MANUAL — LED encendido fijo, no hace nada 
        case MODO_MANUAL:
            break;

        // EEPROM — parpadeo cada 250ms 
        case MODO_EEPROM:
            intervalo = 250;
            if ((ahora - _t_ultimo_parpadeo) >= intervalo) {
                _t_ultimo_parpadeo = ahora;
                if (_led_estado == 0) {
                    PORTB |=  (1 << PB5);   
                    _led_estado = 1;
                } else {
                    PORTB &= ~(1 << PB5);  
                    _led_estado = 0;
                }
            }
            break;

        // UART — parpadeo cada 100ms
        case MODO_UART:
            intervalo = 100;
            if ((ahora - _t_ultimo_parpadeo) >= intervalo) {
                _t_ultimo_parpadeo = ahora;
                if (_led_estado == 0) {
                    PORTB |=  (1 << PB5);
                    _led_estado = 1;
                } else {
                    PORTB &= ~(1 << PB5);   
                    _led_estado = 0;
                }
            }
            break;

        default:
            break;
    }
}