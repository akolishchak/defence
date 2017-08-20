
        MODEL tiny
        .CODE
        .STARTUP

        .386

        mov     ax,3d00h
        mov     dx,offset path
        int     21h
        jc      error
        mov     fhandle,ax

        mov     ah,3fh
        mov     dx,offset beg_file
        mov     cx,hand_size
        mov     bx,fhandle
        int     21h

        movzx   eax,page_cnt
        mov     ebx,512
        mul     ebx
        movzx   ebx,last_bytes
        sub     eax,ebx
        mov     sizef,eax

        mov     ax,4202h
        mov     bx,fhandle
        xor     cx,cx
        xor     dx,dx
        int     21h

        shl     edx,16
        mov     dx,ax

        cmp     edx,sizef
        jne     error

next_comp1:
        mov     ax,4c00h
        int     21h
error:
        mov     ax,4c77h
        int     21h
sizef   dd      ?
fhandle dw      ?
path    db      'asd.exe',0
;-----------------------------------------
beg_file    label   byte
sign        dw      ?
last_bytes  dw      ?
page_cnt    dw      ?
relo_cnt    dw      ?
size_hand   dw      ?
            dw      ?
            dw      ?
beg_ss      dw      ?
beg_sp      dw      ?
            dw      ?
beg_offs    dd      ?
relotabl    dw      ?
hand_size  = $ - beg_file
;-----------------------------------------
        end


