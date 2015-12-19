;63,26,27 不能重入
data segment 
	interrupt_str db "this is a interrupt!",0dh,0ah,"$"
	tips db "process begin here",0dh,0ah,"$"
	int_time dw 0
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

	;开始中断计数
	sti ;允许终端产生
loop1:
	mov cx,int_time
	cmp cx,10
	jz loop1

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

	;计数加1
	inc int_time

	;输出终端产生字符串
	mov ax,data
	mov ds,ax
	mov dx,offset interrupt_str
	mov ah,09h
	int 21h

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

code ends
end start







