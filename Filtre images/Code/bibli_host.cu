//##########################################################################################
//################################### HOST #################################################
//##########################################################################################


double get_time() {
  struct timeval tv;
  gettimeofday(&tv, (void *)0);
  return (double) tv.tv_sec + tv.tv_usec*1e-6;
}

__host__ int error_msg(int argc,int argv1, int argv2, int argv3){
  int q = (argv3 == 0) + (argv3 == 6) + (argv3 == 7) + (argv3 == 8) + (argv3 == 9) + (argv3 == 10) + (argv3 == 12) + (argv3 == 14);
	if(argc != 4 || !q){
		printf("Usage : le programme prend 3 arguments.\n"
					"argv[1] = le nombre de threads par bloc selon x.\n"
					"argv[2] = le nombre de threads par bloc selon y.\n"
					"argv[3] = le numéro de la question qu'on souhaite réaliser (6,7,8,9,10,12,14).\n\n"
          "Exemple: ./modif_img.exe 32 20 6 \n\n");
    return 1;
	}
  if(argv1*argv2 > 1024){
    printf("\nERROR : Nombre de threads par bloc possible dépassé, argv[2]*argv[3] doit etre inférieur à 1024. \n\n");
    return 1;
  }
  return 0;
}

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

__host__ void SAVE_IMG(unsigned int *img,int  height, int width,const char *PathDest,const char *PathSave,unsigned pitch,FIBITMAP* bitmap){
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

  if( FreeImage_Save (FIF_PNG, bitmap , PathSave , 0 ))
    printf("Image successfully saved ! ");
  FreeImage_DeInitialise(); //Cleanup !
	printf("bip bip bip\n");
}


__host__ void free_all(unsigned int* d_img,unsigned int *img, unsigned int *d_tmp,int *d_filtre,int* filtre){
	cudaFree(d_img);
  cudaFree(d_tmp);
	cudaFree(d_filtre);

	cudaFree(img);
	cudaFree(filtre);
}

__host__ void affichage(int block_x, int block_y, int grid_x, int grid_y, int height, int width){

	int nb_sleep_thread_x = grid_x*block_x-width; // nombres de threads inatif par ligne
	int nb_sleep_thread_y = grid_y*block_y-height;
	printf("\n");
	printf("##############   blockDim.x = %d\n",block_x);
	printf("##############   gridDim.x = %d\n",grid_x);
	printf("##############   blockDim.y = %d\n",block_y);
	printf("##############   gridDim.y = %d\n",grid_y);
	printf("##############   nombre de threads inactif par ligne = %d\n",nb_sleep_thread_x);
	printf("##############   nombre de threads inactif par colonne = %d\n",nb_sleep_thread_y);
	printf("\n");
}


__host__ void filtre_SOBEL(int *filtre){
	//############# FILTRE NORMAL ########################
	//déclaration et initialisation filtre horizontal
	filtre[0] = filtre[6] = -1;
	filtre[1] = filtre[4] = filtre[7] = 0;
	filtre[2] = filtre[8] = 1;
	filtre[3] = -2;
	filtre[5] = 2;

	//déclaration et initialisation filtre vertical
	filtre[9] = filtre[11] = -1;
	filtre[12] = filtre[13] = filtre[14] = 0;
	filtre[15] = filtre[17] = 1;
	filtre[10] = -2;
	filtre[16] = 2;
}
