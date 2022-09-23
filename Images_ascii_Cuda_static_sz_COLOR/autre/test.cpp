#include <iostream>
#include "FreeImage.h"

#define WIDTH 800
#define HEIGHT 600
#define BPP 24//Sincewe’reoutputtingthree8bitRGBvalues
using namespace std;

int main(int argc,char *argv[]){
    FreeImage_Initialise();
    FIBITMAP *bitmap=FreeImage_Allocate(WIDTH,HEIGHT,BPP);
    RGBQUAD color;
    if(!bitmap)
        exit(1);//WTF?!Wecan’tevenallocateimages?Die!
    //Drawsagradientfrombluetogreen:
    for(int i=0;i<WIDTH;i++){
        for(int j=0;j<HEIGHT;j++){
            color.rgbRed=0;
            color.rgbGreen=255;
            color.rgbBlue=255;
            // color.rgbGreen=(double)i/WIDTH*255.0;
            // color.rgbBlue=(double)j/HEIGHT*255.0;
            FreeImage_SetPixelColor(bitmap,i,j,&color);
            //Noticehowwe’recallingthe&operatoron”color”
            //sothatwecanpassapointertothecolorstruct.
        }
    }
    if(FreeImage_Save(FIF_PNG,bitmap,"test.png",0))
        cout<<"Imagesuccessfullysaved!"<<endl;
    FreeImage_DeInitialise();//Cleanup!
}