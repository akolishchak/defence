block_size     equ     1024*5
max_bloks  equ   100
TRomaddr struc
         addr     dw   ?
         bl_size  dw   ?
TRomaddr ends
Tcomm   struc
        offs  dw   ?
        segm  dw   ?
        rel16 dw   ?
Tcomm   ends

code    segment para
        assume ds:some,cs:code
        org 100h
begin_init = $
start   proc
        .386p
;        int     7dh
        mov     cs:old_ds,ds
        mov     cs:old_es,es
        mov     ax,offset endcodes
        mov     bx,ax
        shr     ax,4
        test    bl,0fh
        jz      ord_pass
        inc     ax
ord_pass:
        mov     bx,cs
        add     ax,bx
        mov     ds,ax
        mov     bp,sp
        movzx   eax,word ptr [bp+2]
        shl     eax,4
        mov     input,eax
        movzx   eax,word ptr [bp]
        add     input,eax

;        push    es ds
;        push    cs
;        pop     ds
;        push    cs
;        pop     es
;---------------------------------------
;        xor      ax,ax
;        mov      es,ax
;        mov      eax,es:[22h*4]
;        mov      es:[7eh*4],eax
;---------------------------------------------
         jmp       real_code

;------------------------------------------
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
        jcxz      xclabel_2         ; эталонная область
                                    ;  занимает 1 байт
xclabel_1:
        add       bx,cx             ; подсчитать контрольную
                                    ;  сумму эталонной
                                    ;  области памяти
        lodsw
        mul       bp
        add       bx,ax
        adc       bx,dx
        loop      xclabel_1
xclabel_2:
        pop       ax                ; восстановить длину
                                    ;  эталонной области
        test      al,1              ; в эталонной области
                                    ;  целое число слов ?
        jz        xclabel_3         ; да, переход
        add       bl,byte ptr [si]  ; учесть последний или
                                    ;  единственный байт
                                    ;  эталонной области
xclabel_3:
        pop       si                ; восстановить
                                    ;  коэфециент C и длину
                                    ;  шифруемой области
        pop       cx
        push      cx                ; сохранить длину
                                    ;  шифруемой области
        shr       cx,1              ; получить длину
                                    ;  шифруемой области
                                    ;  в словах
        jcxz      xclabel_5         ; шифруется один байт
xclabel_4:
        mov       ax,bx             ; вычислить очуредной
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
        loop      xclabel_4
xclabel_5:
        pop       cx                ; восстановить длину
                                    ;  шифруемой области
        test      cl,1              ; в шифруемой области
                                    ;  целое число слов ?
        jz        xclabel_6         ; да, переход
        xor       byte ptr es:[di],bl ; зашифровать последний
                                      ;  или единственный байт
                                      ;  шифруемой области
xclabel_6:
        pop       di                ; восстановить рабочие
                                    ;  регистры
        pop       si
        pop       dx
        pop       bx
        pop       ax
        ret
extra_crypto     endp
;---------------------------------------------------------------
real_code:

        ; расшифровать код
        push    cx ds
        mov     ax,cs
        mov     ds,ax
        call    getRomKey
        ; bp, si уже есть
        mov     bx,offset KeyBuf
        pop     ds
        mov     eax,input       ;
        sub     eax,old_input   ; \
        mov     cx,ax           ;
        shr     eax,4           ;   es:di - нач. адрес
        mov     es,ax           ;
        and     cx,0fh          ; /
        mov     di,cx           ;
        mov     ecx,exe_size
        push    ds
        push    cs
        pop     ds
rep_decode:
        cmp     ecx,block_size
        jae     ordinal_decode
        cmp     cx,0
        je      end_decode
        mov     ax,KeySize
        call    extra_crypto
        jmp short end_decode
ordinal_decode:
        push    ecx bp di
        mov     cx,block_size
        mov     ax,KeySize
        call    extra_crypto
        pop     di bp ecx
        ; теперь подготовить следующий блок
        mov     ax,es
        add     ax,140h
        mov     es,ax
        sub     ecx,block_size
        jmp short rep_decode
end_decode:
        pop     ds cx
;-------------------------------------------------------------
        ; настроить релокейшены
        mov      bx,offset first
        mov      ax,6
        mul      quant_comm
        add      bx,ax
        mov      cx,[bx]
        add      bx,2
        mov      edx,input
        sub      edx,old_input
        shr      edx,4           ; dx = start_seg
        cmp      cx,0
        je       relo_pass
rep_relo:
        mov      ax,[bx+2]
        add      ax,dx
        mov      es,ax
        mov      si,[bx]
        mov      ax,es:[si]
        add      ax,dx
        mov      es:[si],ax
        add      bx,4
        loop     rep_relo
;--------------------------------------------------------------
;--------------------------------------------------------------
relo_pass:
        ; выделить блок памяти под int1 и данные
        mov     bx,offset first
        mov     ax,6
        mul     quant_comm
        add     bx,ax
        shr     bx,4
        inc     bx
        mov     cx,bx
        add      bx,400h


;        inc     bx
        shl     cx,4
;        mov     ah,48h
;        int     21h
        call    getmem
        jnc     move2block
;        mov     bx,7000h
;        mov     es,dx
;        mov     ah,4ah
;        int     21h
;        call    getmem
;        jnc     move2block
        mov     ax,cs
        mov     ds,ax
        mov     ah,9
        mov     dx,offset err_msg1
        int     21h
        mov     al,0
        out     21h,al
        mov     ax,4c00h
        int     21h
err_msg1   db   7,'There is not enought memory',13,10,36
move2block:
        ; перекинуть все в этот блок
        mov     si,offset end_pro
        xor     di,di
        mov     es,ax
        cld
        rep movsb
        mov     ds,ax
        dec     quant_comm

        xor     ax,ax
        mov     fs,ax
        mov     eax,fs:[4]
        mov     oldint1,eax
        mov     ax,ds
        shl     eax,16
        mov     ax,offset int1
        mov     fs:[4],eax

;        mov     ax,2501h
;        mov     dx,0
;        int     21h
;        xor      eax,eax
;        mov      dr6,eax
        ; устанавливаем контр. точку на first call
        mov     eax,dword ptr first.offs
;        movzx   ebx,first.rel16
;        add     ebx,3
;        add     eax,ebx
        add     eax,input
        mov     dr0,eax
        mov     eax,00000002h
        mov     dr7,eax

        ; повеситься на выход
;        xor       ax,ax
;        mov       es,ax
;        movzx     eax,word ptr es:[0ah+2]
;        shl       eax,4
;        movzx     ebx,word ptr es:[0ah]
;        add       eax,ebx
;----------------------------
;        mov       eax,22h*4

        mov       es,_psp
        movzx     eax,word ptr es:[2ch]
        dec       eax
        shl       eax,4
        inc       eax
        mov       dr1,eax
        mov       eax,00d0030ch
        mov       ebx,dr7
        or        ebx,eax
        mov       dr7,ebx

        ; повеситься на чтение int1
        mov       eax,ds
        shl       eax,4
        add       eax,dword ptr offset next_scan
        mov       ebx,offset next_scan
        and       bx,0fch
        add       eax,ebx
        mov       dr2,eax
        mov       eax,03000320h
        mov       ebx,dr7
        or        ebx,eax
        mov       dr7,ebx

        ; повеситься на запись  1-го ветора
         mov       eax,04
         mov       dr3,eax
         mov       eax,0d0000380h
         mov       ebx,dr7
         or        ebx,eax
         mov       dr7,ebx
;---------------------------------------


        mov       ax,cs
        mov       es,ax
        mov       di,offset start
        mov       cx,init_size
        rep stosb

;---------------------------------------
init_size = $ - begin_init
        nop
        nop
        nop
        mov      flag,1
;        pop     ds es
       mov       ds,cs:old_ds
       mov       es,cs:old_es

        ; настроим far jmp
        pop     ax
        mov     cs:_ofs,ax
        pop     ax
        mov     cs:_seg,ax
        jmp short $+2

        ; установим старый стек
        mov     ax,word ptr cs:old_stack
        add     ax,cs:_seg
        mov     ss,ax
        mov     sp,word ptr cs:old_stack+2
;        push    0

        mov     al,0
        out     21h,al
        db      0eah
_ofs    dw      0
_seg    dw      0
;        retf
start   endp

old_ds     dw        ?
old_es     dw        ?
RomBuf     TRomaddr  max_bloks  dup(?)
KeyBuf     db        1000       dup(?)
KeySize    dw        ?
tec_bl     dw        0

getmem  proc
        push    es dx cx
        mov     es,membl_addr
        mov     cx,cs
        xor     dx,dx
memfind:
        cmp     word ptr es:[1],0
        jne     next_memfind
        cmp     es:[3],bx
        jb      next_memfind
;        jmp short end_memfind

next_memfind:
        cmp     byte ptr es:[0],'Z'
        jne     cont_find
        mov     cs:_psp,dx
        inc     cs:_psp
        ; DOS не хочет - сами возьмем (отымем)
        mov     es,dx
        mov     ax,es:[3]
        sub     ax,bx
        dec     ax
        mov     es:[3],ax
        ; формирование шапки для нового блока
        mov     dl,es:[0]
        mov     byte ptr es:[0],'M'
        mov     cx,es
        add     ax,cx
        inc     ax
        mov     es,ax
        mov     es:[0],dl
        mov     word ptr es:[1],8
        mov     es:[3],bx
        ; вот и все
        inc     ax
        pop     cx dx es
        clc
        ret
cont_find:
        mov     ax,es
        add     ax,es:[3]
        inc     ax
;--------------------------
        cmp     cx,ax
        jnb     ord_mem_pass
        cmp     dx,0
        jne     ord_mem_pass
        mov     dx,es     ; блок, в котором находится программа
;--------------------------
ord_mem_pass:
        mov     es,ax
        jmp short memfind
end_memfind:
        ; формирование из одного блока двух, если надо
        add     bx,2
        cmp     es:[3],bx
        jae     two
        mov     word ptr es:[1],08
        mov     ax,es
        inc     ax
        pop     cx dx es
        clc
        ret
two:
        mov     cl,es:[0]
        mov     byte ptr es:[0],'M'
        mov     dx,es:[3]
        mov     word ptr es:[1],08
        sub     bx,2
        mov     es:[3],bx
        mov     ax,es
        push    ax
        add     ax,bx
        inc     ax
        mov     es,ax
        mov     es:[0],cl
        mov     word ptr es:[1],0
        sub     dx,bx
        dec     dx
        mov     es:[3],dx
        pop     ax
        inc     ax
        pop     cx dx es
        clc
        ret
_psp    dw      ?
getmem  endp

endcodes:
code    ends


.286
some    segment para
        assume cs:some,ds:some
end_pro:
        mov     ax,cs
        mov     es,ax
        mov     di,offset int1
        mov     cx,int1_len
        rep stosb

        mov     di,offset end_pro
        mov     cx,offset quit
        rep stosb
.386
quit:

        mov     eax,cs:s_eax
        mov     ebx,cs:s_ebx
        mov     cx,cs:s_cx
        mov     dx,cs:s_dx
        mov     si,cs:s_si
        mov     bp,cs:s_bp
        mov     ds,cs:s_ds
        mov     es,cs:s_es
        mov     di,cs:s_di

        iretd

s_eax   dd      ?
s_ebx   dd      ?
s_cx    dw      ?
s_dx    dw      ?
s_si    dw      ?
s_bp    dw      ?
s_ds    dw      ?
s_es    dw      ?
s_di    dw      ?

int1_begin = $
int1    proc
    .386p
        mov     cs:s_eax,eax
        mov     cs:s_ebx,ebx
        mov     cs:s_cx,cx
        mov     cs:s_dx,dx
        mov     cs:s_si,si
        mov     cs:s_bp,bp
        mov     cs:s_ds,ds
        mov     cs:s_es,es
        mov     cs:s_di,di
;-----------------------------------------
        mov     eax,dr6
        cmp      cs:flag,1
        jne      int1_exit
        ; проверка на разреш. точки
;--------------------------------------
        mov      eax,dr6
        mov      ebx,dr7
        mov      cx,4
tnext:  test     bl,00000011b
        jnz      trep
        and      al,11111110b
trep:   ror      bl,2
        ror      al,1
        loop     tnext
        rol      al,4
;------------------------------------

;        mov     eax,dr6
        bt      eax,13
        jnc     next_view
        je      make_act
        jmp     int1_exit
        ; кто-то что-то делает с регистрами отладки
make_act:
;         mov     sp,3
;         pusha
;        mov     eax,dr7
;        mov     cs:m_dr7,eax
;        mov     eax,dr0
;        mov     cs:m_dr0,eax
;        mov     eax,dr1
;        mov     cs:m_dr1,eax
;        mov     eax,dr2
;        mov     cs:m_dr2,eax
;        mov     eax,dr3
;        mov     cs:m_dr3,eax
;
;        xor     eax,eax
;        mov     dr7,eax
;        mov     dr0,eax
;        mov     dr1,eax
;        mov     dr2,eax
;        mov     dr3,eax
;
;        mov     bp,sp
;        and     byte ptr [bp+5],0fdh
;        or      byte ptr [bp+5],1
;        mov     ax,0b800h
;        mov     fs,ax
;        mov     byte ptr fs:[0],1
;        mov     cs:_fl,1
;
         jmp     int1_exit
;_fl     db      0
next_view:
        bt      eax,14
        jnc     break_point
        ; step mode
        mov     ax,0b800h
        mov     es,ax
        mov     byte ptr es:[2400],'P'

        jmp     int1_exit
;        xor     eax,eax
;        mov     dr6,eax
;
;        mov     eax,cs:s_eax
;        mov     ebx,cs:s_ebx
;        mov     cx,cs:s_cx
;        mov     dx,cs:s_dx
;        mov     si,cs:s_si
;        mov     bp,cs:s_bp
;        mov     ds,cs:s_ds
;        mov     es,cs:s_es
;
;        iret
;
;        jmp     int1_exit
break_point:
        bt      eax,0
        jnc     test_p1
        jmp     point_0
test_p1:
        bt      eax,1
        jnc     test_p2
        jmp     point_1
test_p2:
        bt      eax,2
        jnc     test_p3
        jmp     point_2
test_p3:
        bt      eax,3
        jnc     unknown_p
        jmp     point_3
unknown_p:
        jmp     int1_exit
point_0:
        mov     ax,cs
        mov     ds,ax
        ; ищем адрес вызвавшей процедуры с стеке
        mov     bp,sp
        movzx   ebx,word ptr [bp+2]
        shl     ebx,4
        movzx   eax,word ptr [bp+6]
        sub     eax,3
        add     ebx,eax
        sub     ebx,input
        xor     si,si
beg_scan:
        cmp     si,cs:quant_comm
        jb      next_scan
        jmp int1_exit
        align   4
next_scan:
        push    si
        mov     ax,6
        mul     si
        mov     si,ax
        cmp     ebx,dword ptr extrn_comm[si].offs
        je      end_scan
        pop     si
        inc     si
        jmp short beg_scan
end_scan:
        add     sp,2
        mov     ax,extrn_comm[si].rel16
        add     ax,[bp+6]
        mov     [bp],ax
        jmp     int1_exit
point_1:

        xor     eax,eax
        mov     dr7,eax
        mov     eax,0ffff4ff0h
        mov     dr6,eax


        mov     ax,cs
        dec     ax
        mov     es,ax
        mov     word ptr es:[1],0
        xor     ax,ax
        mov     es,ax
        mov     eax,cs:oldint1
        mov     es:[4],eax

        pop     bx
        pop     dx
        pop     cx
        pushfd
        pop     eax
        or      eax, 10000h    ;устанавливаем флаг возобновления
        mov     ax,cx
        push    eax            ;флаги помещаем в стек
        push    0
        push    dx
        push    0
        push    bx



        jmp     end_pro
point_2:
        mov     sp,3
        pusha
        jmp     int1_exit
point_3:
;        mov     sp,3
;        pusha
int1_exit:
;-----------------------------------------
        xor     eax,eax
        mov     dr6,eax
        pop     bx
        pop     dx
        pop     cx
        pushfd
        pop     eax
        or      eax, 10000h    ;устанавливаем флаг возобновления
        mov     ax,cx
        push    eax            ;флаги помещаем в стек
        push    0
        push    dx
        push    0
        push    bx

        mov     eax,cs:s_eax
        mov     ebx,cs:s_ebx
        mov     cx,cs:s_cx
        mov     dx,cs:s_dx
        mov     si,cs:s_si
        mov     bp,cs:s_bp
        mov     ds,cs:s_ds
        mov     es,cs:s_es
        mov     di,cs:s_di

        iretd
;----------------------------------
flag    dw      0
oldint1 dd      ?

m_dr7   dd      ?
m_dr0   dd      ?
m_dr1   dd      ?
m_dr2   dd      ?
m_dr3   dd      ?
int1    endp
cnt     dw      0



input   dd      7

;hello   db      'Aga!!!',13,10,36

old_stack   label   dword
        org     old_stack+4
old_input   label   dword
        org     old_input+4
exe_size    label   dword
        org     exe_size+4
quant_comm  label   word
        org     quant_comm+2
membl_addr  label   word
        org     membl_addr+2
first       label   Tcomm
        org     first+6
extrn_comm  label   Tcomm

int1_len = $ - int1_begin
some    ends
        end         start

