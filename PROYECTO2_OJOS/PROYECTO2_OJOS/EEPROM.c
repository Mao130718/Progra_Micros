/*
 * EEPROM.c
 *
 * Created: 11/05/2026 00:35:11
 *  Author: María Olga
 */ 

#include "EEPROM.h"

/* Dirección donde se guards el contador de slots grabados */
#define ADDR_CONTADOR  (EEPROM_BASE + MAX_SLOTS * NUM_SERVOS)  /* = 60 */

/* Lectura y escritura básica 
EEAR = direccion a leer o escribir
EEDR = dato a leer o escribir
EECR = registro de control (bits de habilitacion) */

/* leer un byte de la EEPROM */
uint8_t eeprom_leer(uint16_t addr) {
    while (EECR & (1 << EEPE));			// Esperar si hay escritura 
    EEAR = addr;						// Se carga la dirección
    EECR |= (1 << EERE);				// Se inicia la lectura
    return EEDR;						// Se devuelve el dato leido
}

/* Escribir un byte en la EEPROM, solo escribe si el valor cambio 
para proteger los ciclos de escritura */
void eeprom_escribir(uint16_t addr, uint8_t dato) {
    if (eeprom_leer(addr) == dato) return;		// Si no hay cambio, no se escribe nada
    while (EECR & (1 << EEPE));					// Se espera una escritura previa
    EEAR = addr;								// Se carga la dirección 
    EEDR = dato;								// Se carga un dato
    cli();										// De  deshabilita las interrupciones
    EECR |= (1 << EEMPE);						// Se habilita la escritura
    EECR |= (1 << EEPE);						// Se inicia escritura 
    sei();										// Se rehabilita las interrupciones
}

// API de slots 
/* Graba los angulos actuales de los 6 servos en un slot */
uint8_t eeprom_grabar(uint8_t slot, const uint8_t angulos[NUM_SERVOS]) {
    if (slot >= MAX_SLOTS) {
        uart_puts("[EEPROM] ERROR: slot invalido");
        return 0;
    }

	/* Calcular direccion base del slot */
    uint16_t base = EEPROM_BASE + (uint16_t)slot * NUM_SERVOS;
    for (uint8_t i = 0; i < NUM_SERVOS; i++) {
        eeprom_escribir(base + i, constrain(angulos[i], 0, 180));
    }

	/* Actualizar contador si es un slot nuevo */
    uint8_t total = eeprom_total();
    if (slot >= total) {
        eeprom_escribir(ADDR_CONTADOR, slot + 1);
    }

    uart_puts("[EEPROM] Grabado slot ");
    uart_put_uint8(slot);
    uart_puts("");
    return 1;
}

/* Carga los angulos guardados de un slot al arreglo destino */
uint8_t eeprom_cargar(uint8_t slot, uint8_t angulos[NUM_SERVOS]) {
    if (slot >= MAX_SLOTS) return 0;

    uint16_t base = EEPROM_BASE + (uint16_t)slot * NUM_SERVOS;
    for (uint8_t i = 0; i < NUM_SERVOS; i++) {
        angulos[i] = constrain(eeprom_leer(base + i), 0, 180);
    }
    return 1;
}

/* Devuelve cuantos slots hay grabados */
uint8_t eeprom_total(void) {
    uint8_t val = eeprom_leer(ADDR_CONTADOR);
    return (val > MAX_SLOTS) ? 0 : val;
}

/* eeprom_reproducir: reproduce slots con verificacion de boton
Si el boton PD2 se presiona durante la reproduccion, sale inmediatamente 
para que el loop principal cambie de modo */
void eeprom_reproducir(uint16_t delay_ms_entre_pos) {
    uint8_t total = eeprom_total();
    if (total == 0) {
        uart_puts("[EEPROM] Sin posiciones grabadas");
        return;
    }

    uart_puts("[EEPROM] Reproduciendo...");
    uint8_t angulos[NUM_SERVOS];

    for (uint8_t s = 0; s < total; s++) {

        /* ── Verificar boton antes de cada slot ──────────────────
           PD2 = 0 significa boton presionado (pull-up activo)   */
        if (((PIND >> PD2) & 1) == 0) {
            uart_puts("[EEPROM] Interrumpido por boton");
            delay_ms(200);   /* pausa para evitar doble deteccion */
            return;          /* salir para que el loop cambie modo */
        }

        /* Cargar y aplicar posicion del slot actual */
        eeprom_cargar(s, angulos);
        for (uint8_t i = 0; i < NUM_SERVOS; i++) {
            pwm_servo_write(i, angulos[i]);
        }
        uart_puts("[EEPROM] Slot ");
        uart_put_uint8(s);
        uart_puts("");

        /* Delay entre posiciones verificando boton cada 50ms ────
           Asi el boton responde incluso durante el delay         */
        uint16_t transcurrido = 0;
        while (transcurrido < delay_ms_entre_pos) {
            delay_ms(50);
            transcurrido += 50;
            if (((PIND >> PD2) & 1) == 0) {
                uart_puts("[EEPROM] Interrumpido por boton");
                delay_ms(200);
                return;
            }
        }
    }
    uart_puts("[EEPROM] Listo");
}

/* Borra todos los slots poniendo los servos en 90° y contador en 0 */
void eeprom_borrar_todo(void) {
    for (uint8_t s = 0; s < MAX_SLOTS; s++) {
        uint16_t base = EEPROM_BASE + (uint16_t)s * NUM_SERVOS;
        for (uint8_t i = 0; i < NUM_SERVOS; i++) {
            eeprom_escribir(base + i, 90);
        }
    }
    eeprom_escribir(ADDR_CONTADOR, 0);
    uart_puts("[EEPROM] Todo borrado");
}