//##############################################################################################
//################################### FONCTION DEVICE ##########################################
//##############################################################################################


__global__ void Filtre(unsigned int *d_img, unsigned width, unsigned height)
{
	int x = blockIdx.x * blockDim.x + threadIdx.x;
	int y = blockIdx.y * blockDim.y + threadIdx.y;

	int n_x = gridDim.x*blockDim.x; // nombre de threads par ligne
	int n_y = gridDim.y*blockDim.y; // nombres de threads par colonne

	int nb_sleep_thread_x = n_x-width; // nombres de threads inatif par ligne
  	int nb_sleep_thread_y = n_y-height; // nombre de threads inactif par colonne

	if(blockIdx.y < gridDim.y-1 || blockIdx.y == gridDim.y-1 && threadIdx.y < blockDim.y-nb_sleep_thread_y){
		if(blockIdx.x < gridDim.x-1 || blockIdx.x == gridDim.x-1 && threadIdx.x < blockDim.x-nb_sleep_thread_x){

			int ida = ((y * width) + x) * 3;
			d_img[ida] = 255;

		}
	}
}

__global__ void Sym_horizontale(unsigned int *d_img, unsigned int *d_tmp, unsigned width, unsigned height)
{
	int x = blockIdx.x * blockDim.x + threadIdx.x;
	int y = blockIdx.y * blockDim.y + threadIdx.y;

	int n_x = gridDim.x*blockDim.x; // nombre de threads par ligne
	int n_y = gridDim.y*blockDim.y; // nombres de threads par colonne

	int nb_sleep_thread_x = n_x-width; // nombres de threads inatif par ligne
  	int nb_sleep_thread_y = n_y-height; // nombre de threads inactif par colonne

	if(blockIdx.y < gridDim.y-1 || blockIdx.y == gridDim.y-1 && threadIdx.y < blockDim.y-nb_sleep_thread_y){
		if(blockIdx.x < gridDim.x-1 || blockIdx.x == gridDim.x-1 && threadIdx.x < blockDim.x-nb_sleep_thread_x){

				int ida = ((y * width) + x) * 3;
				int idb = (width * height - y*width - width + x) * 3;
				d_img[ida+0] = d_tmp[idb+0];
				d_img[ida+1] = d_tmp[idb+1];
				d_img[ida+2] = d_tmp[idb+2];
		}
	}
}

__global__ void Floutage(unsigned int *d_img, unsigned int *d_tmp, unsigned width, unsigned height, int p) // FLOU
{
	int n_x = gridDim.x*blockDim.x; // nombre de threads par ligne
	int n_y = gridDim.y*blockDim.y; // nombres de threads par colonne

	int nb_sleep_thread_x = n_x-width; // nombres de threads inatif par ligne
	int nb_sleep_thread_y = n_y-height; // nombre de threads inactif par colonne

	if(blockIdx.y < gridDim.y-1 || blockIdx.y == gridDim.y-1 && threadIdx.y < blockDim.y-nb_sleep_thread_y){
		if(blockIdx.x < gridDim.x-1 || blockIdx.x == gridDim.x-1 && threadIdx.x < blockDim.x-nb_sleep_thread_x){
			int x = blockIdx.x * blockDim.x + threadIdx.x;
			int y = blockIdx.y * blockDim.y + threadIdx.y;

			int idx = ((y * width) + x) * 3;
		  	int idg = ((y*width) + x-1) * 3; //idg = id pixel à gauche
		  	int idd = ((y*width) + x+1) * 3; //idd = id pixel à droite
		  	int idb = (((y-1)*width) + x) * 3; //idb = id pixel en bas
		  	int idh = (((y+1)*width) + x) * 3; //idh = id pixel du dessus
	
		  	int cond_BAS = (blockIdx.y==0 && threadIdx.y == 0); // bas
		  	int cond_HAUT = (blockIdx.y==gridDim.y-1 && threadIdx.y == blockDim.y-nb_sleep_thread_y-1); // haut
		  	int cond_GAUCHE = (blockIdx.x==0 && threadIdx.x == 0); // gauche
		  	int cond_DROITE = (blockIdx.x==gridDim.x-1 && threadIdx.x == blockDim.x-nb_sleep_thread_x-1); // droite
	
		  	int cond_coin_1 = cond_BAS*cond_GAUCHE; // bas gauche
		  	int cond_coin_2 = cond_BAS*cond_DROITE; // bas droite
		  	int cond_coin_3 = cond_HAUT*cond_GAUCHE; // haut gauche
		  	int cond_coin_4 = cond_HAUT*cond_DROITE; // haut droite

				if(cond_BAS) // bas
				{
			    if(cond_coin_1){ // gauche
						for(int k=0;k<3;k++){
							if(p%2==0){
								d_img[idx+k] = (d_img[idx+k]+d_img[idd+k]+d_img[idh+k])/3;
							}
							else{
								d_img[idx+k] = ceil((d_img[idx+k]+d_img[idd+k]+d_img[idh+k])/3.);
							}
						}
			    }

			    else if(cond_coin_2){ // droite
						for(int k=0;k<3;k++){
							if(p%2==0){
								d_img[idx+k] = (d_img[idx+k]+d_img[idg+k]+d_img[idh+k])/3;
							}
							else{
								d_img[idx+k] = ceil((d_img[idx+k]+d_img[idg+k]+d_img[idh+k])/3.);
							}
						}
			    }

			    else{
						for(int k=0;k<3;k++){
							if(p%2==0){
								d_img[idx+k] = (d_img[idx+k]+d_img[idg+k]+d_img[idd+k]+d_img[idh+k])/4;
							}
							else{
								d_img[idx+k] = ceil((d_img[idx+k]+d_img[idg+k]+d_img[idd+k]+d_img[idh+k])/4.);
							}
						}
			    }
			  }

				else if(cond_HAUT) // haut
				{
			    if(cond_coin_3){ // gauche
						for(int k=0;k<3;k++){
							if(p%2==0){
								d_img[idx+k] = (d_img[idx+k]+d_img[idd+k]+d_img[idb+k])/3;
							}
							else{
								d_img[idx+k] = ceil((d_img[idx+k]+d_img[idd+k]+d_img[idb+k])/3.);
							}
						}
			    }

			    else if(cond_coin_4){ // droite
						for(int k=0;k<3;k++){
							if(p%2==0){
								d_img[idx+k] = (d_img[idx+k]+d_img[idg+k]+d_img[idb+k])/3;
							}
							else{
								d_img[idx+k] = ceil((d_img[idx+k]+d_img[idg+k]+d_img[idb+k])/3.);
							}
						}
			    }
			    else{
						for(int k=0;k<3;k++){
							if(p%2==0){
								d_img[idx+k] = (d_img[idx+k]+d_img[idg+k]+d_img[idd+k]+d_img[idb+k])/4;
							}
							else{
								d_img[idx+k] = ceil((d_img[idx+k]+d_img[idg+k]+d_img[idd+k]+d_img[idb+k])/4.);
							}
						}
			    }
			  }

				else if(cond_GAUCHE) // gauche
				{
					for(int k=0;k<3;k++){
						if(p%2==0){
							d_img[idx+k] = (d_img[idx+k]+d_img[idd+k]+d_img[idb+k]+d_img[idh+k])/4;
						}
						else{
							d_img[idx+k] = ceil((d_img[idx+k]+d_img[idd+k]+d_img[idb+k]+d_img[idh+k])/4.);
						}
					}
			  }

				else if(cond_DROITE) // droite
				{
					for(int k=0;k<3;k++){
						if(p%2==0){
							d_img[idx+k] = (d_img[idx+k]+d_img[idg+k]+d_img[idb+k]+d_img[idh+k])/4;
						}
						else{
							d_img[idx+k] = ceil((d_img[idx+k]+d_img[idg+k]+d_img[idb+k]+d_img[idh+k])/4.);
						}
					}
			  }

				else
			  {
					for(int k=0;k<3;k++){
						if(p%2==0){
							d_img[idx+k] = (d_img[idx+k]+d_img[idg+k]+d_img[idd+k]+d_img[idb+k]+d_img[idh+k])/5;
						}
						else{
							d_img[idx+k] = ceil((d_img[idx+k]+d_img[idg+k]+d_img[idd+k]+d_img[idb+k]+d_img[idh+k])/5.);
						}
					}
				}
		}
	}
}

__global__ void Niveau_Gris(unsigned int *d_tmp, unsigned width, unsigned height) // NIVEAU DE GRIS
{
	int n_x = gridDim.x*blockDim.x; // nombre de threads par ligne
	int n_y = gridDim.y*blockDim.y; // nombres de threads par colonne

	int nb_sleep_thread_x = n_x-width; // nombres de threads inatif par ligne
	int nb_sleep_thread_y = n_y-height; // nombre de threads inactif par colonne

	if(blockIdx.y < gridDim.y-1 || blockIdx.y == gridDim.y-1 && threadIdx.y < blockDim.y-nb_sleep_thread_y){
		if(blockIdx.x < gridDim.x-1 || blockIdx.x == gridDim.x-1 && threadIdx.x < blockDim.x-nb_sleep_thread_x){
			int x = blockIdx.x * blockDim.x + threadIdx.x;
			int y = blockIdx.y * blockDim.y + threadIdx.y;

			int idx = ((y * width) + x) * 3;

			d_tmp[idx+0] = 0.299*d_tmp[idx+0]+0.587*d_tmp[idx+1]+0.114*d_tmp[idx+2];
			d_tmp[idx+1] = d_tmp[idx+0];
			d_tmp[idx+2] = d_tmp[idx+0];
		}
	}
}

__global__ void Contour_Sobel(unsigned int *d_img, unsigned int *d_tmp, unsigned width,unsigned height, // SOBEL CONTOUR
											 				int *d_filtre)
{
	int n_x = gridDim.x*blockDim.x; // nombre de threads par ligne
	int n_y = gridDim.y*blockDim.y; // nombres de threads par colonne

	int nb_sleep_thread_x = n_x-width; // nombres de threads inatif par ligne
	int nb_sleep_thread_y = n_y-height; // nombre de threads inactif par colonne

	if(blockIdx.y < gridDim.y-1 || blockIdx.y == gridDim.y-1 && threadIdx.y < blockDim.y-nb_sleep_thread_y){
		if(blockIdx.x < gridDim.x-1 || blockIdx.x == gridDim.x-1 && threadIdx.x < blockDim.x-nb_sleep_thread_x){
			int x = blockIdx.x * blockDim.x + threadIdx.x;
			int y = blockIdx.y * blockDim.y + threadIdx.y;

			int idx = ((y * width) + x) * 3;

			int idhg = (((y+1)*width) + x-1) * 3;
			int idh = (((y+1)*width) + x) * 3; //idh = id pixel du dessus
			int idhd = (((y+1)*width) + x+1) * 3;
			int idg = ((y*width) + x-1) * 3; //idg = id pixel à gauche
			int idd = ((y*width) + x+1) * 3; //idd = id pixel à droite
			int idbg = (((y-1)*width) + x-1) * 3;
			int idb = (((y-1)*width) + x) * 3; //idb = id pixel en bas
			int idbd = (((y-1)*width) + x+1) * 3;

			int cond_BAS = (blockIdx.y==0 && threadIdx.y==0); // bas
			int cond_HAUT = (blockIdx.y==gridDim.y-1 && threadIdx.y==blockDim.y-nb_sleep_thread_y-1); // haut
			int cond_GAUCHE = (blockIdx.x==0 && threadIdx.x==0); // gauche
			int cond_DROITE = (blockIdx.x==gridDim.x-1 && threadIdx.x==blockDim.x-nb_sleep_thread_x-1); // droite

			int cond_coin_1 = cond_BAS*cond_GAUCHE; // bas gauche
			int cond_coin_2 = cond_BAS*cond_DROITE; // bas droite
			int cond_coin_3 = cond_HAUT*cond_GAUCHE; // haut gauche
			int cond_coin_4 = cond_HAUT*cond_DROITE; // haut droite

			//on applique maintenant les filtres de Sobel
			int d_G[2] = {0,0};
			int id[9] = {idhg,idh,idhd,idg,idx,idd,idbg,idb,idbd};

			if(cond_BAS) // BAS
			{
		    if(cond_coin_1) // gauche
				{
					for(int k=0; k<9;k++){
						d_G[0] += d_tmp[id[k]+3*width+3]*d_filtre[k];
						d_G[1] += d_tmp[id[k]+3*width+3]*d_filtre[k+9];
					}
		    }

		    else if(cond_coin_2)//droite
				{
					for(int k=0; k<9;k++){
						d_G[0] += d_tmp[id[k]+3*width-3]*d_filtre[k];
						d_G[1] += d_tmp[id[k]+3*width-3]*d_filtre[k+9];
					}
		    }

		    else
				{
					for(int k=0; k<9;k++){
						d_G[0] += d_tmp[id[k]+3*width]*d_filtre[k];
						d_G[1] += d_tmp[id[k]+3*width]*d_filtre[k+9];
					}
		    }
		  }

			else if(cond_HAUT) // HAUT
			{
		    if(cond_coin_3) // gauche
				{
					for(int k=0; k<9;k++){
						d_G[0] += d_tmp[id[k]-3*width+3]*d_filtre[k];
						d_G[1] += d_tmp[id[k]-3*width+3]*d_filtre[k+9];
					}
		    }

		    else if(cond_coin_4) //droite
				{
					for(int k=0; k<9;k++){
						d_G[0] += d_tmp[id[k]-3*width-3]*d_filtre[k];
						d_G[1] += d_tmp[id[k]-3*width-3]*d_filtre[k+9];
					}
		    }
		    else
				{
					for(int k=0; k<9;k++){
						d_G[0] += d_tmp[id[k]-3*width]*d_filtre[k];
						d_G[1] += d_tmp[id[k]-3*width]*d_filtre[k+9];
					}
		    }
		  }

			else if(cond_GAUCHE) // GAUCHE
			{
				for(int k=0; k<9;k++){
					d_G[0] += d_tmp[id[k]+3]*d_filtre[k];
					d_G[1] += d_tmp[id[k]+3]*d_filtre[k+9];
				}
		  }

			else if(cond_DROITE) // DROITE
			{
				for(int k=0; k<9;k++){
					d_G[0] += d_tmp[id[k]-3]*d_filtre[k];
					d_G[1] += d_tmp[id[k]-3]*d_filtre[k+9];
				}
		  }

			else // CAS GENERAL
		  {
				for(int k=0; k<9;k++){
					d_G[0] += d_tmp[id[k]]*d_filtre[k];
					d_G[1] += d_tmp[id[k]]*d_filtre[k+9];
				}
			}
			d_img[idx] = (int)pow(d_G[0]*d_G[0] + d_G[1]*d_G[1],0.5);
			d_img[idx+1] = d_img[idx];
			d_img[idx+2] = d_img[idx];
		}
	}
}

__global__ void Pop_art(unsigned int *d_img, unsigned int *d_tmp, unsigned width, unsigned height)
{
	int n_x = gridDim.x*blockDim.x; // nombre de threads par ligne
	int n_y = gridDim.y*blockDim.y; // nombres de threads par colonne

	int nb_sleep_thread_x = n_x-width; // nombres de threads inatif par ligne
	int nb_sleep_thread_y = n_y-height; // nombre de threads inactif par colonne

	if(blockIdx.y < gridDim.y-1 || blockIdx.y == gridDim.y-1 && threadIdx.y < blockDim.y-nb_sleep_thread_y){
		if(blockIdx.x < gridDim.x-1 || blockIdx.x == gridDim.x-1 && threadIdx.x < blockDim.x-nb_sleep_thread_x){
			int x = blockIdx.x * blockDim.x + threadIdx.x - blockIdx.y*nb_sleep_thread_x;
			int y = blockIdx.y * blockDim.y + threadIdx.y;

			int ida  = ((y * width) + x) * 3;

			if((x <= width/2) && (y < height/2)){ // BAS GAUCHE
				d_img[ida+0] = 255;
			}
			else if((x > width/2) && (y < height/2)){ // BAS DROITE
				d_img[ida+1] = 255;
			}
			else if((x > width/2) && (y >= height/2)){ //HAUT DROITE
				d_img[ida+2] = 255;
			}
		}
	}
}

__global__ void Pop_art_stream(unsigned int *d_img, unsigned width, unsigned height,int taille,int p)
{
	int n_x = gridDim.x*blockDim.x; // nombre de threads par ligne
	int n_y = gridDim.y*blockDim.y; // nombres de threads par colonne

	int nb_sleep_thread_x = n_x-width; // nombres de threads inatif par ligne
	int nb_sleep_thread_y = n_y-height; // nombre de threads inactif par colonne

	if(blockIdx.y < gridDim.y-1 || blockIdx.y == gridDim.y-1 && threadIdx.y < blockDim.y-nb_sleep_thread_y){
		if(blockIdx.x < gridDim.x-1 || blockIdx.x == gridDim.x-1 && threadIdx.x < blockDim.x-nb_sleep_thread_x){
			int x = blockIdx.x * blockDim.x + threadIdx.x - blockIdx.y*nb_sleep_thread_x;
			int y = p*n_y + blockIdx.y * blockDim.y + threadIdx.y;

			int ida  = ((y * width) + x) * 3;

			if((x <= width/2) && (y < height/2)){
				d_img[ida+0] = 255;
			}
			else if((x > width/2) && (y < height/2)){
				d_img[ida+1] = 255;
			}
			else if((x > width/2) && (y >= height/2)){
				d_img[ida+2] = 255;
			}
		}
	}
}


//##############################################################################################
//################################### EN PLUS ##################################################
//##############################################################################################




__global__ void AUTRE_Pop_art(unsigned int *d_img, unsigned int *d_tmp, unsigned width, unsigned height)
{
	int n_x = gridDim.x*blockDim.x; // nombre de threads par ligne
	int n_y = gridDim.y*blockDim.y; // nombres de threads par colonne

	int nb_sleep_thread_x = n_x-width; // nombres de threads inatif par ligne
	int nb_sleep_thread_y = n_y-height; // nombre de threads inactif par colonne

	if(blockIdx.y < gridDim.y-1 || blockIdx.y == gridDim.y-1 && threadIdx.y < blockDim.y-nb_sleep_thread_y){
		if(blockIdx.x < gridDim.x-1 || blockIdx.x == gridDim.x-1 && threadIdx.x < blockDim.x-nb_sleep_thread_x){
			int x = blockIdx.x * blockDim.x + threadIdx.x - blockIdx.y*nb_sleep_thread_x;
			int y = blockIdx.y * blockDim.y + threadIdx.y;

			int ida  = ((y * width) + x) * 3;

			if((x <= width/2) && (y < height/2)){ // BAS GAUCHE
				int idb = (((y+height/2) * width) + x) * 3;
				d_img[ida+0] = 255;
				d_img[ida+1] = d_tmp[idb+1];
				d_img[ida+2] = d_tmp[idb+2];
			}
			else if((x > width/2) && (y < height/2)){ // BAS DROITE
				int idb = (((y+height/2) * width) + x - width/2) * 3;
				d_img[ida+0] = d_tmp[idb+0];
				d_img[ida+1] = 255;
				d_img[ida+2] = d_tmp[idb+2];
			}
			else if((x > width/2) && (y >= height/2)){ //HAUT DROITE
				int idb = ((y * width) + x - width/2) * 3;
				d_img[ida+0] = d_tmp[idb+0];
				d_img[ida+1] = d_tmp[idb+1];
				d_img[ida+2] = 255;
			}
		}
	}
}
