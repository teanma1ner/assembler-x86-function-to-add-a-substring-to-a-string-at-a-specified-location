locals __
model small
stack 100h


dataseg
MESS1     db 0dh,0ah,0dh,0ah,"Enter the string:",0dh,0ah,"$"
MESS2     db 0dh,0ah,0dh,0ah,"Enter the substring:",0dh,0ah,"$"
MESS3     db 0dh,0ah,"Enter position: $"
MESS4     db 0dh,0ah,0dh,0ah,"String after change:",0dh,0ah,"$"
S_BUFLEN1 db 80         ; Макс. длина строки 1
S_FACTLEN1 db ?         ; Длина фактически введенной строки 1
S_INPBUF1 db 80 dup(?)  ; Введенная строка 1

S_BUFLEN2 db 80         ; Макс. длина строки 2
S_FACTLEN2 db ?         ; Длина фактически введенной строки 2
S_INPBUF2 db 80 dup(?)  ; Введенная строка 2

N_BUFLEN db 3          ; Макс. длина числа при вводе
N_FACTLEN db ?         ; Фактическая длина
N_INPBUF db 3 dup(?)   ; Строка представления числа
POSADD dw ?            ; Позиция, начиная с которой добавляем


codeseg
startupcode
; Ввод строки 1
MLOOP:  
    lea     DX, MESS1
    mov     AH, 09h
    int     21h			;Приглашение к вводу строки
    lea     DX, S_BUFLEN1
    mov     AH, 0Ah
    int     21h         ;Ввод строки
    mov     BL, S_FACTLEN1
    cmp     BL, 0       ;Строка пустая?
    jne     LLL01        ;Нет – продолжать
    jmp     QUIT		;Закончить работу
LLL01:   
    mov     BH, 0         
    ; Дополнить длину до слова
    add     BX, 2        	; и получить адрес позиции
    add     BX, DX	        ; сразу после конца строки
    mov     byte ptr [BX],0	;Записать признак конца строки

; Ввод строки 2  
    lea     DX, MESS2
    mov     AH, 09h
    int     21h			;Приглашение к вводу строки
    lea     DX, S_BUFLEN2
    mov     AH, 0Ah
    int     21h         ;Ввод строки
    mov     BL, S_FACTLEN2
    cmp     BL, 0       ;Строка пустая?
    jne     LLL02        ;Нет – продолжать
    jmp     QUIT		;Закончить работу
LLL02:   
    mov     BH, 0         
    ; Дополнить длину до слова
    add     BX, 2        	; и получить адрес позиции
    add     BX, DX	        ; сразу после конца строки
    mov     byte ptr [BX],0	;Записать признак конца строки

; Ввод позиции добавления
LLL1:   
    lea     DX, MESS3       ;Приглашение
    mov     AH, 09h         ; к вводу
    int     21h             ; позиции удаления
    lea     DX, N_BUFLEN
    mov     AH, 0Ah
    int     21h		        ;Ввод строки числа
    lea     BX, N_INPBUF	;Адрес строки представления числа
    mov     CL, N_FACTLEN   ;Длина этой строки
    call    VAL			    ;Перевод в целое число
    jc      LLL1            ;Ошибка? – повторить ввод
    cmp     AL, S_FACTLEN1   ;Превышает длину строки?
    jg      LLL1          	;Повторить ввод
    mov     POSADD, AX	    ;Запомнить позицию удаления





; Занесение параметров в стек и вызов подпрограммы добавления
    lea     AX, S_INPBUF1
    push    AX			;1-й параметр – адрес строки 1

    mov     AL, S_FACTLEN1
    push    AX	        ;2-й параметр – длина строки 1

    lea     AX, S_INPBUF2
    push    AX			;3-й параметр – адрес подстроки 2

    mov     AL, S_FACTLEN2
    push    AX	        ;4-й параметр – длина подстроки 2

    mov     AX, POSADD
    dec     AX
    mov     POSADD, AX
    push    POSADD		;5-й параметр – позиция добавления
        
    call    ADDSUBS		;Вызов подпрограммы





; Вывод результата
    lea     DX, MESS4
    mov     AH, 09h
    int     21h         ;Заголовок вывода
    lea     BX, S_INPBUF1
    mov     CX, 80
LLL3:   
    cmp     byte ptr [BX],0	;Цикл поиска конца строки и выход
    je      LLL4        ; если найден конец строки 
    inc     BX			;Сдвиг по строке
    loop    LLL3
LLL4:   
    mov     byte ptr [BX],'$';Заменить признак конца строки
    lea     DX, S_INPBUF1
    mov     AH, 09h
    int     21h			; Вывод результата
    jmp     MLOOP		; На повторение работы


QUIT:   exitcode 0








;Действие: 
;  функция вычисляет целое число по его строковому представлению.
;  Результат не может быть больше 255.
;  Для неверно введенных чисел устанавливает флаг переноса
; Параметры:
;  BX – адрес строки представления числа
;  CX – длина этой строки
; Возвращает:
;  CF – установлен, если в строке не цифры, AX – не определен
;       	сброшен, строка нормальная, AX – число
;  AX – преобразованное число, если сброшен
VAL proc near
    push    DX		    ;Сохранить все изменяемые регистры,
                        ; кроме AX, в котором результат
    mov     CH, 0       ;Расширяем длину до слова
    mov     AX, 0       ;Начальное значение результата
    mov     DL, 10      ;Основание системы счисления
__1:    
    imul    DL		    ;Умножить на основание
    jc      __2         ;Переполнение байта?
    mov     DH, [BX]    ;Очередная цифра
    sub     DH, '0'     ;Получить значение цифры
    jl      __2         ;Это была не цифра!
    cmp     DH, 9
    jg      __2         ;Это опять же была не цифра!
    add     AL, DH	    ;+ значение цифры к результату
    jc      __2         ;Переполнение байта?
    inc     BX		    ;Сдвиг по строке
    loop    __1         ;Цикл по строке
    jmp     __3         ;Нормальное число
__2:    
    stc			        ;Было переполнение – устанавливаем CF
__3:    
    pop     DX		    ;Восстановить все, что сохраняли
    ret
    VAL     endp



; Подпрограмма добавления подстроки
ADDSUBS proc    near
        arg  __Padd: word, __SubStrLen: word, __SubStrAdr: word, __StrLen: word, __StrAdr: word = __ArgSize
;Params struc           ; Структура стека после сохранения BP
;  SaveBP dw ?          ; Сохраненное значение BP
;  SaveIP dw ?          ; Адрес возврата
;  Padd dw ?            ; 5-й параметр – позиция добавления
;  SubStrLen dw ?       ; 4-й параметр – длина подстроки
;  SubStrAdr dw ?       ; 3-й параметр – адрес подстроки
;  StrLen dw ?          ; 2-й параметр – длина строки
;  StrAdr dw ?          ; 1-й параметр – адрес строки
;Params  ends
    push    BP          ;Сохранить BP
    mov     BP, SP	    ;Теперь BP адресует стек ПОСЛЕ сохранения BP,
                        ; но ДО сохранения остальных регистров
    push    ES          ;Сохранить все изменяемые регистры
    push    AX          ;
    push    SI          ;
    push    DI          ;
    push    CX          ;


    mov     AX,DS   	; ES будет указывать на
    mov     ES,AX   	;  сегмент данных

    ; делаем окно для подстроки
    mov     SI,__StrAdr	; Установить в SI адрес,
    add     SI,__StrLen	; откуда надо
 ;   dec     SI		    ;  пересылать символы
    mov     DI,SI		; А в DI – адрес,
    add     DI,__SubStrLen ; куда их пересылать
;    inc     DI
    mov     CX,__StrLen ; Сохранение количества смещаемых 
    sub     CX,__Padd   ; символов в CX для счетчика в цикле
__REPEAT1: 
    mov     BL, [SI]
    mov     byte ptr [SI], '.'
    mov     [DI], BL
    dec     DI
    dec     SI
    loop     __REPEAT1


    ; пересылаем символы из подстроки
    mov     DI,__StrAdr	; Установить в DI адрес,
    add     DI,__Padd	; куда надо 
    inc     DI          ; пересылать символы
    mov     SI, __SubStrAdr ; А в SI – адрес, откуда их пересылать
    cld			        ;Продвигаться от начала строки к концу
    mov     CX,__SubStrLen ; В CX длину подстроки для цикла 
__REPEAT2: 
    movsb
    loop     __REPEAT2


    pop     CX	        ;Восстановить все, что сохраняли
    pop     DI          ;
    pop     SI          ;
    pop     AX          ;
    pop     ES          ;

    pop     BP
    ret     __ArgSize	;Убрать из стека 5 параметров-слов
    ADDSUBS endp
end
