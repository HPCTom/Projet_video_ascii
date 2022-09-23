default: all

all:
	nvcc -I${HOME}/softs/FreeImage/include main.cu -L${HOME}/softs/FreeImage/lib/ -lfreeimage -o modif_img

clean:
	rm -f *.o modif_img
