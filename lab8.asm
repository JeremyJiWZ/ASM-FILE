data segment
	str1 db "THIS IS THE STRING FROM PC$";PC发送字符串
	str2 db "this is the string from lab$";试验仪发送字符串
data ends
stack segment
	db 256 dup(?)
stack ends
code segment
	assume cs:code,ds:data,ss:stack
start:
	mov ax,data
	mov ds,ax

	;初始化PC串口
	mov dx,3fbh;线寄存器
	mov al,10001110b
	out dx,al

	;波特率
	mov dx,3f8h
	mov al,24
	out dx,al
	mov dx,3f9h
	mov al,0
	out dx,al

	;设置2位stop,奇校验
	mov al,00001110b
	mov dx,3fbh
	out dx,al

	;设置FIFO
	mov al,00000111b
	mov dx,3fah
	out dx,al

	;初始化实验仪串口
	mov dx,0de13h;线寄存器
	mov al,10001110b
	out dx,al

	;波特率
	mov dx,0de10h
	mov al,24
	out dx,al
	mov dx,0de11h
	mov al,0
	out dx,al

	;设置2位stop,奇校验
	mov al,00001110b
	mov dx,0de13h
	out dx,al

	;设置FIFO
	mov al,00000111b
	mov dx,0de12h
	out dx,al

	;初始化传送数据
	mov cx,0	;cx用来判断是否完成该项通讯，若完成，相应的位数置1
	mov si,offset str1
	mov di,offset str2

	;开始通讯
transmit:
	test cx
	jnz pcgeting
	mov ah,[si]
	cmp ah,'$'
	jne pcsending
	or cx,1

	;PC发送数据
pcsending:
	call pcsend
	inc si

	;PC接受数据
pcgeting:
	test cx,2
	jnz labsending
	call pcget
	cmp al,'$'
	jne showdata1
	or cx,2
	jmp labsending

	;收到的数据不是'$'，打印在屏幕上
showdata1:
	mov dl,al
	mov ah,02h
	int 21h

	;实验仪发送数据
labsending:
	test cx,4
	jnz labgetting ;跳过
	mov ah,[di]
	cmp ah,'$'
	jne labsended
	or cx,4

	;发送数据给PC
labsended:
	call labsend
	inc di

	;实验仪收据数据
labgetting:
	test cx,8
	jnz transmit	;跳过
	call labget
	cmp al,'$'
	jne showdata2
	or cx,8
	jmp labend

	;收到数据，打印在屏幕上
showdata2:
	mov dl,al
	mov ah,02h
	int 21h

	;一次查询结束，判断此时cx是否为1111b，若是证明通讯全部完毕，程序结束
labend:
	cmp cx,0fh
	jne transmit
	
	;exit
	mov ah,4ch
	int 21h

	;send data in ah
pcsend proc
	push ax
send1:
	mov dx,3fdh
	in al,dx
	test al,20h
	jz send1
	mov al,ah
	mov dx,3f8h
	out dx,al
	pop ax
	ret
pcsend endp

	;收取数据并用AL返回
pcget proc
	mov dx,3fdh
	in al,dx
	test al,1
	jz pcgetend
	mov dx,3f8h
	in al,dx
	ret
pcgetend:
	ret
pcget endp

	;实验仪发送数据
labsend proc
	push ax
send2:
	mov dx,0de15h
	in al,dx
	test al,20h
	jz send2
	mov al,ah
	mov dx,0de10h
	out dx,al
	pop ax
	ret
labsend endp

	;实验仪收取数据
labget proc
	mov dx,0de15h
	in al,dx
	test al,1
	jz labgetend
	mov dx,0de10h
	in al,dx
	ret 
labgetend:
	ret
labget endp

code ends
end start

