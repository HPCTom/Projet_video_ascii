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
#include "bibli.cu"
#include "host.cu"
#include "device.cu"

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
      declaration_1(bitmap,&width,&height,&pitch,img,argc,atoi(argv[1]),atoi(argv[2]),atoi(argv[3]),atoi(argv[4]));
      sz_in_bytes = sizeof(unsigned int) * 3 * width * height; //nb de valeurs pour toute image
      img = (unsigned int*) malloc(sz_in_bytes);
    }

  	//### allocation device ###
  	cudaMalloc((void**)&d_img, sz_in_bytes);

    REORDER_IMG(img,height,width,pitch,bitmap);

    cudaMemcpy(d_img, img, sz_in_bytes,cudaMemcpyHostToDevice);

    declaration_2(&block_x, &block_y, &grid_x, &grid_y, width, height, atoi(argv[1]), atoi(argv[2]), k);

    //##############################################################################################
    //################################### Traitement ascii d'image #################################
    //##############################################################################################

    if(k==0){
      declaration_3(&DETAIL, &grid_x_ascii,&grid_y_ascii,&block_x_ascii,&block_y_ascii,img_ascii,width,height,atof(argv[3]),atoi(argv[4]));
      img_ascii = (float*) malloc(sizeof(float)*grid_x_ascii*grid_y_ascii);
    }

    dim3 dimBlock_ascii(block_x_ascii,block_y_ascii,1);
    dim3 dimGrid_ascii(grid_x_ascii,grid_y_ascii,1);
  
    cudaMalloc((void**)&d_img_ascii, grid_x_ascii*grid_y_ascii*sizeof(float));
    start_kernel = get_time();
    Niveau_Gris_Moyennage<<<dimGrid_ascii, dimBlock_ascii>>>(d_img_ascii,d_img, width, height);
    stop_kernel = get_time();
    temps_kernel[k] = stop_kernel-start_kernel;
    cudaMemcpy(img_ascii, d_img_ascii, grid_x_ascii*grid_y_ascii*sizeof(float),cudaMemcpyDeviceToHost);
    cudaFree(d_img);
    cudaFree(d_img_ascii);

    char tab_txt[100]; // nom de l'image txt de sortie
    char tab_png[100]; // nom de l'image png de sortie
    strcat(strcpy(tab_txt, "autre/temporaire/frame"), num);
    strcat(strcpy(tab_png, "frame"), num);
    strcat(tab_txt, ".txt");
    strcat(tab_png, ".png");

    if(k==0){
      MAX = 255; //max du niveau de gris
      final_ascii = (char*) malloc(sizeof(char)*grid_x_ascii*grid_y_ascii);
    }

    tab_to_txt(final_ascii,img_ascii,tab_txt,grid_y_ascii,grid_x_ascii,block_x_ascii,block_y_ascii,MAX,DETAIL); // Creation du fichier texte contenant l'image

    txt_to_png(width,height,grid_x_ascii,tab_txt,tab_png,MAX,DETAIL); // Creation de l'image png à l'aide du fichier txt créé precedement

  }
  stop = get_time();
  cpu_time_used = stop-start;
  free(img);
  free(final_ascii);
  free(img_ascii);


  printf("\nTemps pour le traitement d'images : %f secondes\n",cpu_time_used);
  temps_kernel_moyen = 0;
  for(int k=0; k<max_it;k++){
    temps_kernel_moyen += temps_kernel[k];
  }
  printf("\nTemps moyen pour le traitement d'un kernel : %f secondes\n\n",temps_kernel_moyen/max_it);

  printf("[------------------ ASSEMBLAGE DE LA VIDEO ------------------]\n\n");
  char assemble[100] = "python3 assemble_vid.py ";
  strcat(assemble, argv[5]);
  system(assemble);

  printf("\nVideo bien assemblée.\n");

  return 0;
}
