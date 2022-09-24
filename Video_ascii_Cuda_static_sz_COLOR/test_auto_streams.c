#include <stdio.h>

#define NB_STREAMS 4

int main()
{
    int nb_streams = NB_STREAMS;
    int streams[NB_STREAMS];
    for(int k=0;k<NB_STREAMS;k++){
        streams[k] = k;
    }
    int max = 9;
    printf("khkhj %d %f \n",max%NB_STREAMS,(float)max/(float)NB_STREAMS);
    
    for (int k=0;k<max;k=k+NB_STREAMS){
        if(k+NB_STREAMS>=max && max%NB_STREAMS != 0){
            nb_streams = max%NB_STREAMS;
        }
        
        for(int i = 0; i<nb_streams;i++){
            printf("stream[%d] = %d \n",i,streams[i]);
        }
        printf("\n");
        
    }

    return 0;
}