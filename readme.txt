This repository contains matlab files for the publication "Passive visual stimulation induces fatigue or improvement depending on cognitive load" by Ioannucci, Borragan and Zenon

the "MainScripts" folder contains all the scripts related to running the experiment, they require Psychtoolbox to work.
Masterscript.m is the script launched to run any participant, and calls all the other main scripts included in the folder, which themselves then rely on the
codes within the "private" folder.

the "analysis" folder contains all the scripts relating to data extraction and analysis.
in the case of the EEG, all is done through matlab. 
In the case of the behaviour (GLMMmatrix.m, pupilpupil.m and performanceinAudioTasks.m) they extract and organise the data into txt files for analysis with external software.
questionnairetestnplots.m does both data extraction while plotting and calcuating the correlation between variables.


please note that the raw and extracted data are downloadable at: https://zenodo.org/record/4545773

for any questions or issues, feel free to contact me at: ste.ioannucci@gmail.com
