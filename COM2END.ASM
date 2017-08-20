;▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
;▒▒                                                          ▒▒
;▒▒               Com2end.com                                ▒▒
;▒▒  Предназначена для приписывания COM-файла к исполняемому ▒▒
;▒▒  файлу EXE или COM типа. Входит в комплект защиты от     ▒▒
;▒▒  копирования DEFENCE.                                    ▒▒
;▒▒                      (C) 1996  Колищак А.Н.              ▒▒
;▒▒                                                          ▒▒
;▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
        MODEL tiny
        .CODE
        .386p
        org     80h
dta     label   byte
com_siz db      ?
probel  db      ?
com_par db      ?
        .startup
      jmp     test_par
; переменные
type_t  db      ?                   ; тип расширения target
len_s   dw      ?                   ; длина файла source_file
len_t_1 dw      ?                   ; длина файла target_file
len_t_2 dw      ?                   ; длина файла target_file
hand_1  dw      ?                   ; обработка файла source_file
hand_2  dw      ?                   ; обработка файла target_file
NameTarOff  dw  ?                   ; смещение имени target
NameSouOff  dw  ?                   ; смещение имени source
; допустимые расширения
ext_a   db      'com','exe'
;  выводимые сообщения
mbad_use db     'Используйте COM2END без параметров для помощи.',10,13,36
; Если пустая коммандная строка
syn      db     'COM2END <target_file>  <source_file>',10,13,36
;--------------------
mbad_1   db     'Ошибка: Плохой файл target_file.'
         db     'Расширение должно быть com или exe',10,13,36

mmis_2   db     'Ошибка: Пропущен файл source_file.',10,13,36
mbad_2   db     'Ошибка: Плохой файл source_file'
         db     'Расширение должно быть com',10,13,36
mn_op_1  db     'Ошибка открытия файла target_file',10,13,36
mn_op_2  db     'Ошибка открытия файла source_file',10,13,36
mn_mov_2 db     'Ошибка при перемещении указателя в файле'
         db     'source_file',10,13,36
mn_mov_1 db     'Ошибка при перемещении указателя в файле'
         db     'target_file',10,13,36
mn_r_1   db     'Ошибка чтения файла source_file',10,13,36
mn_r_2   db     'Ошибка чтения файла target_file',10,13,36
mn_w_1   db     'Ошибка записи в файл source_file',10,13,36
mn_w_2   db     'Ошибка записи в файл target_file',10,13,36
mn_cl_1  db     'Ошибка закрытия файла target_file',10,13,36
mn_cl_2  db     'Ошибка закрытия файла source_file',10,13,36
m_Ok     db     'Обработка завершена',10,13,36
;  начало программы
test_par:
;  1. Проверка параметров в коммандной строке
;     1.1 Найти первый отличный от пробела символ в
;         коммандной строке
         lea    si,dta+1
l_0:
         cmp    byte ptr [si],0dh
         je     c_syn
         cmp    byte ptr [si],' '
         jne    not_prob
         inc    si
         jmp short l_0
; сообщение с подсказкой
c_syn:
         mov    ah,9
         lea    dx,syn
         int    21h
         mov    ax,4c01h
         int    21h
use:
         mov    ah,9
         lea    dx,mbad_use
         int    21h
         mov    ax,4c01h
         int    21h
not_prob:
; 1.2. Первый параметр правильный ?
         mov    NameTarOff,si       ; запомнить начало имени target
;  поиск начала расширения
l_1:
         cmp    byte ptr [si],0dh
         je     c_b_1_m_2
         cmp    byte ptr [si],' '
         je     c_b_1
         cmp    byte ptr [si],'.'
         je     d_t_1
         inc    si
         jmp short l_1
; нет ни точки, ни пробела в командной строке
c_b_1_m_2:
         mov    ah,9
         lea    dx,mbad_1
         int    21h
         lea    dx,mmis_2
         int    21h
         jmp    use
; недопустимое расширение у файла target_file
c_b_1:
         mov    ah,9
         lea    dx,mbad_1
         int    21h
         jmp    use
; анлиз расширения
d_t_1:
         inc    si
         call   det_type
         pop    ax
         mov    type_t,al           ; сохранить
         cmp    ax,2
         je     c_b_1
         add    si,3                ; установка нуля для ASCIIZ
         lea    cx,dta              ; конец коммандной строки
         add    cl,byte ptr dta
         adc    ch,0
         cmp    cx,si               ; конец ?
         jbe    c_m_2               ; да
         mov    byte ptr [si],0
; второй параметр правильный ?
l_2:
         inc    si
         cmp    cx,si               ; конец коммандной строки ?
         jb     c_m_2               ; да
         cmp    byte ptr [si],' '
         je     l_2
         mov    NameSouOff,si        ; запомнить начало
l_3:
         cmp    byte ptr [si],'.'    ; расширение
         je     d_t_2
         inc    si
         cmp    cx,si                ; конец ?
         jb     c_b_2
         jmp short l_3
; отсутствует файл source_file
c_m_2:
         mov    ah,9
         lea    dx,mmis_2
         int    21h
         jmp    use
d_t_2:
         inc    si
         call   det_type
         pop    ax
         cmp    ax,0
         je     test_end            ; может быть
c_b_2:
         mov    ah,9
         lea    dx,mbad_2
         int    21h
         jmp    use
test_end:
         add    si,2                ; расширение входит
                                    ; в коммандную строку ?
         cmp    cx,si
         jb     c_b_2
         mov    byte ptr [si+1],0   ; для ASCIIZ
; 2. Открыть, определить длину и прочитать в буфер
; файл source_file
open_f:
;      2.1. Открыть
         mov    ah,3dh              ; open file
         mov    al,2
         mov    dx,NameSouOff
         int    21h
         jnc    yes_open
         mov    ah,9
         lea    dx,mn_op_2
         int    21h
         int    20h
yes_open:
;      2.2. Определить длину
         mov    bx,ax               ; handler
         mov    hand_2,ax
         mov    ax,4202h
         xor    cx,cx
         xor    dx,dx
         int    21h
         jnc    yes_p_1
cn_mov_2:
         mov    ah,9
         lea    dx,mn_mov_2
         int    21h
         int    20h
;      2.3. Читать в буфер
yes_p_1:
         mov    word ptr len_s,ax   ; сохранить длину
         mov    ax,4200h
         xor    cx,cx
         xor    dx,dx
         int    21h
         jc     cn_mov_2
; читать
         mov    ah,3fh
         lea    dx,buff
         mov    cx,word ptr len_s
         int    21h
         jnc    open_targ
         mov    ah,9
         lea    dx,mn_r_1
         int    21h
         int    20h
; 3. Открыть файл target_file
open_targ:
         mov    ah,3dh
         mov    al,2
         mov    dx,NameTarOff
         int    21h
         jnc    det_len_1
         mov    ah,9
         lea    dx,mn_op_1
         int    21h
         int    20h
; определить длину
det_len_1:
         mov    hand_1,ax           ; сохранить обработчик
         mov    bx,hand_1
         mov    ax,4202h
         xor    cx,cx
         xor    dx,dx
         int    21h
         jnc    rest_len
         jmp    cn_mov_1
rest_len:
         mov    len_t_1,dx
         mov    len_t_2,ax
; 4. Если файл target_file - com, то call wr2com.
;    Если файл target_file - exe, то call wr2exe.
to_proc:
         cmp     type_t,0           ; com ?
         je      c_com
         call    wr2exe
         jmp short close_f
c_com:
         call    wr2com
; 5. Закрыть файлы
close_f:
         mov     ah,3eh
         mov     bx,hand_1
         int     21h
         jnc     cl_2
         mov     ah,9
         lea     dx,mn_cl_1
         int     21h
         int     20h
cl_2:
         mov    ah,3eh
         mov    bx,hand_2
         int    21h
         jnc    Ok
         mov    ah,9
         lea    dx,mn_cl_2
         int    21h
         int    20h

; 6. Конец обработки
Ok:
         mov    ah,9
         lea    dx,m_Ok
         int    21h
         mov    ax,4c00h
         int    21h


;▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
;
;                  Подпрограммы
;
;▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒

;    det_type
; Вход:
;      ds:si  - расширение файла
; Выход:
;      в стеке 0, если com
;              1, если exe
;              2, если другое расширение
;
det_type     proc
         mov    bp,sp
         push   ax cx di
         xor    ax,ax
         lea    di,ext_a
loo_1:
         push   si di
         mov    cx,3
         repe   cmpsb
         jne    end_loo_1
         pop    di si
         mov    [bp+2],ax
         jmp    d_ret
end_loo_1:
         inc    al
         pop    di
         add    di,3                ; следующий 3-байтный элемент
         pop    si
         cmp    al,2
         jb     loo_1
         mov    [bp+2],ax
d_ret:
         pop    di cx ax
         ret
det_type     endp
;---------------------------------------
;          wr2exe
;---------------------------------------
wr2exe   proc
         push ax bx cx dx si di
         jmp    st_2exe
;----------переменные---------------
;len_t_o dw     ?
;len_t_n dw     ?
;-----------------------------------
;   заголовок exe-файла
hdr      label  byte
         dw     ?
PartPag  dw     ?
PageCnt  dw     ?
         dw     ?
HdrSize  dw     ?
         dw     ?
         dw     ?
beg_ss   dw     ?
beg_sp   dw     ?
         dw     ?
ExeIP    dw     ?
ReloCS   dw     ?
len_hdr  equ    $-hdr
; команды, записываемые в конец файла
; команды записи в стек адреса начала exe-файла:
imit     label  byte
         mov    al,0ffh
         out    21h,al
         mov    ax,es
i_1:     add    ax,0                ; для параметра ReloCS
         add    ax,10h
         push   ax
i_2:     mov    ax,0                ; для параметра ExeIP
         push   ax
; команды передачи управления source-файлу, как и для
; com-файла:
         mov    ax,100h
         push   ax
         ret
len_imit        equ     $-imit
; 1. Читать заголовок exe-файла
;    1.1. Установить указатель на начало файла
st_2exe:
         mov    ax,4200h
         mov    bx,hand_1
         xor    cx,cx
         xor    dx,dx
         int    21h
         jc     cn_mov_1
;  читать
         mov    ah,3fh
         lea    dx,hdr
         mov    cx,len_hdr
         int    21h
         jnc    prep_end
cn_r_1:
         mov    ah,9
         lea    dx,mn_r_1
         int    21h
         int    20h
; 2. Настроить команды, дописываемые в конец файла
;    target_file
prep_end:
;    2.1. Записать в стек адреса начала exe-файла
         mov    ax,ReloCS
         mov    word ptr i_1[1],ax
         mov    ax,ExeIP
         mov    word ptr i_2[1],ax
;    2.2. Передать управление файлу source_file
;         для com-файла настройка не нужна
; 3. Записать команды в конец exe-файла
;      загрузить в регистры cx:dx длину файла
         mov    cx,len_t_1
         mov    dx,len_t_2
         mov    si,cx               ; si:di = cx:dx
         mov    di,dx
;      указатель в конец
         mov    ax,4200h
         mov    bx,hand_1
         int    21h
         jnc    yes_wr
cn_mov_1:
         mov    ah,9
         lea    dx,mn_mov_1
         int    21h
         int    20h
yes_wr:
;      записать
         mov    ah,40h
         lea    dx,imit
         mov    cx,len_imit
         int    21h
         jnc    wr_sour
cn_w_1:
         mov    ah,9
         lea    dx,mn_w_1
         int    21h
         int    20h
wr_sour:
; 4. Записать файл source_file в конец exe-файла, начиная с
;    границы параграфа
; Загрузить в регистры cx:dx длину файла, выровненную на
;    границу параграфа
         mov    cx,si               ; восстановить длину
         mov    dx,di
         add    dx,len_imit
         jnc    m1
         inc    cx
m1:
         add    dx,15               ; выровнять на границу параграфа
         jnc    m2
         inc    cx
m2:
         and    dx,0fff0h
         mov    si,cx               ; сохранить
         mov    di,dx
;   установить указатель на конец файла, начиная с
;   границы параграфа
         mov    ax,4200h
         int    21h
         jc     cn_mov_1
;    записать
         mov    ah,40h
         lea    dx,buff
         mov    cx,len_s
         int    21h
         jc     cn_w_1
; 5. Определить поля нового загаловка
;           ReloCS
         mov    ax,si               ; восстановить
         mov    bx,di
         add    bx,ax
         mov    cl,4
         ror    bx,cl
         sub    bx,10h
         sub    bx,HdrSize
         mov    ReloCS,bx

;           ExeIP
;         mov    ax,PartPag
;         and    ax,000fh            ; остаток от деления
;                                    ; PartPag на 16
;         mov    bx,ax               ; сохранить остаток
;         add    ax,len_imit
;         add    ax,15
;         and    ax,0fff0h           ; число параграфов
;         add    bx,100h
;         sub    bx,ax
;         mov    ExeIP,bx
;--------------------------------------------------------
          movzx  eax,len_t_1
          shl    eax,16
          mov    ax,len_t_2
          movzx  ebx,ReloCS
          shl    ebx,4
          sub    eax,ebx
          movzx  ebx,HdrSize
          shl    ebx,4
          sub    eax,ebx
          mov    ExeIP,ax

;           PageCnt, PartPag
         mov    ax,si               ; восстановить
         mov    bx,di
         add    bx,len_s            ; новая длина
         jnc    m3
         inc    ax
m3:
;           PartPag
         mov    dx,bx               ; сохранить
         and    dx,1ffh
         mov    PartPag,dx
;           PageCnt
         add    bx,511
         jnc    m4
         inc    ax
m4:
         and    bh,0feh
         mov    ah,bh
         mov    cl,9
         ror    ax,cl
         mov    PageCnt,ax
;------------------------------------------------------
   ; настроить стек
         mov    ax,ExeIp
         mov    dx,ReloCS
         add    ax,len_s
         jnc    ord1
         add    dx,1000h
ord1:
         add    ax,256
         jnc    ord2
         add    dx,1000h
ord2:
         mov    beg_ss,dx
         mov    beg_sp,ax
;------------------------------------------------------
; 6. Записать настроенный загаловок в начало exe-файла.
;    Установить указатель на начало файла
         mov    ax,4200h
         mov    bx,hand_1
         xor    cx,cx
         xor    dx,dx
         int    21h
         jnc    write_1
         jmp    cn_mov_1
;      Записать
write_1:
         mov    ah,40h
         lea    dx,hdr
         mov    cx,len_hdr
         int    21h
         jnc    m_ret
         jmp    cn_w_1
m_ret:
         pop di si dx cx bx ax
         ret
wr2exe   endp
;---------------------------------------
;        wr2com
;---------------------------------------
wr2com   proc
         jmp    st_2com
; Код, который настраивается и записывается в начало файла
new_beg  label  byte
         mov    ax,cs
c_1:     add    ax,0                ; +TOP((len_t_2+len_im)/16)*16,
         push   ax                  ; где TOP(x) - наименьшее целое,
                                    ; не меньшее x,
c_2:     mov    ax,0                ; +100h+x-TOP((x+len_im)/16)*16,
         push   ax                  ; где x - остаток от деления
                                    ; len_t_2 на 16
         retf
len_new_beg     equ      $-new_beg
; код, который записывается в конец файла target_file
com      label  byte
         mov    di,100h
         push   cs
         pop    ds                  ; адресация для пересылки
; вычислить si=100h-(MOD16(16-MOD16(len_t_2+len_im))+len_new_beg)
c_3:     mov    ax,0                ; + len_t_2
c_4:     add    ax,0                ; + len_im
         and    ax,000fh            ; остаток от деления на 16
         mov    bx,16
         sub    bx,ax               ; число байтов до конца
                                    ; параграфа
         and    bx,000fh            ; не больше 15, если 16, то 0
         add    bx,len_new_beg      ; смещение от начала
                                    ; source "начала"
         mov    ax,100h
         sub    ax,bx               ; смещение "начала" от
                                    ; адреса на регистре CS
         mov    si,ax
         mov    cx,len_new_beg
         rep    movsb
         push   es
         pop    ds
; занести в стек адрес начала файла  target_file
         push   es
         mov    ax,100h
         push   ax
; передать управление файлу source_file
         push   ax
         ret
len_com  equ    $-com
old_beg  label  byte
         db     len_new_beg  dup(?)
len_im   equ    $-com

; 1. Читать (сохранить) len_new_beg байт файла
;    target_file в области old_beg_file
; указатель на начало
st_2com:
         mov    bx,hand_1
         mov    ax,4200h
         xor    cx,cx
         xor    dx,dx
         int    21h
         jnc    read_beg
         jmp    cn_mov_2
; читать
read_beg:
         mov    ah,3fh
         lea    dx,old_beg
         mov    cx,len_new_beg
         int    21h
         jnc    prep_beg
         jmp    cn_r_1
; 2. Подготовить новое начало файла
prep_beg:
         mov    ax,len_t_1          ; восстановить длину
         mov    bx,len_t_2
         add    bx,len_im
         jnc    pr1
         inc    ax
pr1:
         add    bx,15
         and    bx,0fff0h
         add    bx,ax
         mov    cl,4
         ror    bx,cl
         mov    word ptr c_1[1],bx
         mov    ax,len_t_2
         and    ax,000fh
         mov    bx,ax               ; сохранить
         add    ax,len_im
         add    ax,15
         and    ax,0fff0h
         add    bx,100h
         sub    bx,ax
         mov    word ptr c_2[1],bx
; 3. Записать новое начало в файл target_file
; указатель в начало
         mov    bx,hand_1
         mov    ax,4200h
         xor    cx,cx
         xor    dx,dx
         int    21h
         jnc    wr_beg
         jmp    cn_mov_2
; записать
wr_beg:
         mov    ah,40h
         lea    dx,new_beg
         mov    cx,len_new_beg
         int    21h
         jnc    prep_C_end
         jmp    cn_w_1
; 4. Подготовить код, который записать в конец файла
prep_C_end:
         mov    ax,len_t_2
         mov    word ptr c_3[1],ax
         mov    word ptr c_4[1],len_im
; 5. Записать подготовленный код в конец файла target_file
;   указатель в конец
         mov    bx,hand_1
         mov    ax,4200h
         mov    cx,len_t_1
         mov    dx,len_t_2
         int    21h
         jnc    wr_end
         jmp    cn_mov_2
;  записать
wr_end:
         mov    ah,40h
         lea    dx,com
         mov    cx,len_im
         int    21h
         jnc    cal_b
         jmp    cn_w_1
; 6. Записать source, начиная с границы параграфа
; вычислить границы
cal_b:
         mov    cx,len_t_1
         mov    dx,len_t_2
         add    dx,len_im
         jnc    cal_1
         inc    cx
cal_1:
         add    dx,15
         jnc    cal_2
         inc    cx
cal_2:
         and    dx,0fff0h
; указатель на границу
         mov   bx,hand_1
         mov   ax,4200h
         int   21h
         jnc   wr_sr
         jmp   cn_mov_2
wr_sr:
         mov    ah,40h
         lea    dx,buff
         mov    cx,len_s
         int    21h
         jnc    end_2com
         jmp    cn_w_1
end_2com:
         ret
         ret
wr2com   endp


buff    label   byte

        end


