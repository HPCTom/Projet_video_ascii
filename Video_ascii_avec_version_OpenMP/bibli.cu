
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

unsigned int *d_img;

// Pour le prétraitement d'images
int block_x;
int grid_x;
int block_y;
int grid_y;


// Pour le traitement ascii
int DETAIL; //nombre d'ascii différents

int grid_x_ascii; // largeur de l'image en nombre d'ascii
int grid_y_ascii;

int block_x_ascii;
int block_y_ascii;

int nb_sleep_thread_x_all; // nombres de threads inatif selon x
int nb_sleep_thread_y_all; // nombres de threads inatif selon y
int nb_sleep_block_x; // nombre de blocks inactifs selon x (arrondie inférieur)
int nb_sleep_block_y; // nombre de blocs inactis selon y (arrondie inférieur)



float *img_ascii;
float *d_img_ascii;

int MAX;

char *final_ascii;
