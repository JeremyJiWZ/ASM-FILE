data segment
	adcdata db 80 dup(0) 
	;定义80个byte的空间，用于存放adc数据
data ends

stack segment 
	db 256 dup(?)
stack ends
code segment 
	assume cs:code,ds:data,ss:stack
start:
	mov ax,data
	mov ds,ax
	mov ax,stack
	mov ss,ax

mov bx,0
mov cx,80
waitadc:
	mov dx,0de80h
	out dx,al   ;开始进行转换

	call getpb  ;调用函数，B端口数据给到AL,检测其是否完成转换
	test al,80h
	jz waitadc ;继续等待

	;转换完成
	mov dx,0de80h ;IN0端口
	in al,dx
	mov adcdata[bx],al ;存于缓冲区
wait100ms:
	call setcalculator
waiting:	
	call getpb  ;调用函数，B端口数据给到AL,检测第六位，计数结束为高
	test al,40h
	jz waiting ;继续等待直到100ms

	;等待时间到，继续读数据
	inc bx
	dec cx
	jnz waitadc

	;在窗口中显示转换得到的数据
	mov ah,06h ;initialize the screen
	mov al,0
	mov bh,01110000b
	mov ch,0
	mov cl,0
	mov dh,25
	mov dl,80
	int 10h

	mov cx,80
	mov bx,0
showdata:
	push bx
	push cx
	mov al,adcdata[bx] ;al为存放的数据
	mov ah,0
	mov cl,10
	div cl
	mov cl,24
	sub cl,al
	mov dh,cl 	;设置行号
	mov dl,bl	;设置列号
	mov ah,02h
	mov bh,0h
	int 10h

	mov dl,'*'
	mov ah,06h
	int 21h

	pop cx
	pop bx
	inc bx
	dec cx
	jnz showdata
exit:
	mov ah,01h
	int 21h

	mov ah,4ch
	int 21h

getpb proc
	;设置控制字
	mov dx,0de03h
	mov al,10000010b;方式0，B端口输入
	out dx,al

	mov dx,0de01h
	in al,dx;将B端口数据输入到AL，PB6:OUT0,PB7:E0C
	ret
getpb endp

setcalculator proc
	;设置计数器0，计时100ms后PB6为高
	mov dx,0de23h ;caculator 0
    mov al,30h ;方式1，先读写低8位，再读写高8位
    out dx,al ;设置计数器0的控制字

    mov dx,0de20h ;caculator 0
    mov al,35h; 由于连线时设置输入时钟为31.25k，所以计数器为3.125k
    out dx,al

    mov dx,0de20h
    mov al,0ch; 3125 = 0xC35
    out dx,al
    ret
setcalculator endp

code ends
end start