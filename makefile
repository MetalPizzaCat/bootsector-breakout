main:
	nasm -f bin -o brick.bin main.asm

run: main
	qemu-system-i386 -fda brick.bin

clean:
	rm -f brick.bin