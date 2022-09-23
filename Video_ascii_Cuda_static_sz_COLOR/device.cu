//##############################################################################################
//################################### FONCTION DEVICE ##########################################
//##############################################################################################


__global__ void Init_float_num(float *d_img, unsigned int width, unsigned int height,unsigned int nb_sleep_thread_x,
							   unsigned int nb_sleep_thread_y,float num)
{

	// dim3 dimBlock_init(blockDim_x_ascii,blockDim_y_ascii,1);
    // dim3 dimGrid_init(gridDim_x_ascii,gridDim_y_ascii,1);
    // Init_float_num<<<dimGrid_init, dimBlock_init>>>(d_img_ascii,gridDim_x_ascii,gridDim_y_ascii,
    //                                                 nb_sleep_thread_x_ascii,nb_sleep_thread_y_ascii,0.);

	if(blockIdx.y < gridDim.y-1 || blockIdx.y == gridDim.y-1 && threadIdx.y < blockDim.y-nb_sleep_thread_y){
		if(blockIdx.x < gridDim.x-1 || blockIdx.x == gridDim.x-1 && threadIdx.x < blockDim.x-nb_sleep_thread_x){
			int x = blockIdx.x * blockDim.x + threadIdx.x;
			int y = blockIdx.y * blockDim.y + threadIdx.y;

			int idx = ((y * width) + x) * 4;

			d_img[idx+0] = num;
			d_img[idx+1] = num;	
			d_img[idx+2] = num;	
			d_img[idx+3] = num;
			
		}
	}
}



__global__ void Niveau_Gris_Color_Moyennage(float *d_img_ascii,unsigned int* d_img,unsigned width,
											int nb_sleep_thread_x,int nb_sleep_thread_y,
 									  		int nb_sleep_thread_x_ascii,int nb_sleep_thread_y_ascii,
									  		int gridDim_x_ascii,int gridDim_y_ascii,int blockDim_x_ascii,
											int blockDim_y_ascii,int ite)
{
	if(blockIdx.y < gridDim.y-1 || blockIdx.y == gridDim.y-1 && threadIdx.y < blockDim.y-nb_sleep_thread_y){
		if(blockIdx.x < gridDim.x-1 || blockIdx.x == gridDim.x-1 && threadIdx.x < blockDim.x-nb_sleep_thread_x){

			int x = blockIdx.x * blockDim.x + threadIdx.x;
			int y = blockIdx.y * blockDim.y + threadIdx.y;

			int idx = ((y * width) + width - x) * 3;

			int idx_ascii = (int)((float)y/(float)blockDim_y_ascii) * gridDim_x_ascii + (int)((float)x/(float)blockDim_x_ascii);

			atomicAdd(&d_img_ascii[4*idx_ascii+0],0.299*d_img[idx+0]+0.587*d_img[idx+1]+0.114*d_img[idx+2]);
			atomicAdd(&d_img_ascii[4*idx_ascii+1],d_img[idx+0]);
			atomicAdd(&d_img_ascii[4*idx_ascii+2],d_img[idx+1]);
			atomicAdd(&d_img_ascii[4*idx_ascii+3],d_img[idx+2]);

		}
	}

}


// kernel avec des blocks en ascii.kwidthCaracter*(ascii.kheightCaracter+1)
__global__ void Image_Color(float *d_img_ascii,unsigned char *d_img_ascii_color_final,unsigned char *d_tab_ascii_lib,
							unsigned int width_color,unsigned int width_lib,unsigned int height_lib,
							unsigned int nb_characters,unsigned int gridDim_x_ascii,unsigned int gridDim_y_ascii,
							int blockDim_x_ascii,int blockDim_y_ascii,unsigned int nb_sleep_thread_x_color, unsigned int nb_sleep_thread_y_color,
							int mode_a, int mode_b)
{

	int x = blockIdx.x * blockDim.x + threadIdx.x;
	int y = blockIdx.y * blockDim.y + threadIdx.y;
	int idx = ((y * width_color) + width_color - x) * 3 - 3;
	int idx_ascii = blockIdx.y * gridDim.x + blockIdx.x;
	float eps = 0.1;

	if(blockIdx.x == gridDim.x-1 && blockIdx.y == gridDim.y-1){
		int deno = (blockDim_x_ascii-nb_sleep_thread_x_color)*(blockDim_y_ascii-nb_sleep_thread_y_color);
		int pos = (int)(nb_characters*(((float)d_img_ascii[4*idx_ascii+0]/(deno))/(float)255));
		int idx_lib = pos*width_lib*height_lib;
		int idx_tab_ascii_lib = idx_lib + width_lib*height_lib - (threadIdx.y+1)*blockDim.x + width_lib-threadIdx.x-1;
		float val_red = (d_img_ascii[4*idx_ascii+1])/(deno);
		float val_green = (d_img_ascii[4*idx_ascii+2])/(deno);
		float val_blue = (d_img_ascii[4*idx_ascii+3])/(deno);
		if(d_tab_ascii_lib[idx_tab_ascii_lib] == 0){
			int var_temp_b = __float2int_rn(mode_b/255); // 0 si 0 ou 1 sinon 1 pour 255
			float background_red = (val_red+eps)*((((mode_b*var_temp_b)/(val_red+eps))+abs((var_temp_b-1)*mode_b)));
			float background_green = (val_green+eps)*((((mode_b*var_temp_b)/(val_green+eps))+abs((var_temp_b-1)*mode_b)));
			float background_blue = (val_blue+eps)*((((mode_b*var_temp_b)/(val_blue+eps))+abs((var_temp_b-1)*mode_b)));

			d_img_ascii_color_final[idx+0] = __float2int_rn(background_red);
			d_img_ascii_color_final[idx+1] = __float2int_rn(background_green);
			d_img_ascii_color_final[idx+2] = __float2int_rn(background_blue);
		}
		else{
			int var_temp_a = __float2int_rd(mode_a/255); // 0 si 0 ou 1 sinon 1 pour 255
			float ascii_red = (val_red+eps)*((((mode_a*var_temp_a)/(val_red+eps))+abs((var_temp_a-1)*mode_a)));
			float ascii_green = (val_green+eps)*((((mode_a*var_temp_a)/(val_green+eps))+abs((var_temp_a-1)*mode_a)));
			float ascii_blue = (val_blue+eps)*((((mode_a*var_temp_a)/(val_blue+eps))+abs((var_temp_a-1)*mode_a)));

			d_img_ascii_color_final[idx+0] = __float2int_rn(ascii_red);
			d_img_ascii_color_final[idx+1] = __float2int_rn(ascii_green);
			d_img_ascii_color_final[idx+2] = __float2int_rn(ascii_blue);
		}
	}

	else if(blockIdx.x == gridDim.x-1){
		int deno = (blockDim_x_ascii-nb_sleep_thread_x_color)*blockDim_y_ascii;
		int pos = (int)(nb_characters*(((float)d_img_ascii[4*idx_ascii+0]/(deno))/(float)255));
		int idx_lib = pos*width_lib*height_lib;
		int idx_tab_ascii_lib = idx_lib + width_lib*height_lib - (threadIdx.y+1)*blockDim.x + width_lib-threadIdx.x-1;
		float val_red = (d_img_ascii[4*idx_ascii+1])/(deno);
		float val_green = (d_img_ascii[4*idx_ascii+2])/(deno);
		float val_blue = (d_img_ascii[4*idx_ascii+3])/(deno);
		if(d_tab_ascii_lib[idx_tab_ascii_lib] == 0){
			int var_temp_b = __float2int_rn(mode_b/255); // 0 si 0 ou 1 sinon 1 pour 255
			float background_red = (val_red+eps)*((((mode_b*var_temp_b)/(val_red+eps))+abs((var_temp_b-1)*mode_b)));
			float background_green = (val_green+eps)*((((mode_b*var_temp_b)/(val_green+eps))+abs((var_temp_b-1)*mode_b)));
			float background_blue = (val_blue+eps)*((((mode_b*var_temp_b)/(val_blue+eps))+abs((var_temp_b-1)*mode_b)));

			d_img_ascii_color_final[idx+0] = __float2int_rn(background_red);
			d_img_ascii_color_final[idx+1] = __float2int_rn(background_green);
			d_img_ascii_color_final[idx+2] = __float2int_rn(background_blue);
		}
		else{
			int var_temp_a = __float2int_rd(mode_a/255); // 0 si 0 ou 1 sinon 1 pour 255
			float ascii_red = (val_red+eps)*((((mode_a*var_temp_a)/(val_red+eps))+abs((var_temp_a-1)*mode_a)));
			float ascii_green = (val_green+eps)*((((mode_a*var_temp_a)/(val_green+eps))+abs((var_temp_a-1)*mode_a)));
			float ascii_blue = (val_blue+eps)*((((mode_a*var_temp_a)/(val_blue+eps))+abs((var_temp_a-1)*mode_a)));

			d_img_ascii_color_final[idx+0] = __float2int_rn(ascii_red);
			d_img_ascii_color_final[idx+1] = __float2int_rn(ascii_green);
			d_img_ascii_color_final[idx+2] = __float2int_rn(ascii_blue);
		}
	}

	else if(blockIdx.y == gridDim.y-1){
		int deno = blockDim_x_ascii*(blockDim_y_ascii-nb_sleep_thread_y_color);
		int pos = (int)(nb_characters*(((float)d_img_ascii[4*idx_ascii+0]/(deno))/(float)255));
		int idx_lib = pos*width_lib*height_lib;
		int idx_tab_ascii_lib = idx_lib + width_lib*height_lib - (threadIdx.y+1)*blockDim.x + width_lib-threadIdx.x-1;
		float val_red = (d_img_ascii[4*idx_ascii+1])/(deno);
		float val_green = (d_img_ascii[4*idx_ascii+2])/(deno);
		float val_blue = (d_img_ascii[4*idx_ascii+3])/(deno);
		if(d_tab_ascii_lib[idx_tab_ascii_lib] == 0){
			int var_temp_b = __float2int_rn(mode_b/255); // 0 si 0 ou 1 sinon 1 pour 255
			float background_red = (val_red+eps)*((((mode_b*var_temp_b)/(val_red+eps))+abs((var_temp_b-1)*mode_b)));
			float background_green = (val_green+eps)*((((mode_b*var_temp_b)/(val_green+eps))+abs((var_temp_b-1)*mode_b)));
			float background_blue = (val_blue+eps)*((((mode_b*var_temp_b)/(val_blue+eps))+abs((var_temp_b-1)*mode_b)));

			d_img_ascii_color_final[idx+0] = __float2int_rn(background_red);
			d_img_ascii_color_final[idx+1] = __float2int_rn(background_green);
			d_img_ascii_color_final[idx+2] = __float2int_rn(background_blue);
		}
		else{
			int var_temp_a = __float2int_rd(mode_a/255); // 0 si 0 ou 1 sinon 1 pour 255
			float ascii_red = (val_red+eps)*((((mode_a*var_temp_a)/(val_red+eps))+abs((var_temp_a-1)*mode_a)));
			float ascii_green = (val_green+eps)*((((mode_a*var_temp_a)/(val_green+eps))+abs((var_temp_a-1)*mode_a)));
			float ascii_blue = (val_blue+eps)*((((mode_a*var_temp_a)/(val_blue+eps))+abs((var_temp_a-1)*mode_a)));

			d_img_ascii_color_final[idx+0] = __float2int_rn(ascii_red);
			d_img_ascii_color_final[idx+1] = __float2int_rn(ascii_green);
			d_img_ascii_color_final[idx+2] = __float2int_rn(ascii_blue);
		}
	}

	else{
		int deno = blockDim_x_ascii*blockDim_y_ascii; 																		// Nombre de threads ayant participé au caractère
		int pos = (int)(nb_characters*(((float)d_img_ascii[4*idx_ascii+0]/(deno))/(float)255));								// choix du caracter en fonction du niveau de gris
		int idx_lib = pos*width_lib*height_lib; 																			// Position du carcatere dans la lib
		int idx_tab_ascii_lib = idx_lib + width_lib*height_lib - (threadIdx.y+1)*blockDim.x + width_lib-threadIdx.x-1;		// Indice dans la lib de caractères
		float val_red = (d_img_ascii[4*idx_ascii+1])/(deno);																// Couleur rouge moyennée
		float val_green = (d_img_ascii[4*idx_ascii+2])/(deno);																// Couleur verte moyennée
		float val_blue = (d_img_ascii[4*idx_ascii+3])/(deno);																// Couleur bleue moyennée
		if(d_tab_ascii_lib[idx_tab_ascii_lib] == 0){	
			int var_temp_b = __float2int_rn(mode_b/255); 																	// 0 si 0 ou 1, sinon, 1 pour 255
			float background_red = (val_red+eps)*((((mode_b*var_temp_b)/(val_red+eps))+abs((var_temp_b-1)*mode_b)));		// Couleur du fond rouge , complexe mais perlet d'avoir 3 modes différents (noir,blanc et couleur) avec 3 input (0,255 et 1)
			float background_green = (val_green+eps)*((((mode_b*var_temp_b)/(val_green+eps))+abs((var_temp_b-1)*mode_b))); 	// Couleur du fond vert , complexe mais perlet d'avoir 3 modes différents (noir,blanc et couleur) avec 3 input (0,255 et 1)
			float background_blue = (val_blue+eps)*((((mode_b*var_temp_b)/(val_blue+eps))+abs((var_temp_b-1)*mode_b)));		// Couleur du fond bleu, complexe mais perlet d'avoir 3 modes différents (noir,blanc et couleur) avec 3 input (0,255 et 1)

			d_img_ascii_color_final[idx+0] = __float2int_rn(background_red);
			d_img_ascii_color_final[idx+1] = __float2int_rn(background_green);
			d_img_ascii_color_final[idx+2] = __float2int_rn(background_blue);
		}
		else{
			int var_temp_a = __float2int_rd(mode_a/255);
			float ascii_red = (val_red+eps)*((((mode_a*var_temp_a)/(val_red+eps))+abs((var_temp_a-1)*mode_a)));
			float ascii_green = (val_green+eps)*((((mode_a*var_temp_a)/(val_green+eps))+abs((var_temp_a-1)*mode_a)));
			float ascii_blue = (val_blue+eps)*((((mode_a*var_temp_a)/(val_blue+eps))+abs((var_temp_a-1)*mode_a)));

			d_img_ascii_color_final[idx+0] = __float2int_rn(ascii_red);
			d_img_ascii_color_final[idx+1] = __float2int_rn(ascii_green);
			d_img_ascii_color_final[idx+2] = __float2int_rn(ascii_blue);
		}
	}


}