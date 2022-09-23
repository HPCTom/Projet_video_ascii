//##############################################################################################
//################################### FONCTION HOST ############################################
//##############################################################################################

//#### Gestion des erreurs dans les parametres d'entré #####
__host__ void error_msg(int argc,int argv1, int argv2, int width){
	if(argc != 4){
		printf("\nUsage : le programme prend 3 arguments.\n"
					 "argv[1] = pourcentage de résolution de l'image entre 0 et 100 (100 %% indique qu'il y aura autant d'ascii en largeur que de pixels).\n"
					 "argv[2] = nombre d'ascii différents utilisés pour générer l'image.\n"
           "argv[3] = nom de la video.\n"
           "Exemple: ./modif_img 50 10 my_video.mp4 \n\n");
	}

	if(argv1 > 100 || argv1 <= 0){
		printf("\nLe pourcentage de résolution de l'image doit etre compris entre 0 (exclu) et 100 (cf README).\n\n");
	}
}

//#### Declaration des parametres
__host__ void declaration_1(FIBITMAP *bitmap,unsigned *width,unsigned *height,unsigned *pitch,unsigned int *img,int argc,int argv1, int argv2){
    *width  = FreeImage_GetWidth(bitmap);
    *height = FreeImage_GetHeight(bitmap);
    *pitch  = FreeImage_GetPitch(bitmap);
    error_msg(argc,argv1,argv2,*width); // gestion des erreur les arguments d'entrée
}

__host__ void declaration_2(int *DETAIL, int *gridDim_x,int *gridDim_y,int *blockDim_x,int *blockDim_y,int width, int height,
                            int *n_x,int *n_y,int *nb_sleep_thread_x,int *nb_sleep_thread_y,float argv3, int argv4){
  *DETAIL = argv4; //nombre d'ascii différents

  *gridDim_x = (int)((float)width*argv3/100.); // largeur de l'image en nombre d'ascii

  float ratio = (float)width/(float)height*1.8; //calcul la hauteur de l'image en prennant en compte le ratio de l'image Hauteur/Largeur et compense le fait que les characteres soit plus espacés en hauteur que en largeur (1.8) dans un fihcier texte.
	*gridDim_y = *gridDim_x/ratio; // hauteur de l'image en nombre d'ascii

  *blockDim_x = ceil((float)width/(float)(*gridDim_x));
  *blockDim_y = ceil((float)height/(float)(*gridDim_y));

  int nb_sleep_thread_x_all = *gridDim_x*(*blockDim_x)-width; // nombres de threads inactif selon x
  int nb_sleep_thread_y_all = *gridDim_y*(*blockDim_y)-height; // nombres de threads inactif selon y
  int nb_sleep_block_x = nb_sleep_thread_x_all/(*blockDim_x); // nombre de blocks inactifs selon x (arrondie inférieur)
  int nb_sleep_block_y = nb_sleep_thread_y_all/(*blockDim_y); // nombre de blocs inactis selon y (arrondie inférieur)

  *gridDim_x = *gridDim_x - nb_sleep_block_x; // nouvelle grid en x redimensionnée
  *gridDim_y = *gridDim_y - nb_sleep_block_y; // nouvelle grid en y redimensionnée

  *n_x = *gridDim_x*(*blockDim_x); // nombre de threads par ligne
  *n_y = *gridDim_y*(*blockDim_y); // nombres de threads par colonne
  *nb_sleep_thread_x = *n_x-width; // nombres de threads inatif par ligne
  *nb_sleep_thread_y = *n_y-height; // nombre de threads inactif par colonne

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

void barre_chargement(char *barre,float p,int k, float max, float eps,int taille){ //entier entre 0 et 100

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

//#### Ordonne le tableau en RGB #####
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
}

//#### Sauvergarde l'image finale #####
__host__ void SAVE_IMG(unsigned int *img,int  height, int width,const char *PathDest,unsigned pitch,FIBITMAP* bitmap){
	BYTE* bits = (BYTE*)FreeImage_GetBits(bitmap);
  for ( int y =0; y<height; y++)
  {
    BYTE *pixel = (BYTE*)bits;
    for ( int x =0; x<width; x++)
    {
      RGBQUAD newcolor;

      int idx = ((y * width) + x) * 3;
      newcolor.rgbRed = img[idx + 0];
      newcolor.rgbGreen = img[idx + 1];
      newcolor.rgbBlue = img[idx + 2];

      if(!FreeImage_SetPixelColor(bitmap, x, y, &newcolor))
      { fprintf(stderr, "(%d, %d) Fail...\n", x, y); }

      pixel+=3;
    }
    // next line
    bits += pitch;
  }

  if( FreeImage_Save (FIF_PNG, bitmap , PathDest , 0 ))
  FreeImage_DeInitialise(); //Cleanup !
}

__host__ void choix_ascii(float *img_ascii,int taille,int taille_x,int taille_y,char *tab_final,
													int min, int DETAIL, int nb_sleep_thread_x, int nb_sleep_thread_y){

	char ascii[255] = {'8','*','0','w','^','&','=','!','$','4','q','+','1','m','#','%','l',':','2','<','>','}','5','/','.','2','a','3','p','t','6','?','9','c','7','r','[',']','x','b'}; //40
  //char ascii[255] = {'8','&','4','w','^','*','=','!','$','0','q','+','1','m','#','%','l',':','2','<','>','}','5','/','.','2','a','3','p','t','6','?','9','c','7','r','[',']','x','b'}; //40

	if(DETAIL > 255){
		printf("nombres d'ascii max dépacé DETAIL = %d et MAX = %d\n",DETAIL,255);
	}

	int eps = 255/DETAIL;
	int moy;

	for(int i=0;i<taille;i++)
	{
		moy = img_ascii[i];
		if(moy/eps > DETAIL-1){
			tab_final[i] = ascii[moy/eps-1];
		}
		else{
			tab_final[i] = ascii[moy/eps];
		}
	}

}

__host__ void tab_to_txt(char *final_ascii,float *img_ascii,char *tab,int hauteur_ascii,int largeur_ascii,
	 											 int taille_x, int taille_y, int DETAIL, int nb_sleep_thread_x, int nb_sleep_thread_y)
{
	FILE *fp = NULL;
	fp = fopen(tab,"w");

	if(fp ==NULL)
	{
		printf("\ntab_to_txt : ERREUR OUVERTURE FICHIER\n");
	}

	choix_ascii(img_ascii,largeur_ascii*hauteur_ascii,taille_x,taille_y,final_ascii,0,DETAIL,nb_sleep_thread_x,nb_sleep_thread_y);

	int cpt = 0;

	for(int k=largeur_ascii*hauteur_ascii-1;k>-1;k--){

		if(cpt == largeur_ascii){
			cpt = 0;
			fprintf(fp,"\n");
		}
		cpt = cpt+1;
		if(k>0){
			fprintf(fp,"%c",final_ascii[k]);
		}
		else{
			fprintf(fp,"%c",final_ascii[0]);
		}
	}
	fclose(fp);

}

__host__ void txt_to_png(int width,char* tab_txt, char* tab_png)
{

	char ligne[width];

	sprintf(ligne,"convert -font Courier -background white -fill black label:@%s -flatten images_ascii/%s",tab_txt,tab_png);

  system(ligne);
}
