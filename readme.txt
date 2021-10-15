This repository contains matlab files for the publication "Passive visual stimulation induces fatigue or improvement depending on cognitive load" by Ioannucci, Borragan and Zenon

the "MainScripts" folder contains all the scripts related to running the main experiment, while in eyeTDT the scripts for study 2 may be found and in orientationTDT the scripts for study3. They require Psychtoolbox to work.

In each experiment, a Masterscript.m is the script that calls the other scripts to run any participant, which themselves then rely on the codes within the "private" folder.

the "analysis" folder contains all the scripts relating to data extraction and analysis of the main study.
in the case of the EEG, all is done through matlab. 
In the case of the behaviour (GLMMmatrix.m, pupilpupil.m and performanceinAudioTasks.m) they extract and organise the data into txt files for analysis with external software.
questionnairetestnplots.m does both data extraction while plotting and calcuating the correlation between variables. the other studies have similar scripts ("correl.m")


please note that the raw and extracted data, plus the files to run the statistical analyses, are downloadable at: https://zenodo.org/record/5569636

for any questions or issues, feel free to contact me at: ste.ioannucci@gmail.com
