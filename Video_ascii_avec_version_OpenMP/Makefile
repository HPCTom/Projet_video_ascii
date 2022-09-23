default: all

all:
	nvcc -I${HOME}/softs/FreeImage/include main.cu -L${HOME}/softs/FreeImage/lib/ -g -lfreeimage -o modif_img
	nvcc -I${HOME}/softs/FreeImage/include main_OpenMP.cu -L${HOME}/softs/FreeImage/lib/ -g -lfreeimage -Xcompiler -fopenmp -o modif_img_openmp

clean:
	rm -f *.o modif_img
