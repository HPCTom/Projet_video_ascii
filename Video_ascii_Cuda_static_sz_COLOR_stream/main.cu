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

#define BPP 24                                                                            // Bytes Per Pixels (24 => 3*8)
#define NB_STREAMS 4                                                                      // NB_STREAMS > 1

static int nb_streams=NB_STREAMS;
// Assemblage video python //
static char decoupe[100] = "python3 decoupe_vid.py ";                                     // appel focntion python pour découper la vidéo
static char nbr_img[100] = {0};                                                           // nombre d'images dans la video
static char assemble[100] = "python3 assemble_vid.py ";                                   // appel focntion python pour assembler la vidéo
// Mesures temps //
static double start,stop,start_kernel,stop_kernel,
temps_reor,temps_ascii,temps_cut,temps_ass,
temps_kernel1_moyen,temps_kernel2_moyen;                                                  // variables pour mesurer le temps
static double *temps_kernel1,*temps_kernel2;                                              // pointeur tableau qui stock le temps des kernels à chaque itérations
static char PathName1[100],PathName2[100],PathName3[100],PathName4[100];
static char num[10];                                                                      // pour le numéro des iamges (framex.png)
// Barre de chargement //
static char barre[200] = "Traitement ascii des images";                                   //
static float eps;                                                                         // pourcentage équivalent à 1 '#' dans la barre de chargement
static int taille;                                                                        //
static int max_it;                                                                        //
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
static long unsigned int sz_in_bytes;                                                     // nb de bytes pour l'image initiale
static long unsigned int sz_in_bytes_img_ascii;                                           // nb de bytes pour l'image moyennée
static long unsigned int sz_in_bytes_ascii_color;                                         //

static unsigned int *img1,*img2,*img3,*img4;                                              // pointeur
static float *img_ascii1,*img_ascii2,*img_ascii3,*img_ascii4;                             // pointeur
static unsigned char *img_ascii_color_final1,*img_ascii_color_final2,                     //
                     *img_ascii_color_final3,*img_ascii_color_final4;                     //
static char *final_ascii1,*final_ascii2,*final_ascii3,*final_ascii4;                      // pointeur
static unsigned int *d_img1,*d_img2,*d_img3,*d_img4;                                      // pointeur
static const char *use_ascii;                                                             // pointeur du tableau des ascii qui seront utilisés dans l'image (trié par ordre de niveau de gris croissant)
static unsigned char *d_tab_ascii_lib;                                                    //
static float *d_img_ascii1,*d_img_ascii2,*d_img_ascii3,*d_img_ascii4;                     // pointeur
static unsigned char *d_img_ascii_color_final1,*d_img_ascii_color_final2,
                     *d_img_ascii_color_final3,*d_img_ascii_color_final4;                 //

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

FIBITMAP *bitmap1_final,*bitmap2_final,*bitmap3_final,*bitmap4_final;
FIBITMAP *bitmap1,*bitmap2,*bitmap3,*bitmap4;
FREE_IMAGE_FORMAT fif;

static cudaStream_t stream[NB_STREAMS];                                                   //

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

   temps_kernel1 = (double*) malloc((int(max_it/4)+1)*sizeof(double));
   temps_kernel2 = (double*) malloc(max_it*sizeof(double));
   data_preparation(&bitmap1,&width,&height,&pitch,&sz_in_bytes,&img1,&img2,&img3,&img4,&d_img1,&d_img2,&d_img3,&d_img4,&blockDim_x,&blockDim_y,&gridDim_x,
                    &gridDim_y,&blockDim_x_ascii,&blockDim_y_ascii,&gridDim_x_ascii,&gridDim_y_ascii,&nb_sleep_thread_x,&nb_sleep_thread_y,&nb_sleep_thread_x_ascii,
                    &nb_sleep_thread_y_ascii,atof(argv[1]),&sz_in_bytes_img_ascii,
                    &img_ascii1,&img_ascii2,&img_ascii3,&img_ascii4,
                    &d_img_ascii1,&d_img_ascii2,&d_img_ascii3,&d_img_ascii4,ascii,
                    &blockDim_x_color, &blockDim_y_color,&gridDim_x_color,&gridDim_y_color,&nb_sleep_thread_x_color,
                    &nb_sleep_thread_y_color,&sz_in_bytes_ascii_color,&width_color,&height_color,&img_ascii_color_final1,&img_ascii_color_final2,&img_ascii_color_final3,&img_ascii_color_final4,
                    &d_img_ascii_color_final1,&d_img_ascii_color_final2,&d_img_ascii_color_final3,&d_img_ascii_color_final4,
                    &bitmap1_final,&bitmap2_final,&bitmap3_final,&bitmap4_final);

   FreeImage_Initialise();
   start = get_time();

   for(int k=0; k<max_it;k=k+NB_STREAMS){

      // printf("\nmax_it = %d, k0 = %d, k1 = %d, k2 = %d, k3 = %d \n",max_it,k-nb_streams+0,k-nb_streams+1,k-nb_streams+2,k-nb_streams+3);

      START_IT(barre,k,max_it,eps,taille,NB_STREAMS,&nb_streams,PathName1,PathName2,PathName3,PathName4,num);

      // printf("\nk0 = %d, k1 = %d, k2 = %d, k3 = %d \n",k-nb_streams+0,k-nb_streams+1,k-nb_streams+2,k-nb_streams+3);


      bitmap1 = FreeImage_Load(FIF_JPEG, PathName1, 0);
      bitmap2 = FreeImage_Load(FIF_JPEG, PathName2, 0);
      bitmap3 = FreeImage_Load(FIF_JPEG, PathName3, 0);
      bitmap4 = FreeImage_Load(FIF_JPEG, PathName4, 0);

      REORDER_IMG(img1,height,width,pitch,bitmap1);
      REORDER_IMG(img2,height,width,pitch,bitmap2);
      REORDER_IMG(img3,height,width,pitch,bitmap3);
      REORDER_IMG(img4,height,width,pitch,bitmap4);

      cudaStreamCreate(&stream[0]);
      cudaStreamCreate(&stream[1]);
      cudaStreamCreate(&stream[2]);
      cudaStreamCreate(&stream[3]);

      start_kernel = get_time();
      cudaMemcpyAsync(d_img1, img1, sz_in_bytes,cudaMemcpyHostToDevice,stream[0]);
      cudaMemcpyAsync(d_img2, img2, sz_in_bytes,cudaMemcpyHostToDevice,stream[1]);
      cudaMemcpyAsync(d_img3, img3, sz_in_bytes,cudaMemcpyHostToDevice,stream[2]);
      cudaMemcpyAsync(d_img4, img4, sz_in_bytes,cudaMemcpyHostToDevice,stream[3]);
      stop_kernel = get_time();
      temps_kernel1[int(k/4)] = stop_kernel-start_kernel;
      gpuErrchk( cudaPeekAtLastError() );

      cudaMemsetAsync(d_img_ascii1,0.,4*sz_in_bytes_img_ascii,stream[0]);      
      cudaMemsetAsync(d_img_ascii2,0.,4*sz_in_bytes_img_ascii,stream[1]);  
      cudaMemsetAsync(d_img_ascii3,0.,4*sz_in_bytes_img_ascii,stream[2]);  
      cudaMemsetAsync(d_img_ascii4,0.,4*sz_in_bytes_img_ascii,stream[3]);                                            
      gpuErrchk( cudaPeekAtLastError() );


      //############################### FIRST KERNEL ######################################  
      dim3 dimBlock(blockDim_x,blockDim_y,1);
      dim3 dimGrid(gridDim_x,gridDim_y,1);
      //start_kernel = get_time();
      Niveau_Gris_Color_Moyennage<<<dimGrid, dimBlock, 0, stream[0]>>>(d_img_ascii1,d_img1,width,nb_sleep_thread_x,nb_sleep_thread_y_ascii,gridDim_x_ascii,blockDim_x_ascii,blockDim_y_ascii);
      Niveau_Gris_Color_Moyennage<<<dimGrid, dimBlock, 0, stream[1]>>>(d_img_ascii2,d_img2,width,nb_sleep_thread_x,nb_sleep_thread_y_ascii,gridDim_x_ascii,blockDim_x_ascii,blockDim_y_ascii);
      Niveau_Gris_Color_Moyennage<<<dimGrid, dimBlock, 0, stream[2]>>>(d_img_ascii3,d_img3,width,nb_sleep_thread_x,nb_sleep_thread_y_ascii,gridDim_x_ascii,blockDim_x_ascii,blockDim_y_ascii);
      Niveau_Gris_Color_Moyennage<<<dimGrid, dimBlock, 0, stream[3]>>>(d_img_ascii4,d_img4,width,nb_sleep_thread_x,nb_sleep_thread_y_ascii,gridDim_x_ascii,blockDim_x_ascii,blockDim_y_ascii);
      // stop_kernel = get_time();
      // temps_kernel1[k] = stop_kernel-start_kernel;
      gpuErrchk( cudaPeekAtLastError() );
      //############################ END FIRST KERNEL ###################################### 
    
      //############################## SECOND KERNEL #######################################   
      dim3 dimBlock_color(blockDim_x_color,blockDim_y_color,1);
      dim3 dimGrid_color(gridDim_x_color,gridDim_y_color,1);   
      
      // start_kernel = get_time();
      Image_Color<<<dimGrid_color, dimBlock_color ,0 ,stream[0]>>>(d_img_ascii1,d_img_ascii_color_final1,d_tab_ascii_lib,width_color,ascii.kwidthCaracter,ascii.kheightCaracter,nb_characters,gridDim_x_ascii,
                                                                   gridDim_y_ascii,blockDim_x_ascii,blockDim_y_ascii,nb_sleep_thread_x_color,nb_sleep_thread_y_color,atoi(argv[2]),atoi(argv[3]));
      Image_Color<<<dimGrid_color, dimBlock_color ,0 ,stream[1]>>>(d_img_ascii2,d_img_ascii_color_final2,d_tab_ascii_lib,width_color,ascii.kwidthCaracter,ascii.kheightCaracter,nb_characters,gridDim_x_ascii,
                                                                   gridDim_y_ascii,blockDim_x_ascii,blockDim_y_ascii,nb_sleep_thread_x_color,nb_sleep_thread_y_color,atoi(argv[2]),atoi(argv[3]));
      Image_Color<<<dimGrid_color, dimBlock_color ,0 ,stream[2]>>>(d_img_ascii3,d_img_ascii_color_final3,d_tab_ascii_lib,width_color,ascii.kwidthCaracter,ascii.kheightCaracter,nb_characters,gridDim_x_ascii,
                                                                   gridDim_y_ascii,blockDim_x_ascii,blockDim_y_ascii,nb_sleep_thread_x_color,nb_sleep_thread_y_color,atoi(argv[2]),atoi(argv[3]));
      Image_Color<<<dimGrid_color, dimBlock_color ,0 ,stream[3]>>>(d_img_ascii4,d_img_ascii_color_final4,d_tab_ascii_lib,width_color,ascii.kwidthCaracter,ascii.kheightCaracter,nb_characters,gridDim_x_ascii,
                                                                   gridDim_y_ascii,blockDim_x_ascii,blockDim_y_ascii,nb_sleep_thread_x_color,nb_sleep_thread_y_color,atoi(argv[2]),atoi(argv[3]));      
      // stop_kernel = get_time();
      // temps_kernel2[k] = stop_kernel-start_kernel; 
      gpuErrchk( cudaPeekAtLastError() ); 
      //############################ END SECOND KERNEL ######################################
      
      cudaMemcpyAsync(img_ascii_color_final1, d_img_ascii_color_final1, sz_in_bytes_ascii_color, cudaMemcpyDeviceToHost,stream[0]);   
      cudaMemcpyAsync(img_ascii_color_final2, d_img_ascii_color_final2, sz_in_bytes_ascii_color, cudaMemcpyDeviceToHost,stream[1]);  
      cudaMemcpyAsync(img_ascii_color_final3, d_img_ascii_color_final3, sz_in_bytes_ascii_color, cudaMemcpyDeviceToHost,stream[2]);  
      cudaMemcpyAsync(img_ascii_color_final4, d_img_ascii_color_final4, sz_in_bytes_ascii_color, cudaMemcpyDeviceToHost,stream[3]);  
      gpuErrchk( cudaPeekAtLastError() );

      SAVE_IMG(img_ascii_color_final1,height_color,width_color,bitmap1_final,k-nb_streams+0);  // Créer le pitch&bitmap de img_ascii_color
      SAVE_IMG(img_ascii_color_final2,height_color,width_color,bitmap2_final,k-nb_streams+1);  // Créer le pitch&bitmap de img_ascii_color
      SAVE_IMG(img_ascii_color_final3,height_color,width_color,bitmap3_final,k-nb_streams+2);  // Créer le pitch&bitmap de img_ascii_color
      SAVE_IMG(img_ascii_color_final4,height_color,width_color,bitmap4_final,k-nb_streams+3);  // Créer le pitch&bitmap de img_ascii_color

      cudaStreamDestroy(stream[0]);
      cudaStreamDestroy(stream[1]);
      cudaStreamDestroy(stream[2]);
      cudaStreamDestroy(stream[3]);
   }
   FreeImage_DeInitialise();
   stop = get_time();
   temps_ascii = stop-start;
   free(img1);
   free(img2);
   free(img3);
   free(img4);
   free(final_ascii1);
   free(final_ascii2);
   free(final_ascii3);
   free(final_ascii4);
   free(img_ascii1);
   free(img_ascii2);
   free(img_ascii3);
   free(img_ascii4);
   free(img_ascii_color_final1);
   free(img_ascii_color_final2);
   free(img_ascii_color_final3);
   free(img_ascii_color_final4);
   cudaFreeAsync(d_tab_ascii_lib,0);
   cudaFreeAsync(d_img_ascii1,0);
   cudaFreeAsync(d_img_ascii2,0);
   cudaFreeAsync(d_img_ascii3,0);
   cudaFreeAsync(d_img_ascii4,0);
   cudaFreeAsync(d_img_ascii_color_final1,0);
   cudaFreeAsync(d_img_ascii_color_final2,0);
   cudaFreeAsync(d_img_ascii_color_final3,0);
   cudaFreeAsync(d_img_ascii_color_final4,0);

   printf("\nTemps moyen traitement ascii : %f secondes\n",temps_ascii/max_it);
   temps_kernel1_moyen = 0, temps_kernel2_moyen = 0;
   for(int k=0; k<int(max_it/4)+1;k++){
      temps_kernel1_moyen += temps_kernel1[k];
      // temps_kernel2_moyen += temps_kernel2[k];
   }
   printf("Temps copie 4 sterams %f secondes\n",temps_kernel1_moyen/(int(max_it/4)+1));
   // printf("Temps moyen pour le traitement du kernel \"Niveau_Gris_Color_Moyennage\": %f secondes\n",temps_kernel1_moyen/max_it);
   // printf("Temps moyen pour le traitement du kernel \"Image_Color\" : %f secondes\n",temps_kernel2_moyen/max_it);
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
