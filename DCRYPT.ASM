
.286c
data_1e         equ     4
data_2e         equ     0Ch
data_3e         equ     46Ch
PSP_cmd_tail    equ     81h
data_48e        equ     0FDFFh                  ;*
data_49e        equ     0FFE7h                  ;*


                MODEL tiny
                .CODE
                .STARTUP

main            proc

start:
                mov     ah,4Ah                  ; 'J'
                mov     bx,1000h
                int     21h                     ; DOS Services  ah=function 4Ah
                                                ;  change memory allocation
                                                ;   bx=bytes/16, es=mem segment
                mov     dx,6CEh
                call    info
                cmp     byte ptr ds:PSP_cmd_tail,0Dh
                je      loc_3                   ; Jump if equal
                cmp     byte ptr ds:PSP_cmd_tail+1,0Dh
                je      loc_3                   ; Jump if equal
                mov     cx,50h
                mov     di,PSP_cmd_tail+1
                mov     dx,di
                mov     al,20h                  ; ' '
                repne   scasb                   ; Rep zf=0+cx >0 Scan es:[di] for al
                dec     di
                xor     al,al                   ; Zero register
                stosb                           ; Store al to es:[di]
                mov     cx,50h
                mov     di,PSP_cmd_tail+1
                mov     dx,di
                mov     al,0Dh
                repne   scasb                   ; Rep zf=0+cx >0 Scan es:[di] for al
                dec     di
                xor     al,al                   ; Zero register
                stosb                           ; Store al to es:[di]
                test    cx,cx
                jnz     loc_1                   ; Jump if not zero
                jmp     short loc_ret_2
                db      90h
loc_1:
                mov     dx,7A5h
                call    info
                call    actions

loc_ret_2:
                ret
loc_3:
                mov     dx,74Eh
                call    info
                ret

main            endp

actions         proc    near
                call    mak_files
                mov     ax,3D00h
                mov     dx,PSP_cmd_tail+1
                int     21h                     ; DOS Services  ah=function 3Dh
                                                ;  open file, al=mode,name@ds:dx
                jnc     loc_4                   ; Jump if carry=0
                mov     dx,774h
                jmp     loc_10
loc_4:
                mov     bx,ax
                mov     data_45,ax
                mov     ah,3Fh                  ; '?'
                mov     dx,offset data_34
                mov     cx,1Ch
                int     21h                     ; DOS Services  ah=function 3Fh
                                                ;  read file, bx=file handle
                                                ;   cx=bytes to ds:dx buffer
                mov     di,offset data_30
                mov     si,PSP_cmd_tail+1
                mov     cx,80h

locloop_5:
                movsb                           ; Mov [si] to es:[di]
                cmp     byte ptr [di-1],2Eh     ; '.'
                loopnz  locloop_5               ; Loop if zf=0, cx>0

                cmp     data_34,4D5Ah
                je      loc_6                   ; Jump if equal
                cmp     data_34,5A4Dh
                je      loc_6                   ; Jump if equal
                mov     si,7E7h
                jmp     short loc_7
loc_6:
                mov     si,offset data_32
loc_7:
                mov     cx,3
                rep     movsb                   ; Rep when cx >0 Mov [si] to es:[di]
                mov     ah,3Ch                  ; '<'
                mov     dx,offset tempfile
                xor     cx,cx                   ; Zero register
                int     21h                     ; DOS Services  ah=function 3Ch
                                                ;  create/truncate file @ ds:dx
                mov     bx,ax
                mov     data_46,ax
                cmp     data_34,4D5Ah
                je      loc_8                   ; Jump if equal
                cmp     data_34,5A4Dh
                je      loc_8                   ; Jump if equal
                call    on_com
                jmp     short loc_9
loc_8:
                call    on_exe
loc_9:
                mov     ah,3Eh                  ; '>'
                mov     bx,data_45
                int     21h                     ; DOS Services  ah=function 3Eh
                                                ;  close file, bx=file handle
                mov     ah,3Eh                  ; '>'
                mov     bx,data_46
                int     21h                     ; DOS Services  ah=function 3Eh
                                                ;  close file, bx=file handle
                mov     ah,41h                  ; 'A'
                mov     dx,PSP_cmd_tail+1
                int     21h                     ; DOS Services  ah=function 41h
                                                ;  delete file, name @ ds:dx
                mov     ah,56h                  ; 'V'
                mov     dx,offset tempfile
                mov     di,PSP_cmd_tail+1
                int     21h                     ; DOS Services  ah=function 56h
                                                ;  rename file @ds:dx to @es:di
                mov     dx,7B1h
                call    info
                ret
                                                ;* No entry point to code
                mov     dx,74Eh
                call    info
                ret
loc_10:
                call    info
                int     20h                     ; DOS program terminate
actions         endp

on_exe          proc    near
                mov     ax,4202h
                xor     cx,cx                   ; Zero register
                xor     dx,dx                   ; Zero register
                mov     bx,data_45
                int     21h                     ; DOS Services  ah=function 42h
                                                ;  move file ptr, bx=file handle
                                                ;   al=method, cx,dx=offset
                mov     cx,200h
                div     cx                      ; ax,dx rem=dx:ax/reg
                test    dx,dx
                jz      loc_11                  ; Jump if zero
                inc     ax
loc_11:
                cmp     ax,data_36
                jne     loc_12                  ; Jump if not equal
                cmp     dx,data_35
                je      loc_13                  ; Jump if equal
loc_12:
                mov     dx,789h
                call    info
                mov     ah,3Eh                  ; '>'
                mov     bx,data_45
                int     21h                     ; DOS Services  ah=function 3Eh
                                                ;  close file, bx=file handle
                mov     ah,3Eh                  ; '>'
                mov     bx,data_46
                int     21h                     ; DOS Services  ah=function 3Eh
                                                ;  close file, bx=file handle
                mov     ah,41h                  ; 'A'
                mov     dx,offset tempfile
                int     21h                     ; DOS Services  ah=function 41h
                                                ;  delete file, name @ ds:dx
                int     20h                     ; DOS program terminate
loc_13:
                mov     ax,4200h
                xor     cx,cx                   ; Zero register
                mov     dx,data_44
                mov     bx,data_45
                int     21h                     ; DOS Services  ah=function 42h
                                                ;  move file ptr, bx=file handle
                                                ;   al=method, cx,dx=offset
                mov     cx,data_37
                imul    cx,cx,4                 ; reg1 = reg2 * value
                push    cx
                mov     ah,3Fh                  ; '?'
                mov     dx,offset data_47
                mov     bx,cs:data_45
                int     21h                     ; DOS Services  ah=function 3Fh
                                                ;  read file, bx=file handle
                                                ;   cx=bytes to ds:dx buffer
                mov     data_41,0
                mov     ax,data_37
                mov     word ptr ds:[4ABh],ax
                mov     data_37,0
                mov     ax,data_43
                mov     data_18,ax
                mov     ax,data_42
                mov     data_17,ax
                mov     data_44,1Ch
                mov     ax,data_39
                mov     data_20,ax
                mov     ax,data_40
                mov     data_21,ax
                push    data_38
                mov     cx,10h
                xor     dx,dx                   ; Zero register
                mov     ax,data_38
                mul     cx                      ; dx:ax = reg * ax
                mov     data_38,2
                mov     si,ax
                mov     di,dx
                mov     ax,4202h
                xor     dx,dx                   ; Zero register
                xor     cx,cx                   ; Zero register
                mov     bx,data_45
                int     21h                     ; DOS Services  ah=function 42h
                                                ;  move file ptr, bx=file handle
                                                ;   al=method, cx,dx=offset
                xor     bp,bp                   ; Zero register
                sub     ax,si
                sbb     dx,di
                shl     dx,0Ch                  ; Shift w/zeros fill
                test    ax,ax
                jz      loc_15                  ; Jump if zero
                mov     bx,dx
                xor     dx,dx                   ; Zero register
                mov     cx,10h
                div     cx                      ; ax,dx rem=dx:ax/reg
                test    dx,dx
                jz      loc_14                  ; Jump if zero
                inc     ax
                mov     bp,10h
                sub     bp,dx
loc_14:
                add     bx,ax
                mov     dx,bx
                xor     ax,ax                   ; Zero register
loc_15:
                mov     data_43,dx
                mov     data_42,ax
                add     ax,1A7h
                jnc     loc_16                  ; Jump if carry=0
                add     dx,1000h
loc_16:
                mov     data_39,dx
                mov     data_40,ax
                mov     ah,40h                  ; '@'
                mov     dx,offset data_34
                mov     cx,20h
                mov     bx,data_46
                int     21h                     ; DOS Services  ah=function 40h
                                                ;  write file  bx=file handle
                                                ;   cx=bytes from ds:dx buffer
                mov     ax,4200h
                xor     cx,cx                   ; Zero register
                pop     dx
                imul    dx,dx,10h               ; reg1 = reg2 * value
                mov     bx,data_45
                int     21h                     ; DOS Services  ah=function 42h
                                                ;  move file ptr, bx=file handle
                                                ;   al=method, cx,dx=offset
                mov     ah,48h                  ; 'H'
                mov     bx,0FFFh
                int     21h                     ; DOS Services  ah=function 48h
                                                ;  allocate memory, bx=bytes/16
                mov     ds,ax
                mov     es,ax
loc_17:
                mov     ax,0E2Eh
                mov     ax,ax                      ; Video display   ah=functn 0Eh
                                                ;  write char al, teletype mode
                mov     ah,3Fh                  ; '?'
                xor     dx,dx                   ; Zero register
                mov     cx,0F000h
                mov     bx,cs:data_45
                int     21h                     ; DOS Services  ah=function 3Fh
                                                ;  read file, bx=file handle
                                                ;   cx=bytes to ds:dx buffer
                mov     cx,ax
                pusha                           ; Save all regs
                xor     di,di                   ; Zero register
                xor     si,si                   ; Zero register
                mov     ah,1
                jcxz    loc_20                  ; Jump if cx=0

locloop_18:
                lodsb                           ; String [si] to al
                add     cs:data_19,al
                xor     al,ah
                rol     ah,3                    ; Rotate
                add     ah,cl
                stosb                           ; Store al to es:[di]
                add     word ptr cs:[40Ah],1
                cmp     word ptr cs:[40Ah],0F000h
                jne     loc_19                  ; Jump if not equal
                add     word ptr cs:[40Dh],1
                mov     word ptr cs:[40Ah],0
loc_19:
                loop    locloop_18              ; Loop if cx > 0

loc_20:
                popa                            ; Restore all regs
                mov     cx,ax
                mov     ah,40h                  ; '@'
                mov     bx,cs:data_46
                int     21h                     ; DOS Services  ah=function 40h
                                                ;  write file  bx=file handle
                                                ;   cx=bytes from ds:dx buffer
                test    ax,ax
                jnz     loc_17                  ; Jump if not zero
                mov     ah,49h
                int     21h                     ; DOS Services  ah=function 49h
                                                ;  release memory block, es=seg
                push    cs
                pop     ds
                push    cs
                pop     es
                mov     ah,40h                  ; '@'
                mov     cx,bp
                mov     bx,data_46
                int     21h                     ; DOS Services  ah=function 40h
                                                ;  write file  bx=file handle
                                                ;   cx=bytes from ds:dx buffer
                mov     ah,40h                  ; '@'
                mov     dx,offset exe_input
                mov     cx,1A7h
                mov     bx,data_46
                int     21h                     ; DOS Services  ah=function 40h
                                                ;  write file  bx=file handle
                                                ;   cx=bytes from ds:dx buffer
                pop     cx
                push    cx
                jcxz    loc_22                  ; Jump if cx=0
                mov     ax,cx
                xor     dx,dx                   ; Zero register
                mov     cx,4
                div     cx                      ; ax,dx rem=dx:ax/reg
                mov     cx,ax
                mov     si,offset data_47
                mov     di,si
                mov     bx,cx

locloop_21:
                lodsw                           ; String [si] to ax
                xor     ax,bx
                stosw                           ; Store ax to es:[di]
                lodsw                           ; String [si] to ax
                xor     ax,bx
                stosw                           ; Store ax to es:[di]
                rol     bx,cl                   ; Rotate
                add     bx,cx
                loop    locloop_21              ; Loop if cx > 0

loc_22:
                mov     ah,40h                  ; '@'
                pop     cx
                mov     dx,offset data_47
                mov     bx,data_46
                int     21h                     ; DOS Services  ah=function 40h
                                                ;  write file  bx=file handle
                                                ;   cx=bytes from ds:dx buffer
                mov     ax,4202h
                xor     cx,cx                   ; Zero register
                xor     dx,dx                   ; Zero register
                int     21h                     ; DOS Services  ah=function 42h
                                                ;  move file ptr, bx=file handle
                                                ;   al=method, cx,dx=offset
                mov     cx,200h
                div     cx                      ; ax,dx rem=dx:ax/reg
                inc     ax
                mov     data_35,dx
                mov     data_36,ax
                mov     ax,4200h
                xor     cx,cx                   ; Zero register
                xor     dx,dx                   ; Zero register
                int     21h                     ; DOS Services  ah=function 42h
                                                ;  move file ptr, bx=file handle
                                                ;   al=method, cx,dx=offset
                mov     ah,40h                  ; '@'
                mov     dx,offset data_34
                mov     cx,20h
                int     21h                     ; DOS Services  ah=function 40h
                                                ;  write file  bx=file handle
                                                ;   cx=bytes from ds:dx buffer
                ret
on_exe           endp
; \AA\E3᮪, \A4\AE\AF\A8\E1뢠\A5\AC\EB\A9 \AA exe 䠩\AB\E3
;-----------------------------------------------------------------------
exe_input         db      0Eh
                db       17h, 9Ch, 58h,0F6h,0C4h, 01h
                db       74h, 03h,0E9h, 98h, 00h
loc_23:
                push    ds
                mov     al,2
                out     21h,al                  ; port 21h, 8259-1 int comands
                mov     dx,ds
                add     dx,10h
                mov     ds,dx
                mov     es,dx
                mov     bx,0
                mov     dx,0
                test    dx,dx
                jz      loc_26                  ; Jump if zero
loc_24:
                mov     ah,1
                xor     di,di                   ; Zero register
                xor     si,si                   ; Zero register
                mov     cx,0F000h

locloop_25:
                lodsb                           ; String [si] to al
                xor     al,ah
                rol     ah,3                    ; Rotate
                add     ah,cl
                add     byte ptr cs:[122h],al
                stosb                           ; Store al to es:[di]
                loop    locloop_25              ; Loop if cx > 0

                mov     ax,ds
                add     ax,0F00h
                mov     ds,ax
                mov     es,ax
                dec     dx
                test    dx,dx
                jz      loc_26                  ; Jump if zero
                jmp     short loc_24
loc_26:
                pusha                           ; Save all regs
                mov     ah,30h
                int     21h                     ; DOS Services  ah=function 30h
                                                ;  get DOS version number ax
                cmp     al,2
                jae     loc_27                  ; Jump if above or =
                xor     ax,ax                   ; Zero register
                push    es
                push    ax
                retf                            ; Return far
loc_27:
                popa                            ; Restore all regs
                mov     ah,1
                xor     di,di                   ; Zero register
                xor     si,si                   ; Zero register
                mov     cx,bx

locloop_28:
                lodsb                           ; String [si] to al
                xor     al,ah
                rol     ah,3                    ; Rotate
                add     ah,cl
                add     byte ptr cs:[122h],al
                stosb                           ; Store al to es:[di]
                loop    locloop_28              ; Loop if cx > 0

                mov     bx,data_3e
                mov     ax,111h
                xor     di,di                   ; Zero register
                mov     es,di
                mov     byte ptr es:[bx],0
                mov     di,data_2e
                stosw                           ; Store ax to es:[di]
                mov     ax,cs
                stosw                           ; Store ax to es:[di]
                mov     ax,0ACh
                mov     di,data_1e
                stosw                           ; Store ax to es:[di]
                mov     ax,cs
                stosw                           ; Store ax to es:[di]
                cmp     byte ptr es:[bx],0
                jne     loc_29                  ; Jump if not equal
                db       2Eh, 9Ch, 58h, 9Eh, 72h, 05h
                db       80h,0F4h, 01h, 50h, 9Dh
loc_29:
                mov     al,0FEh
                out     64h,al                  ; port 64h, kybd cntrlr functn
                                                ;  al = 0FEh, pulse CPU reset
                xor     cx,cx                   ; Zero register

locloop_30:
                loop    locloop_30              ; Loop if cx > 0

                push    cs
                pop     ds
                mov     bx,1A4h
                mov     [bx],bh
                sub     [bx],bh
                jnz     loc_29                  ; Jump if not zero
                int     3                       ; Debug breakpoint
                add     sp,6
                mov     cx,0
                mov     si,1A7h
                pop     dx
                push    dx
                add     dx,10h
                mov     bx,cx
                jcxz    loc_32                  ; Jump if cx=0

locloop_31:
                lodsw                           ; String [si] to ax
                xor     ax,bx
                mov     di,ax
                lodsw                           ; String [si] to ax
                xor     ax,bx
                rol     bx,cl                   ; Rotate
                add     bx,cx
                add     ax,dx
                mov     es,ax
                add     es:[di],dx
                loop    locloop_31              ; Loop if cx > 0

loc_32:
                pop     ax
                mov     dl,byte ptr cs:[121h]
                cmp     dl,byte ptr cs:[122h]
                jne     loc_29                  ; Jump if not equal
                mov     dx,ax
                add     dx,10h
                add     word ptr cs:[11Fh],dx
                mov     bx,word ptr cs:[123h]
                add     bx,dx
                mov     ss,bx
                mov     bx,word ptr cs:[125h]
                mov     sp,bx
                mov     es,ax
                mov     ds,ax
                xor     ax,ax                   ; Zero register
                jmp     dword ptr cs:[11Dh]
                                                ;* No entry point to code
                xor     al,al                   ; Zero register
                out     21h,al                  ; port 21h, 8259-1 int comands
                mov     bx,sp
                or      word ptr [bx+4],200h
                iret                            ; Interrupt return
data_17         dw      0
data_18         dw      0
data_19         db      0
                db      0
data_20         dw      0
data_21         dw      0
;----------------------------------------------------------------------------

on_com          proc
                mov     ax,4202h
                xor     cx,cx                   ; Zero register
                xor     dx,dx                   ; Zero register
                mov     bx,data_45
                int     21h                     ; DOS Services  ah=function 42h
                                                ;  move file ptr, bx=file handle
                                                ;   al=method, cx,dx=offset
                mov     word ptr cs:[5B2h],ax
                mov     ax,4200h
                xor     cx,cx                   ; Zero register
                xor     dx,dx                   ; Zero register
                mov     bx,data_45
                int     21h                     ; DOS Services  ah=function 42h
                                                ;  move file ptr, bx=file handle
                                                ;   al=method, cx,dx=offset
                mov     ah,48h                  ; 'H'
                mov     bx,0FFFh
                int     21h                     ; DOS Services  ah=function 48h
                                                ;  allocate memory, bx=bytes/16
                mov     ds,ax
                mov     es,ax
                mov     ax,0E2Eh
                mov     ax,ax                      ; Video display   ah=functn 0Eh
                                                ;  write char al, teletype mode
                mov     ah,3Fh                  ; '?'
                xor     dx,dx                   ; Zero register
                mov     cx,0F000h
                mov     bx,cs:data_45
                int     21h                     ; DOS Services  ah=function 3Fh
                                                ;  read file, bx=file handle
                                                ;   cx=bytes to ds:dx buffer
                mov     cx,ax
                pusha                           ; Save all regs
                xor     di,di                   ; Zero register
                xor     si,si                   ; Zero register
                mov     ah,1
                xor     dx,dx                   ; Zero register

locloop_33:
                lodsb                           ; String [si] to al
                add     byte ptr cs:[625h],al
                xor     al,ah
                rol     ah,5                    ; Rotate
                add     ah,cl
                stosb                           ; Store al to es:[di]
                loop    locloop_33              ; Loop if cx > 0

                popa                            ; Restore all regs
                pusha                           ; Save all regs
                push    ds
                push    cs
                pop     ds
                mov     ah,40h                  ; '@'
                mov     dx,offset data_22
                mov     bx,data_46
                mov     cx,0A5h
                int     21h                     ; DOS Services  ah=function 40h
                                                ;  write file  bx=file handle
                                                ;   cx=bytes from ds:dx buffer
                pop     ds
                popa                            ; Restore all regs
                mov     ah,40h                  ; '@'
                mov     bx,cs:data_46
                int     21h                     ; DOS Services  ah=function 40h
                                                ;  write file  bx=file handle
                                                ;   cx=bytes from ds:dx buffer
                mov     ah,49h
                int     21h                     ; DOS Services  ah=function 49h
                                                ;  release memory block, es=seg
                push    cs
                pop     ds
                push    cs
                pop     es
                ret
on_com           endp
; \AA\E3᮪, \A4\AE\AF\A8\E1뢠\A5\AC\EB\A9 \AA com 䠩\AB\E3
;-----------------------------------------------------------------------
data_22         db      0Eh
                db       17h, 9Ch, 58h,0F6h,0C4h, 01h
                db       74h, 03h,0EBh, 4Ch, 90h
loc_34:
                mov     ah,1
                mov     si,124h
                mov     di,data_48e
                mov     cx,81h
                push    100h
                push    1A5h
                push    1A5h
                push    di
                rep     movsb                   ; Rep when cx >0 Mov [si] to es:[di]
                ret
                                                ;* No entry point to code
                mov     al,2
                out     21h,al                  ; port 21h, 8259-1 int comands
                pusha                           ; Save all regs
                mov     ax,199h
                xor     di,di                   ; Zero register
                mov     es,di
                mov     di,data_2e
                stosw                           ; Store ax to es:[di]
                mov     ax,cs
                stosw                           ; Store ax to es:[di]
                mov     bx,data_3e
                mov     ax,0FE3Ah
                mov     di,data_1e
                mov     byte ptr es:[bx],0
                stosw                           ; Store ax to es:[di]
                mov     ax,cs
                stosw                           ; Store ax to es:[di]
                cmp     byte ptr es:[bx],0
                jne     loc_35                  ; Jump if not equal
                db       2Eh, 9Ch, 58h, 9Eh, 80h,0F4h
                db       01h, 50h, 9Dh
loc_35:
                mov     al,0FEh
                out     64h,al                  ; port 64h, kybd cntrlr functn
                                                ;  al = 0FEh, pulse CPU reset
                xor     cx,cx                   ; Zero register

locloop_36:
                loop    locloop_36              ; Loop if cx > 0

                mov     ah,30h
                int     21h                     ; DOS Services  ah=function 30h
                                                ;  get DOS version number ax
                cmp     al,2
                jae     loc_37                  ; Jump if above or =
                xor     ax,ax                   ; Zero register
                push    es
                push    ax
                retf
loc_37:
                mov     bx,data_49e
                mov     [bx],bh
                sub     [bx],bh
                jnz     loc_35                  ; Jump if not zero
                int     3                       ; Debug breakpoint
                add     sp,6
                popa                            ; Restore all regs
                push    cs
                pop     es
                pop     cx
                pop     si
                pop     di
                push    di
                xor     dx,dx                   ; Zero register

locloop_38:
                lodsb                           ; String [si] to al
                xor     al,ah
                rol     ah,5                    ; Rotate
                add     ah,cl
                add     dl,al
                stosb                           ; Store al to es:[di]
                loop    locloop_38              ; Loop if cx > 0

                cmp     dl,0
                je      loc_39                  ; Jump if equal
                int     20h                     ; DOS program terminate
loc_39:
                xor     ax,ax                   ; Zero register
                ret
                                                ;* No entry point to code
                xor     al,al                   ; Zero register
                out     21h,al                  ; port 21h, 8259-1 int comands
                mov     bx,sp
                or      word ptr [bx+4],200h
                iret                            ; Interrupt return
;----------------------------------------------------------------------------
info            proc
                ret
info            endp
mak_files           proc    near
                mov     si,PSP_cmd_tail+1
                mov     di,offset com_input
                mov     cx,80h

locloop_43:
                movsb                           ; Mov [si] to es:[di]
                cmp     byte ptr [di-1],2Eh     ; '.'
                loopnz  locloop_43              ; Loop if zf=0, cx>0

                mov     si,offset data_33
                mov     cx,3
                rep     movsb                   ; Rep when cx >0 Mov [si] to es:[di]
                mov     ax,3D00h
                mov     dx,PSP_cmd_tail+1
                int     21h                     ; DOS Services  ah=function 3Dh
                                                ;  open file, al=mode,name@ds:dx
                mov     data_45,ax
                mov     ah,3Ch                  ; '<'
                mov     dx,offset com_input
                mov     cx,20h
                int     21h                     ; DOS Services  ah=function 3Ch
                                                ;  create/truncate file @ ds:dx
                mov     data_46,ax
loc_44:
                mov     ah,3Fh                  ; '?'
                mov     dx,offset data_47
                mov     cx,7FFFh
                mov     bx,data_45
                int     21h                     ; DOS Services  ah=function 3Fh
                                                ;  read file, bx=file handle
                                                ;   cx=bytes to ds:dx buffer
                mov     cx,ax
                mov     ah,40h                  ; '@'
                mov     bx,data_46
                int     21h                     ; DOS Services  ah=function 40h
                                                ;  write file  bx=file handle
                                                ;   cx=bytes from ds:dx buffer
                test    ax,ax
                jnz     loc_44                  ; Jump if not zero
                mov     ah,3Eh                  ; '>'
                mov     bx,data_45
                int     21h                     ; DOS Services  ah=function 3Eh
                                                ;  close file, bx=file handle
                mov     ah,3Eh                  ; '>'
                mov     bx,data_46
                int     21h                     ; DOS Services  ah=function 3Eh
                                                ;  close file, bx=file handle
                ret
mak_files       endp

com_input       dw      6 dup (0)
                db      0, 1, 7
tempfile        db      '$TEMP$$.TMP',0
data_30         db      0
                db      12 dup (0)
data_31         db      7
                db       43h, 4Fh, 4Dh
data_32         db      45h
                db       58h, 45h
data_33         db      42h
                db       41h, 4Bh
data_34         dw      50Ch
data_35         dw      0F0EEh
data_36         dw      0C423h
data_37         dw      0A1EEh
data_38         dw      0E2FEh
                db       12h,0E2h, 63h,0EEh
data_39         dw      0EE00h
data_40         dw      514h
data_41         dw      36FFh
data_42         dw      8F8h
data_43         dw      10h
data_44         dw      40C4h
                db       69h,0A1h
data_45         dw      0F7F8h
data_46         dw      0E0E1h
                db      0FAh, 02h
data_47         db      0FEh
                db      6Eh

                end
