function [qq] = checksaturatedquad
% script to check satEEG side per subject
% first column is saturated quadrant, second column is starting eeg
% quadrant

fileshub = 'C:\Users\MococoEEG\ownCloud\MATLAB\Data\TDT\';
cd(fileshub)

folders = dir();
for k = 3:50
    cd([fileshub,'\', folders(k).name])
        bckp = dir('**\backup*');
        cd(bckp.folder)
        load(bckp.name)
        SaturatedQuadrant(k-2) = options.satQuadrant;
        StartingEEGquadrant(k-2) = str2num(startQuadrant);
        
cd ..
cd ..
clear bckp
end

qq = [SaturatedQuadrant', StartingEEGquadrant'];