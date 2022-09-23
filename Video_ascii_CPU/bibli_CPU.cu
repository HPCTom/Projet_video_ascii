
// Mesures temps
double start,stop,start_kernel,stop_kernel,cpu_time_used,temps_kernel_moyen;
double *temps_kernel;
char num[10]; // Pour le num de framex.png

// Pour la barre de chargement
float p_avant = 0.;
float eps = 1.5; // pourcentage pour 1 '#' dans la barre
char barre[200];


unsigned width;
unsigned height;
unsigned pitch;


int sz_in_bytes;
unsigned int *img;

// Pour le traitement ascii
int block_x;
int grid_x;
int block_y;
int grid_y;

int DETAIL; //nombre d'ascii différents

int gridDim_x; // largeur de l'image en nombre d'ascii
int gridDim_y; // hauteur de l'image en nombre d'ascii

int blockDim_x; // nombre de pixel en largeur qui sera contenu dans 1 ascii
int blockDim_y; // nombre de pixel en hauteur qui sera contenu dans 1 ascii
int blockIdx_x; // Id des blocks en largeur (identique en Cuda)
int blockIdx_y; // Id des blocks en hauteur (identique en Cuda)

int threadIdx_y;
int threadIdx_x;

int n_x;
int n_y;

int nb_sleep_thread_x; // nombres de threads inatif par ligne
int nb_sleep_thread_y; // nombre de threads inactif par colonne

float *img_ascii;

int MAX;

char *final_ascii;
