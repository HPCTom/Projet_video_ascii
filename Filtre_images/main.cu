#include <iostream>
#include <string.h>
#include <cuda.h>
#include <stdio.h>
#include <stdlib.h>
#include <curand.h>
#include <curand_kernel.h>
#include <math.h>
#include <sys/time.h>
#include "FreeImage.h"
#include "bibli_host.cu"
#include "bibli_device.cu"


#define WIDTH 1920
#define HEIGHT 1024
#define BPP 24 // Since we're outputting three 8 bit RGB values

typedef float              f32;
typedef double             f64;
typedef unsigned long long u64;

using namespace std;

int main (int argc , char** argv)
{
  double start,stop,cpu_time_used;

  int err = 0;
  err = error_msg(argc,atoi(argv[1]),atoi(argv[2]),atoi(argv[3])); // gestion des erreur des arguments d'entrée
  if(err==1){
    return 0;
  }

  FreeImage_Initialise();
  const char *PathName = "frame27.jpg";
  const char *PathDest,*PathSave;

  // load and decode a regular file
  FREE_IMAGE_FORMAT fif = FreeImage_GetFileType(PathName);
  FIBITMAP* bitmap = FreeImage_Load(FIF_JPEG, PathName, 0);

  if(! bitmap )
    exit( 1 ); //WTF?! We can't even allocate images ? Die !

  unsigned width  = FreeImage_GetWidth(bitmap);
  unsigned height = FreeImage_GetHeight(bitmap);
  unsigned pitch  = FreeImage_GetPitch(bitmap);

  fprintf(stderr, "Processing Image of size %d x %d\n", width, height);

	int sz_in_bytes = sizeof(unsigned int) * 3 * width * height; //nb de valeurs pour toute image

  //déclaration host
	unsigned int *img;	//image de départ
  int *filtre;
  //allocation host
  img = (unsigned int*) malloc(sz_in_bytes);
  filtre = (int*) malloc(sizeof(int)*18);
  filtre_SOBEL(filtre);

	//déclaration device
	unsigned int *d_img;
	unsigned int *d_tmp;
  unsigned int *d_tmp_N;
  int *d_filtre;
	//allocation device
	cudaMalloc((void**)&d_img, sz_in_bytes);
  cudaMalloc((void**)&d_tmp, sz_in_bytes);
  cudaMalloc((void**)&d_tmp_N, sz_in_bytes);
  cudaMalloc((void**)&d_filtre,sizeof(int)*18);

  REORDER_IMG(img,height,width,pitch,bitmap);

  cudaMemcpy(d_img, img, sz_in_bytes,cudaMemcpyHostToDevice);
  cudaMemcpy(d_tmp, img, sz_in_bytes,cudaMemcpyHostToDevice);
  cudaMemcpy(d_filtre, filtre, sizeof(int)*18,cudaMemcpyHostToDevice);

  int block_x = atoi(argv[1]);
  int grid_x = ceil((float)width/(float)block_x);
  int block_y = atoi(argv[2]);
  int grid_y = ceil((float)height/(float)block_y);

  affichage(block_x,block_y,grid_x,grid_y,height,width);

  dim3 dimBlock(block_x,block_y,1);
  dim3 dimGrid(grid_x,grid_y,1);

  start = get_time();

  //############################## TEST ##############################
	if(atoi(argv[3])==0){

		for(int k=0;k<3*100000;k=k+3){
      img[k+0] = 255;
      img[k+1] = 0;
      img[k+2] = 0;
    }

		PathDest = "test.png";
		PathSave = "ImageRapport/test.png";
		printf("Execute: Un test\n\n");

		SAVE_IMG(img,height,width,PathDest,PathSave,pitch,bitmap);
	}

	//############################## Saturation rouge ##############################
	if(atoi(argv[3])==6){

		Filtre<<<dimGrid, dimBlock>>>(d_img, width, height);

		cudaMemcpy(img, d_img, sz_in_bytes,cudaMemcpyDeviceToHost);

		PathDest = "Saturation_rouge.png";
		PathSave = "ImageRapport/Saturation_rouge.png";
		printf("Execute: Saturation rouge\n\n");

		SAVE_IMG(img,height,width,PathDest,PathSave,pitch,bitmap);
	}

	//############################## Symétrie horizontale ##############################
	if(atoi(argv[3])==7){

		Sym_horizontale<<<dimGrid, dimBlock>>>(d_img, d_tmp, width, height);

		cudaMemcpy(img, d_img, sz_in_bytes,cudaMemcpyDeviceToHost);

		PathDest = "Symétrie_horizontale.png";
		PathSave = "ImageRapport/Symétrie_horizontale.png";
		printf("Execute: Symétrie horizontale\n\n");

		SAVE_IMG(img,height,width,PathDest,PathSave,pitch,bitmap);
	}

	//############################## Floutage ##############################
  if(atoi(argv[3])==8){

    int nb_flou = 100; // Nombre de floutage consécutifs
    for(int p = 0; p < nb_flou; p++){
      Floutage<<<dimGrid, dimBlock>>>(d_img, d_tmp, width, height,p);
    }

    cudaMemcpy(img, d_img, sz_in_bytes,cudaMemcpyDeviceToHost);

    PathDest = "Floutage.png";
    PathSave = "ImageRapport/Floutage.png";
    printf("Execute: Floutage\n\n");

    SAVE_IMG(img,height,width,PathDest,PathSave,pitch,bitmap);
  }

  //############################## Niveau de gris ##############################
  if(atoi(argv[3])==9){

    Niveau_Gris<<<dimGrid, dimBlock>>>(d_img, width, height);

    cudaMemcpy(img, d_img, sz_in_bytes,cudaMemcpyDeviceToHost);

    PathDest = "Niveau_gris.png";
    PathSave = "ImageRapport/Niveau_gris.png";
    printf("Execute: Niveau de Gris\n\n");

    SAVE_IMG(img,height,width,PathDest,PathSave,pitch,bitmap);
  }

  //############################## Contour Sobel ##############################
  if(atoi(argv[3])==10){

    Niveau_Gris<<<dimGrid, dimBlock>>>(d_tmp, width, height);
  	Contour_Sobel<<<dimGrid, dimBlock>>>(d_img, d_tmp, width, height, d_filtre);

    cudaMemcpy(img, d_img, sz_in_bytes,cudaMemcpyDeviceToHost);

    PathDest = "Contour_Sobel.png";
    PathSave = "ImageRapport/Contour_Sobel.png";
    printf("Execute: Contour Sobel\n\n");

    SAVE_IMG(img,height,width,PathDest,PathSave,pitch,bitmap);
  }

  //############################## Pop_art ##############################
  if(atoi(argv[3])==12){

    Pop_art<<<dimGrid, dimBlock>>>(d_img, d_tmp, width, height);

    cudaMemcpy(img, d_img, sz_in_bytes,cudaMemcpyDeviceToHost);

    PathDest = "Pop_art.png";
    PathSave = "ImageRapport/Pop_art.png";
    printf("Execute: Pop art\n\n");

    SAVE_IMG(img,height,width,PathDest,PathSave,pitch,bitmap);
  }

  //############################## Pop art stream ##############################
  if(atoi(argv[3])==14){
    cudaStream_t stream[4];
    cudaStreamCreate(&stream[0]);
    cudaStreamCreate(&stream[1]);
    cudaStreamCreate(&stream[2]);
    cudaStreamCreate(&stream[3]);

    int taille = 3 * width * height/4;

    dim3 dimBlock(block_x,block_y,1);
    dim3 dimGrid(grid_x,grid_y/4,1);

    cudaMemcpyAsync(d_img, img, sz_in_bytes,cudaMemcpyHostToDevice,stream[0]);

    Pop_art_stream<<<dimGrid, dimBlock, 0, stream[0]>>>(d_img, width, height, taille, 0);
    Pop_art_stream<<<dimGrid, dimBlock, 0, stream[1]>>>(d_img, width, height, taille, 1);
    Pop_art_stream<<<dimGrid, dimBlock, 0, stream[2]>>>(d_img, width, height, taille, 2);
    Pop_art_stream<<<dimGrid, dimBlock, 0, stream[3]>>>(d_img, width, height, taille, 3);

    cudaMemcpyAsync(img, d_img, sz_in_bytes/4,cudaMemcpyDeviceToHost,stream[0]);
    cudaMemcpyAsync(img+taille, d_img+taille, sz_in_bytes/4,cudaMemcpyDeviceToHost,stream[1]);
    cudaMemcpyAsync(img+2*taille, d_img+2*taille, sz_in_bytes/4,cudaMemcpyDeviceToHost,stream[2]);
    cudaMemcpyAsync(img+3*taille, d_img+3*taille, sz_in_bytes/4,cudaMemcpyDeviceToHost,stream[3]);

    PathDest = "Pop_art_STREAM.png";
    PathSave = "ImageRapport/Pop_art_STREAM.png";
    printf("Execute: Pop art STREAM\n\n");

    SAVE_IMG(img,height,width,PathDest,PathSave,pitch,bitmap);
  }

  stop = get_time();
  cpu_time_used = stop-start;
  printf("\ntemps %f\n",cpu_time_used);

  free_all(d_img,img,d_tmp,d_filtre,filtre);
}
