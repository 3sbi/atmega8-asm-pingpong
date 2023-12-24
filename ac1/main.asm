; https://ww1.microchip.com/downloads/en/DeviceDoc/Atmel-2486-8-bit-AVR-microcontroller-ATmega8_L_datasheet.pdf
; https://dfe.karelia.ru/koi/posob/avrlab/avrasm-rus.htm
.include "m8def.inc"
.def temp = r16

; ����������� �������
.cseg
.org 0;
rjmp setup

; timer/counter0 overflow
.org OVF0addr 
rjmp timer1_overflow 

; timer/counter1 overflow
.org OVF1addr 
rjmp timer2_overflow 

; ���������
; 8 ���, ������������ = 1024
; 8000000 / 1024 = 7812.5 ��
.equ TIMER1_INTERVAL = 7812  ; �������� ��� TIMER1 (1 �������)

.equ TIMER2_INTERVAL = 15625  ; �������� ��� TIMER2 (2 �������)
TIMER1_STR: .db "ping", 13, 10, 0  ; ������ ��� ������ ��� ������������ TIMER1
TIMER2_STR: .db "pong", 13, 10, 0  ; ������ ��� ������ ��� ������������ TIMER2

setup:
	; https://youtu.be/PHDKorunI38?&t=553
	ldi temp, high(RAMEND) 
	out SPH, temp
	ldi temp, low(RAMEND)  
	out SPL, temp
	
	ldi temp, (1 << TOIE2) | (1 << TOIE1)
	out TIMSK, temp

	ldi temp, (1 << TOV2) | (1 << TOV1)
	out TIFR, temp

    ; ��������� TIMER1
    ldi temp, (1 << CS12) | (1 << CS10)  ; ��������� ���������� �� ������������, ������������ 1024
    out TCCR1B, temp
    ldi temp, high(TIMER1_INTERVAL)  ; �������� �������� ��� ��������� TIMER1
    out OCR1AH, temp  ; ��������� �������� ��������� A
    ldi temp, low(TIMER1_INTERVAL)
    out OCR1AL, temp

    ; ��������� TIMER2
    ldi temp, (1 << TOIE2) | (1 << CS22) | (1 << CS21) | (1 << CS20)  ; ��������� ���������� �� ������������, ������������ 1024
    out TCCR2, temp

    ldi temp, high(TIMER2_INTERVAL)  ; �������� �������� ��� ��������� TIMER2
    out OCR2, temp  ; ��������� �������� ���������

	;https://ww1.microchip.com/downloads/en/DeviceDoc/Atmel-2486-8-bit-AVR-microcontroller-ATmega8_L_datasheet.pdf
	; ���. 135
	; ��������� USART
    ldi temp, (1 << URSEL) | (1 << USBS) | (1 << UCSZ1)  | (1 << UCSZ0)  ; 8 ��� ������, 1 ����-���
    out UCSRC, temp
    ldi temp, (1 << RXEN) | (1 << TXEN)  ; ��������� ��������� � ����������� USART
    out UCSRB, temp
    ldi temp, 51 ; ��������� �������� �������� USART �� 9600 ��� - ���� ���� 9600��� ��� ������ 8��� ��� 8000000/(9600*16)-1=51,08 ����������, �� ��������� �� 51 -��� 0�33 (hex)
    out UBRRL, temp
    sei  ; ���������� ���� ����������

main:
    rjmp main  ; ����������� ����



timer1_overflow:
	cli
	ldi temp, low(TIMER1_STR)  ; �������� ������ ������ TIMER1_STR
	rjmp usart_send_string  ; �������� ������ ����� USART
	sei
	reti


timer2_overflow:
	cli
	ldi temp, low(TIMER2_STR)  ; �������� ������ ������ TIMER2_STR
	rjmp usart_send_string  ; �������� ������ ����� USART
	sei
	reti



; �������� ������ ����� USART
usart_send_string:
    push temp  ; ��������� �������� � ����
    push r17  ; ��������� �������� � ����

    loop:
        lpm temp, Z+  ; �������� ������� �� ������ ���������
        cp temp, r1   ; ��������� � ����� (����� ������)
        brne send_char         pop r17  ; �������������� ��������
        pop r16  ; �������������� ��������
        ret

    send_char:
		;https://ww1.microchip.com/downloads/en/DeviceDoc/Atmel-2486-8-bit-AVR-microcontroller-ATmega8_L_datasheet.pdf
		; ���. 136
        sbis UCSRA, UDRE  ; �������� ���������� �����������
        rjmp send_char  ; �������� ����������
		
		out UDR, r16  ; �������� ������� ����� USART
        
		rjmp loop  ; ������� � ���������� �������s