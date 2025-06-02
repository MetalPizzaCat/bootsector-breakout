org 0x7c00

start:
    mov ax, 0x13                                ; enable 320 x 200 x 8 video mode
    int 0x10

    mov ax, screen.address                      ; set the video mem address
    mov es, ax

    mov ax, board.address
    mov ds, ax

prepare_loop:
    mov cx, board.row_count
    xor si, si
    .row:
        push cx
        mov cx, board.column_count
        .column:
            mov al, cl
            mov byte [si], al
            inc si
        loop .column
        pop cx
    loop .row

game_loop:
    clr_scr:
        mov di, screen.w * screen.h                 ; screen size
        .loop:
        mov byte [es:di], 0                         ; write black pixels
        dec di
        jnz .loop

update_bricks:
    xor si, si
    mov cx, board.column_count                      ; first layer of loop will go over the columns, call it 'i'
    .vert:
        push cx                                     ; preserve i because we need it for 
        dec cx
        imul ax, cx, brick.w
        mov cx, board.row_count
        .hor:
            ;mov ax, cx
            push cx
            dec cx
            imul bx, cx, brick.h
            mov dl, [ds:si]
            mov cx, brick.size
            call draw_rect
            inc si
            pop cx
        loop .hor
        pop cx
    loop .vert

; mov ax, 2
; mov bx, 5
; mov dl, 14
; mov ch, 50
; mov cl, 15
; call draw_rect
frame_delay:
    mov ah, 0x86                    ; elapsed time wait call
    mov cx, 0                       ; delay
    mov dx, screen.frame_delay      ; delay
    int 0x15                        ; call the delay
    
    jmp game_loop
.spin:
    jmp .spin                       ; Spin forever


; ax - x, preserved
; bx - y, preserved
; dl - color, preserved
; ch - w
; cl - h
draw_rect:
    mov dh, cl                                      ; preserve width because it resets each line
    mov di, bx
    imul di, screen.w
    add di, ax                                      ; calculate starting x as x + y * width
    .vert:
        mov cl, dh
        push di                                     ; save to know what value we start at
        .hor:
            mov [es:di], dl                         ; write the pixel data
            inc di                                  ; advance graphics
            dec cl                                  ; reduce counter
        jnz .hor
    pop di                                          ; restore graphics pointer
    add di, screen.w                                ; y++, to avoid recalculating whole coordinate
    dec ch
    jnz .vert
    .end:
    ret


; al - char
; bl - color
; dl - x
; dh - y
plot_char:
    mov bh, 0                   ; page zero
    push ax
    mov ax, 0x200               ; move cursor
    int 0x10
    pop ax
    mov ah, 0xa                 ; plot character
    mov cx, 1                   ; repeat once
    int 0x10
    ret



brick:
    .w equ 32
    .h equ 12
    .size equ (.h << 8) | .w 

board:
    .address equ 0x500
    .column_count equ screen.w / brick.w
    .row_count equ 5
    .total equ .column_count * .row_count

screen:
    .address equ 0xa000
    .w equ 320
    .h equ 200
    .frame_delay equ 8192


padding:
        %assign compiled_size $-$$
        %warning Compiled size: compiled_size bytes
        
times 510-(compiled_size) db 0x4f
db 0x55, 0xaa                   ; bootable signature