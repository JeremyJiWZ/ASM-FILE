data segment ;19,22,105,103,115,168,177
	;定义0~9的ABD数码管断码
	ADB_NUM db 0C0h,0F9h,0A4h,0B0h,99h,92h,82h,0F8h,80h,98h 
	int_time db 0 ;显示目前的终端次数
	flag_itr db 0 ;显示是否有中断发生
	flag_stop db 0 ;代表是否停止计时，1表示停止
	hour db 0
	min db 0
	
data ends
stack segment
	db 100 dup(?)
stack ends

code segment
	assume cs:code,ds:data,ss:stack
start:
	mov ax,data
	mov ds,ax
	mov ax,stack
	mov ss,ax

	;控制字，A出B出
	mov dx,0de03h
	mov al,10001000b;方式0，行（C低位）输出，列（C高位）输入
	out dx,al

	;计数器设置,连续产生8ms的中断信号
	mov dx,0de23h ;caculator 0
    mov al,34h
    out dx,al

    ;125k/1000=125hz,1000=3e8h
    mov dx,0de20h
    mov al,0e8h
    out dx,al
    mov al,3h
    out dx,al

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

	;开始显示
	sti ;允许中断产生
	mov ax,data
	mov ds,ax
	mov ax,0
loop1:
	cmp flag_itr,1
	jne loop1 ;中断未产生
	;中断产生
	mov flag_itr,0
	cmp int_time,125 ;比较是否进位1秒
	jne display_time
	;有一秒产生，min++，同时清零int_time
	mov int_time,0

	;用寄存器bx来暂时存储hour，min值，并做一些运算
	mov bl,min
	mov bh,hour
	inc bl
	mov cl,bl
	and cl,0fh
	cmp cl,09h;是否进位
	jne restore_time
	add bl,10h;十为进一
	and bl,0f0h;个位清零
	cmp min,60h;是否进位
	jne restore_time
	inc bh ;小时加一
	mov bl,0;分钟清零
	mov cl,bh
	and cl,0fh
	cmp cl,9h;是否进位
	jne restore_time
	add bh,10h;十位进一
	and bh,0f0h;个位清零
	cmp bh,24h;是否24h进位
	jne restore_time
	mov bh,0

restore_time:
	mov min,bl
	mov hour,bh
display_time:
	;switch ah,根据ah读出相应的数字
	cmp ah,0
	je display_0

	cmp ah,1
	je display_1

	cmp ah,2
	je display_2

	cmp ah,3
	je display_3

display_0:
	mov al,min
	and al,0fh
	jmp display_this
display_1:
	mov al,min
	and al,0f0h
	mov cl,4
	shr al,cl
	jmp display_this
display_2:
	mov al,hour
	and al,0fh
	jmp display_this
display_3:
	mov al,min
	and al,0fh
	mov cl,4
	shr al,cl
	jmp display_this

display_this:
	call display
	inc ah
	cmp ah,4
	jne loop1
	mov ah,0
	jmp loop1 ;继续循环

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

;中断服务程序
IntCode:
	cli ;禁止中断产生
	push ax
	push ds
	push dx

	mov flag_itr,1;标志中断发生
	test flag_stop,1
	jnz end_itr ;结束中断，不计数
	;中断次数增加
	inc int_time;增加中断次数

end_itr:
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

;根据ah,al来显示，其中ah表示选中哪一位(0~3)，al表示显示的数字(0~9)
display proc
	push dx
	push ax
	push bx
	push cx
	;转移
	mov bl,al
	mov bh,ah

	;选择哪一位
	mov ch,1
	mov cl,bh
	shl ch,cl
	mov bh,0fh
	xor bh,ch;相关位 置0
	mov al,bh
	mov dx,0de01h
	out dx,al

	;转为段数据
	mov bh,0
	mov dx,offset ADB_NUM
	add bx,dx
	mov al,ds:[bx]
	;显示
	mov dx,0de00h
	out dx,al

	pop cx
	pop bx
	pop ax
	pop dx
	ret
display endp

scankey proc	
;扫面键盘码，并存在AL中
	push ax
	push bx
	push dx

	;设置第0行
	mov dx,0de02h
	mov al,0eh
	out dx,al
	;输入列数据
	mov dx,0de02h
	in al,dx
	;处理AL，恢复低4位数值
	and al,0f0h 	;先把低位清空
	or al,0eh 		;再把低位置为该行值
	;处理bl,若有输入bl!=0f0h
	mov bl,0f0h
	and bl,al
	cmp bl,0f0h
	jnz key_pressed

	;设置第1行
	mov dx,0de02h
	mov al,0dh
	out dx,al
	;输入列数据
	mov dx,0de02h
	in al,dx
	;处理AL，恢复低4位数值
	and al,0f0h	 	;先把低位清空
	or al,0dh 		;再把低位置为该行值
	;处理bl,若有输入bl!=0f0h
	mov bl,0f0h
	and bl,al
	cmp bl,0f0h
	jnz key_pressed

	;设置第2行
	mov dx,0de02h
	mov al,0bh
	out dx,al
	;输入列数据
	mov dx,0de02h
	in al,dx
	;处理AL，恢复低4位数值
	and al,0f0h 	;先把低位清空
	or al,0bh 		;再把低位置为该行值
	;处理bl,若有输入bl!=0f0h
	mov bl,0f0h
	and bl,al
	cmp bl,0f0h
	jnz key_pressed

	;设置第3行
	mov dx,0de02h
	mov al,07h
	out dx,al
	;输入列数据
	mov dx,0de02h
	in al,dx
	;处理AL，恢复低4位数值
	and al,0f0h 	;先把低位清空
	or al,07h 		;再把低位置为该行值
	;处理bl,若有输入bl!=0f0h
	mov bl,0f0h
	and bl,al
	cmp bl,0f0h
	jnz key_pressed
	;没有键按下

	cmp al,0eeh;1被按下
	inc flag_stop;每次按下加一，用第0位来判断是否开始计时(1代表停止计时)

	pop dx
	pop bx
	pop ax
	ret
scankey endp

code ends
end start