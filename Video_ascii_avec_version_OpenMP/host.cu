//##############################################################################################
//################################### FONCTION HOST ############################################
//##############################################################################################

//#### Gestion des erreurs dans les parametres d'entré #####
__host__ void error_msg(int argc,int argv1, int argv2, int argv3,int argv4,int width){
	if(argc != 6 && argc != 7){
		printf("\nUsage : le programme prend 6 arguments.\n"
					 "argv[1] = le nombre de threads par bloc selon x.\n"
					 "argv[2] = le nombre de threads par bloc selon y.\n"
					 "argv[3] = pourcentage de résolution de l'image entre 0 et 100 (100 %% indique qu'il y aura autant d'ascii en largeur que de pixels).\n"
					 "argv[4] = nombre d'ascii différents utilisés pour générer l'image.\n"
           "argv[5] = nom de la video.\n"
           "Exemple: ./modif_img 30 30 100 10 \n\n");
	}

  if(argv1*argv2 > 1024){
    printf("\nNombre de threads par bloc possible dépassé, argv[1]*argv[2] doit etre inférieur à 1024. \n\n");
  }
	if(argv3 > 100 || argv3 <= 0){
		printf("\nLe pourcentage de résolution de l'image doit etre compris entre 0 (exclu) et 100 (cf README).\n\n");
	}
}

__host__ void ratio(float fact, int width, int height,int largeur_ascii,int *hauteur_ascii){
	// fact est le facteur qui compense l'ecart des caractere entre ses voisin gauche/droite et haut/bas
	float ratio = (float)width/(float)height*fact;
	*hauteur_ascii = largeur_ascii/ratio;

}

//#### Declaration des parametres
__host__ void declaration_1(FIBITMAP *bitmap,unsigned *width,unsigned *height,unsigned *pitch,unsigned int *img,int argc,int argv1, int argv2, int argv3, int argv4){
    *width  = FreeImage_GetWidth(bitmap);
    *height = FreeImage_GetHeight(bitmap);
    *pitch  = FreeImage_GetPitch(bitmap);
    error_msg(argc,argv1,argv2,argv3,argv4,*width); // gestion des erreur les arguments d'entrée
}

__host__ void declaration_2(int *block_x,int *block_y, int *grid_x, int *grid_y,int width, int height, int argv1, int argv2,int k){
  if(k==0){
    *block_x = argv1;
    *grid_x = ceil((float)width/(float)(*block_x));
    *block_y = argv2;
    *grid_y = ceil((float)height/(float)(*block_y));
  }
}

__host__ void declaration_3(int *DETAIL, int *grid_x_ascii,int *grid_y_ascii,int *block_x_ascii,int *block_y_ascii, float *img_ascii,int width, int height, float argv3, int argv4){
  *DETAIL = argv4; //nombre d'ascii différents

  *grid_x_ascii = (int)((float)width*argv3/100.); // largeur de l'image en nombre d'ascii

	//ratio(1.8,width,height,*grid_x_ascii,grid_y_ascii)

  float ratio = (float)width/(float)height*1.8; //calcul la hauteur de l'image en prennant en compte le ratio de l'image Hauteur/Largeur et compense le fait que les characteres soit plus espacés en hauteur que en largeur (1.8) dans un fihcier texte.
	*grid_y_ascii = *grid_x_ascii/ratio;

  *block_x_ascii = ceil((float)width/(float)(*grid_x_ascii));
  *block_y_ascii = ceil((float)height/(float)(*grid_y_ascii));

  int nb_sleep_thread_x_all = *grid_x_ascii*(*block_x_ascii)-width; // nombres de threads inactif selon x
  int nb_sleep_thread_y_all = *grid_y_ascii*(*block_y_ascii)-height; // nombres de threads inactif selon y
  int nb_sleep_block_x = nb_sleep_thread_x_all/(*block_x_ascii); // nombre de blocks inactifs selon x (arrondie inférieur)
  int nb_sleep_block_y = nb_sleep_thread_y_all/(*block_y_ascii); // nombre de blocs inactis selon y (arrondie inférieur)

  *grid_x_ascii = *grid_x_ascii - nb_sleep_block_x; // nouvelle grid en x redimensionnée
  *grid_y_ascii = *grid_y_ascii - nb_sleep_block_y; // nouvelle grid en y redimensionnée

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
__host__ void barre_chargement_openmp(char *barre,float p,int k, int max, float eps,int taille,int max_it){ //entier entre 0 et 100
  int idx = (int)(p/eps); // a quelle intervalle jn'appartiens

  if(k==max-1 && max_it%max == 0){
    for(int k=taille; k<taille+idx+1; k++){
      barre[k] = '#';
    }
    printf("\r%s  100.00%% \n",barre);
    fflush(stdout);
  }

  else if(k==max){
    for(int k=taille; k<taille+idx; k++){
      barre[k] = '#';
    }
    printf("\r%s  100.00%% \n",barre);
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

__host__ int max_tab(unsigned int *img, int block_x, int block_y,int grid_x, int grid_y) //calcul le max du tableau en niveau de gris
{
	int taille = (grid_x)*(grid_y);
	int MAX = 0;
  for(int i=0;i<taille;i++)
  {
    if(img[i] > MAX){
      MAX=img[i];
    }
  }
	return MAX;
}

__host__ void choix_ascii(float *img_ascii,int taille,int taille_x,int taille_y,char *tab_final,
													int min, int MAX, int DETAIL){

	char ascii[255] = {'8','*','0','w','^','&','=','!','$','4','q','+','1','m','#','%','l',':','2','<','>','}','5','/','.','2','a','3','p','t','6','?','9','c','7','r','[',']','x','b'}; //40
  //char ascii[255] = {'8','&','4','w','^','*','=','!','$','0','q','+','1','m','#','%','l',':','2','<','>','}','5','/','.','2','a','3','p','t','6','?','9','c','7','r','[',']','x','b'}; //40

	if(DETAIL > MAX){
		printf("nombres d'ascii max dépacé DETAIL = %d et MAX = %d\n",DETAIL,MAX);
	}

	int eps = MAX/DETAIL;
	int moy;
	//printf("taille = %d, taille_x = %d, taille_y = %d\n",taille,taille_x,taille_y);

	for(int i=0;i<taille;i++)
	{
		moy = img_ascii[i]/((float)taille_x*(float)taille_y); //moyenne
		if(moy/eps > DETAIL-1){
			//printf("i = %d\n", i);
			tab_final[i] = ascii[moy/eps-1];
			//printf("indice = %d\n",moy/eps-1);


		}
		else{
			//printf("i2 = %d\n",i);
			tab_final[i] = ascii[moy/eps];
		}
	}

}

__host__ void tab_to_txt(char *final_ascii,float *img_ascii,char *tab,int hauteur_ascii,int largeur_ascii,
	 											 int taille_x, int taille_y,int MAX, int DETAIL)
{
	FILE *fp = NULL;
	fp = fopen(tab,"w");

	if(fp ==NULL)
	{
		printf("\ntab_to_txt : ERREUR OUVERTURE FICHIER\n");
	}

	choix_ascii(img_ascii,largeur_ascii*hauteur_ascii,taille_x,taille_y,final_ascii,0,MAX,DETAIL);

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

__host__ void txt_to_png(int width, int height,int largeur_ascii,char* tab_txt, char* tab_png,int MAX, int DETAIL)
{

	char ligne[width];

	sprintf(ligne,"convert -font Courier -background white -fill black label:@%s -flatten images_ascii/%s",tab_txt,tab_png);

  system(ligne);
}
