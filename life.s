@ Assembly - 3. assigment
@ Kamil Tokarski, kt361223@students.mimuw.edu.pl
.data

height:
    .word 0
width:
    .word 0
board_prev:
    .word 0
board:
    .word 0

.balign 4

.text
.global board_offset
.global board_size
.global start
.global run

.balign 4


@ counts offset of the fist cell of the board
board_offset:
    cmp r0, #1
    ble board_incorrect_arg
    cmp r1, #0
    ble board_incorrect_arg
    mov r1, r0, LSL#1
    add r0, r1
    bx lr


@ counts size of the buffer needed for board with required extra rows
board_size:
    cmp r0, #1
    ble board_incorrect_arg
    cmp r1, #0
    ble board_incorrect_arg
    add r1, #4
    mul r0, r1
    bx lr


board_incorrect_arg:
    eor r0, r0
    bx lr


start:
    @store begining of board and width and height in static variables
    ldr r3, =board_prev
    str r2, [r3]
    ldr r3, =height
    str r1, [r3]
    ldr r3, =width
    str r0, [r3]
    @call board_offset
    str lr, [sp, #-4]!
    bl board_offset
    ldr lr, [sp], #4
    @store address of first cell of the board
    ldr r2, =board_prev
    ldr r2, [r2]
    add r2, r0
    ldr r3, =board
    str r2, [r3]
    bx lr


run:
    @ to preserve registers
    str lr, [sp, #-4]!
    str r11, [sp, #-4]!
    str r10, [sp, #-4]!
    str r8, [sp, #-4]!
    str r7, [sp, #-4]!
    str r6, [sp, #-4]!
    str r5, [sp, #-4]!
    str r4, [sp, #-4]!

    ldr r8, =width @board width, constant throught run
    ldr r8, [r8]
    ldr r7, =height @board height, decreases to 0
    ldr r7, [r7]
    ldr r6, =board @first cell of the board
    ldr r6, [r6]
    ldr r10, =board_prev @buffer to store previous values of currently updated row
    ldr r10, [r10]
    add r11, r10, r8 @buffer to read previous values of preceeding row

    bl clear_history @zeroes [r11] row

row_loop:
    mov r5, #0  @col_counter := 0
    cmp r7, #0  @is row loop finished?
    ble finish_run
    sub r7, #1

    @updates of first, last and columns in between
    @are split here as they differ in the manner neighbours
    @needed to be count.

update_fst_cell:
    ldrb r3, [r6]
    strb r3, [r10], #1
    mov r0, #1
    @count neighburs
    @top
    ldrb r0, [r11], #1
    ldrb r3, [r11]
    add r0, r3
    @same row
    ldrb r3, [r6, #1]
    add r0, r3
    @bottom
    mov r2, r6
    add r2, r8
    ldrb r3, [r2]
    add r0, r3
    ldrb r3, [r2, #1]
    add r0, r3
    ldrb r1, [r6]
    @update cell state and increase column counter
    bl cell_state
    strb r0, [r6], #1
    add r5, #1

internall_col_loop:
    sub r4, r8, r5
    cmp r4, #2
    blt update_last_cell 
    ldrb r3, [r6]
    strb r3, [r10], #1
    @count neighburs
    @top
    ldrb r0, [r11, #-1]
    ldrb r3, [r11], #1
    add r0, r3
    ldrb r3, [r11]
    add r0, r3
    @same row
    ldrb r3, [r10, #-2]
    add r0, r3
    ldrb r3, [r6, #1]
    add r0, r3
    @bottom
    mov r2, r6
    add r2, r8
    ldrb r3, [r2, #-1]
    add r0, r3
    ldrb r3, [r2]
    add r0, r3
    ldrb r3, [r2, #1]
    add r0, r3
    ldrb r1, [r6]
    @update cell state and increase column counter
    bl cell_state
    strb r0, [r6], #1
    add r5, #1
    b internall_col_loop

update_last_cell:
    ldrb r3, [r6]
    strb r3, [r10], #1
    @count neighburs
    @top
    ldrb r0, [r11, #-1]
    ldrb r3, [r11], #1
    add r0, r3
    @same row
    ldrb r3, [r10, #-2]
    add r0, r3
    @bottom
    mov r2, r6
    add r2, r8
    ldrb r3, [r2, #-1]
    add r0, r3
    ldrb r3, [r2]
    add r0, r3
    ldrb r1, [r6]
    @update cell state and increase column counter
    bl cell_state
    strb r0, [r6], #1
    add r5, #1

row_loop_cont:
    @swap pointers to read/write old row
    @and make them point to begining of thr corresonding rows
    sub r4, r10, r8
    sub r10, r11, r8
    mov r11, r4
    b row_loop

finish_run:
    ldr r4, [sp], #4
    ldr r5, [sp], #4
    ldr r6, [sp], #4
    ldr r7, [sp], #4
    ldr r8, [sp], #4
    ldr r10, [sp], #4
    ldr r11, [sp], #4
    ldr lr, [sp], #4
    bx lr


@ given present cell state and neighbours count returns new cell state
cell_state:
    cmp r1, #0
    beq is_dead
    cmp r0, #2
    beq alive_cell
    cmp r0, #3
    beq alive_cell
    b dead_cell
is_dead:
    cmp r0, #3
    beq alive_cell
dead_cell:
    eor r0, r0
    bx lr
alive_cell:
    mov r0, #1
    bx lr


@clears buffer containing previous state of of the preceeding row
clear_history:
    eor r0, r0
    mov r1, r11
    mov r2, #4
clear_4_loop:
    cmp r2, r8
    bge clear_less_4
    str r0, [r1], #4
    add r2, #4
    b clear_4_loop
clear_less_4:
    sub r2, #4
clear_char_step_loop:
    cmp r2, r8
    bge finish_clear
    strb r0, [r1], #1
    add r2, #1
    b clear_char_step_loop
finish_clear:
    bx lr

