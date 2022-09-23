default: all

all:
	nvcc -I${HOME}/softs/FreeImage/include main_CPU.cu -L${HOME}/softs/FreeImage/lib/ -g -lfreeimage -o modif_img
clean:
	rm -f *.o modif_img
