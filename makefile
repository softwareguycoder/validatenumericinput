validatenumericinput: validatenumericinput.o
	ld -m elf_i386 -o validatenumericinput validatenumericinput.o
validatenumericinput.o: validatenumericinput.asm
	nasm -f elf -F dwarf -g validatenumericinput.asm -l validatenumericinput.lst
clean:
	rm -f *.o *.lst validatenumericinput
