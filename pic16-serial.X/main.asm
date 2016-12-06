
    
;	    DESCRIZIONE
; Si realizzi un  firmware che riceve un carattere da porta seriale (EUSART) 
; corrispondente ad una cifra da 0 a 9, 
; quindi emette un suono con il buzzer 
; della durata di n secondi (n = valore ricevuto). 
; Se il carattere ricevuto non è nel range '1'..'9', 
; il carattere deve essere ignorato.
 
#include <p16f887.inc>
#include <macro.inc>
    LIST p=16f887
; *** Configurazione microcontrollore ***
    ;clock interno, watchdog e low voltage programming disabilitati
    __CONFIG _CONFIG1, _INTRC_OSC_NOCLKOUT & _WDT_OFF & _LVP_OFF
    ;brown out reset impostato a 2.1v
    __CONFIG _CONFIG2, _BOR21V

res_vect    CODE    0x0000	    ;vettore di reset
    pagesel start
    GOTO start			    ;inizia il programma
  
t_vect    CODE    0x0004	    ;vettore di interrupt
    pagesel irq
    GOTO irq			    ;vai alla ruoutine
    
; *** Definizione variabili in memoria condivisa ***
    UDATA_SHR
secondi	RES 1			    ;secondi in cui il buzzer deve suonare
    
main_prog CODE                      ; let linker place main program

irq
    retfie

start
    ; configura clock
    setRegK OSCCON, B'01110001' ;oscillatore interno a 8 MHz
    call initHw
    
loop
    banksel PORTD
    bcf PORTD,0			;spengo il led 0
    banksel PIR1
    btfss PIR1,RCIF
	goto $-1		;gira finche non c'è un carattere in seriale
    banksel PORTD
    bsf PORTD,0			;accendo il led 0
    banksel RCREG
    movf RCREG,w		;sposto il carattere letto da seriale su W
    movwf secondi		;salvo W in memoria
    
    ;controlla se il carattere è maggiore di '0'
    movlw '0'
    subwf secondi,1
    btfss STATUS,Z
    btfss STATUS,C
	goto loop		;ignora se char era minore di '0'
    
    ;controlla se il carattere è minore o uguale di '9'
    movlw .10
    subwf secondi,w
    btfss STATUS,Z
    btfsc STATUS,C
	goto loop		;ingora se char è maggiore di 9
	
    ;gira e suona finche ci sono secondi da scalare
suono call beep1s
    decfsz secondi,1		
	goto suono
    
    goto loop

    
initHw
    ; setup EUSART 
    banksel TXSTA
    bcf TXSTA,SYNC		;utilizza l'EUSART in modalità asincrona
    bsf TXSTA,BRGH		;BRGH 1 per avere un baudrate a 19200
    banksel BAUDCTL
    bcf	BAUDCTL,BRG16		;BRG16 0 per avere un baudrate a 19200
    movlw D'25'			;scrive 25 in decimale nel registro W
    banksel SPBRG
    movwf SPBRG			;sposta il valore di W(25) nel registro SPBRG per impostare il baudrate a 19200
    banksel RCSTA
    bsf RCSTA,CREN		;abilita il circuito di ricezione
    bsf RCSTA,SPEN		;abilita la periferica
    
    ; inzializzazione dei timer e della PWM

    ;timer1:
    ; quarzo esterno (32768 Hz), prescaler = 1
    ;  -> freq = 32768 Hz, tick ~= 30.518 us, max period = 2 s
    setRegK T1CON, B'00001011'
    

    ; timer2 e CCP1: PWM a 800 Hz (T = 1250 us) per buzzer
    ;  tmr2 prescaler = 16
    ;   -> freq. = 125 kHz, tick = 8 us, max period = 2048 us
    setRegK T2CON, B'00000011'    ; TMR2ON = 0 (PWM disabilitata)
    setRegK PR2, .156             ; T = 1250 us
    setRegK CCPR1L, .78           ; duty cycle = 50%
    setRegK CCP1CON, B'00001100'  ; PWM mode

    ;port C:
    ; RC2: digital output for buzzer
    banksel TRISC
    bcf TRISC,2
		
    ;port D:
    ; RD0-RD3: usati come output (LEDs)
    setRegK TRISD, 0xF0
    setReg0 PORTD
    return
    
delay
    ; Ritardo tramite timer1
    ; input:
    ;   W = valore iniziale per TMR1H (TMR1L viene posto = 0)
    ;
    ; Utilizzo del timer in polling
    banksel TMR1H
    clrf TMR1L           ; TMR1L = 0
    movwf TMR1H          ; TMR1H = W
    banksel PIR1
    bcf PIR1,TMR1IF      ; azzeramento flag di overflow

    btfss PIR1,TMR1IF    ; se overflow del timer -> salta goto
	goto $-1      ; ripetizione loop di attesa
    return
    
beep1s
    banksel T2CON
    bsf T2CON,2			;accendi timer2 per suonare il buzzer
    movlw 0x80			;carica W con 32768 per fare un delay di 1s
    pagesel delay
    call delay			;delay 1s
    banksel T2CON
    bcf T2CON,2			;spegni il timer2
    return
    
    END