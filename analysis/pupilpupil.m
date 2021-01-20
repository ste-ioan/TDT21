%% extracting Pupil signal from satuTDT experiment
addpath('/Users/mococomac/ownCloud/MATLAB/Scripts/TDT/original/private/analysis')
if ispc
    cd('C:\Users\MococoEEG\ownCloud\MATLAB\Data\TDT')
elseif ismac
    %     cd('/Users/zenon/Dropbox/Data/TDT2019')
    cd('~/Documents/tdt_sources/tdt_data_backup/')
end

data_carpets = dir();
output = cell(48,2);
rootDir = pwd;
T = table;

for jj = 1:length(data_carpets)
    if ~isempty(str2num(data_carpets(jj).name))
        sub = str2num(data_carpets(jj).name);
        
        if any(sub==1:2:48)
            group = 'easy';
        else
            group = 'hard';
        end
        cd([rootDir,filesep,data_carpets(jj).name,filesep,group])
        
        % get tdt files to extract middle of experiment time
        tdtfiles = dir('*.csv');
        tdthour = str2double(tdtfiles(3).name(end-11:end-10));
        tdtminute = str2double(tdtfiles(3).name(end-8:end-7));
        
        % let's get to pupil stuff..
        data = loadData(pwd, false, 'trialOnsets');
        
        % take out backup.mat
        if strcmp(data(end).filename, 'backup.mat')
            data(end) = [];
        end
        % sort by time
        [~,index] = sortrows({data.date}.'); data = data(index); clear index
        
        % downsample
        fs = 10;
        data = downsampleEyedata(data, fs, 1000);
        
        % filter
        data = filterPupil(data, 0.05, fs);
        
        % will have to go to trial
        for taskn = 1:length(data)
            
            % get time of block
            taskhour =     str2double(data(taskn).filename(end-11:end-10));
            taskminute =     str2double(data(taskn).filename(end-8:end-7));
            
   
            
            
            if isstruct(data(taskn).pupilData.block)
                task = data(taskn).behavioralData.task;
                N = numel(data(taskn).behavioralData.outputs);
                pupil_max = nan(N,1);
                pupil_mean = pupil_max;
%How about taking the baseline-corrected (on top of filtering) average between end of fixation period of trial t and end of fixation of trial t+1                
                
                for tr = 1:N
                timeVector = data(taskn).pupilData.trials(tr).eyeTime;
                pupilMatrix = (data(taskn).pupilData.trials(tr).filteredPupilSize') - nanmean(data(taskn).pupilData.trials(tr).filteredPupilSize);
                
                curr_tr_stim_onset_time = data(taskn).behavioralData.outputs(tr).display(2).onset;
                try
                next_tr_stim_onset_time = data(taskn).behavioralData.outputs(tr+1).display(2).onset;
                catch
                next_tr_stim_onset_time = data(taskn).behavioralData.outputs(tr).display(end).onset;  
                end
                
                [~,onset_idx] = min(abs(timeVector - curr_tr_stim_onset_time));
                [~,offset_idx] = min(abs(timeVector - next_tr_stim_onset_time));
                                 
                pupildata(sub).block(taskn).trial(tr).max = nanmax(pupilMatrix(onset_idx:offset_idx));
                pupildata(sub).block(taskn).trial(tr).mean = nanmean(pupilMatrix(onset_idx:offset_idx));
                pupildata(sub).block(taskn).trial(tr).sub = sub;
                pupildata(sub).block(taskn).trial(tr).trial = tr;
                pupildata(sub).block(taskn).trial(tr).block = taskn;
                pupildata(sub).block(taskn).trial(tr).task = {task};
                pupildata(sub).block(taskn).trial(tr).group = {group};
                
                         % assign session
            if  taskhour < tdthour
                pupildata(sub).block(taskn).trial(tr).session = 1;
            elseif taskhour == tdthour
                if taskminute<tdtminute
                    pupildata(sub).block(taskn).trial(tr).session = 1;
                else
                    pupildata(sub).block(taskn).trial(tr).session = 2;
                end
            else
                pupildata(sub).block(taskn).trial(tr).session = 2;
            end
                
                
                end           
            end
        end
    end
end

T = table;
for k =1:48
    for j = 1:numel(pupildata(k).block)
lil_t = struct2table(pupildata(k).block(j).trial);

T = [T; lil_t];  
    end

end

T.Properties.VariableNames = fieldnames(pupildata(k).block(j).trial);
cd('~/Documents/jamovi analyses/TDT/pupil/')
writetable(T)

