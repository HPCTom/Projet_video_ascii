//##############################################################################################
//################################### FONCTION HOST ############################################
//##############################################################################################

__host__ void description_parametre(int arg0, int arg1, int arg2, int *max_it){
  char ascii[10];
  char fond[10];
  if(arg1 == 0){
    sprintf(ascii, "%s", "noir");
  }
  else if (arg1 == 255){
    sprintf(ascii, "%s", "blanc");
  }
  else{
    sprintf(ascii, "%s", "couleur");
  }

  if(arg2 == 0){
    sprintf(fond, "%s", "noir");
  }
  else if (arg2 == 255){
    sprintf(fond, "%s", "blanc");
  }
  else{
    sprintf(fond,"%s", "couleur");
  }

  char nbr_img[100] = {0}; 

  FILE * f_img = popen("find images -type f | wc -l","r");
  fgets(nbr_img, 100, f_img); // calcul le nombre d'image à transformer
  pclose(f_img);
  *max_it = atoi(nbr_img);

  printf("Traduction ascii à %d%% avec ascii %s et fond %s pour %d images \n",arg0,ascii,fond,*max_it);

}

void list_dir(char *path,int *cpt,char **path_dir,int mode)
{ 

  DIR * d = opendir(path); // open the path
  if(d==NULL) return; // if was not able, return
  struct dirent * dir; // for the directory entries

  while ((dir = readdir(d)) != NULL) // if we were able to read somehting from the directory
    {

      if(dir -> d_type == DT_DIR && strcmp(dir->d_name,".")!=0 && strcmp(dir->d_name,"..")!=0 && mode == 0 ) // if it is a directory
      {
        *cpt = *cpt+1;
        char d_path[257]; // here I am using sprintf which is safer than strcat
        sprintf(d_path, "%s/%s", path, dir->d_name);
        list_dir(d_path,cpt,path_dir,0);
      }
      if(dir -> d_type == DT_DIR && strcmp(dir->d_name,".")!=0 && strcmp(dir->d_name,"..")!=0 && mode == 1 ) // if it is a directory
      {
        char d_path[257]; // here I am using sprintf which is safer than strcat
        sprintf(d_path, "%s/%s", path, dir->d_name);
        sprintf(path_dir[*cpt], "%s", d_path);
        char ascii_path_dir[255] = "mkdir images_ascii";
        strcat(ascii_path_dir, &path_dir[*cpt][6]);

        //printf("%s \n",ascii_path_dir);
        system(ascii_path_dir);

        *cpt = *cpt+1;
        list_dir(d_path,cpt,path_dir,1);
        
      }
    }
    closedir(d); // finally close the directory
}

void show_dir_content(char *path, int nb_img, char **path_img,int *ite)
{ 

  DIR * d = opendir(path); // open the path
  if(d==NULL) return; // if was not able, return
  struct dirent * dir; // for the directory entries

  while ((dir = readdir(d)) != NULL) // if we were able to read somehting from the directory
    {
      if(dir-> d_type != DT_DIR)
      { // if the type is not directory just print it with blue color
        sprintf(path_img[*ite], "%s/%s", path,dir->d_name);
        *ite = *ite+1;
      }
      else
      if(dir -> d_type == DT_DIR && strcmp(dir->d_name,".")!=0 && strcmp(dir->d_name,"..")!=0 ) // if it is a directory
      {
        char d_path[257]; // here I am using sprintf which is safer than strcat
        sprintf(d_path, "%s/%s", path, dir->d_name);
        show_dir_content(d_path,nb_img,path_img,ite); // recall with the new path
      }
    }
    closedir(d); // finally close the directory
}

__host__ void find_path_img(char **path_img, int *max_it){

  char nbr_img[100] = {0}; 

  FILE * f_img = popen("find images -type f | wc -l","r");
  fgets(nbr_img, 100, f_img); // calcul le nombre d'image à transformer
  pclose(f_img);

  *max_it = atoi(nbr_img);
  //printf("max_it = %d \n",*max_it);

  int ite = 0;
  show_dir_content("images",atoi(nbr_img),path_img,&ite);
}

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


void init_barre_chargement(char *barre,int *cpt,float eps,int max_it){
  strcat(barre, " [");
  while(barre[*cpt]!='\0'){
    *cpt = *cpt+1;
  }
  int taille = (int)ceil(100./eps); //nombre de #

  for(int t=0;t<taille;t++){
    strcat(barre, " ");
  }
  strcat(barre, "]");
}

void barre_chargement(char *barre,float p,int k, int max, float eps,int taille){ //entier entre 0 et 100

  int idx = (int)(p/eps); // a quelle intervalle j'appartiens

  if(k==max){
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
__host__ void SAVE_IMG(char *PathName,unsigned char *img,unsigned int height,unsigned int width,unsigned int pitch,FIBITMAP* bitmap,int num){

  FreeImage_Initialise();
  // FreeImage_SetTransparent(bitmap, TRUE);
  // int cpt = 1;
  // float val = (float)num;
  // while (val/10 > 1){
  //   cpt = cpt+1;
  //   val = val/10;
  // }
  // int size_PathDest = 22+cpt;
  // char PathDest[size_PathDest];                            // nom de l'image png de sortie
  // sprintf(PathDest,"images_ascii/frame%d.png", num);
  //strcpy(PathDest,PathName);


  char PathDest[255] = "images_ascii";
  strcat(PathDest, &PathName[6]);

  // for(int kk = 0; kk<sizeof(PathDest)+1;kk++){
  //   printf("%c",PathDest[kk]);
  // }

	// BYTE* bits = (BYTE*)FreeImage_GetBits(bitmap);
  RGBQUAD newcolor;
  // #pragma omp parallel for collapse(2)
  for ( int y =0; y<height; y++)
  {
    // BYTE *pixel = (BYTE*)bits;
    for ( int x =0; x<width; x++)
    {
      // RGBQUAD newcolor;

      int idx = ((y * width) + x) * 3;

      // printf("pitch =  %d, height = %d, width = %d \n",pitch,height,width);
      // if(num == 0){
      //   printf("\nimg[idx + 0] = %d \n",img[idx + 0]);
      //   printf("img[idx + 1] = %d \n",img[idx + 1]);
      //   printf("img[idx + 2] = %d \n",img[idx + 2]);
      // }
      // // printf("%d ",*bitmap);
      newcolor.rgbRed = img[idx + 0];
      newcolor.rgbGreen = img[idx + 1];
      newcolor.rgbBlue = img[idx + 2];
      // newcolor.rgbReserved = img[idx + 3];

      if(!FreeImage_SetPixelColor(bitmap, x, y, &newcolor))
      { fprintf(stderr, "(%d, %d) Fail...\n", x, y); }

      // pixel+=3;
    }
    // next line
    // bits += pitch;
  }
  //printf("%s \n",PathDest);
  if( FreeImage_Save (FIF_JPEG, bitmap , PathDest , 0 ))
  FreeImage_DeInitialise(); //Cleanup !
}