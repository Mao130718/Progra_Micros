/*
* Laboratorio2_Timer0_MaoJoachin.asm
*
* Creado: 14/02/2026 21:36:47
* Autor : María Olga Joachin
* Descripción: Contador de cuatro segundos con Timer0 junto con un contador hexadecimal con botones
*/
/****************************************/

.include "M328PDEF.inc"
.dseg
.org SRAM_START

// Definición de los constantes a utilizar
.EQU COUNTER_MAX     = 15       // Valor máximo del contador (F en hex)
.EQU OVERFLOW_COUNT  = 6        // Overflows para ~100ms
.EQU TIMER_PRELOAD   = 6        // Precarga del Timer0
.EQU SECONDS_MAX     = 10       // 10 x 100ms = 1 segundo
.EQU DEBOUNCE_COUNT  = 5        // 5 ciclos de 1ms para anti-rebote

// Definición de los registros 
.DEF TEMPORAL        = R16      // Registro temporal
.DEF COUNTER_BTN     = R17      // Contador de botones (display 7seg)
.DEF SEGMENT_DATA    = R18      // Datos para el display
.DEF COUNTER_SEG     = R19      // Contador de segundos (4 LEDs)
.DEF COUNTER_OVF     = R20      // Contador de overflows del Timer0
.DEF COUNTER_100MS   = R21      // Contador de 100ms para llegar a 1s
.DEF LED_STATE       = R22      // Estado del LED indicador (0 o 1)
.DEF DEBOUNCE_B1     = R23      // Contador anti-rebote B1
.DEF DEBOUNCE_B2     = R24      // Contador anti-rebote B2
.DEF PREV_BTN        = R25      // Estado anterior de los botones

.cseg
.org 0x0000
    RJMP SETUP

// Tabla de valores para un display de 7 segmentos (Cátodo)
table7seg:
    .DB 0x3F, 0x06, 0x5B, 0x4F  // 0, 1, 2, 3
    .DB 0x66, 0x6D, 0x7D, 0x07  // 4, 5, 6, 7
    .DB 0x7F, 0x6F, 0x77, 0x7C  // 8, 9, A, b
    .DB 0x39, 0x5E, 0x79, 0x71  // C, d, E, F

/****************************************/
// Configuracion MCU
SETUP:
	// Pre-cargar puntero Z con dirección base de la tabla
    LDI TEMPORAL, LOW(RAMEND)
    OUT SPL, TEMPORAL
    LDI TEMPORAL, HIGH(RAMEND)
    OUT SPH, TEMPORAL

    // Pre-cargar puntero Z
    LDI ZH, HIGH(table7seg<<1)
    LDI ZL, LOW(table7seg<<1)

    // Inicializar registros
    CLR COUNTER_BTN             // Contador botones
    CLR COUNTER_SEG             // Contador segundos 
    CLR COUNTER_OVF             // Contador overflows 
    CLR COUNTER_100MS           // Contador 100ms
    CLR LED_STATE               // LED apagado
    CLR DEBOUNCE_B1             // Anti-rebote B1 
    CLR DEBOUNCE_B2             // Anti-rebote B2
    LDI PREV_BTN, 0xFF          // Botones no presionados inicialmente

    // Configurar PORTD
    // D4-D5 como entrada para los botones
    // D6-D7 como salida para los segmentos a y b
    LDI TEMPORAL, 0xC0
    OUT DDRD, TEMPORAL

    // Pull-ups en D4 y D5
    LDI TEMPORAL, 0x30
    OUT PORTD, TEMPORAL

    // Configurar PORTB
    // PB0-PB4 para los segmentos c,d,e,f,g
    // PB5 para el LED indicador D13
    LDI TEMPORAL, 0x3F
    OUT DDRB, TEMPORAL

    // Configurar PORTC
    // PC0-PC3 para los 4 LEDs del contador de segundos
    LDI TEMPORAL, 0x0F
    OUT DDRC, TEMPORAL

    // Configurar Timer0
    LDI TEMPORAL, 0x00
    OUT TCCR0A, TEMPORAL
    LDI TEMPORAL, (1<<CS02)|(1<<CS00)
    OUT TCCR0B, TEMPORAL
    LDI TEMPORAL, TIMER_PRELOAD
    OUT TCNT0, TEMPORAL
    LDI TEMPORAL, (1<<TOV0)
    OUT TIFR0, TEMPORAL

    // Mostrar valores iniciales
    RCALL UPDATE_DISPLAY
    RCALL UPDATE_LEDS
    RCALL UPDATE_LED_INDICATOR

/****************************************/
// Loop Infinito
MAIN_LOOP:

    // Verificar Timer0
    IN TEMPORAL, TIFR0
    SBRS TEMPORAL, TOV0
    RJMP CHECK_BUTTONS

    // Limpiar flag y recargar timer
    LDI TEMPORAL, (1<<TOV0)
    OUT TIFR0, TEMPORAL
    LDI TEMPORAL, TIMER_PRELOAD
    OUT TCNT0, TEMPORAL

    // Contar overflows
    INC COUNTER_OVF
    CPI COUNTER_OVF, OVERFLOW_COUNT
    BRNE CHECK_BUTTONS
    CLR COUNTER_OVF

    // Han pasado 100ms
    INC COUNTER_100MS
    CPI COUNTER_100MS, SECONDS_MAX
    BRNE CHECK_BUTTONS
    CLR COUNTER_100MS

    // Ha pasado 1 segundo
    INC COUNTER_SEG
    CPI COUNTER_SEG, 16
    BRNE UPDATE_SEG_DISPLAY
    CLR COUNTER_SEG

UPDATE_SEG_DISPLAY:
    RCALL UPDATE_LEDS

    CP COUNTER_SEG, COUNTER_BTN
    BRNE CHECK_BUTTONS

    // Son iguales! Reiniciar y togglear LED
    CLR COUNTER_SEG
    RCALL UPDATE_LEDS
    RCALL TOGGLE_LED

// Antirrebote para los botones a utilizar
CHECK_BUTTONS:

    // Boton 1
CHECK_B1:
    IN TEMPORAL, PIND

    // ¿Cambió de estado?
    MOV R26, TEMPORAL
    ANDI R26, 0x20              // Bit 5 actual
    MOV R27, PREV_BTN
    ANDI R27, 0x20              // Bit 5 anterior

    CP R26, R27
    BRNE B1_CHANGED

    // NO cambió → Reset Counter B1
    CLR DEBOUNCE_B1
    RJMP B1_DELAY

B1_CHANGED:
    // SÍ cambió → Increment Counter B1
    INC DEBOUNCE_B1

    // ¿Counter B1 = 5?
    CPI DEBOUNCE_B1, DEBOUNCE_COUNT
    BRNE B1_DELAY

    // Llegó a 5 → Change State + Reset Counter
    CLR DEBOUNCE_B1

    // Guardar nuevo estado de B1
    ANDI PREV_BTN, 0xDF         // Limpiar bit 5
    MOV R27, TEMPORAL
    ANDI R27, 0x20
    OR PREV_BTN, R27

    // ¿Fue presionado (bit=0)?
    SBRS TEMPORAL, 5
    RCALL PROCESS_B1

B1_DELAY:
    RCALL DELAY_1MS           

    // Boton 2
CHECK_B2:
    IN TEMPORAL, PIND

    // ¿Cambió de estado?
    MOV R26, TEMPORAL
    ANDI R26, 0x10              // Bit 4 actual
    MOV R27, PREV_BTN
    ANDI R27, 0x10              // Bit 4 anterior

    CP R26, R27
    BRNE B2_CHANGED

    // NO cambió → Reset Counter B2
    CLR DEBOUNCE_B2
    RJMP B2_DELAY

B2_CHANGED:
    // SÍ cambió → Increment Counter B2
    INC DEBOUNCE_B2

    // ¿Counter B2 = 5?
    CPI DEBOUNCE_B2, DEBOUNCE_COUNT
    BRNE B2_DELAY

    // Llegó a 5 → Change State + Reset Counter
    CLR DEBOUNCE_B2

    // Guardar nuevo estado de B2
    ANDI PREV_BTN, 0xEF         // Limpiar bit 4
    MOV R27, TEMPORAL
    ANDI R27, 0x10
    OR PREV_BTN, R27

    // ¿Fue presionado (bit=0)?
    SBRS TEMPORAL, 4
    RCALL PROCESS_B2

B2_DELAY:
    RCALL DELAY_1MS             // Delay al final como indica diagrama

    RJMP MAIN_LOOP

// NON-Interrupt subroutines

	// Subrutina para el incremento del Boton 1
PROCESS_B1:
    INC COUNTER_BTN
    CPI COUNTER_BTN, 16
    BRNE B1_UPDATE
    CLR COUNTER_BTN
B1_UPDATE:
    RCALL UPDATE_DISPLAY
    RET

	// Subrutina para el incremento del Boton 2
PROCESS_B2:
    DEC COUNTER_BTN
    CPI COUNTER_BTN, 255
    BRNE B2_UPDATE
    LDI COUNTER_BTN, 15
B2_UPDATE:
    RCALL UPDATE_DISPLAY
    RET

	// Subrutina para el LED indicador
TOGGLE_LED:
    CPI LED_STATE, 0
    BREQ TOGGLE_LED_ON
    CLR LED_STATE
    RJMP UPDATE_LED_INDICATOR
TOGGLE_LED_ON:
    LDI LED_STATE, 1
UPDATE_LED_INDICATOR:
    IN TEMPORAL, PORTB
    ANDI TEMPORAL, 0xDF         // Limpiar bit 5
    CPI LED_STATE, 1
    BRNE LED_OFF
    ORI TEMPORAL, 0x20          // Encender bit 5
LED_OFF:
    OUT PORTB, TEMPORAL
    RET

	// Subrutina para el display de 7 segmentos
UPDATE_DISPLAY:
    PUSH R30
    PUSH R31
    PUSH R20

    LDI R30, LOW(table7seg<<1)
    LDI R31, HIGH(table7seg<<1)
    ADD R30, COUNTER_BTN
    LDI R20, 0
    ADC R31, R20
    LPM SEGMENT_DATA, Z

    // Segmentos a, b → PORTD bits 6, 7
    IN TEMPORAL, PORTD
    ANDI TEMPORAL, 0x3F
    MOV R19, SEGMENT_DATA
    ANDI R19, 0x03
    LSL R19
    LSL R19
    LSL R19
    LSL R19
    LSL R19
    LSL R19
    OR TEMPORAL, R19
    OUT PORTD, TEMPORAL

    // Segmentos c, d, e, f, g → PORTB bits 0-4
    IN TEMPORAL, PORTB
    ANDI TEMPORAL, 0xE0
    MOV R19, SEGMENT_DATA
    LSR R19
    LSR R19
    ANDI R19, 0x1F
    OR TEMPORAL, R19
    OUT PORTB, TEMPORAL

    POP R20
    POP R31
    POP R30
    RET

// Subrutina para la actualización del contador de los LEDs
UPDATE_LEDS:
    IN TEMPORAL, PORTC
    ANDI TEMPORAL, 0xF0
    MOV R19, COUNTER_SEG
    ANDI R19, 0x0F
    OR TEMPORAL, R19
    OUT PORTC, TEMPORAL
    RET

// Subrutina para el delay de 1ms
DELAY_1MS:
    PUSH R20
    PUSH R21
    LDI R20, 16
DELAY_1MS_OUTER:
    LDI R21, 250
DELAY_1MS_INNER:
    DEC R21
    BRNE DELAY_1MS_INNER
    DEC R20
    BRNE DELAY_1MS_OUTER
    POP R21
    POP R20
    RET
/****************************************/