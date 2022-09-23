//##############################################################################################
//################################### FONCTION DEVICE ##########################################
//##############################################################################################


__global__ void Niveau_Gris(unsigned int *d_img, unsigned width, unsigned height) // NIVEAU DE GRIS
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

			d_img[idx+0] = 0.299*d_img[idx+0]+0.587*d_img[idx+1]+0.114*d_img[idx+2];
			d_img[idx+1] = d_img[idx+0];
			d_img[idx+2] = d_img[idx+0];
		}
	}
}


__global__ void Moyennage(float *d_img_ascii, unsigned int* d_tmp, unsigned width,unsigned height)
{

	int n_x = gridDim.x*blockDim.x; // nombre de threads par ligne
	int n_y = gridDim.y*blockDim.y; // nombres de threads par colonne

	int nb_sleep_thread_x = n_x-width; // nombres de threads inatif par ligne
	int nb_sleep_thread_y = n_y-height; // nombre de threads inactif par colonne

	if(blockIdx.y < gridDim.y-1 || blockIdx.y == gridDim.y-1 && threadIdx.y < blockDim.y-nb_sleep_thread_y){
		if(blockIdx.x < gridDim.x-1 || blockIdx.x == gridDim.x-1 && threadIdx.x < blockDim.x-nb_sleep_thread_x){

			int x = blockIdx.x * blockDim.x + threadIdx.x;
			int y = blockIdx.y * blockDim.y + threadIdx.y;

			int idx = ((y * width) + width - x) * 3;
			int idx_ascii  = gridDim.x*blockIdx.y + blockIdx.x;

			atomicAdd(&d_img_ascii[idx_ascii],(float)d_tmp[idx]);

		}
	}

}


__global__ void Niveau_Gris_Moyennage(float *d_img_ascii, unsigned int* d_img, unsigned width,unsigned height)
{

	int n_x = gridDim.x*blockDim.x; // nombre de threads par ligne
	int n_y = gridDim.y*blockDim.y; // nombres de threads par colonne

	int nb_sleep_thread_x = n_x-width; // nombres de threads inatif par ligne
	int nb_sleep_thread_y = n_y-height; // nombre de threads inactif par colonne

	if(blockIdx.y < gridDim.y-1 || blockIdx.y == gridDim.y-1 && threadIdx.y < blockDim.y-nb_sleep_thread_y){
		if(blockIdx.x < gridDim.x-1 || blockIdx.x == gridDim.x-1 && threadIdx.x < blockDim.x-nb_sleep_thread_x){

			int x = blockIdx.x * blockDim.x + threadIdx.x;
			int y = blockIdx.y * blockDim.y + threadIdx.y;

			int idx = ((y * width) + width - x) * 3;
			int idx_ascii  = gridDim.x*blockIdx.y + blockIdx.x;

			atomicAdd(&d_img_ascii[idx_ascii],0.299*d_img[idx+0]+0.587*d_img[idx+1]+0.114*d_img[idx+2]);

		}
	}

}
