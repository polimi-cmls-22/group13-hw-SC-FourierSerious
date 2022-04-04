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
Open the "Harmonizer.scd" file in SuperCollider, select all the code and execute it (with [shift+Enter] in Mac OSX, with [ctrl+Enter] in Windows and with [ctrl+c] in Linux). The program boots automatically the server if it isn't already booted. The harmonizer GUI should appear. The harmonizer runs by default with the audio file "Nirvana.wav", that is in the same folder of the code. If you want to change the audio file to harmonize, you can put the desired file in the same folder of "Harmonizer.scd" file and modify line 9 replacing "Nirvana.wav" with the name of the file:

c = Buffer.read(s,~path ++ "Nirvana.wav");
