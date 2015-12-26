data segment 
	tips db "process begin here",0dh,0ah,"$"
	int_time dw 0
	flag_itr db 0
	switch_data db 0
data ends

stack segment
	db 500 dup(?)
stack ends

code segment
	assume cs:code,ss:stack,ds:data
start:
	mov ax,data
	mov ds,ax
	mov ax,stack
	mov ss,ax

	;设置控制字
	mov dx,0de03h
	mov al,10110110b;方式1，B输入
	out dx,al

	;清除中断
	mov dx,0de03h;C端口,复位方式
	mov al,00000100b
	out dx,al

	;输出提示信息
	mov dx,offset tips
	mov ah,09h
	int 21h

	;将中断程序装入
	mov dx,offset IntCode
	mov ax,cs
	mov ds,ax
	mov ah,25h
	mov al,71h
	int 21h

	;初始化9052，enable中断
	mov dx,0dccch
	mov al,5bh
	out dx,al

	;初始化8259，enable中断
	in al,21h
	and al,11111011b ;主寄存器第3位
	out 21h,al
	in al,0a1h
	and al,11111101b ;从寄存器第2为，9级中断
	out 0a1h,al

	;开放中断
	mov dx,0de03h
	mov al,00000101b
	out dx,al

	;开始中断计数
	sti ;允许终端产生
	mov ax,data
	mov ds,ax
loop1:
	cmp flag_itr,1
	jne loop1
	mov flag_itr,0
	mov al,switch_data
	call show_data
	cmp int_time,10
	jne loop1

	;结束程序
exit:
	;9052恢复
	mov dx,0dccch
	mov al,17h
	out dx,al

	;8259恢复
	in al,0a1h
	or al,00000010b
	out 0a1h,al

	mov ah,4ch
	int 21h

show_data proc
	test al,10000000b
	jz put0_8
put1_8:
	call put1
	jmp next8
put0_8:
	call put0

next8:
	test al,01000000b
	jz put0_7
put1_7:
	call put1
	jmp next7
put0_7:
	call put0

next7:
	test al,00100000b
	jz put0_6
put1_6:
	call put1
	jmp next6
put0_6:
	call put0

next6:
	test al,00010000b
	jz put0_5
put1_5:
	call put1
	jmp next5
put0_5:
	call put0

next5:
	test al,00001000b
	jz put0_4
put1_4:
	call put1
	jmp next4
put0_4:
	call put0

next4:
	test al,00000100b
	jz put0_3
put1_3:
	call put1
	jmp next3
put0_3:
	call put0

next3:
	test al,00000010b
	jz put0_2
put1_2:
	call put1
	jmp next2
put0_2:
	call put0

next2:
	test al,00000001b
	jz put0_1
put1_1:
	call put1
	jmp next1
put0_1:
	call put0
next1:
	ret
show_data endp

;中断服务程序
IntCode:
	cli ;禁止中断产生
	push ax
	push ds
	push dx

	;计数加1
	inc int_time

	;输出PB数据
	mov dx,0de01h
	in al,dx;获得到数据
	mov switch_data,al
	mov flag_itr,1

	;EOI信号
	mov al,20h
	out 20h,al
	out 0a0h,al

	;9052信号
	mov dx,0dccdh
	in al,dx
	or al,00001100b
	out dx,al

	pop dx
	pop ds
	pop ax
	;允许中断产生
	sti
	iret

;output 1 in the screen
put1 proc
	push ax
	push dx
	mov ah,02h
	mov dl,'1'
	int 21h
	pop dx
	pop ax
	ret
put1 endp

;output 0 in the screen
put0 proc
	push ax
	push dx
	mov ah,02h
	mov dl,'0'
	int 21h
	pop dx
	pop ax
	ret
put0 endp
code ends
end start







