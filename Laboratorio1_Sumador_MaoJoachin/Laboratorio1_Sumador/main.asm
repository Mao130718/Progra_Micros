/*
* Laboratorio1_Sumador.asm
*
* Creado: 7/02/2026 18:26:01
* Autor : María Olga Joachín
* Descripción: Sumador con LEDs y botnes 
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)

// Definición de los pines para los botones utilizando el Puerto D (D2 a D6)
.equ BOTON_INCREMENTO1 = PD2
.equ BOTON_DECREMENTO1 = PD3
.equ BOTON_INCREMENTO2 = PD4
.equ BOTON_DECREMENTO2 = PD5
.equ BOTON_SUMA = PD6

// Definición de los pines para los LEDs del primer contador utilizando el Puerto B (D8 a D11)
.equ LED_BIT0 = PB0
.equ LED_BIT1 = PB1
.equ LED_BIT2 = PB2
.equ LED_BIT3 = PB3

// Definición de los pines para los LEDs del segundo contador utilizando el Puerto C (A0 a A3)
.equ LED2_BIT0 = PC0
.equ LED2_BIT1 = PC1
.equ LED2_BIT2 = PC2
.equ LED2_BIT3 = PC3

// Definición de los pines para los LEDs del resultado de la suma utlizando de nuevo los puertos B y C restante (D12 y D13, como A4 y A5)
.equ LED_SUMA0 = PB4
.equ LED_SUMA1 = PB5
.equ LED_SUMA2 = PC4
.equ LED_SUMA3 = PC5

// Definición del LED que representara un carry/ overflow
.equ LED_OVERFLOW = PD7

// Definición de los registros para su funcionamiento en el sumador
// variables para el antirrebote
.def TEMPORAL = R16							// Variable para el registro de las operaciones temporales
.def CONTADOR = R17							// Utilizando un contador para los delays del antirebote
.def ESTADO_BOTON = R18						// Lectura de los estados de los botones

// Variables para definir los contadores
.def CONTADOR_BINARIO1 = R19				// Muestra el valor actual del primer contador
.def CONTADOR_BINARIO2 = R20				// Muestra el valor actual del segundo contador 

// Variables para indicar el estado de cada uno de los botones
// Se muestran los estados de los botones que incrementan y decrementan del primer contador y para el segundo
.def ESTADO_BOTON_INCREMENTO1 = R21
.def ESTADO_BOTON_DECREMENTO1 = R22
.def ESTADO_BOTON_INCREMENTO2 = R23
.def ESTADO_BOTON_DECREMENTO2 = R24
.def ESTADO_BOTON_SUMA = R25

// Variables para los resultados del carry/ overflow
.def RESULTADO_SUMA = R10					// Almacena la informacion de la suma de ambos contadores
.def FLAG_OVERFLOW = R11					// Se presenta 1 si hay overflow y 0 si no   

.cseg
.org 0x0000
	JMP SETUP
 /****************************************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16
/****************************************/
// Configuracion MCU
SETUP:
    // Configuración del clock a 1MHz
	LDI TEMPORAL, 0x80						// Se carga el valor 0x80 en la variable temporal para habilitar el cambio del prescaler
    STS CLKPR, TEMPORAL						// Se escribe en el registro Clock Prescaler Register la variable guardada en temporal
    LDI TEMPORAL, 0x03						// Carga el valor 0x03 (en prescaler representa 8)
    STS CLKPR, TEMPORAL						// Se escribe en el prescaler que 8MHz luego del prescaler de 8 sería al final 1MHz

	// Configuración de los botones como entrada pull-up
	CBI DDRD, BOTON_INCREMENTO1				// CBI hace que el bit PD2 de DDRD en 0, osea la coloca como entrada
    SBI PORTD, BOTON_INCREMENTO1			// Pone el bit (Set Bit) en 1 (activa el pull-up con logica inversa)

    CBI DDRD, BOTON_DECREMENTO1				// Se coloca PD3 como entrada
    SBI PORTD, BOTON_DECREMENTO1			// Se activa el pull-up

    CBI DDRD, BOTON_INCREMENTO2				// Se coloca PD4 como entrada
    SBI PORTD, BOTON_INCREMENTO2			// Se activa el pull-up

    CBI DDRD, BOTON_DECREMENTO2				// Se coloca el PD5 como entrada
    SBI PORTD, BOTON_DECREMENTO2			// Se activa el pull-up

    CBI DDRD, BOTON_SUMA					// Se coloca PD6 como entrada
    SBI PORTD, BOTON_SUMA					// Se activa el pull-up

	// Configración de los LEDs como salida
	// Los LEDs del primer contador se coloca en DDRB en 1 (salida)
	SBI DDRB, LED_BIT0
    SBI DDRB, LED_BIT1
    SBI DDRB, LED_BIT2
    SBI DDRB, LED_BIT3

	// Los LEDs del segundo contador también se colocan como salida en DDRC
    SBI DDRC, LED2_BIT0
    SBI DDRC, LED2_BIT1
    SBI DDRC, LED2_BIT2
    SBI DDRC, LED2_BIT3

	// Los LEDs para mostrar la suma de ambos contadores se colocan como salida
    SBI DDRB, LED_SUMA0
    SBI DDRB, LED_SUMA1
    SBI DDRC, LED_SUMA2
    SBI DDRC, LED_SUMA3

	// LED del overflow
    SBI DDRD, LED_OVERFLOW

// Inicialización de las variables (se usa la instrucción de MOV para que al cargar en temporal sea mas fácil asignarselos a los demas registros
	LDI TEMPORAL, 0							// Se carga el valor 0 a la variable temporal para empezar el contador en 0
    MOV CONTADOR_BINARIO1, TEMPORAL			// El primer contador debe iniciar en 0
    MOV CONTADOR_BINARIO2, TEMPORAL			// El segundo contador debe iniciar en 0
    MOV RESULTADO_SUMA, TEMPORAL			// Al igual que los contadores, la suma debe empezar desde 0
    MOV FLAG_OVERFLOW, TEMPORAL				// El overflow también debe de comenzar en 0

	LDI TEMPORAL, 1							// Se le carga el valor de 1 a a variable de Temporal asi es más fácil colocarselos a los demás registros
// Todos los botones comienzan en 1 representando que estan "presionados" utilizando la lógica inversa
    MOV ESTADO_BOTON_INCREMENTO1, TEMPORAL	
    MOV ESTADO_BOTON_DECREMENTO1, TEMPORAL	
    MOV ESTADO_BOTON_INCREMENTO2, TEMPORAL	
    MOV ESTADO_BOTON_DECREMENTO2, TEMPORAL	
    MOV ESTADO_BOTON_SUMA, TEMPORAL		

	// Inicialización de los LEDs para la suma entonces se colocan 0 al igual que el led para el overflow
	CBI PORTB, LED_SUMA0					// Se usa un CBI para colocar en PB4 en 0
    CBI PORTB, LED_SUMA1					
    CBI PORTC, LED_SUMA2					
    CBI PORTC, LED_SUMA3					
    CBI PORTD, LED_OVERFLOW					
    
    IN TEMPORAL, PORTB						// Para leer el estado actual del PORTB 
    ANDI TEMPORAL, 0b11110000				// Se utiliza un ANDI para mantener los bits de 4 a 7 mientras de limpian los bits de 0 a 3
    OUT PORTB, TEMPORAL						// Se escribe de nuevo al PORTB los LEDs apagados
    
    IN TEMPORAL, PORTC						// Para leer el estado del PORTC 
    ANDI TEMPORAL, 0b11110000				// Se limpian los bits de 0 a 3
    OUT PORTC, TEMPORAL						// Se escribe el nuevo PORTC como LEDs apagados 

/****************************************/
// Loop Infinito
MAIN_LOOP:
	// Botón de incremento 1
	SBIS PIND, BOTON_INCREMENTO1			// Se skipea el bit si PD2 esta en High (osea que no esta presionado)
    JMP CHECK_INC1							// Si esta en Low (osea que si esta presionado se verifica ewn la subrutina
    LDI TEMPORAL, 1							// Se salta a esta instrucción si no esta presionado por lo que se carga el valor de 1
    MOV ESTADO_BOTON_INCREMENTO1, TEMPORAL	// Se marca la variable como si estuviera libre 
    JMP CHECK_DEC1							// Se salta a otra subrutina para verificar el siguiente boton

CHECK_INC1:
    LDI CONTADOR, 50						// Para comenzar el antirebote se carga el valor de 50 al contador 
DELAY_INC1:
    DEC CONTADOR							// Se decrementa el contador de 50 para abajo
    BRNE DELAY_INC1							// Se realiza un Branch if not equal para que revise a cada rato si el contadro no es 0 para que vualva a repetir el delay
    SBIS PIND, BOTON_INCREMENTO1			// Luego del delay se verifica si el boton aun sigue presionado por lo que se hace un SBIS para verificar esta función
    JMP EXEC_INC1							// Si aun esta presionado se ejecuta el incremento
    JMP CHECK_DEC1							// Si no esta presionado, se presencia un rebote e ignora la tarea

EXEC_INC1:
    LDI TEMPORAL, 1							// Se carga el valor de 1
    CP ESTADO_BOTON_INCREMENTO1, TEMPORAL	// Se hace una comparación del estado con el valor de 1
    BREQ EXEC_INC1_CONTINUAR				// Se realiza un Brach if equal si es 1 osea si hay una nueva pulsación
    JMP CHECK_DEC1							// Si no hay una nueva pulsación se ignora (osea el boton ya estaba presionado)

EXEC_INC1_CONTINUAR:
    LDI TEMPORAL, 0							// Se carga el valor de 0
    MOV ESTADO_BOTON_INCREMENTO1, TEMPORAL	// Se marca como si el boton estuviera presionado
 
// Incrementación del primer contador 
    INC CONTADOR_BINARIO1					// Se hace un incremento al contador
    LDI TEMPORAL, 16						// Se carga el valor a 16 para verificar si ya llego a ese numero (limite)
    CP CONTADOR_BINARIO1, TEMPORAL			// Comparamos el estado del contador con la variable temporal
    BRLO UPDATE_LED1						// Se usa un Branch if Lower si el contador es menor a 16, se actualizan los LEDs en otra subrutina
    LDI TEMPORAL, 0							// Se carga el valor de 0
    MOV CONTADOR_BINARIO1, TEMPORAL			// El contador equivaldría a 0

UPDATE_LED1:
// Se desea actualizar los LEDs del primer contador para que se mantengan encendidos o apagados todo el tiempo
    IN TEMPORAL, PORTB						// Se lee el estado actual del PORTB
    ANDI TEMPORAL, 0b11110000				// Se limpian los bits del 0 al 3 en donde se encuentran los LEDs del contador
    MOV ESTADO_BOTON, CONTADOR_BINARIO1		// Se copian los valores del contador
    ANDI ESTADO_BOTON, 0b00001111			// Se debe asegurar que solo existan 4 bits
    OR TEMPORAL, ESTADO_BOTON				// Se combinan los bits para colocar el contador
    OUT PORTB, TEMPORAL						// Se escribe el resultado en PORTB y luyego se debería de mostrar el resultado el los LEDs 

// Decrementación del primer contador
	CHECK_DEC1:
    SBIS PIND, BOTON_DECREMENTO1			// Verificación de si el boton para decrementar esta siendo presionado
    JMP CHECK_DEC1_PRESSED					// Se salta a la subrutina para verificar la tarea
    LDI TEMPORAL, 1							// Si no esta presionado se marca como libre (queda en la variable 1)
    MOV ESTADO_BOTON_DECREMENTO1, TEMPORAL	 
    JMP CHECK_INC2							// Se traslada al siguiente botón

CHECK_DEC1_PRESSED:
    LDI CONTADOR, 50						// Se carga el valor de 50 igual que para el boton de incrementar pero ahora para decrementar
DELAY_DEC1:									 
    DEC CONTADOR							
    BRNE DELAY_DEC1							// Se salta a la rutina del antirebote por si se hace un decremento
    										 
    SBIS PIND, BOTON_DECREMENTO1			
    JMP EXEC_DEC1							 
    JMP CHECK_INC2							

EXEC_DEC1:
    LDI TEMPORAL, 1
    CP ESTADO_BOTON_DECREMENTO1, TEMPORAL	// Se le carga una comparación de 1 al boton de decremento
    BREQ EXEC_DEC1_CONTINUAR				// Se usa un Brach y equal para verificar si el valor no es 0 por el decremento
    JMP CHECK_INC2							// Se salta a la subrutina para revisar si se realizp un decremento

EXEC_DEC1_CONTINUAR:
    LDI TEMPORAL, 0							
    MOV ESTADO_BOTON_DECREMENTO1, TEMPORAL	
    
    DEC CONTADOR_BINARIO1					// Se realiza un decremento en el contador desde 5 para abajo
    LDI TEMPORAL, 255						// Para verifricar overflow se carga el valor de 255 para colocarlo como límite
    CP CONTADOR_BINARIO1, TEMPORAL			// Se compara el valor a 255
    BRNE UPDATE_LED1_DEC					// Si no es igual a 255 se actualiza la LED
    LDI TEMPORAL, 15						// Si llego a 255 se debe poner en 15 para decrementar
    MOV CONTADOR_BINARIO1, TEMPORAL			

UPDATE_LED1_DEC:							// Se realiza un actualización de los LEDs como se realizo para el incremento
    IN TEMPORAL, PORTB
    ANDI TEMPORAL, 0b11110000
    MOV ESTADO_BOTON, CONTADOR_BINARIO1
    ANDI ESTADO_BOTON, 0b00001111
    OR TEMPORAL, ESTADO_BOTON
    OUT PORTB, TEMPORAL

// Incrementáción del segundo contador, se presenta la misma logica del primer contador 
// pero ahora configurado para el contador 2 en el PORTC
	CHECK_INC2:
    SBIS PIND, BOTON_INCREMENTO2
    JMP CHECK_INC2_PRESSED
    LDI TEMPORAL, 1
    MOV ESTADO_BOTON_INCREMENTO2, TEMPORAL
    JMP CHECK_DEC2

CHECK_INC2_PRESSED:
    LDI CONTADOR, 50
DELAY_INC2:
    DEC CONTADOR
    BRNE DELAY_INC2
    
    SBIS PIND, BOTON_INCREMENTO2
    JMP EXEC_INC2
    JMP CHECK_DEC2

EXEC_INC2:
    LDI TEMPORAL, 1
    CP ESTADO_BOTON_INCREMENTO2, TEMPORAL
    BREQ EXEC_INC2_CONTINUAR
    JMP CHECK_DEC2
EXEC_INC2_CONTINUAR:
    LDI TEMPORAL, 0
    MOV ESTADO_BOTON_INCREMENTO2, TEMPORAL
    
    INC CONTADOR_BINARIO2
    LDI TEMPORAL, 16
    CP CONTADOR_BINARIO2, TEMPORAL
    BRLO UPDATE_LED2
    LDI TEMPORAL, 0
    MOV CONTADOR_BINARIO2, TEMPORAL

UPDATE_LED2:
    IN TEMPORAL, PORTC								// Se lee el PORTC
    ANDI TEMPORAL, 0b11110000						// Se limpian los datos de los bits de 0 a 3
    MOV ESTADO_BOTON, CONTADOR_BINARIO2				
    ANDI ESTADO_BOTON, 0b00001111					
    OR TEMPORAL, ESTADO_BOTON						 
    OUT PORTC, TEMPORAL								// Se escribe el valor en el PORTC y se ve reflejado luego en los LEDs

// Decremento del segundo contador, miama logica que el primer contador pero ahora en PORTC
	CHECK_DEC2:
    SBIS PIND, BOTON_DECREMENTO2
    JMP CHECK_DEC2_PRESSED
    LDI TEMPORAL, 1
    MOV ESTADO_BOTON_DECREMENTO2, TEMPORAL
    JMP CHECK_SUMA_BTN

CHECK_DEC2_PRESSED:
    LDI CONTADOR, 50

DELAY_DEC2:
    DEC CONTADOR
    BRNE DELAY_DEC2
    
    SBIS PIND, BOTON_DECREMENTO2
    JMP EXEC_DEC2
    JMP CHECK_SUMA_BTN

EXEC_DEC2:
    LDI TEMPORAL, 1
    CP ESTADO_BOTON_DECREMENTO2, TEMPORAL
    BREQ EXEC_DEC2_CONTINUAR
    JMP CHECK_SUMA_BTN

EXEC_DEC2_CONTINUAR:
    LDI TEMPORAL, 0
    MOV ESTADO_BOTON_DECREMENTO2, TEMPORAL
    
    DEC CONTADOR_BINARIO2
    LDI TEMPORAL, 255
    CP CONTADOR_BINARIO2, TEMPORAL
    BRNE UPDATE_LED2_DEC
    LDI TEMPORAL, 15
    MOV CONTADOR_BINARIO2, TEMPORAL

UPDATE_LED2_DEC:
    IN TEMPORAL, PORTC
    ANDI TEMPORAL, 0b11110000
    MOV ESTADO_BOTON, CONTADOR_BINARIO2
    ANDI ESTADO_BOTON, 0b00001111
    OR TEMPORAL, ESTADO_BOTON
    OUT PORTC, TEMPORAL

// Botón de suma
CHECK_SUMA_BTN:
    SBIS PIND, BOTON_SUMA						// Se verifica si el boton de suma esta presionado o no
    JMP CHECK_SUMA_PRESSED
    LDI TEMPORAL, 1
    MOV ESTADO_BOTON_SUMA, TEMPORAL
    JMP MAIN_LOOP

CHECK_SUMA_PRESSED:
    LDI CONTADOR, 50

DELAY_SUMA:
    DEC CONTADOR
    BRNE DELAY_SUMA
    
    SBIS PIND, BOTON_SUMA
    JMP EXEC_SUMA
    JMP MAIN_LOOP

EXEC_SUMA:
    LDI TEMPORAL, 1
    CP ESTADO_BOTON_SUMA, TEMPORAL
    BREQ EXEC_SUMA_CONTINUAR
    JMP MAIN_LOOP
EXEC_SUMA_CONTINUAR:
    LDI TEMPORAL, 0
    MOV ESTADO_BOTON_SUMA, TEMPORAL

// Calcular suma de ambos contadores 
	MOV RESULTADO_SUMA, CONTADOR_BINARIO1				// Se mueve el resultado del contador 1...
    ADD RESULTADO_SUMA, CONTADOR_BINARIO2				// Para después sumarlo con un ADD con el segundo contador
    
    LDI TEMPORAL, 16									// Se carga el valor de 16 ya que este va a ser nuestro limite
    CP RESULTADO_SUMA, TEMPORAL							// Se compara la suma con este valor
    BRLO NO_OVERFLOW									// Se realiza un Branch if Lower si la suma es menor a 16 representando que no es un overflow

// ¿Hay un overflow?
	LDI TEMPORAL, 1
    MOV FLAG_OVERFLOW, TEMPORAL							// Si el flag es igual a 1 es porque esta ocurriendo un overflow
    LDI TEMPORAL, 16
    SUB RESULTADO_SUMA, TEMPORAL						// Se realiza una resta por si hay un overflow (se va a mostrar el residuo de la resta en los bits de la suma)
    JMP MOSTRAR_RESULTADO								

NO_OVERFLOW:
    LDI TEMPORAL, 0
    MOV FLAG_OVERFLOW, TEMPORAL

MOSTRAR_RESULTADO:
    // Actualización del LED bit 0 (PB4)
    SBRC RESULTADO_SUMA, 0								// Skip if bit is clear para que se salte si el bit 0 es igual a 0
    JMP SET_BIT0										// Si el bit 0 es igual a 1 se enciende la LED
    CBI PORTB, LED_SUMA0								// Si el bit 0 es igual a 0 se apaga la LED
    JMP CHECK_BIT1										 
SET_BIT0:
    SBI PORTB, LED_SUMA0								// La LED se enciende si el bit 0

// Actualización del LED bit 1 (PB5)
CHECK_BIT1:
    SBRC RESULTADO_SUMA, 1								// Verificar bit 1
    JMP SET_BIT1
    CBI PORTB, LED_SUMA1								// Apagar si el bit 1 es igual a 0
    JMP CHECK_BIT2

SET_BIT1:
    SBI PORTB, LED_SUMA1								// Se enciende la luz si el bit 1 es igual a 1

// Actualización del LED bit 2 (PC4)
CHECK_BIT2:
    SBRC RESULTADO_SUMA, 2								// Verificar el bit 2
    JMP SET_BIT2
    CBI PORTC, LED_SUMA2								// Apagar si el bit 2 es igual a 0
    JMP CHECK_BIT3

SET_BIT2:
    SBI PORTC, LED_SUMA2								// Se enciende la luz si el bit 2 es igual a 1

// Actualización del LED bit 3 (PC5)
CHECK_BIT3:
    SBRC RESULTADO_SUMA, 3								// Verificar el bit 3
    JMP SET_BIT3
    CBI PORTC, LED_SUMA3								// Apagar si el bit 3 es igual a 0
    JMP UPDATE_OVERFLOW

SET_BIT3:
    SBI PORTC, LED_SUMA3								// Se enciende la luz si el bit 3 es igual a 1

// Actualización del LED overflow
UPDATE_OVERFLOW:
    LDI TEMPORAL, 1
    CP FLAG_OVERFLOW, TEMPORAL							// Se verifica si la flag del overflow es 0
    BREQ SET_OVERFLOW									// Si es 1 se enciende el LED
    CBI PORTD, LED_OVERFLOW								// Si es 0 se apaga el LED de overflow
    JMP MAIN_LOOP										// Se vuleve a la rutina principal

SET_OVERFLOW:
    SBI PORTD, LED_OVERFLOW								// Se enciende la LED del overflow
    JMP MAIN_LOOP										// Vuelve a la rutina general

/****************************************/