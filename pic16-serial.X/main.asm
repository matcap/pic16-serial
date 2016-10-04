#include <p16f887.inc>
    LIST p=16f887
    
; Configurazione microcontrollore
    __CONFIG _CONFIG1, _INTRC_OSC_NOCLKOUT & _WDT_OFF

RES_VECT CODE 0x0000		; processor reset vector
    GOTO START			; go to beginning of program
  
INT_VECT CODE 0x0004
    GOTO IRQ
    
; Definizione variabili in memoria condivisa
USER_VARIABLES	UDATA_SHR
ReadChar    RES	1
Temp	    RES	1
	
MAIN_PROG CODE
 
IRQ
    retfie
    
    
;Setup I/O e EUSART
    global setup
setup
    ; Imposta led D1,D2,D3,D4 come output
    BANKSEL PORTD
    movlw 0x00
    movwf PORTD
    BANKSEL TRISD
    movlw 0x00
    movwf TRISD
   
    BANKSEL TRISC
    bcf TRISC, RC6		;Set TX pin come output
    bsf TRISC, RC7		;Set RX pin come input

    BANKSEL TXSTA
    bcf TXSTA,SYNC		;utilizza EUSART in modalità asincrona
    bsf TXSTA,BRGH		;high baudrate
    BANKSEL BAUDCTL
    bcf	BAUDCTL,BRG16		;registro baudrate a 8 bit
    movlw D'25'			;TODO: comment
    BANKSEL SPBRG
    movwf SPBRG			;TODO: comment
    
    ;BANKSEL PIE1
    ;bsf PIE1,RCIE		;abilita l'interrupt in ricezione
    BANKSEL INTCON
    bsf INTCON,PEIE		;abilita l'interrupt della periferica
    bsf INTCON,GIE		;abilita gli interrupt generali
    
    BANKSEL RCSTA
    bsf RCSTA,CREN		;abilita il circuito di ricezione
    bsf RCSTA,SPEN		;abilita la periferica
    retlw 0
    
    
;Determina se il carattere in ReadChar è compreso tra ['0','9']
;ritorna W = 0xFF se falso, W = (ASCII -> num) se vero
    global is_digit
is_digit
    movlw 0x29			;0x30 is '0' in ASCII
    clrf Temp			
    subwf ReadChar, 0
    rlf Temp, 1			;memorizza il precedente carry
    btfss Temp, 0		;se il carry è 1, il numero è >= '0'
    retlw 0xFF
    
    movlw 0x40			;0x39 is '9' in ASCII
    clrf Temp
    subwf ReadChar, 0		
    rlf Temp, 1			;memorizza il precedente carry
    btfsc Temp, 0		;se il carry è 0, il numero è > '9'
    retlw 0xFF
    
    movlw 0x30
    subwf ReadChar, 0		;sottrae '0' per ottenere la cifra intera
    return

;Ciclo principale infinito
    global main_loop
main_loop
    BANKSEL PIR1
    btfss PIR1, RCIF		;Controlla se il buffer in lettura è pieno
    goto main_loop		;Ritorna al main_loop se il buffer è vuoto
    
    BANKSEL RCREG
    movf RCREG, 0		;Lettura EUSART rx buffer
    movwf ReadChar		;Copia in ReadChar
    call is_digit		;Traduzione da ASCII a numero intero
    
    BANKSEL PORTD
    movwf PORTD			;Mostra il numero sui led D1,D2,D3,D4
    
    
    
    goto main_loop	    
    retlw 0
    
    
    
; Starting point
START
    call setup
    call main_loop
    END