;▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
;▒▒                                                              ▒▒
;▒▒                    Encrypt.com                               ▒▒
;▒▒   Предназначена для шифрования исполняемого файла по ключу,  ▒▒
;▒▒   сформированному по ПЗУ. Вохдит в комплект защиты от        ▒▒
;▒▒   копирования DEFENCE.                                       ▒▒
;▒▒                           (C) 1996 Колищак А.Н.              ▒▒
;▒▒                                                              ▒▒
;▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒


block_size     equ     1024*5
max_bloks  equ   10
TRomaddr struc
         addr     dw   ?
         bl_size  dw   ?
TRomaddr ends

        MODEL tiny
        .CODE
        .STARTUP
        .286p

        mov     bx,offset last
        mov     cl,4
        shr     bx,cl
        add     bx,17

        mov     ah,4ah
        int     21h

        mov     ax,bx
        shl     ax,cl
        dec     ax
        mov     sp,ax
        ;--------------------------------
        call    getRomkey

        mov     ax,cs
        mov     ds,ax
        mov     dx,offset fname
        mov     bx,offset KeyBuf
        mov     ax,KeySize
        call    encrypt
        mov     ax,4c00h
        int     21h
; подготовка ключа и коэф. из ROM
getRomkey  proc
           push    ax bx cx dx di ds es

           mov     ax,cs
           mov     ds,ax
           call    getRom
           xor     dx,dx
           mov     ax,1000
           div     tec_bl
           mov     cx,ax
           shl     cx,1
           mov     KeySize,cx
           shr     ax,2
           mov     cx,ax            ; dKey
           mov     ax,cs
           mov     es,ax
           mov     di,offset KeyBuf
           cld
           xor     bx,bx
form_rep1:
           cmp     bx,cs:tec_bl
           jae     end_form_rep1
           push    bx
           xor     si,si            ; M = 0
           shl     bx,2
           mov     dx,cs:RomBuf[bx].bl_size
           shr     dx,2             ; dM  = bl_size/4
           mov     ds,cs:RomBuf[bx].addr
           xor     bp,bp
form_rep2:
           cmp     bp,4
           jae     end_form_rep2
           push    cx si
           add     si,27
           rep movsb
           pop     si cx
           add     si,dx
           inc     bp
           jmp short form_rep2
end_form_rep2:
           pop     bx
           inc     bx
           jmp short form_rep1
end_form_rep1:
           ; формируем коэф. A и C
           xor     bx,bx
           mov     es,cs:RomBuf[bx].addr
           mov     bp,es:[16]       ; A
           mov     si,es:[21]       ; C

           pop     es ds di dx cx bx ax

           ret
getRomKey  endp

RomBuf     TRomaddr  max_bloks  dup(?)
KeyBuf     db        1000       dup(?)
KeySize    dw        ?
tec_bl     dw        0
; поиск блоков ROM
getRom     proc
           push    si ax es ds
           mov     ax,cs
           mov     ds,ax
           mov     tec_bl,0
; поиск rom устройств
           mov     ax,0c000h
           mov     es,ax
rep_find:
           cmp     ax,0fe00h
           jae     end_find
           cmp     word ptr es:[0],0aa55h
           jne     next_rep_find
           mov     si,tec_bl
           shl     si,2
           xor     ax,ax
           mov     al,es:[2]
           shl     ax,9     ; * 512
           mov     bx,ax  ;--------
           mov     RomBuf[si].bl_size,ax
           mov     RomBuf[si].addr,es
           shr     ax,4
           mov     si,es
           add     si,ax
           mov     es,si
           mov     ax,es
           inc     tec_bl
        ;-----------------------
           jmp short rep_find
next_rep_find:
           mov     ax,es
           add     ax,80h
           mov     es,ax
           jmp short rep_find
end_find:
; записываем адрес bios
           mov     si,tec_bl
           shl     si,2
           mov     RomBuf[si].bl_size,100h
           mov     ax,0fe00h
           mov     RomBuf[si].addr,ax
           inc     tec_bl
getRom_exit:
           pop     ds es ax si
           ret
getRom     endp


fname   db      'asd.exe',0
key     db      'And'
; ds:dx - имя файла
; ds:bx - ключ
; ax - длина ключа
; si - C
; bp - A
encrypt   proc
        push  cx dx es ds ax bx
; прочитать заголовок файла
        mov     ah,3dh
        mov     al,2
        mov     cx,0
        int     21h
        jnc     next_act0
        jmp     cerror
next_act0:
        mov     fh,ax

        mov     bx,fh
        mov     ah,3fh
        mov     dx,offset cbeg_file
        mov     cx,24
        int     21h
        jnc     next_act1
        jmp     cerror
next_act1:
        cmp     csign,'MZ'
        je      exe_f
        cmp     csign,'ZM'
        je      exe_f
        ; com
        jmp short make_crypt
exe_f:
        mov     ax,4200h
        mov     bx,fh
        mov     dx,csize_hand
        shl     dx,4
        xor     cx,cx
        int     21h
        jnc     make_crypt
        jmp     cerror

make_crypt:
        mov     size_bl,1024*5
crypt_rep:

        mov     ah,3fh
        mov     bx,cs:fh
        mov     cx,cs:size_bl
        mov     dx,cs
        mov     ds,dx
        mov     dx,offset cbuf
        int     21h
        jc      cerror
        cmp     ax,0
        je      end_crypt_rep
        ; теперь приготавливаем параметры для extra_crypto
        mov     cx,ax
        mov     ax,cs
        mov     es,ax
        mov     di,offset cbuf
        pop     bx ax ds
        push    ds ax bx
        call    extra_crypto

        ; записать
        push    cx
        mov     ax,4201h
        mov     bx,cs:fh
        neg     cx
        mov     dx,cx
        mov     cx,0ffffh
        int     21h
        jc      cerror

        mov     ah,40h
        mov     bx,cs:fh
        pop     cx
        mov     dx,cs
        mov     ds,dx
        mov     dx,offset cbuf
        int     21h

        mov     ah,2
        mov     dl,2eh
        int     21h

;        mov     ah,0fh
;        int     10h
;        mov     ax,0a2eh
;        mov     cx,1
;        int     10h

        jmp short crypt_rep
end_crypt_rep:
        mov     ah,3eh
        mov     bx,cs:fh
        int     21h

        pop     bx ax ds es dx cx
        clc
        ret
cerror:
        pop     bx ax ds es dx cx
        stc
        ret
; заголовок
;-----------------------------------------
cbeg_file    label   byte
csign        dw      ?
             db   6  dup(?)
csize_hand   dw      ?
             db   10 dup(?)
cbeg_offs    dd      ?
;-----------------------------------------
fh           dw      ?
cbuf         db   1024*5  dup(?)
size_bl      dw      ?
encrypt   endp

;▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
;▓▓                                                        ▓▓
;▓▓                                                        ▓▓
;▓▓  Шифрование указанной области по ключу, находящемуся   ▓▓
;▓▓  в другой области.                                     ▓▓
;▓▓  (Разновидность метода гаммирования с обратной связью) ▓▓
;▓▓                                                        ▓▓
;▓▓  Входные  параметры :                                  ▓▓
;▓▓                                                        ▓▓
;▓▓  ES:DI - шифруемая область, CX - длина этой области;   ▓▓
;▓▓  BP - коэффецент A, SI - коэффецент C в формуле для    ▓▓
;▓▓  получения очередного ПСЧ гаммы шрифта:                ▓▓
;▓▓    T(i+1) = (A*(T(i)+C) mod M.                         ▓▓
;▓▓  DS:BX - адресуют эталонную область (ключ)             ▓▓
;▓▓  AX - длина этой области                               ▓▓
;▓▓                                                        ▓▓
;▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

extra_crypto  proc
        cld                         ; Установить рпямое направление
                                    ;  цепочных пераций
        push      ax                ; Сохранить рабочие регистры
        push      bx
        push      dx
        push      si
        push      di
        push      cx                ; сохранить длину
                                    ;  шифруемой области
                                    ;  и коэффициент C
        push      si
        push      ax                ; сохранить длину
                                    ;  эталонной области
        mov       si,bx             ; установить адресацию
                                    ;  эталонной области
        xor       bx,bx             ; обнулить накопитель
                                    ;  контрольной суммы
        mov       cx,ax             ; получить длину эталонной
                                    ;  области в словах
        shr       cx,1
        jcxz      xc_2              ; эталонная область
                                    ;  занимает 1 байт
xc_1:   add       bx,cx             ; подсчитать контрольную
                                    ;  сумму эталонной
                                    ;  области памяти
        lodsw
        mul       bp
        add       bx,ax
        adc       bx,dx
        loop      xc_1
xc_2:   pop       ax                ; восстановить длину
                                    ;  эталонной области
        test      al,1              ; в эталонной области
                                    ;  целое число слов ?
        jz        xc_3              ; да, переход
        add       bl,byte ptr [si]  ; учесть последний или
                                    ;  единственный байт
                                    ;  эталонной области
xc_3:   pop       si                ; восстановить
                                    ;  коэфециент C и длину
                                    ;  шифруемой области
        pop       cx
        push      cx                ; сохранить длину
                                    ;  шифруемой области
        shr       cx,1              ; получить длину
                                    ;  шифруемой области
                                    ;  в словах
        jcxz      xc_5              ; шифруется один байт
xc_4:   mov       ax,bx             ; вычислить очуредной
                                    ;  коэфециент
                                    ;  случайного числа
        mul       bp
        add       ax,si
        mov       bx,ax             ; сохранить очуредной
                                    ;  коэффициент в регистре BX
        xor       word ptr es:[di],ax ; закодировать одно слово
                                    ;   области
        inc       di                ; перейти к следующему
                                    ;  слову области
        inc       di
        loop      xc_4
xc_5:   pop       cx                ; восстановить длину
                                    ;  шифруемой области
        test      cl,1              ; в шифруемой области
                                    ;  целое число слов ?
        jz        xc_6              ; да, переход
        xor       byte ptr es:[di],bl ; зашифровать последний
                                      ;  или единственный байт
                                      ;  шифруемой области
xc_6:   pop       di                ; восстановить рабочие
                                    ;  регистры
        pop       si
        pop       dx
        pop       bx
        pop       ax
        ret
extra_crypto     endp
last    db        ?
        end

