# group13-hw-SC-FourierSerious
Group 13 repository for the SC homework of CMLS 2022

# Group FourierSerious - Components:
- Manuel Alejandro Jaramillo Rodríguez
- Marcello Grati
- Maria Gracia Fernandez
- Silvia Pasin
- Natasa Popovic

# Project description:
This is an implementation of a digital harmonizer in the SuperCollider environment, it can be used either with the internal microphone of your computer or with an input signal controlled by an audio interface. The most recent version of the harmonizer adds four different voices: sixth down, fourth down, third up, fifth up. It also allows to mix all the voices and original signal in the way the user want. Finally, a reverberation effect can be added to the final mix. 

# Instructions:
Open the "Harmonizer.scd" file in SuperCollider, select all the code and execute it (with `cmd`+`Enter` in Mac OSX, with `ctrl`+`Enter` in Windows and with `ctrl`+`c` in Linux). The program boots automatically the server if it isn't already booted. The harmonizer GUI should appear. The harmonizer runs by default with the audio file "Nirvana.wav", that is in the same folder of the code. Before pushing the button "Play with file", you need to set the key of the song, in this case A#/Bb. If you want to change the audio file to harmonize, you can put the desired file in the same folder of "Harmonizer.scd" file and modify line 9 replacing "Nirvana.wav" with the name of the file:

c = Buffer.read(s,~path ++ "Nirvana.wav");

# Interface:
![GUI](https://github.com/polimi-cmls-22/group13-hw-SC-FourierSerious/blob/main/GUI.png?raw=true)

In the upper part of the GUI interface, we can find the different voices that take part in the harmonization as well as their volumes and the pan of each one. On the left, it is placed the original input of the signal, and then the different voices.
In the lower part, we find the reverb effect and its different parameters to be configured by the user (from left to right): volume of the reverb (WetAmp), room, wet or dry and damp. 
Finally, on the right side there are the different options to choose the input, the stop button and some parameters of the harmonizer and the shift of the different voices. First, there is a menu that allows to choose the key of the song. Then, there is a slider that controls the pitch dispersion (pitch disp), which makes the second voice vary from the original, making them not exactly the same even though it is shifted, giving an error range in the frequency for the harmonizing voice. The last slider controls the time dispersion (time disp) and does the same as the previous slider but in time, making the second voice not sound at the same time but a little before or a little after.
