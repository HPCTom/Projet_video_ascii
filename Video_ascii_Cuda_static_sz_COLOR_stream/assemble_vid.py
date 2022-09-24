import cv2
import numpy as np
import os
import subprocess
from subprocess import Popen, PIPE
import sys

vidcap = cv2.VideoCapture('video/'+sys.argv[1])
fps = vidcap.get(cv2.CAP_PROP_FPS) #Prend les fps de le video originale

################################## CALCUL LES DIMENSION DES IMAGES ASCII ########################################

W = subprocess.Popen(["identify" ,"-format","\"%w\"","images_ascii/frame0.png"],stdout=PIPE)
stdout = W.communicate()
width = int(stdout[0].decode('ascii')[1:len(stdout[0].decode('ascii'))-1]) #convertit stdout en ascii puis prend uniquement les chiffre et convertit en entier
W.kill()

H = subprocess.Popen(["identify" ,"-format","\"%h\"","images_ascii/frame0.png"],stdout=subprocess.PIPE)
stdout = H.communicate()
height = int(stdout[0].decode('ascii')[1:len(stdout[0].decode('ascii'))-1])
H.kill()


################################ CALCUL LE NOMBRE D'IMAGES DANS LE DOSSIER ############################
count = 0
dir = "images"
for path in os.listdir(dir):
    if os.path.isfile(os.path.join(dir, path)):
        count += 1


################################## CREER UNE NOUVELLE VIDEO ########################################
# choose codec according to format needed
fourcc = cv2.VideoWriter_fourcc(*'mp4v')
video = cv2.VideoWriter('video/video_ascii.avi', fourcc, fps, (width, height))

for j in range(0,count):
    img = cv2.imread('images_ascii/frame'+str(j)+'.png')
    video.write(img)

cv2.destroyAllWindows()
vidcap.release()
video.release()

video = "video/"+sys.argv[1];
video_ascii = "video/"+"ASCII_"+sys.argv[1]

################################# AJOUTE LE SON ##################################################
#subprocess.run(["ffmpeg","-i","video/video.avi","-vn","-acodec","copy","sound.acc"]) # Exporte le son de video.avi en trouvant automatiquement le format (ne marche pas)
subprocess.run(["ffmpeg","-loglevel","quiet","-i",video,"-q:a","0","-map","a","sound.mp3"]) # Exporte le son de video.avi
subprocess.run(["ffmpeg","-loglevel","quiet","-i","video/video_ascii.avi","-i","sound.mp3","-map","0:0","-map","1:0","-c:v","copy","-c:a","copy","video/video_ascii_sound.avi"]) # Fusionne le son + video_ascii.avi et creer video_ascii_sound.avi
subprocess.run(["rm","sound.mp3"]); #supprime le fichier son
subprocess.run(["ffmpeg","-loglevel","quiet","-i","video/video_ascii_sound.avi",video_ascii]) #optimise la video et la transforme en format mp4
subprocess.run(["rm","video/video_ascii.avi"]); #supprime la video sans son
subprocess.run(["rm","video/video_ascii_sound.avi"]); #supprime la video avec son pas opti

