org 0x7c00

start:
    mov ax, 0x13                                ; enable 320 x 200 x 8 video mode
    int 0x10

    mov ax, screen.address                      ; set the video mem address
    mov es, ax

prepare_loop:
    mov cx, board.row_count
    mov si, board.bricks
    .row:
        push cx
        mov cx, board.column_count
        .column:
            ; rdtsc 
            ; and ah, 0b111
            mov byte [si], cl
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

update_ball:
    mov ax, [ball.x]
    mov bl, [ball.y]
    .check_wall_collision_hor:
        cmp ax, screen.w - ball.w                       ; check if hit right wall(accounting for ball width)
        jge .bounce_hor
        test ax, ax                                     ; check if hit left wall(which would be 0)
        jnz .check_wall_collision_vert
        .bounce_hor:
            neg word [ball.x_speed]                         ; invert the ball speed
    .check_wall_collision_vert:
        test bl, bl                                     ; test if hit top of the screen
        jnz .draw_ball
        neg byte [ball.y_speed]                         ; invert the vertical speed
    .draw_ball:
    xor bh, bh
    mov cx, ball.size
    mov dl, ball.color
    call draw_rect
    mov ax, [ball.x_speed]
    add [ball.x], ax
    mov al, [ball.y_speed]
    add [ball.y], al


update_bricks:
    mov si, board.bricks
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
            mov dl, [si]
            mov cx, brick.size
            ;call draw_rect
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
    .address equ 0x0500
    .column_count equ screen.w / brick.w
    .row_count equ 5
    .total equ .column_count * .row_count
    .bricks times .total db 0

paddle:
    .x dw screen.w / 2
    .y equ 180

ball:
    .w equ 5
    .h equ 5
    .size equ (.h << 8) | .w
    .color equ 15                                       ; white ball
    .x dw screen.w / 2 - .w / 2                         ; x has to be a word because max screen width is 320 which would not fit into a byte 
    .y db screen.h - 20                                 ; y
    .x_speed dw 1
    .y_speed db -1

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