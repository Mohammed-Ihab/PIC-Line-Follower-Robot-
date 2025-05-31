;===================================
;	Author: Mohammed Ihab Elmetwally
;
;	Date: 24/5/2025
;
;	PIC Version: PIC16F877A
;
;	Title: Line Follower mobile robot
;
;	Description: Line follower mobile robot control using two ir 
;	sensors, L298N H-Bridge, Proximity sensor, sharp ir, and LCD
;====================================


	LIST P=16F877A
    #include <P16F877A.INC>

    __CONFIG _CP_OFF & _WDT_OFF & _XT_OSC & _PWRTE_ON & _BODEN_OFF & _LVP_OFF

	ORG 0x00

; Variables
	CBLOCK 0x20
    	COUNT1
    	COUNT2
    	TEMP
    	NIBBLE
		ADC_READING_H
		ADC_READING_L
	ENDC


; LCD Control Pins
LCD_RS     EQU 2    ; PORTD.2
LCD_E      EQU 3    ; PORTD.3
LCD_DATA1   EQU 0x0F0 ; PORTC bits 4-7 (mask)

; LCD Commands
LCD_CLEAR  EQU 0x01
LCD_HOME   EQU 0x02
LCD_4BIT   EQU 0x28
LCD_ON     EQU 0x0C
LCD_ENTRY  EQU 0x06

	GOTO SETUP

	ORG 0x04
	
	CALL DISPLAY_STOPPED
STOP_INT:
	BCF INTCON, 1
	BCF PORTD, 1      ; IN2 = 0
	BCF PORTB, 6      ; IN1 = 0

	BCF PORTD, 0      ; IN3 = 0
    BCF PORTC, 3      ; IN4 = 0

    ; Set speed to 0% on both motors
   	MOVLW .0
    MOVWF CCPR1L      ; RC2 PWM
    MOVWF CCPR2L      ; RC1 PWM

WAIT_FOR_LOW:
	BTFSS PORTB, 0
	GOTO WAIT_FOR_LOW
	CALL DISPLAY_MOVING
	RETFIE

SETUP:
	; Setup Phase
	BSF INTCON, 7
	BSF INTCON, 4
	BCF INTCON, 1

	; Select Bank 1
    BCF STATUS, 6
    BSF STATUS, 5
	BCF OPTION_REG, INTEDG

	MOVLW   B'11000000'   ; Right-justified, VDD/VSS reference
    MOVWF   ADCON1

    MOVLW b'00010101'   ; Set RB0, RB2, RB4 as INPUTS, others are OUTPUT
    MOVWF TRISB
	MOVLW b'00000000'   ; Set PORTC as OUTPUT
    MOVWF TRISC        
	MOVLW b'00000000'   ; Set PORTD as OUTPUT
    MOVWF TRISD 
    BCF STATUS, 5        ; Back to Bank 0

	BCF PORTB, 3
	BCF PORTB, 5
	BCF PORTB, 7
	
	BCF PORTD, 1      ; IN2 = 0
	BCF PORTB, 6      ; IN1 = 0

	BCF PORTD, 0      ; IN3 = 0
    BCF PORTC, 3      ; IN4 = 0

	MOVLW   B'01000001'   ; ADC ON, Fosc/16, Channel 0 (AN0)
    MOVWF   ADCON0
    CALL    Delay_20us    ; Wait for acquisition time


	; Set PWM mode
	MOVLW b'00001100'   ; CCP1 in PWM mode
	MOVWF CCP1CON

	MOVLW b'00001100'   ; CCP2 in PWM mode
	MOVWF CCP2CON

	; Set PWM period
	MOVLW .249          ; 20kHz PWM	
	MOVWF PR2

	; Set duty cycle	
	MOVLW .128
	MOVWF CCPR1L        ; 50% duty on RC2
	MOVLW .128
	MOVWF CCPR2L        ; 50% duty on RC1

	; Set TMR2
	MOVLW b'00000111'   ; Prescaler = 16
	MOVWF T2CON

	BSF T2CON, 2        ; Turn on TMR2
    
    ; Initialize LCD with more robust sequence
    CALL LCD_INIT


	CALL DISPLAY_MOVING

START:
	; Main Loop Logic Behavior
	CALL    READ_ADC      ; Get ADC value
    CALL    CHECK_DISTANCE ; Update LED

	BTFSC PORTB, 2
	GOTO CHECK_LEFT
	GOTO CHECK_RIGHT
	
STOP:
	BCF PORTD, 1      ; IN2 = 0
	BCF PORTB, 6      ; IN1 = 0

	BCF PORTD, 0      ; IN3 = 0
    BCF PORTC, 3      ; IN4 = 0

    ; Set speed to 0%
    MOVLW .0
    MOVWF CCPR1L      ; RC2 PWM
    MOVWF CCPR2L      ; RC1 PWM
    GOTO START

MOVE_FORWARD:
	BCF PORTD, 1      ; IN1 = 0
	BSF PORTB, 6      ; IN2 = 1

	BCF PORTD, 0      ; IN3 = 0
    BSF PORTC, 3      ; IN4 = 1


    ; Set speed
    MOVLW .70
    MOVWF CCPR1L      ; RC2 PWM
    MOVWF CCPR2L      ; RC1 PWM
    GOTO START

MOVE_LEFT:
	BCF PORTD, 1	  ; IN1 = 0
	BSF PORTB, 6      ; IN2 = 1

	BCF PORTC, 3      ; IN4 = 0
	BSF PORTD, 0      ; IN3 = 1

    ; Set speed
    MOVLW .60
    MOVWF CCPR1L      ; RC2 PWM
    MOVWF CCPR2L      ; RC1 PWM
    GOTO START

MOVE_RIGHT:
	BCF PORTB, 6      ; IN2 = 0
    BSF PORTD, 1      ; IN1 = 1

	BCF PORTD, 0      ; IN3 = 0
	BSF PORTC, 3      ; IN4 = 1

    ; Set speed
    MOVLW .60
    MOVWF CCPR1L      ; RC2 PWM
    MOVWF CCPR2L      ; RC1 PWM
    GOTO START

CHECK_LEFT:
	BTFSC PORTB, 4
	GOTO MOVE_FORWARD
	GOTO MOVE_RIGHT

CHECK_RIGHT:
	BTFSC PORTB, 4
	GOTO MOVE_LEFT
	GOTO STOP

READ_ADC:
    BSF     ADCON0, GO    ; Start conversion
WAIT_READING:
    BTFSC   ADCON0, GO    ; Wait tell reading
    GOTO    WAIT_READING
    MOVF    ADRESH, W     ; Store high byte
    MOVWF   ADC_READING_H
	BANKSEL ADRESL
    MOVF    ADRESL, W     ; Store low byte
    MOVWF   ADC_READING_L
    BCF STATUS, 5
	RETURN


CHECK_DISTANCE:
    ;----------------------------
    ; Step 1: If ADC > 478 ? RED
    ;----------------------------
    MOVF    ADC_READING_H, W
    SUBLW   0x01
    BTFSS   STATUS, C         ; if ADC_H < 0x01 ? cannot be >478
    GOTO    CHECK_GREEN
    BTFSS   STATUS, Z         ; if ADC_H > 0x01 ? definitely >478
    GOTO    GREEN_LED_ON

    ; If ADC_H == 0x01, check low byte
    MOVF    ADC_READING_L, W
    SUBLW   0xDE              ; check if L > 0xDE
    BTFSS   STATUS, C         ; if ADC_L > 0xDE ? ADC > 478
    GOTO    GREEN_LED_ON

CHECK_GREEN:
    ;----------------------------
    ; Step 2: If ADC < 342 ? GREEN
    ;----------------------------
    MOVF    ADC_READING_H, W
    SUBLW   0x01
    BTFSC   STATUS, C         ; if ADC_H < 0x01 ? definitely <342
    GOTO    YELLOW_LED_ON
    BTFSS   STATUS, Z         ; if ADC_H > 0x01 ? definitely >342
    GOTO    RED_LED_ON

    ; ADC_H == 0x01 ? check low byte
    MOVF    ADC_READING_L, W
    SUBLW   0x56              ; check if L < 0x56
    BTFSC   STATUS, C         ; if ADC_L < 0x56 ? ADC < 342
    GOTO    YELLOW_LED_ON

    ;----------------------------
    ; Step 3: Else ? YELLOW
    ;----------------------------
    GOTO    RED_LED_ON

ADC_FINISH:
    RETURN

GREEN_LED_ON:
    BCF PORTB, 5
    BCF PORTB, 7
    BSF PORTB, 3
    GOTO ADC_FINISH

YELLOW_LED_ON:
    BCF PORTB, 3
    BCF PORTB, 7
    BSF PORTB, 5
    GOTO ADC_FINISH

RED_LED_ON:
    BCF PORTB, 3
    BCF PORTB, 5
    BSF PORTB, 7
    GOTO ADC_FINISH

; Modified LCD Initialization
LCD_INIT:
    ; Extended power-up delay (minimum 100ms to be safe)
    CALL DELAY_50MS
    CALL DELAY_50MS
    CALL DELAY_50MS
    
    ; First initialization sequence (2-bit mode)
    BCF STATUS, 6    ; Bank 0
    BCF STATUS, 5
    
    ; Send 0x03 three times with longer delays
    MOVLW 0x30
    CALL LCD_SEND_INIT
    CALL DELAY_10MS
    
    MOVLW 0x30
    CALL LCD_SEND_INIT
    CALL DELAY_10MS
    
    MOVLW 0x30
    CALL LCD_SEND_INIT
    CALL DELAY_10MS
    
    ; Switch to 4-bit mode
    MOVLW 0x20
    CALL LCD_SEND_INIT
    CALL DELAY_10MS
    
    ; Now in 4-bit mode - send function set
    MOVLW LCD_4BIT     ; 4-bit, 2-line, 5x8
    CALL LCD_CMD
    CALL DELAY_5MS
    
    MOVLW LCD_ON       ; Display on, cursor off, blink off
    CALL LCD_CMD
    CALL DELAY_5MS
    
    MOVLW LCD_CLEAR    ; Clear display
    CALL LCD_CMD
    CALL DELAY_5MS
    
    MOVLW LCD_ENTRY    ; Entry mode: increment, no shift
    CALL LCD_CMD
    CALL DELAY_5MS
    
    RETURN

; Special initialization send
LCD_SEND_INIT:
    BCF PORTD, LCD_E    ; Ensure E is low
    BCF PORTD, LCD_RS   ; Command mode
    
    ; Send upper nibble to all 8 data lines (for initialization)
    MOVWF TEMP
    MOVF TEMP,W
    ANDLW 0xF0
    MOVWF PORTC         ; Send to all data lines
    
    ; Pulse Enable
    BSF PORTD, LCD_E
    NOP
    NOP
    BCF PORTD, LCD_E
    
    ; Wait for command to complete
    CALL DELAY_1MS
    RETURN

; Send command to LCD (4-bit mode)
LCD_CMD:
    BCF PORTD, LCD_RS   ; Command mode
    GOTO LCD_SEND_4BIT

; Send data to LCD (4-bit mode)
LCD_SEND_DATA:
    BSF PORTD, LCD_RS   ; Data mode

LCD_SEND_4BIT:
    MOVWF TEMP
    ; Send upper nibble first
    SWAPF TEMP,W
    CALL LCD_SEND_NIBBLE
    ; Send lower nibble
    MOVF TEMP,W
    CALL LCD_SEND_NIBBLE
    ; Short delay for command execution
    CALL DELAY_100US
    RETURN

; Send a nibble to LCD
LCD_SEND_NIBBLE:
    ANDLW 0x0F          ; Only keep lower 4 bits
    MOVWF NIBBLE
    
    ; Bank selection for PORTC
    BCF STATUS, RP0     ; Bank 0
    BCF STATUS, RP1
    
    ; Clear data bits first
    MOVLW 0x0F
    ANDWF PORTC,F
    
    ; Set data bits according to nibble
    BTFSC NIBBLE, 0
    BSF PORTC, 4
    BTFSC NIBBLE, 1
    BSF PORTC, 5
    BTFSC NIBBLE, 2
    BSF PORTC, 6
    BTFSC NIBBLE, 3
    BSF PORTC, 7
    
    ; Pulse Enable
    BSF PORTD, LCD_E
    NOP                 ; 1µs delay
    NOP                 ; 1µs delay
    BCF PORTD, LCD_E
    RETURN


DISPLAY_MOVING:
	MOVLW   0x01         ; First line address (0x00)
    CALL    LCD_CMD

	MOVLW   0x80         ; First line address (0x00)
    CALL    LCD_CMD
    
    MOVLW   ' '
    CALL    LCD_SEND_DATA
	MOVLW   ' '
    CALL    LCD_SEND_DATA
	MOVLW   ' '
    CALL    LCD_SEND_DATA
	MOVLW   'L'
    CALL    LCD_SEND_DATA
    MOVLW   'I'
    CALL    LCD_SEND_DATA
	MOVLW   'N'
    CALL    LCD_SEND_DATA
	MOVLW   'E'
    CALL    LCD_SEND_DATA
    
    ; Display second line
    MOVLW   0xC0         ; Second line address (0x40)
    CALL    LCD_CMD
    
	MOVLW   ' '
    CALL    LCD_SEND_DATA
    MOVLW   'F'
    CALL    LCD_SEND_DATA
    MOVLW   'O'
    CALL    LCD_SEND_DATA
    MOVLW   'L'
    CALL    LCD_SEND_DATA
	MOVLW   'L'
    CALL    LCD_SEND_DATA
	MOVLW   'O'
    CALL    LCD_SEND_DATA
	MOVLW   'W'
    CALL    LCD_SEND_DATA
	MOVLW   'I'
    CALL    LCD_SEND_DATA
	MOVLW   'N'
    CALL    LCD_SEND_DATA
	MOVLW   'G'
    CALL    LCD_SEND_DATA

	RETURN

DISPLAY_STOPPED:
	MOVLW   0x01         ; First line address (0x00)
    CALL    LCD_CMD

	MOVLW   0x80         ; First line address (0x00)
    CALL    LCD_CMD
    
    MOVLW   ' '
    CALL    LCD_SEND_DATA
	MOVLW   ' '
    CALL    LCD_SEND_DATA
	MOVLW   ' '
    CALL    LCD_SEND_DATA
    MOVLW   'S'
    CALL    LCD_SEND_DATA
	MOVLW   'T'
    CALL    LCD_SEND_DATA
    MOVLW   'O'
    CALL    LCD_SEND_DATA
	MOVLW   'P'
    CALL    LCD_SEND_DATA

    ; Display second line
    MOVLW   0xC0         ; Second line address (0x40)
    CALL    LCD_CMD
    
	MOVLW   ' '
    CALL    LCD_SEND_DATA
    MOVLW   'O'
    CALL    LCD_SEND_DATA
    MOVLW   'B'
    CALL    LCD_SEND_DATA
    MOVLW   'J'
    CALL    LCD_SEND_DATA
	MOVLW   'E'
    CALL    LCD_SEND_DATA
	MOVLW   'C'
    CALL    LCD_SEND_DATA
	MOVLW   'T'
    CALL    LCD_SEND_DATA
	MOVLW   ' '
    CALL    LCD_SEND_DATA
	MOVLW   'D'
    CALL    LCD_SEND_DATA
	MOVLW   'E'
    CALL    LCD_SEND_DATA
	MOVLW   'T'
    CALL    LCD_SEND_DATA
	MOVLW   'E'
    CALL    LCD_SEND_DATA
	MOVLW   'C'
    CALL    LCD_SEND_DATA
	MOVLW   'T'
    CALL    LCD_SEND_DATA
	MOVLW   'E'
    CALL    LCD_SEND_DATA
	MOVLW   'D'
    CALL    LCD_SEND_DATA

	RETURN
	
; DELAY FUNCTIONS


; --- 50ms Delay ---
DELAY_50MS:
    MOVLW   D'200'       ; 200 loops
    MOVWF   COUNT1
DELAY_50MS_1:
    MOVLW   D'250'       ; 250 inner loops
    MOVWF   COUNT2
DELAY_50MS_2:
    NOP                  ; 1µs
    DECFSZ  COUNT2,F     ; 1µs (2µs when last)
    GOTO    DELAY_50MS_2 ; 2µs
    DECFSZ  COUNT1,F     ; 1µs
    GOTO    DELAY_50MS_1 ; 2µs
    RETURN               ; Total: 200*(250*3 + 3) + 2 ˜ 50ms

; --- 10ms Delay ---
DELAY_10MS:
    MOVLW   D'40'        ; 40 loops
    MOVWF   COUNT1
DELAY_10MS_1:
    MOVLW   D'250'       ; 250 inner loops
    MOVWF   COUNT2
DELAY_10MS_2:
    NOP
    DECFSZ  COUNT2,F
    GOTO    DELAY_10MS_2
    DECFSZ  COUNT1,F
    GOTO    DELAY_10MS_1
    RETURN

; --- 5ms Delay ---
DELAY_5MS:
    MOVLW   D'20'
    MOVWF   COUNT1
DELAY_5MS_1:
    MOVLW   D'250'
    MOVWF   COUNT2
DELAY_5MS_2:
    NOP
    DECFSZ  COUNT2,F
    GOTO    DELAY_5MS_2
    DECFSZ  COUNT1,F
    GOTO    DELAY_5MS_1
    RETURN

; --- 2ms Delay ---
DELAY_2MS:
    MOVLW   D'8'
    MOVWF   COUNT1
DELAY_2MS_1:
    MOVLW   D'250'
    MOVWF   COUNT2
DELAY_2MS_2:
    NOP
    DECFSZ  COUNT2,F
    GOTO    DELAY_2MS_2
    DECFSZ  COUNT1,F
    GOTO    DELAY_2MS_1
    RETURN

; --- 1ms Delay ---
DELAY_1MS:
    MOVLW   D'4'
    MOVWF   COUNT1
DELAY_1MS_1:
    MOVLW   D'250'
    MOVWF   COUNT2
DELAY_1MS_2:
    NOP
    DECFSZ  COUNT2,F
    GOTO    DELAY_1MS_2
    DECFSZ  COUNT1,F
    GOTO    DELAY_1MS_1
    RETURN

; --- 100us Delay ---
DELAY_100US:
    MOVLW   D'100'
    MOVWF   COUNT1
DELAY_100US_LOOP:
    NOP
    DECFSZ  COUNT1,F
    GOTO    DELAY_100US_LOOP
    RETURN

; --- 20us Delay ---
Delay_20us:
    MOVLW   D'20'
    MOVWF   TEMP
Delay_Loop:
    DECFSZ  TEMP, F
    GOTO    Delay_Loop
	RETURN

	
	END