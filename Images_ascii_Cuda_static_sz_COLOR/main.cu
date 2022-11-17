#include <iostream>
#include <dirent.h> 
#include <string.h>
#include <cuda.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <curand.h>
#include <curand_kernel.h>
#include <math.h>
#include <sys/time.h>
#include "omp.h"
#include "FreeImage.h"
#include "lib_ascii.h"
#include "host.cu"
#include "device.cu"

#define BPP 24

// Assemblage video python //
//static char nbr_img[100] = {0};                                                           // nombre d'images dans la video
static char **path_img;
static char **path_dir;
// Mesures temps //
static double start,stop,start_kernel,stop_kernel,cpu_time_used,
temps_kernel0_moyen,temps_kernel1_moyen,temps_kernel2_moyen,temps_kernel3_moyen,
temps_kernel4_moyen;                                                                      // variables pour mesurer le temps
static double *temps_kernel0,*temps_kernel1,*temps_kernel2,*temps_kernel3,*temps_kernel4; // pointeur tableau qui stock le temps des kernels à chaque itérations
//static char num[10];                                                                      // pour le numéro des iamges (framex.png)
// Barre de chargement //
static char barre[200] = "Traitement ascii des images";                                   //
static float eps;                                                                         // pourcentage équivalent à 1 '#' dans la barre de chargement
static int taille;                                                                        //
static int max_it;                                                                      //
// Pour le traitement d'images //
static unsigned int blockDim_x;                                                           //
static unsigned int blockDim_y;                                                           //
static unsigned int gridDim_x;                                                            //
static unsigned int gridDim_y;                                                            // 
static unsigned int nb_characters;                                                        //
static unsigned int width;                                                                //
static unsigned int height;                                                               //
static unsigned int width_color;                                                          //
static unsigned int height_color;                                                         //
// static unsigned int width_lib;                                                         //
// static unsigned int height_lib;                                                        //
static unsigned int pitch;                                                                //
static unsigned int pitch_final;   
static long unsigned int sz_in_bytes;                                                     // nb de bytes pour l'image initiale
static long unsigned int sz_in_bytes_img_ascii;                                           // nb de bytes pour l'image moyennée
static long unsigned int sz_in_bytes_ascii_color;                                         //

static unsigned int *img;                                                                 // pointeur
static float *img_ascii;                                                                  // pointeur
static unsigned char *img_ascii_color_final;                                              //
static unsigned int *d_img;                                                               // pointeur
static const char *use_ascii;                                                             // pointeur du tableau des ascii qui seront utilisés dans l'image (trié par ordre de niveau de gris croissant)
static unsigned char *d_tab_ascii_lib;                                                    //
float *d_img_ascii;                                                                       // pointeur
static unsigned char *d_img_ascii_color_final;                                            //

static unsigned int gridDim_x_ascii;                                                      // largeur de l'image en nombre d'ascii
static unsigned int gridDim_y_ascii;                                                      //
static unsigned int blockDim_x_ascii;                                                     //
static unsigned int blockDim_y_ascii;                                                     //
static unsigned int nb_sleep_thread_x;                                                    //
static unsigned int nb_sleep_thread_y;                                                    //
static unsigned int nb_sleep_thread_x_ascii;                                              //
static unsigned int nb_sleep_thread_y_ascii;                                              //
static unsigned int nb_sleep_thread_x_color;                                              //
static unsigned int nb_sleep_thread_y_color;                                              //

static unsigned int blockDim_x_color;                                                     //
static unsigned int blockDim_y_color;                                                     //
static unsigned int gridDim_x_color;                                                      //
static unsigned int gridDim_y_color;                                                      //

FIBITMAP *bitmap_final;

float *temp_img;

#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
   if (code != cudaSuccess) 
   {
      fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
      if (abort) exit(code);
   }
}

int main (int argc , char** argv)
{

   // ARG_ERROR(argc,argv[1],argv[2]);

   printf("\n[------------------ Réordonnacement du tableau ASCII utilisé pour générer l'image (ordre croissant en niveau de gris) ------------------]\n\n");
   // ############ Librairie ascii ############
   use_ascii = "@802{&a+*! ";
   // use_ascii = "8$&03421*! +@{a";
   nb_characters = strlen(use_ascii);
   lib_ascii ascii{use_ascii, use_ascii + nb_characters};
   affiche_ascii(ascii);
   cudaMalloc((void**)&d_tab_ascii_lib,ascii.RawSize());
   cudaMemcpy(d_tab_ascii_lib,ascii.CaracterArray(),ascii.RawSize(),cudaMemcpyHostToDevice);
   gpuErrchk( cudaPeekAtLastError() );
   // #########################################

   printf("[------------------ TRAITEMENT ASCII DES IMAGES ------------------]\n\n");
   system("rm -r images_ascii/");
   system("mkdir images_ascii");
   description_parametre(atoi(argv[1]),atoi(argv[2]),atoi(argv[3]),&max_it);

   path_img = (char**)malloc(max_it * sizeof(char*));
      for (int i = 0; i < max_it; i++)
         path_img[i] = (char*)malloc(255 * sizeof(char));
   find_path_img(path_img,&max_it);

   int cpt=0;
   list_dir("images",&cpt,path_dir,0);
   path_dir = (char**)malloc(cpt * sizeof(char*));
       for (int i = 0; i < cpt; i++)
           path_dir[i] = (char*)malloc(255 * sizeof(char));
   cpt=0;
   list_dir("images",&cpt,path_dir,1);

   // Pour la barre de chargement
   eps = 1.5; // pourcentage équivalent à 1 '#' dans la barre
   taille = 0;
   //max_it = atoi(nbr_img);
   init_barre_chargement(barre,&taille,eps,max_it);

   temps_kernel0 = (double*) malloc(max_it*sizeof(double));
   temps_kernel1 = (double*) malloc(max_it*sizeof(double));
   temps_kernel2 = (double*) malloc(max_it*sizeof(double));
   temps_kernel3 = (double*) malloc(max_it*sizeof(double));
   temps_kernel4 = (double*) malloc(max_it*sizeof(double));

   start = get_time();
   for(int k=0; k<max_it;k++){

      barre_chargement(barre,100*(k+1)/max_it,k+1,max_it,eps,taille);

      // char num[10];
      // char PathName[100] = "images/frame";
      // sprintf(num, "%d", k);
      // strcat(PathName, num);
      // strcat(PathName,".jpg");

      FreeImage_Initialise();

      // load and decode a regular file

      //printf("path_img inner %s \n",PathName);
      //printf("path_img inner %s \n",path_img[k]);


      FREE_IMAGE_FORMAT fif = FreeImage_GetFileType(path_img[k]);
      FIBITMAP* bitmap = FreeImage_Load(FIF_JPEG, path_img[k], 0);
      //FREE_IMAGE_FORMAT fif = FreeImage_GetFileType(PathName);
      //FIBITMAP* bitmap = FreeImage_Load(FIF_JPEG, PathName, 0);


      declaration_1(bitmap,&width,&height,&pitch);
      sz_in_bytes = sizeof(unsigned int) * 3 * width * height; //nb de valeurs pour toute image
      img = (unsigned int*) malloc(sz_in_bytes);
      cudaMalloc((void**)&d_img, sz_in_bytes);
      gpuErrchk( cudaPeekAtLastError() );

      start_kernel = get_time();
      REORDER_IMG(img,height,width,pitch,bitmap);
      stop_kernel = get_time();
      temps_kernel0[k] = stop_kernel-start_kernel;

      cudaMemcpy(d_img, img, sz_in_bytes,cudaMemcpyHostToDevice);
      gpuErrchk( cudaPeekAtLastError() );

      // //##############################################################################################
      // //################################### Traitement ascii d'image #################################
      // //##############################################################################################


      declaration_2(width,height,&blockDim_x,&blockDim_y,&gridDim_x,&gridDim_y,
                    &blockDim_x_ascii,&blockDim_y_ascii,&gridDim_x_ascii,&gridDim_y_ascii,
                    &nb_sleep_thread_x,&nb_sleep_thread_y,
                    &nb_sleep_thread_x_ascii,&nb_sleep_thread_y_ascii,
                    atof(argv[1]));
      sz_in_bytes_img_ascii = sizeof(float)*gridDim_x_ascii*gridDim_y_ascii;
      img_ascii = (float*) malloc(sz_in_bytes_img_ascii);
      cudaMalloc((void**)&d_img_ascii, 4*sz_in_bytes_img_ascii);
      gpuErrchk( cudaPeekAtLastError() );
      // printf("\n\n GENERAL : \n blockDim_x = %d \n blockDim_y = %d \n gridDim_x = %d \n gridDim_y = %d \n nb_sleep_thread_x = %d \n nb_sleep_thread_y = %d\n",blockDim_x,blockDim_y,gridDim_x,gridDim_y,nb_sleep_thread_x,nb_sleep_thread_y);
      // printf("\n ASCII : \n blockDim_x_ascii = %d \n blockDim_y_ascii = %d \n gridDim_x_ascii = %d \n gridDim_y_ascii = %d \n nb_sleep_thread_x_ascii = %d \n nb_sleep_thread_y_ascii = %d\n",blockDim_x_ascii,blockDim_y_ascii,gridDim_x_ascii,gridDim_y_ascii,nb_sleep_thread_x_ascii,nb_sleep_thread_y_ascii);
      // printf("Le premier kernel lance une grille de taille %dx%d avec des blocks de taille %dx%d \n",gridDim_x,gridDim_y,blockDim_x,blockDim_y);
      // printf("Le premier kernel doit prendre en compte une sous-grille de taille %dx%d avec des blocks de taille %dx%d \n",gridDim_x_ascii,gridDim_y_ascii,blockDim_x_ascii,blockDim_y_ascii);

      cudaMemset(d_img_ascii,0.,4*sz_in_bytes_img_ascii);                                                

      gpuErrchk( cudaPeekAtLastError() );

      dim3 dimBlock(blockDim_x,blockDim_y,1);
      dim3 dimGrid(gridDim_x,gridDim_y,1);
      start_kernel = get_time();
      Niveau_Gris_Color_Moyennage<<<dimGrid, dimBlock>>>(d_img_ascii,d_img,width,nb_sleep_thread_x,nb_sleep_thread_y,nb_sleep_thread_x_ascii,
                                                         nb_sleep_thread_y_ascii,gridDim_x_ascii,gridDim_y_ascii,blockDim_x_ascii,blockDim_y_ascii,k);
      stop_kernel = get_time();
      temps_kernel1[k] = stop_kernel-start_kernel;
      gpuErrchk( cudaPeekAtLastError() );

      blockDim_x_color = ascii.kwidthCaracter; // 7 
      blockDim_y_color = ascii.kheightCaracter; // 11
      nb_sleep_thread_x_color = nb_sleep_thread_x_ascii;
      nb_sleep_thread_y_color = nb_sleep_thread_y_ascii;
      declaration_3(blockDim_x_color,blockDim_y_color,&gridDim_x_color,&gridDim_y_color,gridDim_x_ascii,gridDim_y_ascii,&sz_in_bytes_ascii_color,
                    &width_color,&height_color);
      // printf("\n\n GENERAL : \n blockDim_x_color = %d \n blockDim_y_color = %d \n gridDim_x_color = %d \n gridDim_y_color = %d \n nb_sleep_thread_x_color = %d \n nb_sleep_thread_y_color = %d\n",blockDim_x_color,blockDim_y_color,gridDim_x_color,gridDim_y_color,nb_sleep_thread_x_color,nb_sleep_thread_y_color);
      
      img_ascii_color_final = (unsigned char*) malloc(sz_in_bytes_ascii_color);
      cudaMalloc((void **)&d_img_ascii_color_final, sz_in_bytes_ascii_color); 
      bitmap_final = FreeImage_Allocate(width_color,height_color, BPP);
      pitch_final  = FreeImage_GetPitch(bitmap_final);
 
    
      dim3 dimBlock_color(blockDim_x_color,blockDim_y_color,1);
      dim3 dimGrid_color(gridDim_x_color,gridDim_y_color,1);   
      
      start_kernel = get_time();
      Image_Color<<<dimGrid_color, dimBlock_color>>>(d_img_ascii,d_img_ascii_color_final,d_tab_ascii_lib,width_color,ascii.kwidthCaracter,
                                                     ascii.kheightCaracter,nb_characters,gridDim_x_ascii,gridDim_y_ascii,blockDim_x_ascii,blockDim_y_ascii,
                                                     nb_sleep_thread_x_color,nb_sleep_thread_y_color,atoi(argv[2]),atoi(argv[3]));
      stop_kernel = get_time();
      temps_kernel2[k] = stop_kernel-start_kernel; 
      
      gpuErrchk( cudaPeekAtLastError() ); 
      
      start_kernel = get_time();
      cudaMemcpy(img_ascii_color_final, d_img_ascii_color_final, sz_in_bytes_ascii_color, cudaMemcpyDeviceToHost); 
      stop_kernel = get_time();
      temps_kernel3[k] = stop_kernel-start_kernel; 
      
      gpuErrchk( cudaPeekAtLastError() );
      
      start_kernel = get_time();
      SAVE_IMG(path_img[k],img_ascii_color_final,height_color,width_color,pitch_final,bitmap_final,k);  // Créer le pitch&bitmap de img_ascii_color
      //SAVE_IMG(PathName,img_ascii_color_final,height_color,width_color,pitch_final,bitmap_final,k);  // Créer le pitch&bitmap de img_ascii_color
      stop_kernel = get_time();
      temps_kernel4[k] = stop_kernel-start_kernel;

      free(img);
      free(img_ascii);
      free(img_ascii_color_final);
      cudaFree(d_img);
      cudaFree(d_img_ascii);
      cudaFree(d_img_ascii_color_final);

   }
   stop = get_time();

   printf("\n[------------------ \t\tTEMPS\t\t------------------]\n\n");
   cpu_time_used = stop-start;
   cudaFreeAsync(d_tab_ascii_lib,0);

   printf("\nTemps pour le traitement d'images : %f secondes\n",cpu_time_used);
   printf("\nTemps moyen pour le traitement d'images : %f secondes\n",cpu_time_used/max_it);
   temps_kernel0_moyen = 0, temps_kernel1_moyen = 0,temps_kernel2_moyen = 0, temps_kernel3_moyen = 0,temps_kernel4_moyen = 0;
   for(int k=0; k<max_it;k++){
      temps_kernel0_moyen += temps_kernel0[k];
      temps_kernel1_moyen += temps_kernel1[k];
      temps_kernel2_moyen += temps_kernel2[k];
      temps_kernel3_moyen += temps_kernel3[k];
      temps_kernel4_moyen += temps_kernel4[k];
   }
   printf("\nTemps moyen pour l'agencement des images brutes : %f secondes\n",temps_kernel0_moyen/max_it);
   printf("Temps moyen pour le traitement du kernel \"Niveau_Gris_Color_Moyennage\": %f secondes\n",temps_kernel1_moyen/max_it);
   printf("Temps moyen pour le traitement du kernel \"Image_Color\" : %f secondes\n",temps_kernel2_moyen/max_it);
   printf("Temps la copie GPU -> CPU : %f secondes\n",temps_kernel3_moyen/max_it);
   printf("Temps moyen pour la création de l'image ascii : %f secondes\n\n",temps_kernel4_moyen/max_it);


   return 0;
}
