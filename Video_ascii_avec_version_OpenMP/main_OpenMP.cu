#include <iostream>
#include <string.h>
#include <cuda.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <curand.h>
#include <curand_kernel.h>
#include <math.h>
#include <sys/time.h>
#include <omp.h>
#include "FreeImage.h"
#include "bibli.cu"
#include "host.cu"
#include "device.cu"


#define WIDTH 1920
#define HEIGHT 1024
#define BPP 24 // Since we're outputting three 8 bit RGB values

using namespace std;

int main (int argc , char** argv)
{

  printf("\n[------------------ DECOUPAGE DE LA VIDEO ------------------]\n");
  char decoupe[100] = "python3 decoupe_vid.py ";
  strcat(decoupe, argv[5]);
  system(decoupe);

  printf("[------------------ TRAITEMENT ASCII DES IMAGES ------------------]\n\n");
  system("rm -r images_ascii/");
  system("mkdir images_ascii");

  FILE * f_img = popen("find images -type f | wc -l","r");
  char nbr_img[100] = {0};
  fgets(nbr_img, 100, f_img); // calcul le nombre d'image à transformer
  pclose(f_img);

  // Pour la barre de chargement
  float eps = 2.5; // pourcentage équivalent à 1 '#' dans la barre
  int taille = 0;
  char barre[200] = "Traitement ascii des images";

  int max_it = atoi(nbr_img);

  init_barre_chargement(barre,&taille,eps,max_it);

  start = get_time();

  #pragma omp parallel num_threads(atoi(argv[6])) private(num,width,height,pitch,sz_in_bytes,img,d_img,block_x,block_y,grid_x,grid_y,DETAIL,grid_x_ascii,grid_y_ascii,block_x_ascii,block_y_ascii,nb_sleep_thread_x_all,nb_sleep_thread_y_all,nb_sleep_block_x,nb_sleep_block_y,img_ascii,d_img_ascii,MAX,final_ascii)
  {
    int TN = omp_get_thread_num();
    cudaStream_t num_stream_id;
    cudaStreamCreate(&num_stream_id);
    int cpt_thread = 0;
    #pragma omp for
    for(int k=0; k<max_it;k++){

      if(TN==0){
        barre_chargement_openmp(barre,atoi(argv[6])*100*(k+1)/max_it,k,max_it/atoi(argv[6]),eps,taille,max_it);
      }

      char PathName[100] = "images/frame";
      sprintf(num, "%d", k);
      strcat(PathName, num);
      strcat(PathName,".jpg");

      FreeImage_Initialise();

      // load and decode a regular file
      FREE_IMAGE_FORMAT fif = FreeImage_GetFileType(PathName);
      FIBITMAP* bitmap = FreeImage_Load(FIF_JPEG, PathName, 0);

      if(cpt_thread==0){
        declaration_1(bitmap,&width,&height,&pitch,img,argc,atoi(argv[1]),atoi(argv[2]),atoi(argv[3]),atoi(argv[4]));
        sz_in_bytes = sizeof(unsigned int) * 3 * width * height; //nb de valeurs pour toute image
        img = (unsigned int*) malloc(sz_in_bytes);
      }

    	//### allocation device ###
    	cudaMalloc((void**)&d_img, sz_in_bytes);

      REORDER_IMG(img,height,width,pitch,bitmap);

      cudaMemcpyAsync(d_img, img, sz_in_bytes,cudaMemcpyHostToDevice,num_stream_id);
      //##############################################################################################
      //################################### Prétraitement d'image ####################################
      //##############################################################################################

      declaration_2(&block_x, &block_y, &grid_x, &grid_y, width, height, atoi(argv[1]), atoi(argv[2]), cpt_thread);

      dim3 dimBlock(block_x,block_y,1);
      dim3 dimGrid(grid_x,grid_y,1);
      Niveau_Gris<<<dimGrid, dimBlock,0,num_stream_id>>>(d_img, width, height);
      //##############################################################################################
      //#################################### Traitement ascii d'image #################################
      //##############################################################################################

      if(cpt_thread==0){
        declaration_3(&DETAIL, &grid_x_ascii,&grid_y_ascii,&block_x_ascii,&block_y_ascii,img_ascii,width,height,atof(argv[3]),atoi(argv[4]));
        img_ascii = (float*) malloc(sizeof(float)*grid_x_ascii*grid_y_ascii);
      }

      dim3 dimBlock_ascii(block_x_ascii,block_y_ascii,1);
      dim3 dimGrid_ascii(grid_x_ascii,grid_y_ascii,1);

      cudaMalloc((void**)&d_img_ascii, grid_x_ascii*grid_y_ascii*sizeof(float));
      Niveau_Gris_Moyennage<<<dimGrid_ascii, dimBlock_ascii,0,num_stream_id>>>(d_img_ascii,d_img, width, height);
      cudaFree(d_img);

      cudaMemcpyAsync(img_ascii, d_img_ascii, grid_x_ascii*grid_y_ascii*sizeof(float),cudaMemcpyDeviceToHost,num_stream_id);

      cudaFree(d_img_ascii);

      char tab_txt[100]; // nom de l'image txt de sortie
      char tab_png[100]; // nom de l'image png de sortie
      strcat(strcpy(tab_txt, "autre/temporaire/frame"), num);
      strcat(strcpy(tab_png, "frame"), num);
      strcat(tab_txt, ".txt");
      strcat(tab_png, ".png");

      if(cpt_thread==0){
        MAX = 255; //max du niveau de gris
        final_ascii = (char*) malloc(sizeof(char)*grid_x_ascii*grid_y_ascii);
        cpt_thread = cpt_thread+1;
      }
      tab_to_txt(final_ascii,img_ascii,tab_txt,grid_y_ascii,grid_x_ascii,block_x_ascii,block_y_ascii,MAX,DETAIL); // Creation du fichier texte contenant l'image
      txt_to_png(width,height,grid_x_ascii,tab_txt,tab_png,MAX,DETAIL); // Creation de l'image png à l'aide du fichier txt créé precedement
      remove(tab_txt);
    }
  }
  stop = get_time();
  cpu_time_used = stop-start;
  free(img);
  free(final_ascii);
  free(img_ascii);


  printf("\nTemps pour le traitement d'images : %f secondes\n\n",cpu_time_used);

  printf("[------------------ ASSEMBLAGE DE LA VIDEO ------------------]\n\n");
  char assemble[100] = "python3 assemble_vid.py ";
  strcat(assemble, argv[5]);
  system(assemble);

  printf("\nVideo bien assemblée.\n");

  return 0;
}
