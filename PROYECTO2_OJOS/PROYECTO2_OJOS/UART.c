/*
 * UART.h
 *
 * Created: 11/05/2026 00:32:34
 *  Author: María Olga
 */

#include "UART.h"

#define BUF_SIZE 32

static char    _buf[BUF_SIZE];			// Buffer donde se acumulan de comandos en bytes
static uint8_t _buf_idx = 0;			// Buffer donde se acumulan los caracteres recibidos

/* uart_cmd_init: Inicializa buffer y muestra el menu en serial */
void uart_cmd_init(void) {
    _buf_idx = 0;
    memset(_buf, 0, BUF_SIZE);
    uart_puts("================================");
    uart_puts("   Rostro Animatronico - Menu   ");
    uart_puts("================================");
    uart_puts("MOVER <servo> <angulo> ej: MOVER 0 90");
    uart_puts("GRABAR <slot>          ej: GRABAR 3");
    uart_puts("BORRAR: borra EEPROM");
    uart_puts("NEUTRO: servos a 90 grados");
    uart_puts("ESTADO: ver angulos actuales");
    uart_puts("================================");
}

/* _ejecutar: — Interpreta y ejecuta el comando en _buf*/
static void _ejecutar(void) {

    // MOVER <idx> <angulo> 
    if (strncmp(_buf, "MOVER", 5) == 0) {
        uint8_t idx    = (uint8_t)atoi(_buf + 6);
        char   *espacio = strchr(_buf + 6, ' ');
        if (espacio && idx < NUM_SERVOS) {
            uint8_t ang = (uint8_t)atoi(espacio + 1);
            pwm_servo_write(idx, ang);
            uart_puts("[OK] Servo movido");
        } else {
            uart_puts("[ERROR] Uso: MOVER <servo 0-5> <angulo 0-180>");
        }
    }

    // GRABAR <slot>
    else if (strncmp(_buf, "GRABAR", 6) == 0) {
        uint8_t slot = (uint8_t)atoi(_buf + 7);
        if (slot < 10) {
            uint8_t angulos[NUM_SERVOS];
            for (uint8_t i = 0; i < NUM_SERVOS; i++) {
                angulos[i] = pwm_servo_read(i);
            }
            eeprom_grabar(slot, angulos);
        } else {
            uart_puts("[ERROR] Uso: GRABAR <slot 0-9>");
        }
    }

    // REPRODUCIR
    else if (strncmp(_buf, "REPRODUCIR", 10) == 0) {
        eeprom_reproducir(800);
    }

    // BORRAR 
    else if (strncmp(_buf, "BORRAR", 6) == 0) {
        eeprom_borrar_todo();
    }

    // NEUTRO 
    else if (strncmp(_buf, "NEUTRO", 6) == 0) {
        pwm_neutro();
        uart_puts("[OK] Servos en posicion neutra");
    }

    // PARPADEO 
    else if (strncmp(_buf, "PARPADEO", 8) == 0) {
        uart_cmd_parpadeo();
    }

    // ESTADO 
    else if (strncmp(_buf, "ESTADO", 6) == 0) {
        uart_puts("--- Estado actual ---");
        uart_puts("S0 sup izq = "); uart_put_uint8(pwm_servo_read(0)); uart_puts(" grados");
        uart_puts("S1 sup der = "); uart_put_uint8(pwm_servo_read(1)); uart_puts(" grados");
        uart_puts("S2 inf izq = "); uart_put_uint8(pwm_servo_read(2)); uart_puts(" grados");
        uart_puts("S3 inf der = "); uart_put_uint8(pwm_servo_read(3)); uart_puts(" grados");
        uart_puts("S4 vertical = "); uart_put_uint8(pwm_servo_read(4)); uart_puts(" grados");
        uart_puts("S5 horizontal = "); uart_put_uint8(pwm_servo_read(5)); uart_puts(" grados");
        uart_puts("---------------------");
    }

    // Comando desconocido 
    else {
        uart_puts("[ERROR] Comando no reconocido");
        uart_puts("Escribe ESTADO para ver los comandos disponibles");
    }
}

// uart_cmd_procesar: Lee el Serial byte a byte 
/* Se acumula caracteres en _buf hasta recibir simbolo como '\n' o '\r' 
Al recibir el terminador ejecuta el comando que se acumulo 
Convierte automaticamente a mayusculas para mayor comodidad */
void uart_cmd_procesar(void) {
    while (uart_available()) {
        char c = uart_getc();

        if (c == '\n' || c == '\r') {
            if (_buf_idx > 0) {
                _buf[_buf_idx] = '\0';
                _ejecutar();
                _buf_idx = 0;
            }
        } else if (_buf_idx < BUF_SIZE - 1) {
            /* Convertir a mayusculas para que funcione sin importar
               si el usuario escribe en minusculas o mayusculas      */
            if (c >= 'a' && c <= 'z') c = c - 32;
            _buf[_buf_idx++] = c;
        }
    }
}

/* uart_cmd_parpadeo: Secuencia de parpadeo de ojos
   S0 = párpado sup izq    S1 = párpado sup der
   S2 = párpado inf izq    S3 = párpado inf der */
void uart_cmd_parpadeo(void) {
    uart_puts("[OK] Ejecutando parpadeo...");

    /* Cerrar parpados */
    pwm_servo_write(0, 0);			// sup izq cierra
    pwm_servo_write(1, 180);		// sup der cierra
    pwm_servo_write(2, 180);		// inf izq cierra
    pwm_servo_write(3, 0);			// inf der cierra
    delay_ms(120);					// mantener cerrado 120ms

    // Abrir parpados 
    pwm_servo_write(0, 90);
    pwm_servo_write(1, 90);
    pwm_servo_write(2, 90);
    pwm_servo_write(3, 90);
    delay_ms(80);

    uart_puts("[OK] Parpadeo completado");
}