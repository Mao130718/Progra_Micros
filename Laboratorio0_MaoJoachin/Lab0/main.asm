;
; Laboratorio_0.asm
;
; Created: 25/01/2026 22:13:09
; Author : MariaOlgaJoachin
;

.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.org 0x00
rjmp START


START: 
	LDI R16, LOW(RAMEND)
	OUT SPL, R16
	LDI R16, HIGH(RAMEND)
	OUT SPH, R16

	LDI R16, 0b00000001 //Se carga 1 al bit 0
	OUT DDRB, R16 //Se expresa el registro 16 

LOOP: 
	LDI R16, 0b00000001 //Se carga 1 al bit 0
	OUT PORTB, R16 //Se expresa el registro 16 en el PORTB con la ayuda de la instruccion DDRB
	RCALL DELAY_3S // Se mantiene encendido por tres segundos

	LDI R16, 0b00000000 //Se manda la instruccion para apagar la led
	OUT PORTB, R16 //Se apaga la led
	RCALL DELAY_3S //Se mantiene apagado por 3 segundos

	RJMP LOOP


DELAY_3S:
    LDI R18, 10  //Contador externo     
DELAY_1: 
    LDI R17, 255  // Contador medio    
DELAY_2: 
    LDI R16, 255  // Contador interno     
DELAY_3:
    DEC R16
    BRNE DELAY_3
    DEC R17
    BRNE DELAY_2
    DEC R18
    BRNE DELAY_1
    RET