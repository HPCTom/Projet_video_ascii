//##############################################################################################
//################################### FONCTION HOST ############################################
//##############################################################################################

__host__ void error_msg(int msg_case,const char msg){
  switch(msg_case){
    case 0:
      printf("\nUsage : le programme prend au moins 3 arguments.\n"
      "argv[1] = pourcentage de résolution de l'image entre 0 et 100 (100 %% indique qu'il y aura autant d'ascii en largeur que de pixels).\n"
      "argv[2] = nombre d'ascii différents utilisés pour générer l'image.\n"
      "argv[3] = nom de la video.\n"
      "Exemple: ./modif_img 50 10 my_video.mp4 \n\n");
      break;

    case 1:
      printf("ERROR argument invalide : %c \n",msg);
      break;
  }
}

//#### Gestion des erreurs dans les parametres d'entré #####
__host__ void ARG_ERROR(int argc,char argv1,char argv2){
  int nb_max_arg = 5;

  const char *default_msg[4] = {"0", "orange", "yellow", "blue"};

	if(argc > nb_max_arg || argc < 4){
		error_msg(0,*default_msg[0]);
    exit (EXIT_FAILURE);
	}

  else if(atoi(&argv1) <= 0 || atoi(&argv1) > 100){
    error_msg(0,*default_msg[0]);
    error_msg(1,argv1);
    exit (EXIT_FAILURE);
  }

  else if(atoi(&argv2) <= 0 || atoi(&argv2) > 10){
    error_msg(0,*default_msg[0]);
    error_msg(1,argv2);
    exit (EXIT_FAILURE);
  }

  else{
    printf("Pas de problèmes dans les arguments \n");
  }

}

//#### Declaration des parametres
__host__ void declaration_1(FIBITMAP *bitmap,unsigned *width,unsigned *height,unsigned *pitch){
    *width  = FreeImage_GetWidth(bitmap);
    *height = FreeImage_GetHeight(bitmap);
    *pitch  = FreeImage_GetPitch(bitmap);
    // printf("pitch = %d \n",*pitch);
}

__host__ void declaration_2(unsigned int width, unsigned int height,unsigned int *blockDim_x,unsigned int *blockDim_y,unsigned int *gridDim_x,unsigned int *gridDim_y,
                            unsigned int *blockDim_x_ascii,unsigned int *blockDim_y_ascii,unsigned int *gridDim_x_ascii,unsigned int *gridDim_y_ascii,
                            unsigned int *nb_sleep_thread_x,unsigned int *nb_sleep_thread_y,unsigned int *nb_sleep_thread_x_ascii,unsigned int *nb_sleep_thread_y_ascii,
                            float poucrentage_image){                        

  // #### GRILLE GENERALE ####
  *blockDim_x = 16; // ok 
  *blockDim_y = 16; // ok
  *gridDim_x = ceil((float)width/(float)(*blockDim_x)); // ok 
  *gridDim_y = ceil((float)height/(float)(*blockDim_y)); // ok
  *nb_sleep_thread_x = *gridDim_x*(*blockDim_x)-width; // nombres de threads inatif par ligne
  *nb_sleep_thread_y = *gridDim_y*(*blockDim_y)-height; // nombre de threads inactif par colonne

  // #### DIMENSION ASCII FINALE ####
  int nb_ascii_largeur = ceil(((float)width*poucrentage_image/100.));       //nombre d'ascii qu'il y aura en largeur sur l'image finale
  float ratio = (float)width/(float)height*1.5;                             //ratio largeur/hauteur pour calculer la hauteur en ascii de l'image finale (1.5 prend en compte l'écart plus grand entre les lignes que les colonnes dans un fichier texte)
  int nb_ascii_hauteur = ceil(((float)nb_ascii_largeur/ratio));             //nombre d'ascii qu'il y aura en largeur sur l'image finale

  // //### GRILLE SECONDAIRE ###
  int gridDim_x_ascii_all = nb_ascii_largeur; 
	int gridDim_y_ascii_all = nb_ascii_hauteur;

  *blockDim_x_ascii = ceil((float)width/(float)(gridDim_x_ascii_all));
  *blockDim_y_ascii = ceil((float)height/(float)(gridDim_y_ascii_all));

  int nb_sleep_thread_x_ascii_all = gridDim_x_ascii_all*(*blockDim_x_ascii)-width;   // nombres de threads inactif selon x
  int nb_sleep_thread_y_ascii_all = gridDim_y_ascii_all*(*blockDim_y_ascii)-height;  // nombres de threads inactif selon y
  int nb_sleep_block_x_all = (int)((float)nb_sleep_thread_x_ascii_all/(float)(*blockDim_x_ascii)); // nombre de blocks inactifs selon x pour le premier block qui dépasse (arrondie inférieur)
  int nb_sleep_block_y_all = (int)((float)nb_sleep_thread_y_ascii_all/(float)(*blockDim_y_ascii)); // nombre de blocs inactis selon y pour le premier block qui dépasse (arrondie inférieur)

  *gridDim_x_ascii = gridDim_x_ascii_all - nb_sleep_block_x_all; // nouvelle grid en x redimensionnée 
  *gridDim_y_ascii = gridDim_y_ascii_all - nb_sleep_block_y_all; // nouvelle grid en y redimensionnée 

  *nb_sleep_thread_x_ascii = *gridDim_x_ascii*(*blockDim_x_ascii)-width; // nombres de threads inatif par ligne
  *nb_sleep_thread_y_ascii = *gridDim_y_ascii*(*blockDim_y_ascii)-height; // nombre de threads inactif par colonne

}

__host__ void declaration_3(unsigned int blockDim_x_color,unsigned int blockDim_y_color,unsigned int *gridDim_x_color,unsigned int *gridDim_y_color,
                            unsigned int gridDim_x_ascii,unsigned int gridDim_y_ascii, long unsigned int *sz_in_bytes_ascii_color,
                            unsigned int *width_color,unsigned int *height_color){   


  *width_color = blockDim_x_color*gridDim_x_ascii;
  *height_color = blockDim_y_color*gridDim_y_ascii;                          

  *gridDim_x_color = gridDim_x_ascii;
  *gridDim_y_color = gridDim_y_ascii; 

  *sz_in_bytes_ascii_color = 3*blockDim_x_color*blockDim_y_color*gridDim_x_ascii*gridDim_y_ascii*sizeof(unsigned int);

}


void init_barre_chargement(char *barre,int *taille,float *eps,int *max_it,const char *nbr_img){
  *max_it = atoi(nbr_img);
  *taille = 0;
  *eps = 1.5;
  strcat(barre, " [");
  while(barre[*taille]!='\0'){
    *taille = *taille+1;
  }
  int taille_intervalle = (int)ceil(100./(*eps)); //nombre de #

  for(int t=0;t<taille_intervalle;t++){
    strcat(barre, " ");
  }
  strcat(barre, "]");
}

void barre_chargement(char *barre,float p,int k, int max_it, float eps,int taille){ //entier entre 0 et 100

  int idx = (int)(p/eps); // a quelle intervalle j'appartiens

  if(k==max_it){
    for(int k=taille; k<taille+idx+1; k++){
      barre[k] = '#';
    }
    printf("\r%s  %.2f%% \n",barre,p);
    fflush(stdout);
  }
  else{
    for(int k=taille; k<taille+idx; k++){
      barre[k] = '#';
    }
    printf("\r%s  %.2f%% ",barre,p);
    fflush(stdout);
  }
}

__host__ void START_IT(char *barre,int k, int max_it, float eps,int taille,char *PathName, char *num){
  
  barre_chargement(barre,100*(k+1)/max_it,k+1,max_it,eps,taille);
  strcpy(PathName, "images/frame");
  sprintf(num, "%d", k);
  strcat(PathName, num);
  strcat(PathName,".jpg");
}

//#### Permet de calculer le temps #####
__host__ double get_time() {
  struct timeval tv;
  gettimeofday(&tv, (void *)0);
  return (double) tv.tv_sec + tv.tv_usec*1e-6;
}

//#### Ordonne le tableau en RGB? #####
__host__ void REORDER_IMG(unsigned int *img,int  height, int width,unsigned pitch,FIBITMAP* bitmap){
	BYTE *bits = (BYTE*)FreeImage_GetBits(bitmap);
  for ( int y =0; y<height; y++)
  {
    BYTE *pixel = bits;
    for ( int x =0; x<width; x++)
    {
      int idx = ((y * width) + x) * 3;
      img[idx + 0] = pixel[FI_RGBA_RED];
      img[idx + 1] = pixel[FI_RGBA_GREEN];
      img[idx + 2] = pixel[FI_RGBA_BLUE];
      pixel += 3;
    }
    bits += pitch;
  }
  FreeImage_DeInitialise();
}

//#### Sauvergarde l'image finale #####
__host__ void SAVE_IMG(unsigned char *img,unsigned int height,unsigned int width,unsigned int pitch,FIBITMAP* bitmap,int num){

  FreeImage_Initialise();
  int cpt = 1;
  float val = (float)num;
  while (val/10 > 1){
    cpt = cpt+1;
    val = val/10;
  }
  int size_PathDest = 22+cpt;
  char PathDest[size_PathDest];                            // nom de l'image png de sortie
  sprintf(PathDest,"images_ascii/frame%d.png", num);

  RGBQUAD newcolor;

  for ( int y =0; y<height; y++)
  {
    for ( int x =0; x<width; x++)
    {

      int idx = ((y * width) + x) * 3;

      newcolor.rgbRed = img[idx + 0];
      newcolor.rgbGreen = img[idx + 1];
      newcolor.rgbBlue = img[idx + 2];

      if(!FreeImage_SetPixelColor(bitmap, x, y, &newcolor))
      { fprintf(stderr, "(%d, %d) Fail allocation 2...\n", x, y); }

    }
  }
  FreeImage_Save (FIF_PNG, bitmap , PathDest , 0 );
}


__host__ void data_preparation( FIBITMAP **bitmap,unsigned int *width,unsigned int *height,unsigned int *pitch,unsigned long *sz_in_bytes,unsigned int **img,unsigned int **d_img,
                                unsigned int *blockDim_x,unsigned int *blockDim_y,unsigned int* gridDim_x,unsigned int *gridDim_y,unsigned int *blockDim_x_ascii,unsigned int *blockDim_y_ascii,
                                unsigned int *gridDim_x_ascii,unsigned int *gridDim_y_ascii,unsigned int *nb_sleep_thread_x,unsigned int *nb_sleep_thread_y,unsigned int *nb_sleep_thread_x_ascii,
                                unsigned int *nb_sleep_thread_y_ascii,float argv1,long unsigned int *sz_in_bytes_img_ascii,float **img_ascii,float **d_img_ascii,struct lib_ascii ascii,unsigned int *blockDim_x_color, 
                                unsigned int *blockDim_y_color,unsigned int *gridDim_x_color,unsigned int *gridDim_y_color,unsigned int *nb_sleep_thread_x_color,unsigned int *nb_sleep_thread_y_color,
                                unsigned long *sz_in_bytes_ascii_color,unsigned int *width_color,unsigned int *height_color,unsigned char **img_ascii_color_final,unsigned char **d_img_ascii_color_final,FIBITMAP **bitmap_final,unsigned int *pitch_final)
{
  FreeImage_Initialise();
  
  char PathName_data_prep[100] = "images/frame0.jpg";
  FREE_IMAGE_FORMAT fif = FreeImage_GetFileType(PathName_data_prep);
  *bitmap = FreeImage_Load(FIF_JPEG, PathName_data_prep, 0);

  declaration_1(*bitmap,width,height,pitch);
  *sz_in_bytes = sizeof(unsigned int) * 3 * (*width) * (*height); //nb de valeurs pour toute image
  *img = (unsigned int*) malloc(*sz_in_bytes);
  cudaMalloc((void**)&*d_img, *sz_in_bytes);

  declaration_2(*width,*height,blockDim_x,blockDim_y,gridDim_x,gridDim_y,blockDim_x_ascii,blockDim_y_ascii,gridDim_x_ascii,gridDim_y_ascii,
               nb_sleep_thread_x,nb_sleep_thread_y,nb_sleep_thread_x_ascii,nb_sleep_thread_y_ascii,argv1);
  *sz_in_bytes_img_ascii = sizeof(float)*(*gridDim_x_ascii)*(*gridDim_y_ascii);
  *img_ascii = (float*) malloc(*sz_in_bytes_img_ascii);
  cudaMalloc((void**)&*d_img_ascii, 4*(*sz_in_bytes_img_ascii));

  *blockDim_x_color = ascii.kwidthCaracter; // 7 
  *blockDim_y_color = ascii.kheightCaracter; // 11
  *nb_sleep_thread_x_color = *nb_sleep_thread_x_ascii;
  *nb_sleep_thread_y_color = *nb_sleep_thread_y_ascii;
  declaration_3(*blockDim_x_color,*blockDim_y_color,gridDim_x_color,gridDim_y_color,*gridDim_x_ascii,*gridDim_y_ascii,sz_in_bytes_ascii_color,
                width_color,height_color);

  *img_ascii_color_final = (unsigned char*) malloc(*sz_in_bytes_ascii_color);
  cudaMalloc((void **)&*d_img_ascii_color_final, *sz_in_bytes_ascii_color); 
  *bitmap_final = FreeImage_Allocate(*width_color,*height_color, 24);
  *pitch_final = FreeImage_GetPitch(*bitmap_final);

  FreeImage_DeInitialise();

}


