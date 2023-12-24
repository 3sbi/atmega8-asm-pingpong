; https://ww1.microchip.com/downloads/en/DeviceDoc/Atmel-2486-8-bit-AVR-microcontroller-ATmega8_L_datasheet.pdf
; https://dfe.karelia.ru/koi/posob/avrlab/avrasm-rus.htm
.include "m8def.inc"
.def temp = r16

; программный сегмент
.cseg
.org 0;
rjmp setup

; timer/counter0 overflow
.org OVF0addr 
rjmp timer1_overflow 

; timer/counter1 overflow
.org OVF1addr 
rjmp timer2_overflow 

; Константы
; 8 МГц, предделитель = 1024
; 8000000 / 1024 = 7812.5 Гц
.equ TIMER1_INTERVAL = 7812  ; Интервал для TIMER1 (1 секунда)

.equ TIMER2_INTERVAL = 15625  ; Интервал для TIMER2 (2 секунды)
TIMER1_STR: .db "ping", 13, 10, 0  ; Строка для вывода при срабатывании TIMER1
TIMER2_STR: .db "pong", 13, 10, 0  ; Строка для вывода при срабатывании TIMER2

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

    ; Настройка TIMER1
    ldi temp, (1 << CS12) | (1 << CS10)  ; Включение прерывания по переполнению, предделитель 1024
    out TCCR1B, temp
    ldi temp, high(TIMER1_INTERVAL)  ; Загрузка значения для интервала TIMER1
    out OCR1AH, temp  ; Настройка регистра сравнения A
    ldi temp, low(TIMER1_INTERVAL)
    out OCR1AL, temp

    ; Настройка TIMER2
    ldi temp, (1 << TOIE2) | (1 << CS22) | (1 << CS21) | (1 << CS20)  ; Включение прерывания по переполнению, предделитель 1024
    out TCCR2, temp

    ldi temp, high(TIMER2_INTERVAL)  ; Загрузка значения для интервала TIMER2
    out OCR2, temp  ; Настройка регистра сравнения

	;https://ww1.microchip.com/downloads/en/DeviceDoc/Atmel-2486-8-bit-AVR-microcontroller-ATmega8_L_datasheet.pdf
	; стр. 135
	; Настройка USART
    ldi temp, (1 << URSEL) | (1 << USBS) | (1 << UCSZ1)  | (1 << UCSZ0)  ; 8 бит данных, 1 стоп-бит
    out UCSRC, temp
    ldi temp, (1 << RXEN) | (1 << TXEN)  ; Включение приемника и передатчика USART
    out UCSRB, temp
    ldi temp, 51 ; Установка скорости передачи USART на 9600 бод - если хочу 9600кбс при кварце 8мГц это 8000000/(9600*16)-1=51,08 получается, ну округляем до 51 -это 0х33 (hex)
    out UBRRL, temp
    sei  ; Установить флаг прерываний

main:
    rjmp main  ; Бесконечный цикл



timer1_overflow:
	cli
	ldi temp, low(TIMER1_STR)  ; Загрузка адреса строки TIMER1_STR
	rjmp usart_send_string  ; Отправка строки через USART
	sei
	reti


timer2_overflow:
	cli
	ldi temp, low(TIMER2_STR)  ; Загрузка адреса строки TIMER2_STR
	rjmp usart_send_string  ; Отправка строки через USART
	sei
	reti



; отправка строки через USART
usart_send_string:
    push temp  ; Занесение регистра в стек
    push r17  ; Занесение регистра в стек

    loop:
        lpm temp, Z+  ; Загрузка символа из памяти программы
        cp temp, r1   ; Сравнение с нулем (конец строки)
        brne send_char         pop r17  ; Восстановление регистра
        pop r16  ; Восстановление регистра
        ret

    send_char:
		;https://ww1.microchip.com/downloads/en/DeviceDoc/Atmel-2486-8-bit-AVR-microcontroller-ATmega8_L_datasheet.pdf
		; стр. 136
        sbis UCSRA, UDRE  ; Проверка готовности передатчика
        rjmp send_char  ; Ожидание готовности
		
		out UDR, r16  ; Отправка символа через USART
        
		rjmp loop  ; Переход к следующему символуs