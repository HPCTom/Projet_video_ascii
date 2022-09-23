import cv2
import numpy as np
import os
import subprocess
import sys

################################## DECOUPE LA VIDEO ########################################

if len( sys.argv ) != 2:
    print("Un seul argument autorisé: nom de la video.\n")
    exit()

subprocess.run(["rm","-r","images/"]) # supprime le dossier images
subprocess.run(["mkdir","images"]) # Creer dossier images vide


vidcap = cv2.VideoCapture('video/'+sys.argv[1])
width = int(vidcap.get(cv2.CAP_PROP_FRAME_WIDTH)) #Prend les fps de le video originale
height = int(vidcap.get(cv2.CAP_PROP_FRAME_HEIGHT)) #Prend les fps de le video originale

count = 0
dir = "images"
for path in os.listdir(dir):
    if os.path.isfile(os.path.join(dir, path)):
        count += 1

if count==0: #Si le dossier est vide
    success,image = vidcap.read()
    count = 0
    while success:
      cv2.imwrite("images/frame%d.jpg" % count, image)     # save frame as JPEG file
      success,image = vidcap.read()
      # print('Read a new frame: ', success)
      count += 1
    print("\nVideo \""+ sys.argv[1]+"\" bien decoupée,",count,"images",width,"x",height,"pixels.\n");


cv2.destroyAllWindows()
vidcap.release()
