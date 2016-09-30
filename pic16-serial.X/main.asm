#include <p16f887.inc>
    LIST p=16f887
    
; Configurazione microcontrollore
    __CONFIG _CONFIG1, _INTRC_OSC_NOCLKOUT & _WDT_OFF

RES_VECT CODE 0x0000		; processor reset vector
    GOTO START			; go to beginning of program
  
INT_VECT CODE 0x0004
    GOTO IRQ
    
; Definizione variabili in memoria condivisa
    UDATA_SHR

MAIN_PROG CODE			; let linker place main program

IRQ
    BANKSEL RCREG
    movf RCREG, 0		; Read EUSART rx buffer
    andlw 0x0F			; Map ASCII to 0-9
    BANKSEL PORTD
    movwf PORTD
    retfie

START
    ; Test LEDS
    BANKSEL PORTD
    movlw 0x01
    movwf PORTD
    BANKSEL TRISD
    movlw 0x00
    movwf TRISD
    
    ; Setup EUSART
    BANKSEL TRISC
    bcf TRISC, RC6		;Set TX pin come output
    bsf TRISC, RC7		;Set RX pin come input
    
    BANKSEL TXSTA
    bcf TXSTA,SYNC		;utilizza l'EUSART in modalità asincrona
    bsf TXSTA,BRGH		;high-baudrate
    BANKSEL BAUDCTL
    bcf	BAUDCTL,BRG16		;BRG16 0 per avere un baudrate a 9600
    movlw D'25'			;scrive 25 in decimale nel registro W
    BANKSEL SPBRG
    movwf SPBRG			;sposta il valore di W(25) nel registro SPBRG per impostare il baudrate a 9600

    ; Abilita interrupt alla ricezione di dati
    BANKSEL PIE1
    bsf PIE1,RCIE		;abilita l'interrupt in ricezione
    BANKSEL INTCON
    bsf INTCON,PEIE		;abilita l'interrupt della periferica
    bsf INTCON,GIE		;abilita gli interrupt generali

    ; Avvia periferica EUSART
    BANKSEL RCSTA
    bsf RCSTA,CREN		;abilita il circuito di ricezione
    bsf RCSTA,SPEN		;abilita la periferica
    
main_loop
    ;sleep			;punto di sleep
    BANKSEL PIR1
    btfss PIR1, RCIF		;controlla se c'è qualcosa da leggere in seriale
    goto main_loop		;ritorna al main_loop se il buffer è vuoto

    
    goto main_loop	    
    END