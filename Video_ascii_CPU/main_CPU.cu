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
#include "FreeImage.h"
#include "bibli_CPU.cu"
#include "host_CPU.cu"

int main (int argc , char** argv)
{

  printf("\n[------------------ DECOUPAGE DE LA VIDEO ------------------]\n");
  char decoupe[100] = "python3 decoupe_vid.py ";
  strcat(decoupe, argv[3]);
  system(decoupe);

  printf("[------------------ TRAITEMENT ASCII DES IMAGES ------------------]\n\n");
  system("rm -r images_ascii/");
  system("mkdir images_ascii");

  FILE * f_img = popen("find images -type f | wc -l","r");
  char nbr_img[100] = {0};
  fgets(nbr_img, 100, f_img); // calcul le nombre d'image à transformer
  pclose(f_img);

  // Pour la barre de chargement
  float eps = 1.5; // pourcentage équivalent à 1 '#' dans la barre
  int taille = 0;
  char barre[200] = "Traitement ascii des images";
  float max_it = atoi(nbr_img);
  init_barre_chargement(barre,&taille,eps,max_it);

  temps_kernel = (double*) malloc(max_it*sizeof(double));

  start = get_time();
  for(int k=0; k<max_it;k++){

    barre_chargement(barre,100*(k+1)/max_it,k+1,max_it,eps,taille);

    char PathName[100] = "images/frame";
    sprintf(num, "%d", k);
    strcat(PathName, num);
    strcat(PathName,".jpg");

    FreeImage_Initialise();

    // load and decode a regular file
    FREE_IMAGE_FORMAT fif = FreeImage_GetFileType(PathName);
    FIBITMAP* bitmap = FreeImage_Load(FIF_JPEG, PathName, 0);

    if(k==0){
      declaration_1(bitmap,&width,&height,&pitch,img,argc,atoi(argv[1]),atoi(argv[2]));
      sz_in_bytes = sizeof(unsigned int) * 3 * width * height; //nb de valeurs pour toute image
      img = (unsigned int*) malloc(sz_in_bytes);
    }

    REORDER_IMG(img,height,width,pitch,bitmap);

    //##############################################################################################
    //################################### Traitement ascii d'image #################################
    //##############################################################################################

    if(k==0){
      declaration_2(&DETAIL, &gridDim_x,&gridDim_y,&blockDim_x,&blockDim_y,width,height,
      &n_x,&n_y,&nb_sleep_thread_x,&nb_sleep_thread_y,atof(argv[1]),atoi(argv[2]));
    }

    img_ascii = (float*) calloc(sizeof(float),gridDim_x*gridDim_y);

    threadIdx_y = 0;
    threadIdx_x = 0;

    start_kernel = get_time();
    for(int h=0;h<gridDim_y*blockDim_y;h++){
      blockIdx_y = floor(h/blockDim_y);
      for(int w=0;w<gridDim_x*blockDim_x;w++){
        blockIdx_x = floor(w/blockDim_x);

        if(blockIdx_y < gridDim_y-1 || blockIdx_y == gridDim_y-1 && threadIdx_y < blockDim_y-nb_sleep_thread_y){
		      if(blockIdx_x < gridDim_x-1 || blockIdx_x == gridDim_x-1 && threadIdx_x < blockDim_x-nb_sleep_thread_x){

            int x = blockIdx_x * blockDim_x + threadIdx_x;
            int y = blockIdx_y * blockDim_y + threadIdx_y;

            int idx = ((y * width) + width - x) * 3;
            int idx_ascii  = gridDim_x*blockIdx_y + blockIdx_x;

            if(blockIdx_y == gridDim_y-1){
              img_ascii[idx_ascii] += (0.299*img[idx+0]+0.587*img[idx+1]+0.114*img[idx+2])/(blockDim_x*(blockDim_y-nb_sleep_thread_y));
			      }
            else if(blockIdx_x == gridDim_x-1){
              img_ascii[idx_ascii] += (0.299*img[idx+0]+0.587*img[idx+1]+0.114*img[idx+2])/((blockDim_x-nb_sleep_thread_x)*blockDim_y);
            }
            else{
              img_ascii[idx_ascii] += (0.299*img[idx+0]+0.587*img[idx+1]+0.114*img[idx+2])/(blockDim_x*blockDim_y);
            }

		      }
	      }
        threadIdx_x += 1;
        if(blockDim_x == threadIdx_x){
          threadIdx_x = 0;
        }
      }
      threadIdx_y += 1;
      if(blockDim_y == threadIdx_y){
          threadIdx_y = 0;
      }
    }
    stop_kernel = get_time();
    temps_kernel[k] = stop_kernel-start_kernel;

    char tab_txt[100]; // nom de l'image txt de sortie
    char tab_png[100]; // nom de l'image png de sortie
    strcat(strcpy(tab_txt, "autre/temporaire/frame"), num);
    strcat(strcpy(tab_png, "frame"), num);
    strcat(tab_txt, ".txt");
    strcat(tab_png, ".png");

    if(k==0){
      final_ascii = (char*) malloc(sizeof(char)*gridDim_x*gridDim_y);
    }

    tab_to_txt(final_ascii,img_ascii,tab_txt,gridDim_y,gridDim_x,blockDim_x,blockDim_y,DETAIL,nb_sleep_thread_x,nb_sleep_thread_y); // Creation du fichier texte contenant l'image

    txt_to_png(width,tab_txt,tab_png); // Creation de l'image png à l'aide du fichier txt créé precedement
    free(img_ascii);
  }
  stop = get_time();
  cpu_time_used = stop-start;
  free(img);
  free(final_ascii);

  printf("\nTemps pour le traitement d'images : %f secondes\n",cpu_time_used);
  temps_kernel_moyen = 0;
  for(int k=0; k<max_it;k++){
    temps_kernel_moyen += temps_kernel[k];
  }
  printf("\nTemps moyen pour le traitement d'un kernel : %f secondes\n\n",temps_kernel_moyen/max_it);

  printf("[------------------ ASSEMBLAGE DE LA VIDEO ------------------]\n\n");
  char assemble[100] = "python3 assemble_vid.py ";
  strcat(assemble, argv[3]);
  system(assemble);

  printf("\nVideo bien assemblée.\n");

  return 0;
}