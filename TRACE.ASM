;▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
;▒▒                                                       ▒▒
;▒▒                    Trace.com                          ▒▒
;▒▒ Предназначена для модификации защищаемой программы.   ▒▒
;▒▒ Выполняет поиск и изменение инструкций CALL offset16. ▒▒
;▒▒ Входит в комплект защиты от копирования DEFENCE.      ▒▒
;▒▒                                                       ▒▒
;▒▒                     (C) 1996  Колищак А.Н.            ▒▒
;▒▒                                                       ▒▒
;▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒


max_comm  equ    100
name_len  equ    3
Tcomm   struc
        offs  dw   ?
        segm  dw   ?
        rel16 dw   ?
Tcomm   ends


        MODEL tiny
        .CODE
        .386
        .STARTUP


;        int     7dh
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

        mov     dx,offset int1
        mov     ax,2501h
        int     21h

        mov     bx,offset comm_line
        mov     cmd_off,bx
        mov     cmd_seg,ds
        mov     ax,ds
        mov     es,ax
        mov     bx,offset epb
        mov     dx,offset path

        mov     ax,4b01h
        int     21h
modify1:
        jc      error

        mov     ss,_ss
        mov     sp,_sp

        mov     ax,_cs
        push    ax
        mov     ax,_ip
        push    ax

        push    bx
        mov     bx,offset modify1
                                ; jmp after_run
        mov     word ptr cs:[bx],(after_run-modify1-2)*100h+0ebh
        jmp  short $+2
        pop     bx

        ;  установка адреса программы
        call    findmem

; set debug mode

        pushf
        pop     ax
        or      ah,1
        push    ax
        popf

; run
        retf

after_run:
        mov     dx,offset dummy
        mov     ax,2501h
        int     21h
        pushf
        pop     ax
        and     ah,0feh
        push    ax
        popf

        mov     ah,9
        mov     dx,offset hello
        int     21h
; проверка на модифицируемость

        mov     bx,offset comm_line
        mov     cmd_off,bx
        mov     cmd_seg,ds
        mov     ax,ds
        mov     es,ax
        mov     bx,offset epb
        mov     dx,offset path

        mov     ax,4b01h
        int     21h
modify2:
        jc      error

        mov     bx,offset modify2
                                ; jmp short exit
        mov     byte ptr cs:[bx],0e9h
        mov     word ptr cs:[bx+1],exit-modify2-3
        jmp short  ordinal_code
; здесь выход
exit:
        jmp     write

ordinal_code:
; прочитать заголовок файла
        mov     ah,3dh
        mov     dx,offset path
        mov     al,2
        mov     cx,0
        int     21h
        jc      error
        mov     fhandle,ax

        mov     bx,fhandle
        mov     ah,3fh
        mov     dx,offset beg_file
        mov     cx,hand_size
        int     21h
        jc      error
; проверка типа файла
        cmp     sign,'MZ'
        je      asExe
        cmp     sign,'ZM'
        je      asExe
  ; значит com
        mov     corect,-100h
        jmp     next_act
asExe:   ; exe
        movzx   eax,_cs
        shl     eax,4
        movzx   ebx,_ip
        add     eax,ebx
        xor     ebx,ebx
        mov     bx,word ptr beg_offs+2
        shl     ebx,4
        xor     ecx,ecx
        mov     cx,word ptr beg_offs
        add     ebx,ecx
        sub     eax,ebx             ; base = _cs:_ip - base_offset
        neg     eax                 ; -base
        movzx   ebx,size_hand
        shl     ebx,4
        add     eax,ebx             ; + длина заголовка
        mov     corect,eax
next_act:
        ; открыть файл для дозаписи
        mov     ah,3dh
        mov     al,2
        mov     dx,offset tail_file
        int     21h
        jc      error
        mov     fhandle2,ax
        ; указатель в конец
        mov     ax,4202h
        xor     cx,cx
        xor     dx,dx
        mov     bx,fhandle2
        int     21h
        jc      error
        add     ax,12
        mov     count_offs,ax

; корректировка ASD.EXE и TAIL.COM
        ; записать старый стек
        mov     ah,40h
        mov     dx,offset beg_stack
        mov     cx,4
        mov     bx,fhandle2
        int     21h

        ; записать точку входа и размер
;-------------------------------------
        jmp short real_code
old_input       dd         ?
exe_size        dd         ?
;-------------------------------------
real_code:
        movzx   eax,word ptr beg_offs+2
        shl     eax,4
        movzx   ebx,word ptr beg_offs
        add     eax,ebx
        mov     old_input,eax
        mov     ax,4202h
        mov     bx,fhandle
        xor     cx,cx
        xor     dx,dx
        int     21h
        movzx   ebx,dx
        shl     ebx,16
        mov     bx,ax
        movzx   eax,size_hand
        shl     eax,4
        sub     ebx,eax
        mov     exe_size,ebx

        mov     ah,40h
        mov     bx,fhandle2
        mov     dx,offset old_input
        mov     cx,8
        int     21h
        jc      error


        ; записать в tail кол-во call-ов
        mov     ah,40h
        mov     dx,offset tec_comm
        mov     cx,2
        mov     bx,fhandle2
        int     21h
        jc      error
        ; записать адрес начала блоков памяти
        mov     ah,40h
        mov     dx,offset membl
        mov     cx,2
        mov     bx,fhandle2
        int     21h
        jc      error

        xor     si,si
comp_loop:
        cmp     si,tec_comm
        jae     end_comp
        push    si
        mov     ax,6
        mul     si
        mov     si,ax
        xor     ebx,ebx
        mov     bx,comm_buf[si].offs
        mov     es,comm_buf[si].segm
        cmp     byte ptr es:[bx],0e8h
        jne     comp_pass
        ; запись в файл
        xor     ecx,ecx
        mov     cx,es               ; указатель в segm:offs + corect
        mov     eax,ecx
        shl     eax,4
        mov     ecx,ebx
        add     eax,ecx
        add     eax,corect
        inc     eax                 ; перемещение внутри команды к адресу

        mov     dx,ax
        shr     eax,16
        mov     cx,ax
        mov     ax,4200h
        mov     bx,fhandle
        int     21h
        jc      error
        ; подготовка записываемого адреса
        pop     ax                  ; 1-ый call ?
        push    ax
        cmp     ax,0
        jne     make_change
        mov     ax,comm_buf[si].rel16
        mov     corect_offs,ax
        movzx   eax,comm_buf[si].segm
        mov     first_segm,ax
        shl     eax,4
        mov     first_addr,eax
        movzx   eax,comm_buf[si].offs
        add     first_addr,eax
;        movzx   eax,comm_buf[si].rel16
;        add     first_addr,eax
;        add     first_addr,3

        jmp short write_corect
make_change:
        mov     ax,first_segm
        cmp     ax,comm_buf[si].segm
        jne     non_modify
        movzx   eax,comm_buf[si].segm
        shl     eax,4
        movzx   ebx,comm_buf[si].offs
        add     eax,ebx
        add     eax,3
        sub     eax,first_addr
        neg     eax
;        cmp     eax,-32768
;        jl      non_modify
;        cmp     eax,32767
;        jg      non_modify
        mov     corect_offs,ax
        jmp short write_corect

non_modify:
        inc     pass_count
        jmp     inc_count

write_corect:
        mov     ah,40h
        mov     bx,fhandle
        mov     dx,offset corect_offs
        mov     cx,2
        int     21h
        jc      error

        ; запись данных в tail
        ; корректировка адреса
        movzx   eax,word ptr comm_buf[si].segm
        shl     eax,4
        movzx   ebx,word ptr comm_buf[si].offs
        add     eax,ebx             ; eax - лин. адрес call
        movzx   ebx,word ptr _cs
        shl     ebx,4
        movzx   ecx,word ptr _ip
        add     ebx,ecx             ; ebx - смещение
        sub     eax,ebx
        mov     dword ptr comm_buf[si].offs,eax

        mov     ah,40h
        mov     dx,offset comm_buf
        add     dx,si
        mov     cx,6
        mov     bx,fhandle2
        int     21h
        jc      error
inc_count:
        pop     si
        inc     si
comp_pass:
        jmp comp_loop
end_comp:
        ; скоректировать число записей
        mov     dx,count_offs
        xor     cx,cx
        mov     bx,fhandle2
        mov     ax,4200h
        int     21h
        jc      error
        mov     ax,pass_count
        sub     tec_comm,ax
        mov     ah,40h
        mov     bx,fhandle2
        mov     dx,offset tec_comm
        mov     cx,2
        int     21h
        jc      error

;   теперь запишем релокейшены в tail
;   и подкорректируем заголовок asd.exe
        ; освобождаем память
        ; закрыть файлы
        mov     ah,3eh
        mov     bx,fhandle
        int     21h

        mov     ah,3eh
        mov     bx,fhandle2
        int     21h


        mov     ax,4c00h
        int     21h
        ; заголовок уже считан
write:
        ; переоткрываем файлы
        mov     ax,3d02h
        mov     dx,offset path
        int     21h
        jc      error
        mov     fhandle,ax
        mov     ax,3d02h
        mov     dx,offset tail_file
        int     21h
        jc      error
        mov     fhandle2,ax
        mov     ax,4202h
        xor     dx,dx
        xor     cx,cx
        mov     bx,fhandle2
        int     21h

        ; запишем кол-во релок. в tail
        mov     dx,offset relo_cnt
        mov     cx,2
        mov     bx,fhandle2
        mov     ah,40h
        int     21h

        ; указатель на релок.
        mov     dx,cs:relotabl
        xor     cx,cx
        mov     ax,4200h
        mov     bx,cs:fhandle
        int     21h

        ; читаем их
        mov     cx,relo_cnt
        shl     cx,2
        mov     bx,cx
        shr     bx,4
        inc     bx
        mov     ah,48h
        int     21h
        jc      error
        mov     ds,ax

        xor     dx,dx
        mov     ah,3fh
        mov     bx,cs:fhandle
        int     21h
        ; и записываем
        mov     ah,40h
        mov     bx,cs:fhandle2
        int     21h
        jc      error
        mov     ax,cs
        mov     ds,ax

        ; подкорректируем заголовок у asd.exe
        mov     relotabl,1ch
        mov     relo_cnt,0
;        mov     size_hand,2
        mov     ax,4200h
        xor     dx,dx
        xor     cx,cx
        mov     bx,fhandle
        int     21h

        mov     dx,offset beg_file
        mov     cx,hand_size
        mov     ah,40h
        mov     bx,fhandle
        int     21h
        jc      error

        ; закрыть файлы
        mov     ah,3eh
        mov     bx,fhandle
        int     21h

        mov     ah,3eh
        mov     bx,fhandle2
        int     21h
quit:
        mov     ax,4c00h
        int     21h

error:  mov     ah,9
        mov     dx,offset err_msg1
        int     21h
        mov     ax,4c01h
        int     21h

err_msg1   db      7,'Load error',13,10,36
hello      db      'End of handle',13,10,36
path        db      'asd.exe',0
tail_file   db      'tail.com',0
comm_line   db      0,0
epb         dw      0
cmd_off     dw      ?
cmd_seg     dw      ?
fcb1        dd      ?
fcb2        dd      ?
_sp         dw      ?
_ss         dw      ?
_ip         dw      ?
_cs         dw      ?
tec_comm    dw      0
buf_file    db      'call16.dat',0
fhandle     dw      ?
fhandle2    dw     ?
;-----------------------------------------
beg_file    label   byte
sign        dw      ?
last_bytes  dw      ?
page_cnt    dw      ?
relo_cnt    dw      ?
size_hand   dw      ?
            dw      ?
            dw      ?
beg_stack   dd      ?
            dw      ?
beg_offs    dd      ?
relotabl    dw      ?
hand_size  = $ - beg_file
;-----------------------------------------
corect      dd      ?
corect_offs dw      ?
first_addr  dd      ?
first_segm  dw      ?
pass_count  dw      0
count_offs  dw      ?
membl       dw      ?
;-----------------------------------------
int1    proc

        mov     cs:m_bp,bp
        mov     cs:m_es,es
        mov     cs:m_si,si
        mov     cs:m_eax,eax

        mov     bp,sp
        mov     si,[bp]
        mov     es,[bp+2]

        cmp     cs:int_fl,1
        jne     comp
        mov     eax,[bp]
        cmp     eax,cs:return
        jne     comp
        mov     cs:int_fl,0
        ; проверка на команду, изменяющую 2-ой (старший) байт флагов
comp:
        xor     ax,ax
        cmp     byte ptr es:[si],0cfh
        je      c_iret
        cmp     byte ptr es:[si],09dh
        je      c_popf
        cmp     byte ptr es:[si],066h    ; префикс 32-го кода
        jne     int_comp
        inc     si
        mov     ax,0ffffh
        jmp  short comp
int_comp:
        cmp     byte ptr es:[si],0cdh
        je      c_int

        cmp     byte ptr es:[si],0e8h  ; call rel16
        je      c_comm
        jmp     pass

c_iret:
        or      ax,ax                    ; 32 code ?
        jnz     c_iretd
        mov     si,11
        jmp  store
c_iretd:
        mov     si,21
        jmp store
c_popf:
        or      ax,ax
        jnz     c_popfd
        mov     si,7
        jmp store
c_popfd:
        mov     si,13
        jmp  store
c_int:
        inc     si
        xor     ax,ax
        mov     al,es:[si]
        shl     al,1
        shl     al,1
        xor     si,si
        mov     si,ax
        xor     ax,ax
        mov     es,ax
        mov     ax,es:[si]
        mov     word ptr cs:OldHandler,ax
        mov     ax,es:[si+2]
        mov     word ptr cs:OldHandler+2,ax
        cli
        mov     word ptr es:[si],offset handler
        mov     es:[si+2],cs
        sti
        mov     cs:num,si
        jmp  short pass

c_comm:
;        cmp     cs:int_fl,1
;        je      c_call_pass
        mov     ax,si
        shr     ax,4
        mov     bp,es
        add     ax,bp
        cmp     ax,cs:beg_seg
        ja      test2
        jmp short pass
test2:
        cmp     ax,cs:end_seg
        jb      mark_it
        jmp short pass

mark_it:
        cmp     cs:tec_comm,max_comm
        jae     c_comm_pass         ; переполнен буфер
        mov     bp,si
        inc     si
        mov     ax,es:[si]         ; получение адреса
        ; проверка на данный адрес в буфере
        cmp     cs:tec_comm,0
        je      non_ord
        xor     si,si
comm_find:
        push    si
        push    ax dx
        mov     ax,6
        mul     si
        mov     si,ax
        pop     dx ax
        cmp     cs:comm_buf[si].rel16,ax
        jne     nxt_ord
        pop     si
        jmp     c_comm_pass
nxt_ord:
        pop     si
        inc     si
        cmp     si,cs:tec_comm
        jb      comm_find
; занесение адреса комманды и адреса просцедуры в буфер
non_ord:
        mov     si,cs:tec_comm
        push    ax dx
        mov     ax,6
        mul     si
        mov     si,ax
        pop     dx ax
        mov     cs:comm_buf[si].offs,bp
        mov     cs:comm_buf[si].segm,es
        mov     cs:comm_buf[si].rel16,ax
        inc     cs:tec_comm
c_comm_pass:
        jmp  short pass
store:
        or      byte ptr [bp+si],1
pass:
    ; индикация
        mov     ax,0b800h
        mov     es,ax
        inc     cs:count
        mov     al,cs:count
        mov     es:[0],al

        mov     bp,cs:m_bp
        mov     es,cs:m_es
        mov     si,cs:m_si
        mov     eax,cs:m_eax

        iret

m_bp    dw      0
m_es    dw      0
m_si    dw      0
m_eax   dd      0
count   db      0
num     dw      0
OldHandler dd   0
int_fl  dw      0
beg_seg dw      0
end_seg dw      0
int1    endp

handler  proc

        mov     cs:m2_bp,bp
        mov     cs:m2_es,es
        mov     cs:m2_si,si
        mov     cs:m2_eax,eax
        mov     bp,sp
;----------------------------------------
        mov     cs:int_fl,1
        mov     eax,[bp]
        mov     cs:return,eax
;----------------------------------------

        or      byte ptr [bp+5],1
        mov     si,cs:num
        xor     ax,ax
        mov     es,ax

        cli
        mov     ax,word ptr cs:OldHandler
        mov     es:[si],ax
        mov     ax,word ptr cs:OldHandler+2
        mov     es:[si+2],ax
        sti

        pushf
        pop     ax
        or      ah,1
        push    ax
        popf

        mov     bp,cs:m2_bp
        mov     es,cs:m2_es
        mov     si,cs:m2_si
        mov     eax,cs:m2_eax

        jmp dword ptr cs:OldHandler

m2_bp    dw      0
m2_es    dw      0
m2_si    dw      0
m2_eax   dd      0
return   dd    ?
handler  endp

dummy    proc

         iret
dummy    endp

findmem  proc
         push   bx cx si di es

         mov    ah,52h
         int    21h
         mov    si,es:[bx-2]
         mov    membl,si
         mov    es,si

rep_find:
         cmp    byte ptr es:[0],'M'
         je     next_find
         ; ошибка
         mov    ah,9
         mov    dx,offset err_msg10
         int    21h

         mov    ax,4cffh
         int    21h
err_msg10  db   'Отсутствует имя ASD в памяти',13,10,36

next_find:
         cmp    word ptr es:[1],0
         je     move_next
         mov    di,8
         mov    si,offset path
         mov    cx,name_len
         rep cmpsb
         jcxz   end_find
         ; переход на слудующий блок
move_next:
         mov    bx,es
         add    bx,es:[3]
         inc    bx
         mov    es,bx
         jmp short rep_find
end_find:
         mov    bx,es
         mov    beg_seg,bx
         inc    bx
         mov    si,bx
         mov    bx,es:[3]
         add    bx,si
         mov    end_seg,bx

         pop    es di si cx bx
         ret
findmem  endp

comm_buf    Tcomm   max_comm dup(?)

last        db      ?
        end


