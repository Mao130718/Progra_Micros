/*
* Proyecto1_Reloj.asm
*
* Creado: 3/03/2026 14:18:03
* Autor : María Olga Joachin
* Descripción: Funcionamiento de un reloj con 4 displays de 7 segmentos
el cual estará controlado por 4 pushbuttons, uno para el cambio de configuracion
mientras que los otro 4 para el incremento y decremento de los displays. 
*/
/****************************************/

// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"


.def temp           = r16		 // Registro temporal de uso general
.def num_a_mostrar  = r18		 // Numero del los digitos que se mostraran en el display, 0 a 9
.def estado         = r25    	 // Estado actual del reloj 
.def en_config      = r19    	 // Banderas para verificar el estado de configuración
.def disp_select    = r24    	 // Indica cual de los display esta siendo activado

//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)
.dseg
.org 0x0100
segundos:			 .byte 1	 // Almacena los segundos actuales
minutos:			 .byte 1	 // Almacena los minutos actuales
horas:				 .byte 1	 // Almacena la hora actual
dia:				 .byte 1	 // Almacena el dia del mes actual
mes:				 .byte 1	 // Almacena el mes actual
alarma_horas:		 .byte 1	 // Hora de configuración para la alarma (0 a 23)
alarma_minutos:		 .byte 1	 // Minuto de configuración para la alarma (0 a 59)
alarma_activa:		 .byte 1	 // Bandera para activar la alarma
cont_ms:			 .byte 1     // Contador de milisegundos para el parpadeo de los LEDs
cont_ms2:			 .byte 1     // Contador de milisegundos para el estado de la alarma
digito0:			 .byte 1     // Valor del digito del Display 1
digito1:			 .byte 1     // Valor del digito del Display 2
digito2:			 .byte 1     // Valor del digito del Display 3
digito3:			 .byte 1     // Valor del digito del Display 4

// Vectores de interrupción
.cseg
.org 0x0000
    rjmp Setup

.org 0x0006                  // PCINT1 - Botones Puerto C
    rjmp PCI1_ISR

.org 0x001A                  // Timer1 Compare Match A - 1 segundo
    rjmp TIM1_COMPA_ISR

.org 0x001C                  // Timer0 Compare Match A - 1ms multiplexado
    rjmp TIM0_COMPA_ISR

// Tabla de 7 segmentos (Display Cátodo Común)
.org 0x0034
Tabla7Seg:
    .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F

/****************************************/
// Configuración de la pila
Setup:
    // Inicialización del stack
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

/****************************************/
// Configuracion MCU

    // Configuración de Puertos
    // DDRB: PB0-PB5 salidas 
    ldi temp, 0b00111111					// Se escriben de PB0 a PB5 como salidas
    out DDRB, temp							// Se escribe la configuración en el registro del Puerto B

	// DDRD: PD2-PD7 salidas 
	ldi temp, 0b11111100					// Se escriben de PD2 a PD7 como salidas
	out DDRD, temp							// Se escribe la configuración en el registro del Puerto D
	
	// DDRC: PC5 salida (buzzer), PC0-PC4 entradas (botones)
	ldi temp, 0b00100000					// Se escriben PC5 como salida del buzzer y PC0 a PC4 como entradas 
	out DDRC, temp							// Se escribe la configuración en el registro del Puerto C
	
	// Pull-ups botones PC0-PC4, PC5 apagado al inicio
	ldi temp, 0b00011111					// Habilita el pull-up interno
	out PORTC, temp							// Se escribe en PORTC 

    // Apagar displays al inicio
    clr temp								// Limpieza del registro
    out PORTB, temp							// Se apagan todos los segmentos del Puerto B
    out PORTD, temp							// Se apagan los pines del Puerto D

    // Configuración del Timer0
    ; CTC, prescaler 64, OCR0A=249 => 1ms @ 16MHz
    ldi temp, (1 << WGM01)					// Modo CTC, el temporizador se reinicia cuando llega al valor de OCR0A
    out TCCR0A, temp						// Configuración del registro de control A del Timer0
    ldi temp, (1 << CS01) | (1 << CS00)		// Se usa un prescaler de 64
    out TCCR0B, temp						// Configuración del registro de control B del Timer0 con el prescaler
    ldi temp, 249							// El valro a comparar para una interrupcion de 1ms
    out OCR0A, temp							// Se carga el valor de comparación del Timer0
    ldi temp, (1 << OCIE0A)					// Se habilita la interrupción del Timer0
    sts TIMSK0, temp						// Se escribe en el registro de mascara de interrupciones del Timer0

    // Configurar Timer1
    // CTC, prescaler 1024, OCR1A=15624 => 1s @ 16MHz
    ldi temp, high(15624)					// Valor alto de comparación para 1 segundo
    sts OCR1AH, temp						// Carga el byte alto de OCR1A en la memoria
    ldi temp, low(15624)					// Valor bajo de comparación para 1 segundo
    sts OCR1AL, temp						// Carga el byte bajo de OCR1A en la memoria
    ldi temp, (1 << WGM12) | (1 << CS12) | (1 << CS10)		// Modo CTC con prescaler de 1024
    sts TCCR1B, temp						// Configuración del Timer1 con prescaler 1024
    ldi temp, (1 << OCIE1A)					// Se habilita la interrupción por comparación del Timer 1
    sts TIMSK1, temp						// Se escribe el registro de máscara de interrupciones para el Timer 1

    // Configurar PCINT1 - Botones PC0-PC4
    ldi temp, (1 << PCIE1)					// Se habilitan las insterrupciones por cambio del pin en el Puerto C
    sts PCICR, temp							// Se escribe en el registro de control de interrupciones
    ldi temp, 0b00011111					// Se habilita PCINT para PC0 a PC4
    sts PCMSK1, temp						// Se escriba la máscara de pines a monitorear en Puerto C

    // Inicializar variables
    ldi temp, 0x00							// Valor inicial es 0
    sts segundos, temp						// Inicialización de segundos en 0
    sts minutos, temp						// Inicialización de minutos en 0
    sts horas, temp							// Inicialización de horas en 0
    sts cont_ms, temp						// Inicialización del contador de milisegundos en 0
    sts cont_ms2, temp						// Inicialización del contador de milisegundos para la alarma en 0
    sts alarma_activa, temp					// Inicialización de la bandera para activar la alarma en 0
    sts alarma_horas, temp					// Inicialización de hora de la alarma en 0
    sts alarma_minutos, temp				// Inicialización de minutos de la alarma en 0
    
    // Inicializar todos los digitos a 0
    sts digito0, temp						// Display 1 inicia mostrando 0
    sts digito1, temp						// Display 2 inicia mostrando 0
    sts digito2, temp						// Display 3 inicia mostrando 0
    sts digito3, temp						// Display 4 inicia mostrando 0
    
    ldi temp, 1								// Valor inicial para dia y mes siendo 1
    sts dia, temp							// Inicialización dia en 1
    sts mes, temp							// Inicialización mes en 1

    // Inicializar registros
    clr estado								// Estado inicial en 0 (para visualizar la hora)
    clr en_config							// El reloj comienza a correr
    clr disp_select							// Empieza el display 0 en el multiplexado
    sei										// Habilita interrupciones globales 

/****************************************/
// Loop Infinito

MainLoop:
    rcall Actualizar_Digitos				// Llama a la subrutina pata actualizar los digitos segun el modo actual
    rjmp  MainLoop							// Bucle principal

/****************************************/
// NON-Interrupt subroutines
// Actualización de dígitos para los displays
Actualizar_Digitos:
    cpi  estado, 1							// Compara estado 1 (fecha)
    breq Mostrar_Fecha						// Si el estado == 1, salta a mostrar la fecha
    cpi  estado, 3         					// Compara estado 3 (configuración de fecha)
    breq Mostrar_Fecha      				// Si el estado == 3, salta a mostrar la fecha
    cpi  estado, 4							// Compara estado 4 configuración de alarma)
    breq Mostrar_Alarma						// Si el estado == 4, salta a mostrar la alarma
    rjmp Mostrar_Hora						// En los otros casos como estado 0 o 2, muestra la hora

Mostrar_Hora:
    lds     temp, horas						// Carga el valoor de horas desde la RAM
    rcall   Separar_Digitos					// Separa las decenas y las unidades 
    sts     digito0, r21					// Guarda decenas de hora en el Display 1
    sts     digito1, r22					// Guarda unidades de hora en el Display 2
    lds     temp, minutos					// Carga el valor de munutos desde la RAM
    rcall   Separar_Digitos					// Guarda decenas de minuto en el Display 3
    sts     digito2, r21					// Guarda unidades de minuto en el Display 4
    sts     digito3, r22					// Retorna
    ret

Mostrar_Fecha:
    lds     temp, dia						// Carga el valor del dia desde la RAM
    rcall   Separar_Digitos					// Separa las decenas y las unidades
    sts     digito0, r21					// Guarda decenas de dia en el Display 1
    sts     digito1, r22					// Guarda unidades de dia en el Display 2
    lds     temp, mes						// Carga el valor del mes desde la RAM
    rcall   Separar_Digitos					// Separa las decenas y las unidades
    sts     digito2, r21					// Guarda decenas del mes en el Display 3
    sts     digito3, r22					// Guarda unidades del mes en el Display 4
    ret										// Retorna

Mostrar_Alarma:
    lds     temp, alarma_horas				// Carga el valor de la alarma desde la RAM
    rcall   Separar_Digitos					// Separa las decenas y las unidades
    sts     digito0, r21					// Guarda decenas de hora de alarma en el Display 1
    sts     digito1, r22					// Guarda unidades de hora de alarma en el Display 2
    lds     temp, alarma_minutos			// Carga el valor del mes desde la RAM
    rcall   Separar_Digitos					// Separa las decenas y las unidades
    sts     digito2, r21					// Guarda decenas de minuto de alarma en el Display 3
    sts     digito3, r22					// Guarda unidades de minuto de alarma en el Display 4
    ret										// Retorna

// Separación de dígitos
Separar_Digitos:
    clr     r21								// Inicializa el contador de decenas en 0
Sep_Loop:
    cpi     temp, 10						// Compara el numero restante con 10
    brlo    Sep_Fin							// Si es menor que 10, ya esta las unidades en temo
    subi    temp, 10						// Resta 10 al numero (uya que equivale a extraer una decena)
    inc     r21								// Incrementa el contador de decenas
    rjmp    Sep_Loop						// Repite hasta que temp sea menor que 10
Sep_Fin:
    mov     r22, temp						// El resto (osea 0 a 9) son las unidades
    ret										// Retorna con decenas y unidades (en registros r21 y r22 respectivamente)

/****************************************/
// Interrupt routines
// ISR Timer1 - Avance del reloj
TIM1_COMPA_ISR:				
    push temp								// Guarda el registro temp en la pila
    in   temp, SREG							// Lee el registro de estado del procesador
    push temp								// Guarda SREG en la pila para restaurarlo despues
	push r20								// Guarda r20 en la pila (usado para incrementar)
	push r21								// Guarda r21 en la píla (usado para incrementar)
											
    mov  temp, en_config     				// Copia la bandera de configuración a temp
    tst  temp								// Verifica si la bandera es cero (osea si el reloj esta corriendo)
    brne Salir_T1							// Si en_config es distinto de 0, no avanza el tiempo
											
    lds  temp, segundos						// Se carga el valor actual de segundos desde la RAM
    inc  temp								// Incrementa los segundos de 1 en 1
    cpi  temp, 60							// Compara con 60 ya que es el limite de los segundos (indica overflow)
    brne Guardar_Seg						// Si no llega a 60, guarda y termina
    clr  temp								// Si llego a 60, reinicia a 0 segundos
    sts  segundos, temp						// Guarda segundos en 0
    rcall Inc_Minutos						// Llama a la rutina de incremento de minutos 
    rjmp Salir_T1							// Salta a la final de la ISR 

Guardar_Seg:								
    sts  segundos, temp						// Guarda el nuevo valor de segundos en la RAM

Salir_T1:
    pop r21									// Restaura r21 desde la pila
	pop r20									// Restaura r20 desde la pila
	pop  temp								// Restaura el valor de SREG que se guardo
    out  SREG, temp							// Restaura el registro de estado del procesador
    pop  temp								// Restaura el registro temp original 
    reti									// Retorna de la interrupción y re-habilita las interrupciones

// ISR Timer1 - Multiplexado de los displays
TIM0_COMPA_ISR:
    push temp								// Guarda temp en la pila
    in   temp, SREG							// Lee el registro de estado
    push temp								// Guarda SREG en la pila
    push num_a_mostrar						// Guarda el registro de digito actual
    push r20								// Guarda r20 para operaciones de puerto
    push r21								// Guarda r21 para el uso de máscara XOR

    // Apagar SOLO transistores (PD2-PD5)
    in   temp, PORTD						// Lee el estado actual del Puerto D
    andi temp, 0b11000011					// Apaga PD2 a PD5 
    out  PORTD, temp						// Escribe el resultado, desactiva todos los displays

    // Cargar digito segun display actual
    cpi  disp_select, 0						// Compara el display actual con 0
    breq ISR_D0								// Si es el Display 0, salta a cargarlo
    cpi  disp_select, 1						// Compara con 1
    breq ISR_D1								// Si es el Display 1, salta a cargarlo
    cpi  disp_select, 2						// Compara con 2
    breq ISR_D2								// Si es el Display 2, salta a cargarlo
    rjmp ISR_D3								// Si es 3, carga el Display 3

ISR_D0:
    lds  num_a_mostrar, digito0				// Carga el digito 0 en decenas de hora/dia al mostrarlo
    rjmp ISR_Enviar							// Salta a enviar el digito a los puertos

ISR_D1:
    lds  num_a_mostrar, digito1				// Carga el digito 1 en unidades de hora/dia al mostrarlo
    rjmp ISR_Enviar							// Salta a enviar el digito a los puertos

ISR_D2:
    lds  num_a_mostrar, digito2				// Carga el digito 2 en decenas de minutos/mes al mostrarlo
    rjmp ISR_Enviar							// Salta a enviar el digito a los puertos

ISR_D3:
    lds  num_a_mostrar, digito3				// Carga el digito 3 en unidades minutos/mes al mostrarlo

ISR_Enviar:
    rcall Enviar_a_Puertos					// Llama a la subrutina para enviar las señales a los degmentos del display

    // Activar transistor correspondiente
    cpi  disp_select, 0						// Verifica si el display actual esta es el 0
    breq ISR_T1								// Si es 0, activa el transistor del Display 1
    cpi  disp_select, 1						// Verifica si el display actual esta es el 1
    breq ISR_T2								// Si es 0, activa el transistor del Display 2 
    cpi  disp_select, 2						// Verifica si el display actual esta es el 2 
    breq ISR_T3								// Si es 0, activa el transistor del Display 3
    rjmp ISR_T4								// Si es 3, activa el transistor del Display 4

ISR_T1:
    sbi  PORTD, 5							// Activa PD5, enciende el transistor del Display 1
    rjmp ISR_Fin							// Salta al final del manjeo de transistores

ISR_T2:
    sbi  PORTD, 4							// Activa PD4, enciende el transistor del Display 1
    rjmp ISR_Fin							// Salta al final del manjeo de transistores

ISR_T3:
    sbi  PORTD, 3							// Activa PD3, enciende el transistor del Display 1
    rjmp ISR_Fin							// Salta al final del manjeo de transistores

ISR_T4:
    sbi  PORTD, 2							// Activa PD2, se enciende el transistor del Display 4

ISR_Fin:
    // Avanzar display
    inc  disp_select						// Incrementa el indice del display activo
    andi disp_select, 0x03					// Mantiene el valor en rango de 0 a 3 

    // Parpadeo PB5 segun estado
    lds  temp, cont_ms						// Carga el contador de milisegundos del parpadeo
    inc  temp								// Incrementa el contador en 1

    cpi  estado, 4							// Verifica si el estado es 4 (el de la alarma)
    breq Chk_Rapido							// Si es estado 4, usa parpadeo rápido-

Chk_Lento:
    cpi  temp, 200							// Verifica si han pasado 200ms 
    brne Guardar_Cont						// Si no llegamos a 200ms, guarda y continua 
    clr  temp								// Reincia el contador de milisegundos
    cpi  estado, 2							// Verifica si el estado es menor que 2 (modo normal)
    brlo LED_Fijo							// Si estado es menor a 2, el Led permanece fijo (indicado fecha u hora)
    in   r20, PORTB							// Lee el estado actual del Puerto B
    ldi  r21, (1 << PB5)					// Prepara mascara para el bit PB5 
    eor  r20, r21							// Alterna el bit PB5
    out  PORTB, r20							// Escribe el nuevo estado con PB5 alternado
    rjmp Guardar_Cont						// Salta a guardar el contador

Chk_Rapido:
    cpi  temp, 30							// Verifica si han pasado 30 ms (parpadeo rápido para el arma)
    brne Guardar_Cont						// Si no, guarda y continua 
    clr  temp								// Reinicia el contador
    in   r20, PORTB							// Lee el estado del Puerto B
    ldi  r21, (1 << PB5)					// Prepara mascara para PB5
    eor  r20, r21							// Alterna el LED dos puntos rapidamente
    out  PORTB, r20							// Escribe el nuevo estado
    rjmp Guardar_Cont						// Salta a guardar el contador

LED_Fijo:
    sbi  PORTB, 5							// Enciende el LED PB5 de forma fija

Guardar_Cont:
    sts  cont_ms, temp						// Guarda el contador de ms actualizado en la RAM
											
    rcall Parpadeo_LEDs_Alarma				// Llama a la rutina de parpadeo de LEDs de la alarma
											
    pop  r21								// Restaura r21 desde la pila
    pop  r20								// Restaura r20 desde la pila
    pop  num_a_mostrar						// Restaura la variable de numero a mostrar desde la pila
    pop  temp								// Recupera el valor de SREG guardado
    out  SREG, temp							// Restaura el registro de estado
    pop  temp								// Restaura temp original
    reti									// Retorna de la interrupción

// Parpadeo de los LEDs del reloj
Parpadeo_LEDs_Alarma:
    cpi  estado, 4							// Verifica si el estado actual es 4 (configuracion de alarma)
    brne Salir_Parpadeo						// Si no es estado 4, sale sin hacer nada
											
    lds  temp, cont_ms2						// Carga el segundo contador de ms
    inc  temp								// Lo incrementa
    cpi  temp, 125							// Verifica si han pasado 125ms
    brne Guardar_ms2						// Si no, solo guarda el contador actualizado
    clr  temp								// Reinicia el contador al llegar a 125ms
    in   r20, PORTD							// Lee el estado actual del Puerto D
    ldi  r21, (1 << PD0) | (1 << PD1)		// Mascara para los bits PD0 y PD1
    eor  r20, r21							// Alterna (toggle) PD0 y PD1 simultaneamente
    out  PORTD, r20							// Escribe el nuevo estado en el Puerto D

Guardar_ms2:
    sts  cont_ms2, temp						// Guarda el contador de ms2 actualizado en RAM
Salir_Parpadeo:
    ret										// Retorna al llamador

// Digitos a mostrar en los displays
Enviar_a_Puertos:
    // Asegurar que el dígito está en rango 0-9
    cpi  num_a_mostrar, 10					// Verifica que el digito sea valido 
    brlo Enviar_Seguro      				// Si es menor que 10, procede normalmente
    ldi  num_a_mostrar, 0   				// Si es menor o igual a 10 es invalido, fuerza a mostrar 0 por seguridad
	out PORTD, temp							// Limpia el puerto D 
	ret										// Sale sin continuar
    
Enviar_Seguro:
    // Cargar la dirección base de la tabla (multiplicada por 2 para bytes)
    ldi  ZH, high(Tabla7Seg << 1)			// Carga la´parte alta de la dirección de la tabla en ZH	
    ldi  ZL, low(Tabla7Seg << 1)			// Carga la´parte baja de la dirección de la tabla en ZL
    
    // Sumar el índice (num_a_mostrar) al puntero Z de 16 bits
    add  ZL, num_a_mostrar					// Suma el indice al byte bajo del puntero Z
    clr  temp               				// Limpia temp para usarlo como carry
    adc  ZH, temp           				// Propaga el acarreo al byte alto de Z si ZL se desbordó
    
    // Leer el valor de la tabla
    lpm  r20, Z								// Lee el byte de la tabla de 7 segmentos

    clr  r21								// Limpia r21 para construir el valor a escribir en PORTB
    bst  r20, 0  							// Extrae el bit 0 de r20 en el flag T
    bld r21, 4   							// Deposita el flag T en el bit 4 de r21 (PB4 = seg A)
    bst  r20, 1  							// Extrae el bit 1 en T
    bld r21, 3    							// Deposita en bit 3 de r21 (PB3 = seg B)
    bst  r20, 2  							// Extrae el bit 2 en T
    bld r21, 2    							// Deposita en bit 2 de r21 (PB2 = seg C)
    bst  r20, 3  							// Extrae el bit 3 en T
    bld r21, 1    							// Deposita en bit 1 de r21 (PB1 = seg D)
    bst  r20, 4  							// Extrae el bit 4 en T
    bld r21, 0    							// Deposita en bit 0 de r21 (PB0 = seg E)

    in   temp, PORTB						// Lee el estado actual de PORTB
    andi temp, 0b11100000        			// Conserva solo los bits PB5-PB7 (LED dos puntos y otros)
    or   temp, r21							// Combina con los nuevos valores de segmentos A-E
    out  PORTB, temp						// Escribe el resultado final en PORTB
											
    clr  r22								// Limpia r22 para construir el valor a escribir en PORTD
    bst  r20, 5  							// Extrae el bit 5 de r20 (segmento F) en T
    bld r22, 7     							// Deposita en bit 7 de r22 (PD7 = seg F)
    bst  r20, 6  							// Extrae el bit 6 (segmento G) en T
    bld r22, 6     							// Deposita en bit 6 de r22 (PD6 = seg G)
											
    in   temp, PORTD						// Lee el estado actual de PORTD
	andi temp, 0b00111111    				// Limpia solo los bits PD7 y PD6 (segmentos F y G)
	or   temp, r22           				// Combina con los nuevos valores de seg F y G
	out  PORTD, temp						// Escribe el resultado final en PORTD y retorna (sin ret explicito)

PCI1_ISR:
    push temp								// Guarda temp en la pila						
    in   temp, SREG							// Lee el registro de estado
    push temp								// Guarda SREG
    push r20								// Guarda r20

    in   temp, PINC							// Lee el estado actual de los pines del Puerto C (botones)

    sbrc temp, 4             				// Salta si el bit 4 esta limpio (PC4 presionado = 0)
    rjmp Chk_PC0							// Si PC4 NO esta presionado, revisa el siguiente boton
    rcall Cambiar_Estado					// PC4 presionado: cambia el modo/estado del reloj
    rcall Esperar_Soltar_PC4				// Espera a que se suelte el boton PC4
    rjmp Fin_PCI1							// Termina el manejo de la interrupcion

Chk_PC0:
    sbrc temp, 0             				// Salta si el bit 0 esta limpio (PC0 presionado = 0)
    rjmp Chk_PC1							// Si PC0 NO esta presionado, revisa el siguiente
    rcall Accion_Up_D1						// PC0 presionado: incrementa el primer par de digitos
    rcall Esperar_Soltar_PC0				// Espera a que se suelte PC0
    rjmp Fin_PCI1

Chk_PC1:
    sbrc temp, 1             				// Salta si PC1 esta limpio (presionado)
    rjmp Chk_PC2							// Si no esta presionado, revisa el siguiente
    rcall Accion_Down_D1					// PC1 presionado: decrementa el primer par de digitos
    rcall Esperar_Soltar_PC1				// Espera a que se suelte PC1
    rjmp Fin_PCI1

Chk_PC2:
    sbrc temp, 2             				// Salta si PC2 esta limpio (presionado)
    rjmp Chk_PC3							// Si no esta presionado, revisa el siguiente
    rcall Accion_Up_D2						// PC2 presionado: incrementa el segundo par de digitos
    rcall Esperar_Soltar_PC2				// Espera a que se suelte PC2
    rjmp Fin_PCI1

Chk_PC3:
    sbrc temp, 3             				// Salta si PC3 esta limpio (presionado)
    rjmp Fin_PCI1							// Si PC3 NO esta presionado, no hay accion (sale)
    rcall Accion_Down_D2					// PC3 presionado: decrementa el segundo par de digitos
    rcall Esperar_Soltar_PC3				// Espera a que se suelte PC3

Fin_PCI1:
    pop  r20								// Restaura r20
    pop  temp								// Recupera SREG guardado
    out  SREG, temp							// Restaura el registro de estado
    pop  temp								// Restaura temp
    reti									// Retorna de la interrupcion

// Espera para la verificacion de los botones
Esperar_Soltar_PC4:
    in   temp, PINC							// Lee el estado de los pines del Puerto C
    sbrs temp, 4							// Salta si el bit 4 esta en 1 (boton suelto)
    rjmp Esperar_Soltar_PC4					// Si sigue en 0 (presionado), espera en bucle
    ret										// El boton fue soltado, retorna
											
Esperar_Soltar_PC0:							
    in   temp, PINC							// Lee los pines del Puerto C
    sbrs temp, 0							// Salta si PC0 esta en 1 (suelto)
    rjmp Esperar_Soltar_PC0					// Si sigue presionado, espera
    ret										
											
Esperar_Soltar_PC1:							
    in   temp, PINC							// Lee los pines del Puerto C
    sbrs temp, 1							// Salta si PC1 esta en 1 (suelto)
    rjmp Esperar_Soltar_PC1					// Si sigue presionado, espera
    ret										
											
Esperar_Soltar_PC2:						
    in   temp, PINC							// Lee los pines del Puerto C
    sbrs temp, 2							// Salta si PC2 esta en 1 (suelto)
    rjmp Esperar_Soltar_PC2					// Si sigue presionado, espera
    ret										
											
Esperar_Soltar_PC3:							
    in   temp, PINC							// Lee los pines del Puerto C
    sbrs temp, 3							// Salta si PC3 esta en 1 (suelto)
    rjmp Esperar_Soltar_PC3					// Si sigue presionado, espera
    ret

// Cambios de estado del reloj
Cambiar_Estado:
    ; Primero verificar si la alarma esta sonando
    lds  temp, alarma_activa
    cpi  temp, 1
    brne Modo_Normal						// Si no esta sonando, cambiar modo normal

    // Si esta sonando -> apagarla y NO cambiar estado
    clr  temp
    sts  alarma_activa, temp				// Marca alarma como inactiva	
    cbi  PORTC, 5							// Apagar buzzer
    ret

Modo_Normal:
    inc  estado								// Avanzar al siguiente modo
    cpi  estado, 5							// Verificar si paso del ultimo modo 
    brlo Est_Config_Check					 
    clr  estado								// Si paso de 4, volver a 0
										
Est_Config_Check:						
    // Estados 2,3,4 pausan el reloj	
    cpi  estado, 2							// Verifica si el estado es 2 o mayor
    brsh Est_Pausar							// Si estado >= 2, pausa el reloj
    clr  en_config							// Estado 0 o 1: reloj corre (en_config = 0)
    rjmp Actualizar_LEDs					// Actualiza los LEDs indicadores
Est_Pausar:									
    ldi  en_config, 1						// Pausa el reloj (en_config = 1)
	rjmp Actualizar_LEDs					// Actualiza los LEDs indicadores
											
Actualizar_LEDs:							
    cpi  estado, 2							// Verifica si el estado es 2 o mayor
    brsh LED_Parpadeo    					// Si estado >= 2, activa el parpadeo del LED
    // Estados 0,1 -> encendido fijo
    sbi  PORTB, 5							// Enciende el LED dos puntos de forma fija
    ret
LED_Parpadeo:
    // El parpadeo lo maneja Timer0, solo Setupear contador
    clr  temp								// Limpia temp
    sts  cont_ms, temp						// Reinicia el contador de ms para empezar el parpadeo desde cero
    ret

// Rutinas de incremento desde el Timer 1
Inc_Minutos:
    lds  temp, minutos						// Carga el valor actual de minutos
    inc  temp								// Incrementa los minutos
    cpi  temp, 60							// Compara con el limite de 60 minutos
    brne Guardar_IMin						// Si no llego a 60, guarda el nuevo valor
    clr  temp								// Si llego a 60, reinicia a 0
    sts  minutos, temp						// Guarda minutos = 0 en RAM
    rcall Inc_Horas							// Llama a incrementar las horas
	rcall Verificar_Alarma 
    ret
Guardar_IMin:
    sts  minutos, temp						// Guarda el nuevo valor de minutos en RAM
	rcall Verificar_Alarma					// Llama de nuevo para verificar la hora de la alarma
    ret

Inc_Horas:
    lds  temp, horas						// Carga el valor actual de horas
    inc  temp								// Incrementa las horas
    cpi  temp, 24							// Compara con el limite de 24 horas
    brne Guardar_IHor						// Si no llego a 24, guarda el nuevo valor
    clr  temp								// Si llego a 24, reinicia a 0 
    sts  horas, temp						// Guarda horas = 0
    rcall Inc_Dia							// Llama a incrementar el dia
    ret
Guardar_IHor:
    sts  horas, temp						// Guarda el nuevo valor de horas en RAM
    ret

// Verificar alarma 
Verificar_Alarma:
    lds  r20, horas							// Cargar hora actual
    lds  r21, alarma_horas					// Cargar hora de alarma configurada 
    cp   r20, r21							// Comparar horas 
    brne Alarma_No							// Si no coinciden, salir
    lds  r20, minutos						// Cargar minutos actuales
    lds  r21, alarma_minutos				// Cargar minutos de alarma cofigurada  
    cp   r20, r21							// Comparar minutos
    brne Alarma_No							// Si no coinciden, salir
    // Hora y minutos coinciden: activar buzzer
    ldi  temp, 1							 
    sts  alarma_activa, temp				// Marcar alarma como activa
    sbi  PORTC, 5							// Encender buzzer
    ret										
Alarma_No:
    lds  temp, alarma_activa
    cpi  temp, 1
    breq Mantener_Buzzer					// Si alarma sigue activa, mantener buzzer
    cbi  PORTC, 5							// Si no, apagar
Mantener_Buzzer:
    ret										// Retorna a llamador

Inc_Dia:
    lds  r20, dia							// Carga el dia actual
    lds  r21, mes							// Carga el mes actual (necesario para saber cuantos dias tiene)
    inc  r20								// Incrementa el dia
    rcall Dias_Del_Mes						// Obtiene el maximo de dias del mes actual en r22
    cp   r20, r22							// Compara el nuevo dia con el maximo + 1
    brlo Guardar_IDia						// Si es menor, el dia es valido, lo guarda
    ldi  r20, 1								// Si supera el maximo, reinicia el dia a 1
    sts  dia, r20							// Guarda dia = 1 en RAM
    rcall Inc_Mes							// Llama a incrementar el mes
    ret
Guardar_IDia:
    sts  dia, r20							// Guarda el nuevo valor de dia en RAM
    ret

Inc_Mes:
    lds  temp, mes							// Carga el mes actual
    inc  temp								// Incrementa el mes
    cpi  temp, 13							// Compara con 13 (limite: el mes 13 no existe)
    brlo Guardar_IMes						// Si es menor que 13, el mes es valido
    ldi  temp, 1							// Si llego a 13, reinicia a enero 
Guardar_IMes:
    sts  mes, temp							// Guarda el nuevo mes en RAM
    ret

// Acciones de up/down segun el estado actual
Accion_Up_D1:
    cpi  estado, 2							// Verifica si estamos en modo configurar hora
    breq Up_Horas							// Si si, incrementa las horas
    cpi  estado, 3							// Verifica si estamos en modo configurar fecha
    breq Up_Dias							// Si si, incrementa el dia
    cpi  estado, 4							// Verifica si estamos en modo configurar alarma
    breq Up_Alarma_Hora						// Si si, incrementa la hora de alarma
    ret										// En otro estado, no hace nada

Up_Horas:
    lds  temp, horas						// Carga el valor actual de horas
    inc  temp								// Incrementa las horas
    cpi  temp, 24							// Verifica el limite de 24 horas
    brlo Guardar_Up_Hora					// Si es menor que 24, guarda directamente
    clr  temp								// Si llego a 24, reinicia a 0

Guardar_Up_Hora:
    sts  horas, temp						// Guarda las horas actualizadas en RAM
    ret

Up_Dias:
    lds  r20, dia							// Carga el dia actual
    lds  r21, mes							// Carga el mes actual
    inc  r20								// Incrementa el dia
    rcall Dias_Del_Mes						// Obtiene el maximo de dias del mes en r22
    cp   r20, r22							// Compara con el maximo + 1
    brlo Guardar_Up_Dia						// Si es valido, lo guarda
    ldi  r20, 1								// Si supera el maximo, vuelve al dia 1
Guardar_Up_Dia:
    sts  dia, r20							// Guarda el dia actualizado en RAM
    ret

Up_Alarma_Hora:
    lds  temp, alarma_horas					// Carga la hora de alarma actual
    inc  temp								// Incrementa la hora de alarma
    cpi  temp, 24							// Verifica el limite de 24 horas
    brlo Guardar_Up_AH						// Si es valido, guarda
    clr  temp								// Si llego a 24, reinicia a 0
Guardar_Up_AH:
    sts  alarma_horas, temp					// Guarda la hora de alarma actualizada en RAM
    ret

Accion_Down_D1:
    cpi  estado, 2							// Verifica modo configurar hora
    breq Down_Horas							// Si es modo 2, decrementa horas
    cpi  estado, 3							// Verifica modo configurar fecha
    breq Down_Dias							// Si es modo 3, decrementa dia
    cpi  estado, 4							// Verifica modo configurar alarma
    breq Down_Alarma_Hora					// Si es modo 4, decrementa hora de alarma
    ret										// En otro estado, no hace nada

Down_Horas:
    lds  temp, horas						// Carga las horas actuales
    dec  temp								// Decrementa las horas
    cpi  temp, 0xFF							// Verifica si hubo underflow (0 - 1 = 0xFF en byte sin signo)
    brne Guardar_Down_Hora					// Si no hay underflow, guarda directamente
    ldi  temp, 23							// Si hay underflow, ajusta a 23 (ciclo circular)
Guardar_Down_Hora:
    sts  horas, temp						// Guarda las horas actualizadas en RAM
    ret

Down_Dias:
    lds  r20, dia							// Carga el dia actual
    lds  r21, mes							// Carga el mes actual
    dec  r20								// Decrementa el dia
    cpi  r20, 0								// Verifica si llego a 0 (invalido)
    brne Guardar_Down_Dia					// Si no, guarda directamente
    rcall Dias_Del_Mes						// Si llego a 0, obtiene el maximo del mes para ciclo circular
    dec  r22								// El maximo real es r22 - 1 (porque la funcion retorna max+1)
    mov  r20, r22							// Copia el ultimo dia valido del mes a r20
Guardar_Down_Dia:
    sts  dia, r20							// Guarda el dia actualizado en RAM
    ret

Down_Alarma_Hora:
    lds  temp, alarma_horas					// Carga la hora de alarma actual
    dec  temp								// Decrementa la hora de alarma
    cpi  temp, 0xFF							// Verifica underflow
    brne Guardar_Down_AH					// Si no hay underflow, guarda
    ldi  temp, 23							// Si hay underflow, ajusta a 23
Guardar_Down_AH:
    sts  alarma_horas, temp					// Guarda la hora de alarma actualizada en RAM
    ret

Accion_Up_D2:
    cpi  estado, 2							// Verifica modo configurar hora
    breq Up_Minutos							// Si es modo 2, incrementa minutos
    cpi  estado, 3							// Verifica modo configurar fecha
    breq Up_Mes								// Si es modo 3, incrementa mes
    cpi  estado, 4							// Verifica modo configurar alarma
    breq Up_Alarma_Min						// Si es modo 4, incrementa minutos de alarma
    ret										// En otro estado, no hace nada

Up_Minutos:
    lds  temp, minutos						// Carga los minutos actuales
    inc  temp								// Incrementa los minutos
    cpi  temp, 60							// Verifica el limite de 60
    brlo Guardar_Up_Min						// Si es valido, guarda
    clr  temp								// Si llego a 60, reinicia a 0
Guardar_Up_Min:
    sts  minutos, temp						// Guarda los minutos actualizados en RAM
    ret

Up_Mes:
    lds  temp, mes							// Carga el mes actual
    inc  temp								// Incrementa el mes
    cpi  temp, 13							// Verifica el limite (mes 13 no existe)
    brlo Guardar_Up_Mes						// Si es valido (1-12), guarda
    ldi  temp, 1							// Si llego a 13, reinicia a enero
Guardar_Up_Mes:
    sts  mes, temp							// Guarda el mes actualizado en RAM
    ret

Up_Alarma_Min:
    lds  temp, alarma_minutos				// Carga los minutos de alarma actuales
    inc  temp								// Incrementa los minutos de alarma
    cpi  temp, 60							// Verifica el limite
    brlo Guardar_Up_AM						// Si es valido, guarda
    clr  temp								// Si llego a 60, reinicia a 0
Guardar_Up_AM:
    sts  alarma_minutos, temp				// Guarda los minutos de alarma actualizados en RAM
    ret

Accion_Down_D2:
    cpi  estado, 2							// Verifica modo configurar hora
    breq Down_Minutos						// Si es modo 2, decrementa minutos
    cpi  estado, 3							// Verifica modo configurar fecha
    breq Down_Mes							// Si es modo 3, decrementa mes
    cpi  estado, 4							// Verifica modo configurar alarma
    breq Down_Alarma_Min					// Si es modo 4, decrementa minutos de alarma
    ret										// En otro estado, no hace nada

Down_Minutos:
    lds  temp, minutos						// Carga los minutos actuales
    dec  temp								// Decrementa los minutos
    cpi  temp, 0xFF							// Verifica underflow
    brne Guardar_Down_Min					// Si no hay underflow, guarda directamente
    ldi  temp, 59							// Si hay underflow, ajusta a 59 (ciclo circular)
Guardar_Down_Min:
    sts  minutos, temp						// Guarda los minutos actualizados en RAM
    ret

Down_Mes:
    lds  temp, mes							// Carga el mes actual
    dec  temp								// Decrementa el mes
    cpi  temp, 0							// Verifica si llego a 0 (invalido)
    brne Guardar_Down_Mes					// Si no, guarda directamente
    ldi  temp, 12							// Si llego a 0, ajusta a diciembre (mes 12)
Guardar_Down_Mes:
    sts  mes, temp							// Guarda el mes actualizado en RAM
    ret

Down_Alarma_Min:
    lds  temp, alarma_minutos				// Carga los minutos de alarma actuales
    dec  temp								// Decrementa los minutos de alarma
    cpi  temp, 0xFF							// Verifica underflow
    brne Guardar_Down_AM					// Si no hay underflow, guarda
    ldi  temp, 59							// Si hay underflow, ajusta a 59
Guardar_Down_AM:
    sts  alarma_minutos, temp				// Guarda los minutos de alarma actualizados en RAM
    ret

// Dias del mes (para determinar en la configuración de la fecha)
Dias_Del_Mes:
    cpi  r21, 2								// Verifica si el mes es febrero (mes 2)
    breq DDM_Feb							// Si es febrero, salta a ese caso
    cpi  r21, 4								// Verifica si es abril
    breq DDM_30								// Abril tiene 30 dias
    cpi  r21, 6								// Verifica si es junio
    breq DDM_30								// Junio tiene 30 dias
    cpi  r21, 9								// Verifica si es septiembre
    breq DDM_30								// Septiembre tiene 30 dias
    cpi  r21, 11							// Verifica si es noviembre
    breq DDM_30								// Noviembre tiene 30 dias
    ldi  r22, 32             				// Todos los demas meses tienen 31 dias 
    ret

DDM_Feb:
    ldi  r22, 29							// Febrero tiene 28 dias 
    ret

DDM_30:
    ldi  r22, 31							// Meses de 30 días 
    ret