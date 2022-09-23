#include "lib_ascii.h"

constexpr std::size_t lib_ascii::kwidthCaracter;    // width
constexpr std::size_t lib_ascii::kheightCaracter;  // height
constexpr std::size_t lib_ascii::kCaracter;        // nb characters
constexpr std::size_t lib_ascii::kPixelPerCaracter;
constexpr char  lib_ascii::kOrderedAscii[];
constexpr lib_ascii::PixelType lib_ascii::kDefaultCaracters[];

void affiche_ascii(const lib_ascii &ascii){
    int width = ascii.kwidthCaracter;
    int height = ascii.kheightCaracter;
    int nb = ascii.size();                                          // nombres total de caracteres
    int affichage_nb_ascii_largeur = ascii.size();
    int nb_elem_ligne = affichage_nb_ascii_largeur*width*height;    //nombre de pixels par ligne 
    int val;

    if(affichage_nb_ascii_largeur>nb){
        affichage_nb_ascii_largeur=nb;
    }
    int lignes = ceil((float)(nb)/(float)(affichage_nb_ascii_largeur));
    int size_last_ligne = affichage_nb_ascii_largeur-(lignes*affichage_nb_ascii_largeur-nb);

    for(int l=0;l<lignes;l++){
        if(l==lignes-1){
            affichage_nb_ascii_largeur = size_last_ligne;
        }
        for(int next_l=0;next_l<height;next_l++){
            for(int next_c=0; next_c<affichage_nb_ascii_largeur; next_c++){
                for(int elem=0;elem<width;elem++){
                    val = ascii.CaracterArray()[l*nb_elem_ligne+next_l*width+next_c*width*height+elem];
                    if(val==1){
                        std::cout << "\033[1;33m" << val <<"\033[0m";
                    }
                    else{
                        std::cout << val;
                    }
                }
                std::cout << "\t";
            }
            std::cout << "\n";
        }
        std::cout << "\n";
    }        
}