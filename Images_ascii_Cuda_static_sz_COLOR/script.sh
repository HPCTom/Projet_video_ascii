rm -r images_ascii_script
mkdir images_ascii_script

mode=(0 255 1)

for PERCENT in $@
    do
        cd images_ascii_script
        mkdir $PERCENT
        cd ..
        for first in ${mode[@]}
            do
                for second in ${mode[@]}
                    do
                        if [ $first != $second ]; then
                            cd "images_ascii_script/""$PERCENT" && mkdir "$first""_""$second"                      
                            cd .. && cd ..           
                            ./modif_img $PERCENT $first $second                            
                            cp images_ascii/*.jpg "images_ascii_script/""$PERCENT""/""$first""_""$second" 
                        fi
                    done
            done
    done

