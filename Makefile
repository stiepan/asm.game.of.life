all: life

life: life.o
	gcc -g -o life life.c life.o -Wall -Wextra -std=c99

life.o:
	as -g -o life.o life.s

.PHONY: clean
clean:
	rm -f *.o
	rm -f life


