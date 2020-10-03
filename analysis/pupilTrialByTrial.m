%% first attempt at extracting Pupil signal from satuTDT experiment
% output = pupilTDT
if ispc
    cd('C:\Users\MococoEEG\ownCloud\MATLAB\Data\TDT')
elseif ismac
    %     cd('/Users/zenon/Dropbox/Data/TDT2019')
    cd('/Users/mococomac/Desktop/tdt_data_backup')
end

data_carpets = dir();
output = cell(48,2);
rootDir = pwd;
array = [];
for jj = 1:length(data_carpets)
    if ~isempty(str2num(data_carpets(jj).name))
        sub = str2num(data_carpets(jj).name);
        
        if any(sub==1:2:48)
            group = 'easy';
        else
            group = 'hard';
        end
        cd([rootDir,filesep,data_carpets(jj).name,filesep,group])
        
        % get eyelink files
        %     eye_files = dir('*SAT_*');
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
        data = filterPupil(data, [0.1 0.01], fs);
        
        for block = 1:length(data)
            if isstruct(data(block).pupilData.block)
                task = data(block).behavioralData.task;
                N = numel(data(block).behavioralData.outputs);
                onsets = [];
                responses = [];
                timeVector = data(block).pupilData.block.time;
                pupilMatrix = data(block).pupilData.block.filteredPupilSize';
                events = timeVector*0;
                for tr = 1:N
                    displays = data(block).behavioralData.outputs(tr).display;
                    for ds = 1:numel(displays)
                        d = displays(ds);
                        if ~isempty(d)
                            switch task
                                case 'SIDE'
                                    taskIndex = 1;
                                    if ~isempty(findstr(d.name,'SOUND'))
                                        onsets = [onsets; d.onset];
                                    end
                                case 'NBACK'
                                    taskIndex = 2;
                                    if ~isempty(findstr(d.name,'LETTER'))
                                        onsets = [onsets; d.onset];
                                    end
                                case 'SIMON'
                                    taskIndex = 3;
                                    if ~isempty(findstr(d.name,'BEEP1'))
                                        onsets = [onsets; d.onset];
                                    elseif ~isempty(findstr(d.name,'RESP'))
                                        responses = [responses; d.onset];
                                    end
                            end
                        end
                    end
                    
                end
                
                for k = 1:length(onsets)
                    [~,f] = min(abs(timeVector-onsets(k)));
                    events(f) = 1;
                end
%               this doesn't work on my matlab version
                %                 M = abs(timeVector-onsets); 
                %                 [~,f] = min(M,[],2);
                %                 events(f) = 1;
                clear A A2
                A(:,:,1)=event_align(pupilMatrix(:,1),events(:),1,[-10 300]);
                A(:,:,2)=event_align(pupilMatrix(:,2),events(:),1,[-10 300]);
                A2 = [];
                if ~isempty(responses)
                    % same
                        %                     M = abs(timeVector-responses);
                        %                     [~,f] = min(M,[],2);
                        %                     events(f) = 2;
                    for k = 1:length(responses)
                        [~,f] = min(abs(timeVector-responses(k)));
                        events(f) = 2;
                    end
                    A2(:,:,1)=event_align(pupilMatrix(:,1),events(:),2,[-10 300]);
                    A2(:,:,2)=event_align(pupilMatrix(:,2),events(:),2,[-10 300]);
                end
                
                pu = data(block).pupilData.block.pupilSize;
                pu = pu(:)-nanmean(pu);
                ok = ~isnan(pu);
                events = double(events(:)==1);
                
                opt = ssestOptions('Focus','simulation');
                opt.Regularization.Lambda = 1; % you can increase here to limit outliers
                
                model = ssest(iddata(pu(ok),events(ok),1/10),3,'InputDelay',.4,opt);
                imp = impulse(model);
                puResp = max(imp);
                
                % get time of block
                taskhour =     str2double(data(block).filename(end-11:end-10));
                taskminute =     str2double(data(block).filename(end-8:end-7));
                
                % assign session
                if  taskhour < tdthour
                    session = 1;
                elseif taskhour == tdthour
                    if taskminute<tdtminute
                        session = 1;
                    else
                        session = 2;
                    end
                else
                    session = 2;
                end
                
                analysedData(sub).block(block).task = task;
                analysedData(sub).block(block).difficulty = group;
                analysedData(sub).block(block).session = session;
                analysedData(sub).block(block).pupilResponsesToStim = A;
                analysedData(sub).block(block).pupilResponsesToResp = A2;
                analysedData(sub).block(block).pupilARX = puResp;
                N = size(A,2);
                %array = [array; [ones(N,1)*sub max(A)' ones(N,1)*block ones(N,1)*session ones(N,1)*(strcmp(group,'hard')+1) ones(N,1)*taskIndex]];
            end
        end
    end
end
%
% pupiltab = array2table(array, 'VariableNames', {'subject', 'pupil', 'block', 'session', 'group', 'task'});
%
%
% %%
% if ispc
%     cd('C:\Users\MococoEEG\ownCloud\MATLAB\Scripts\TDT\private\analysis\data_extracted\Tables\Physio\Pupil')
% elseif ismac
%     cd('/Users/zenon/ownCloud/MATLAB/Scripts/TDT/private/analysis/data_extracted/Tables/Physio/Pupil')
%     %cd('~/Documents/jamovi analyses/TDT/pupil/')
% end
% writetable(pupiltab)

next = zeros(1,2);
allData = NaN(311,24,2,2,3);
allARX = NaN(24,2,2,3);
for ss = 1:length(analysedData)
    difficulty = strcmp(analysedData(ss).block(2).difficulty,'hard')+1;
    next(difficulty) = next(difficulty)+1;
    
    for bb = 1:length(analysedData(ss).block)
        session = analysedData(ss).block(bb).session;
        if ~isempty(analysedData(ss).block(bb).task)
            switch analysedData(ss).block(bb).task
                case 'SIDE'
                    allData(:,next(difficulty),difficulty,session,1) = nanmean(analysedData(ss).block(bb).pupilResponsesToStim(:,:,2)');
                    allARX(next(difficulty),difficulty,session,1) = analysedData(ss).block(bb).pupilARX;
                case 'NBACK'
                    allData(:,next(difficulty),difficulty,session,2) = nanmean(analysedData(ss).block(bb).pupilResponsesToStim(:,:,2)');
                    allARX(next(difficulty),difficulty,session,2) = analysedData(ss).block(bb).pupilARX;
                case 'SIMON'
                    allData(:,next(difficulty),difficulty,session,3) = nanmean(analysedData(ss).block(bb).pupilResponsesToStim(:,:,2)');
                    allARX(next(difficulty),difficulty,session,3) = analysedData(ss).block(bb).pupilARX;
            end
        end
    end
end

figure;
subplot(3,1,1);
plot([-1:.1:10],squeeze(nanmean(nanmean(allData(:,:,:,:,1),4),2)))
xlabel('Time following stim onset (s)')
ylabel('Filtered pupil size')
legend('Easy','Hard')
hold on
title('SIDE')
subplot(3,1,2);
plot([-1:.1:10],squeeze(nanmean(nanmean(allData(:,:,:,:,2),4),2)))
xlabel('Time following stim onset (s)')
ylabel('Filtered pupil size')
title('N-BACK')
subplot(3,1,3);
plot([-1:.1:10],squeeze(nanmean(nanmean(allData(:,:,:,:,3),4),2)))
xlabel('Time following stim onset (s)')
ylabel('Filtered pupil size')
title('SIMON')

