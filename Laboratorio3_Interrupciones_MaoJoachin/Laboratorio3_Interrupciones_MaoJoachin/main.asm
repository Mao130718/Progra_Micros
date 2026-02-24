/*
* Laboratorio3_Interrupciones_MaoJoachin.asm
*
* Creado: 22/02/2026 21:36:14
* Autor : María Olga Joachin
* Descripción: Contador decimal con el uso de interrupciones
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)

.def temp = r16          // Registro temporal para operaciones generales
.def unidades = r17      // Almacena el dígito de las unidades (0-9)
.def decenas = r18       // Almacena el dígito de las decenas (0-5)
.def led_cnt = r19       // Contador binario para los 4 LEDs independientes
.def r_tabla = r20       // Aquí guardaremos el dibujo (segmentos) del número
.def contador_tmr = r25  // Cuenta cuántas veces desborda el Timer para llegar a 1s

.cseg                    // Indica que lo que sigue es código para la memoria Flash
.org 0x0000              // Dirección de inicio tras el Reset
    rjmp setup           // Salta a la configuración inicial

.org OVF0addr            // Dirección donde salta el micro cuando el Timer0 se desborda
    rjmp ISR_TMR0        // Salta a la rutina de interrupción del Timer

// --- TABLA DE DIBUJO PARA 7 SEGMENTOS ---
// Cada bit representa un segmento (A, B, C, D, E, F, G)
TABLA_7SEG: 
    .db 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F

 /****************************************/
// Configuración de la pila
setup:
    // Inicialización del Stack Pointer (Puntero de Pila)
    // Es necesario para que el micro recuerde a dónde volver tras un 'rcall'
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

/****************************************/
// Configuracion MCU
    // Configuración de Puertos
    ldi temp, 0xF0       // Bits 4,5,6,7 como salida (Segmentos A-D)
    out DDRD, temp       // PD2 y PD3 quedan como entradas (Botones)
    ldi temp, 0x0C       // Activa resistencias internas (Pull-up) en PD2 y PD3
    out PORTD, temp

    ldi temp, 0x07       // Bits 0,1,2 como salida (Segmentos E, F, G)
    out DDRB, temp

    ldi temp, 0x3F       // Bits 0-3 (LEDs), 4-5 (Selectores Displays) como salida
    out DDRC, temp

    // Configuración del Timer0
    ldi temp, (1<<CS02) | (1<<CS00) // Configura velocidad (Prescaler 1024)
    out TCCR0B, temp
    ldi temp, (1<<TOIE0)            // Habilita la interrupción por desbordamiento
    sts TIMSK0, temp
    
    clr unidades         // Pone el contador de unidades en 0
    clr decenas          // Pone el contador de decenas en 0
    clr led_cnt          // Pone el contador de LEDs en 0
    clr contador_tmr     // Limpia el contador del Timer
    sei                  // ¡Enciende las interrupciones globales!
    
/****************************************/
// Loop Infinito
main_loop:
    rcall leer_botones   // Revisa si presionaste algún botón
    rcall logica_60s     // Revisa si el contador llegó a 60 para reiniciar
    rcall refrescar_dis  // Dibuja los números en los displays (Multiplexación)
    
    // Actualizar LEDs binarios independientes (PC0 a PC3)
    in temp, PORTC       // Lee lo que hay en el puerto C actualmente
    andi temp, 0xF0      // Borra solo los bits de los LEDs (0 al 3)
    mov r22, led_cnt     // Toma el valor del contador binario
    andi r22, 0x0F       // Se asegura de que no use más de 4 bits
    or temp, r22         // Une el contador con el resto del puerto C
    out PORTC, temp      // Saca el resultado por los pines de los LEDs
    
    rjmp main_loop       // Repite el ciclo infinitamente

/****************************************/
// NON-Interrupt subroutines
refrescar_dis:
    cbi PORTC, 4         // Apaga el display de unidades
    cbi PORTC, 5         // Apaga el display de decenas (Evita sombras)

    // Mostrar Unidades
    mov temp, unidades   // Carga el número de unidades
    rcall obtener_hex    // Busca el dibujo (segmentos) en la tabla
    rcall enviar_a_pines // Manda ese dibujo a los puertos D y B
    sbi PORTC, 4         // Enciende el display de unidades
    rcall delay_5ms      // Espera un momento para que el ojo lo vea
    cbi PORTC, 4         // Apaga el display antes de cambiar al otro

    // Mostrar Decenas
    mov temp, decenas    // Carga el número de decenas
    rcall obtener_hex    // Busca el dibujo en la tabla
    rcall enviar_a_pines // Manda el dibujo a los puertos
    sbi PORTC, 5         // Enciende el display de decenas
    rcall delay_5ms      // Espera un momento
    cbi PORTC, 5         // Apaga el display
    ret

enviar_a_pines:
    // Esta parte divide r_tabla para que salga por los pines que cableaste
    mov r22, r_tabla     // Copia el dibujo del número
    andi r22, 0x0F       // Se queda con los bits 0, 1, 2, 3 (A, B, C, D)
    swap r22             // Los mueve a la posición 4, 5, 6, 7 (Para PORTD)
    in r23, PORTD        // Lee PORTD para no borrar los botones
    andi r23, 0x0F       // Limpia los pines de salida anteriores
    or r23, r22          // Une el dibujo con los bits de los botones
    out PORTD, r23       // ¡Saca los segmentos A, B, C, D por PD4-PD7!

    mov r22, r_tabla     // Vuelve a copiar el dibujo
    lsr r22              // Desplaza el bit 4 a la posición 0 (Segmento E)
    lsr r22              // Desplaza el bit 5 a la posición 1 (Segmento F)
    lsr r22              // Desplaza el bit 6 a la posición 2 (Segmento G)
    lsr r22              // (Cuarto desplazamiento para alinear)
    andi r22, 0x07       // Se queda solo con los 3 bits (E, F, G)
    in r23, PORTB        // Lee PORTB
    andi r23, 0xF8       // Limpia los pines 0, 1, 2
    or r23, r22          // Une los segmentos E, F, G
    out PORTB, r23       // ¡Saca los segmentos por PB0-PB2!
    ret

obtener_hex:
    // Busca en la memoria Flash el dibujo correspondiente al número en 'temp'
    ldi ZL, low(TABLA_7SEG<<1)  // Carga la dirección de la tabla (parte baja)
    ldi ZH, high(TABLA_7SEG<<1) // Carga la dirección de la tabla (parte alta)
    add ZL, temp                // Suma el número que queremos buscar (0-9)
    clr r21                     // Registro para el acarreo
    adc ZH, r21                 // Suma el acarreo si hubo
    lpm r_tabla, Z              // Carga el dibujo desde la Flash a r_tabla
    ret

leer_botones:
    sbic PIND, 2         // Si PD2 es 0 (Presionado), no salta
    rjmp check_dec       // Si no está presionado, revisa el otro botón
    rcall delay_20ms     // Anti-rebote: espera a que el ruido pase
    sbic PIND, 2         // Confirma si sigue presionado
    ret
    inc unidades         // ¡Incrementa el contador del display!
wait_rel_inc:
    rcall refrescar_dis  // Sigue multiplexando mientras el dedo está puesto
    sbis PIND, 2         // Si ya soltó el botón, salta
    rjmp wait_rel_inc    // Si no, sigue esperando aquí
    ret

check_dec:
    sbic PIND, 3         // Revisa si presionaste el botón de bajar
    ret
    rcall delay_20ms     // Anti-rebote
    sbic PIND, 3
    ret
    tst unidades         // ¿Las unidades están en 0?
    brne dec_normal      // Si no es 0, resta normal
    ldi unidades, 10     // Si es 0, prepáralo para que baje a 9
    dec decenas          // Y resta una decena
dec_normal:
    dec unidades         // Resta 1 al número
wait_rel_dec:
    rcall refrescar_dis  // Sigue multiplexando
    sbis PIND, 3
    rjmp wait_rel_dec
    ret

logica_60s:
    cpi unidades, 10     // ¿Unidades llegó a 10?
    brne check_underflow // Si no, sigue
    clr unidades         // Resetea unidades a 0
    inc decenas          // Aumenta una decena
check_underflow:
    cpi decenas, 255     // ¿Las decenas bajaron de 0 (Underflow)?
    brne check_max_60
    clr unidades         // Si bajó de 0, resetea todo a 00
    clr decenas
check_max_60:
    cpi decenas, 6       // ¿Llegamos a 60?
    brne fin_logica
    clr unidades         // Resetea a 00
    clr decenas
fin_logica:
    ret

/****************************************/
// Interrupt routines
ISR_TMR0:
    push temp            // Guarda temp para no arruinar lo que hacía el main
    in temp, SREG        // Guarda el estado de las banderas
    push temp

    inc contador_tmr     // Incrementa contador de "tics"
    cpi contador_tmr, 61 // ¿Pasó aprox 1 segundo?
    brne fin_isr
    clr contador_tmr     // Limpia para el siguiente segundo
    inc led_cnt          // ¡Incrementa los 4 LEDs binarios automáticos!

fin_isr:
    pop temp             // Recupera el estado de las banderas
    out SREG, temp
    pop temp             // Recupera temp
    reti                 // Regresa al loop principal

delay_5ms:               // Espera necesaria para la multiplexación
    ldi r22, 100
D5_1: ldi r23, 250
D5_2: dec r23 \ brne D5_2 \ dec r22 \ brne D5_1 \ ret

delay_20ms:              // Espera necesaria para el anti-rebote
    ldi r22, 255
D20_1: ldi r23, 255
D20_2: dec r23 \ brne D20_2 \ dec r22 \ brne D20_1 \ ret
/****************************************/
