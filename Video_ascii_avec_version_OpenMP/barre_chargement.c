#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>
#include <sys/time.h>

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

  int main (int argc , char** argv)
  {
    float eps = 1.5; // pourcentage équivalent à 1 '#' dans la barre
    int taille = 0;
    char barre[200] = "Traitement ascii des images";
    float max_it = 1000;
    init_barre_chargement(barre,&taille,eps,max_it);
    for(int k=0; k<max_it;k++){
      barre_chargement(barre,100*(k+1)/max_it,k+1,max_it,eps,taille);
      usleep(1000);
    }
    printf("\n");
    return 0;
  }
