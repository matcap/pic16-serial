#include <p16f887.inc>
    LIST p=16f887
; *** Configurazione microcontrollore ***
    __CONFIG _CONFIG1, _INTRC_OSC_NOCLKOUT & _WDT_OFF

RES_VECT    CODE    0x0000            ; processor reset vector
    GOTO START                   ; go to beginning of program
  
INT_VECT    CODE    0x0004
    GOTO IRQ
    
; *** Definizione variabili in memoria condivisa ***
    UDATA_SHR

MAIN_PROG CODE                      ; let linker place main program

IRQ
 retfie

START
; setup EUSART 
    BANKSEL TXSTA
    bcf TXSTA,SYNC		;utilizza l'EUSART in modalità asincrona
    bsf TXSTA,BRGH		;BRGH 1 per avere un baudrate a 9600
    BANKSEL BAUDCTL
    bcf	BAUDCTL,BRG16		;BRG16 0 per avere un baudrate a 9600
    movlw D'25'			;scrive 25 in decimale nel registro W
    BANKSEL SPBRG
    movwf SPBRG			;sposta il valore di W(25) nel registro SPBRG per impostare il baudrate a 9600
    BANKSEL RCSTA
    bsf RCSTA,CREN		;abilita il circuito di ricezione
    bsf RCSTA,SPEN		;abilita la periferica

; abilita interrupt alla ricezione di dati
    BANKSEL PIE1
    bsf PIE1,RCIE		;abilita l'interrupt in ricezione
    BANKSEL INTCON
    bsf INTCON,PEIE		;abilita l'interrupt della periferica
    bsf INTCON,GIE		;abilita gli interrupt generali
    
sleep_pnt   SLEEP		;punto di sleep
    
    BTFSS PIR1,RCIF		;controlla se c'è qualcosa da leggere in seriale
	goto sleep_pnt
    ;INSERIRE QUI IN MEZZO LE OPERAZIONI DA FARE QUANDO SI RISVEGLIA DALLO SLEEP
   
    goto sleep_pnt
    END