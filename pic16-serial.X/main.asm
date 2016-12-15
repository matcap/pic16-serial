#include <p16f887.inc>
    LIST p=16f887

RES_VECT CODE 0x0000		; processor reset vector
    GOTO START			; go to beginning of program
  
INT_VECT CODE 0x0004
    GOTO IRQ
    
; Definizione variabili in memoria condivisa
USER_VARIABLES	UDATA_SHR
ReadChar    RES	1
Temp	    RES	1
Counter	    RES 1
	    
MAIN_PROG CODE
 
IRQ
    ;Gestione interrupt da timer2
    banksel PIR1
    btfss PIR1, TMR2IF
    retfie
    
    banksel PORTC
    comf PORTC, 1
    banksel PIR1
    bcf PIR1, TMR2IF
    retfie
    
;Setup I/O e EUSART
    global setup
setup
    ;Imposta oscillatore interno a Fosc = 8 MHz
    banksel OSCCON
    movlw 0x75
    movwf OSCCON
    banksel OSCTUNE
    clrf OSCTUNE
    
    ;Imposta led D1,D2,D3,D4 come output
    banksel PORTD
    movlw 0x00
    movwf PORTD
    banksel TRISD
    movlw 0x00
    movwf TRISD
    
    ;Imposta pin buzzer come output
    banksel TRISC
    bcf TRISC, RC2
    
    ;Setup Timer2
    banksel T2CON
    movlw 0x02			;1/16 prescaler
    movwf T2CON
    banksel TMR2
    clrf TMR2			;azzera contatore
    banksel PR2
    movlw D'142'
    movwf PR2			;compara contatore con 142
    banksel PIE1
    bsf PIE1, TMR2IE		;abilita interrupt 
    
    ;Setup EUSART
    banksel TRISC
    bcf TRISC, RC6		;Set TX pin come output
    bsf TRISC, RC7		;Set RX pin come input
    
    banksel TXSTA
    bcf TXSTA,SYNC		;utilizza EUSART in modalità asincrona
    bsf TXSTA,BRGH		;high baudrate
    banksel BAUDCTL
    bcf	BAUDCTL,BRG16		;registro baudrate a 8 bit
    banksel SPBRG
    movlw D'51'			;Il valore di SPBRG è calcolato tramite la formula
    movwf SPBRG			;SPBRG = Fosc/(16*baud) - 1
    
    banksel RCSTA
    bsf RCSTA,CREN		;abilita il circuito di ricezione
    bsf RCSTA,SPEN		;abilita la periferica
    
    banksel INTCON
    bsf INTCON,PEIE		;abilita l'interrupt da periferica
    bsf INTCON,GIE		;abilita gli interrupt generali
    
    return
    
    
    
    
    
;Determina se il carattere in ReadChar è compreso tra ['0','9']
;ritorna ReadChar = 0xFF se falso, ReadChar = (ASCII -> num) se vero
    global is_digit
is_digit
    movlw 0x29			;0x30 is '0' in ASCII
    clrf Temp			
    subwf ReadChar, 0
    rlf Temp, 1			;memorizza il precedente carry
    btfss Temp, 0		;se il carry è 1, il numero è >= '0'
    goto not_a_digit
    
    movlw 0x40			;0x39 is '9' in ASCII
    clrf Temp
    subwf ReadChar, 0		
    rlf Temp, 1			;memorizza il precedente carry
    btfsc Temp, 0		;se il carry è 0, il numero è > '9'
    goto not_a_digit

    movlw 0x30
    subwf ReadChar, 1		;sottrae '0' per ottenere la cifra intera
    return
    
not_a_digit
    movlw 0xFF
    movwf ReadChar
    return


    
;Genera un ritardo di tanti millisecondi quanto è il valore
;di W al momento della chiamata. Funziona correttamente per Fosc 
;pari a 8 Mhz
    global delay_ms
delay_ms
    movwf Temp			
loop
    decfsz Temp, 1
    goto inner_loop_init
    return
inner_loop_init
    movlw 0xC8			    ;200
    movwf Counter
inner_loop
    decfsz Counter, 1
    goto nops
    goto loop
nops
    nop
    nop
    nop
    nop
    nop
    nop
    goto inner_loop
    
    
;Ciclo principale infinito
    global main_loop
main_loop
    banksel PIR1
    btfss PIR1, RCIF		;Controlla se il buffer in lettura è pieno
    goto main_loop		;Ritorna al main_loop se il buffer è vuoto
    
    banksel RCREG
    movf RCREG, 0		;Lettura EUSART rx buffer
    movwf ReadChar		;Copia in ReadChar
    
    call is_digit		;Traduzione da ASCII a numero intero
    
    btfsc ReadChar, 7		;Continua se ReadChar è un numero tra [0,9]
    goto main_loop
    
    banksel PORTD
    movfw ReadChar
    movwf PORTD			;Mostra il numero sui led D1,D2,D3,D4
    
    banksel RCSTA
    bcf RCSTA,CREN		;disablita ricezione EUSART
    
    
    banksel T2CON
    incf ReadChar, 1		;Incrementa per compensare decfsz
beep_loop
    decfsz ReadChar, 1
    goto beep_loop_begin
    goto beep_loop_end
    
beep_loop_begin
    bsf T2CON, TMR2ON		;abilita il timer
    
    ; Delay di un quarto secondo
    movlw 0xFA
    call delay_ms
    
    bcf T2CON, TMR2ON		;disabilita il timer
    
    ; Delay di un quarto secondo
    movlw 0xFA
    call delay_ms
    
    goto beep_loop	    
    
beep_loop_end
    banksel RCSTA
    bsf RCSTA,CREN		;riablita ricezione EUSART
    
    goto main_loop	    
    return
    
    
 
    
; Starting point
START
    call setup
    call main_loop
    END