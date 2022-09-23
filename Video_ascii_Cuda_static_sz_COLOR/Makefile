CC=nvcc
CFLAGS=-I${HOME}/softs/FreeImage/include -L${HOME}/softs/FreeImage/lib/ -g -lfreeimage
DEPS = lib_ascii.h
OBJ = main.o lib_ascii.o

all:	modif_img

modif_img: $(OBJ)
	$(CC) -o $@ $^ $(CFLAGS)

main.o: main.cu	$(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

clean:
	rm -rf *.o modif_img
