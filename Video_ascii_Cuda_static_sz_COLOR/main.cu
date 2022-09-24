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
#include "lib_ascii.h"
#include "host.cu"
#include "device.cu"

#define BPP 24
#define NB_STREAMS 1

static int nb_streams;
// Assemblage video python //
static char decoupe[100] = "python3 decoupe_vid.py ";                                     // appel focntion python pour découper la vidéo
static char nbr_img[100] = {0};                                                           // nombre d'images dans la video
static char assemble[100] = "python3 assemble_vid.py ";                                   // appel focntion python pour assembler la vidéo
// Mesures temps //
static double start,stop,start_kernel,stop_kernel,
temps_reor,temps_ascii,temps_cut,temps_ass,
temps_kernel1_moyen,temps_kernel2_moyen;                                                  // variables pour mesurer le temps
static double *temps_kernel1,*temps_kernel2;                                              // pointeur tableau qui stock le temps des kernels à chaque itérations
static char num[10];                                                                      // pour le numéro des iamges (framex.png)
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
static unsigned int pitch;                                                                //
static unsigned int pitch_final;   
static long unsigned int sz_in_bytes;                                                     // nb de bytes pour l'image initiale
static long unsigned int sz_in_bytes_img_ascii;                                           // nb de bytes pour l'image moyennée
static long unsigned int sz_in_bytes_ascii_color;                                         //

static unsigned int *img;                                                                 // pointeur
static float *img_ascii;                                                                  // pointeur
static unsigned char *img_ascii_color_final;                                              //
static char *final_ascii;                                                                 // pointeur
static unsigned int *d_img;                                                               // pointeur
static const char *use_ascii;                                                             // pointeur du tableau des ascii qui seront utilisés dans l'image (trié par ordre de niveau de gris croissant)
static unsigned char *d_tab_ascii_lib;                                                    //
static float *d_img_ascii;                                                                       // pointeur
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
FIBITMAP *bitmap;
FREE_IMAGE_FORMAT fif;


static cudaStream_t stream[NB_STREAMS];


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

   printf("\n[------------------ Réordonnancement du tableau ASCII utilisé pour générer l'image (ordre croissant en niveau de gris) ------------------]\n\n");
   start = get_time();
   // ############ Librairie ascii ############
   use_ascii = "8$&03421*! "; // 11
   nb_characters = strlen(use_ascii);
   lib_ascii ascii{use_ascii, use_ascii + nb_characters};
   affiche_ascii(ascii);
   cudaMalloc((void**)&d_tab_ascii_lib,ascii.RawSize());
   cudaMemcpy(d_tab_ascii_lib,ascii.CaracterArray(),ascii.RawSize(),cudaMemcpyHostToDevice);
   gpuErrchk( cudaPeekAtLastError() );
   stop = get_time();
   temps_reor = stop-start;
   printf("\nTemps réordonnancement video : %f secondes\n",temps_reor);
   // #########################################

   printf("\n[------------------ DECOUPAGE DE LA VIDEO ------------------]\n");
   start = get_time();
   strcat(decoupe, argv[4]);
   system(decoupe);
   stop = get_time();
   temps_cut = stop-start;
   printf("\nTemps découpage video : %f secondes \n\n",temps_cut);

   printf("[------------------ TRAITEMENT ASCII DES IMAGES ------------------]\n\n");
   system("rm -r images_ascii/");
   system("mkdir images_ascii");

   FILE * f_img = popen("find images -type f | wc -l","r");
   fgets(nbr_img, 100, f_img); // calcul le nombre d'image à transformer
   pclose(f_img);

   // Pour la barre de chargement
   init_barre_chargement(barre,&taille,&eps,&max_it,nbr_img);

   temps_kernel1 = (double*) malloc(max_it*sizeof(double));
   temps_kernel2 = (double*) malloc(max_it*sizeof(double));
   data_preparation(&bitmap,&width,&height,&pitch,&sz_in_bytes,&img,&d_img,&blockDim_x,&blockDim_y,&gridDim_x,&gridDim_y,&blockDim_x_ascii,&blockDim_y_ascii,
                    &gridDim_x_ascii,&gridDim_y_ascii,&nb_sleep_thread_x,&nb_sleep_thread_y,&nb_sleep_thread_x_ascii,&nb_sleep_thread_y_ascii,atof(argv[1]),
                    &sz_in_bytes_img_ascii,&img_ascii,&d_img_ascii,ascii,&blockDim_x_color, &blockDim_y_color,&gridDim_x_color,&gridDim_y_color,&nb_sleep_thread_x_color,
                    &nb_sleep_thread_y_color,&sz_in_bytes_ascii_color,&width_color,&height_color,&img_ascii_color_final,&d_img_ascii_color_final,&bitmap_final,&pitch_final);

   FreeImage_Initialise();
   start = get_time();
   for(int k=0; k<max_it;k=k+NB_STREAMS){
      if(k+NB_STREAMS>=max_it && max_it%NB_STREAMS != 0){
         nb_streams = max_it%NB_STREAMS;
      }
      barre_chargement(barre,100*(k+1)/max_it,k+1,max_it,eps,taille);
      char PathName[100] = "images/frame";
      sprintf(num, "%d", k);
      strcat(PathName, num);
      strcat(PathName,".jpg");

      bitmap = FreeImage_Load(FIF_JPEG, PathName, 0);

      REORDER_IMG(img,height,width,pitch,bitmap);

      cudaMemcpy(d_img, img, sz_in_bytes,cudaMemcpyHostToDevice);
      gpuErrchk( cudaPeekAtLastError() );

      cudaMemset(d_img_ascii,0.,4*sz_in_bytes_img_ascii);                                                
      gpuErrchk( cudaPeekAtLastError() );

      dim3 dimBlock(blockDim_x,blockDim_y,1);
      dim3 dimGrid(gridDim_x,gridDim_y,1);
      start_kernel = get_time();
      Niveau_Gris_Color_Moyennage<<<dimGrid, dimBlock>>>(d_img_ascii,d_img,width,nb_sleep_thread_x,nb_sleep_thread_y_ascii,
                                                         gridDim_x_ascii,blockDim_x_ascii,blockDim_y_ascii);
      stop_kernel = get_time();
      temps_kernel1[k] = stop_kernel-start_kernel;
      gpuErrchk( cudaPeekAtLastError() );
    
      dim3 dimBlock_color(blockDim_x_color,blockDim_y_color,1);
      dim3 dimGrid_color(gridDim_x_color,gridDim_y_color,1);   
      
      start_kernel = get_time();
      Image_Color<<<dimGrid_color, dimBlock_color>>>(d_img_ascii,d_img_ascii_color_final,d_tab_ascii_lib,width_color,
                                                     ascii.kwidthCaracter,ascii.kheightCaracter,nb_characters,gridDim_x_ascii,
                                                     gridDim_y_ascii,blockDim_x_ascii,blockDim_y_ascii,nb_sleep_thread_x_color,nb_sleep_thread_y_color,
                                                     atoi(argv[2]),atoi(argv[3]));
      stop_kernel = get_time();
      temps_kernel2[k] = stop_kernel-start_kernel; 
      gpuErrchk( cudaPeekAtLastError() ); 
      
      cudaMemcpy(img_ascii_color_final, d_img_ascii_color_final, sz_in_bytes_ascii_color, cudaMemcpyDeviceToHost);   
      gpuErrchk( cudaPeekAtLastError() );

      SAVE_IMG(img_ascii_color_final,height_color,width_color,pitch_final,bitmap_final,k);  // Créer le pitch&bitmap de img_ascii_color
   }
   FreeImage_DeInitialise();
   stop = get_time();
   temps_ascii = stop-start;
   free(img);
   free(final_ascii);
   free(img_ascii);
   cudaFreeAsync(d_tab_ascii_lib,0);
   cudaFreeAsync(d_img_ascii,0);
   cudaFreeAsync(d_img_ascii_color_final,0);

   printf("\nTemps moyen traitement ascii : %f secondes\n",temps_ascii/max_it);
   temps_kernel1_moyen = 0, temps_kernel2_moyen = 0;
   for(int k=0; k<max_it;k++){
      temps_kernel1_moyen += temps_kernel1[k];
      temps_kernel2_moyen += temps_kernel2[k];
   }
   printf("Temps moyen pour le traitement du kernel \"Niveau_Gris_Color_Moyennage\": %f secondes\n",temps_kernel1_moyen/max_it);
   printf("Temps moyen pour le traitement du kernel \"Image_Color\" : %f secondes\n",temps_kernel2_moyen/max_it);
   printf("\nTemps total traitement ascii : %f secondes\n\n",temps_ascii);

   start = get_time();
   printf("[------------------ ASSEMBLAGE DE LA VIDEO ------------------]\n\n");
   strcat(assemble, argv[4]);
   system(assemble);
   stop = get_time();
   temps_ass = stop-start;

   printf("\nVideo bien assemblée.\n\nTemps assemblage video : %f secondes\n\n",stop-start);
   printf("----------------------------------\n");
   printf("TEMPS TOTAL = %f secondes \n",temps_reor+temps_cut+temps_ascii+temps_ass);
   printf("----------------------------------\n\n");
   return 0;
}
