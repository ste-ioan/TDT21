clear
clc

animalsounds = dir('~/ownCloud/MATLAB/Scripts/TDT/original/sounds/1/');
animalsounds = animalsounds(3:end);
animalsounds = {animalsounds(:).name};

carsounds  = dir('~/ownCloud/MATLAB/Scripts/TDT/original/sounds/2/');
carsounds = carsounds(3:end);
carsounds = {carsounds(:).name};

sounds = {animalsounds;carsounds};

datafolder = '~/Documents/tdt_sources/tdt_data_backup/';
cd(datafolder)

data_carpets = dir();
data_carpets = data_carpets(4:end);

for subject = 1:length(data_carpets)
    cd([cd,filesep,data_carpets(subject).name])
    if any(subject==1:2:48)
        group = 'easy';
    else
        group = 'hard';
    end
    cd([cd,filesep,group])
    
    tasks = dir('*.mat');
    if strcmp(tasks(end).name, 'backup.mat')
        tasks(end) = [];
    end
    
    for tasknum = 1:length(tasks)
        load(tasks(tasknum).name)
        
        switch tasks(tasknum).name(8:10)
            
            case 'SIM'
                for kk = 1:length(outputs)
                    wrong(kk,:) = length((find([outputs(kk).response(:).correct] == 0 )));
                    correct(kk,:) = length((find([outputs(kk).response(:).correct] == 1 )));
                end
                SIM_ratio(subject, tasknum) = (sum(correct) / (sum(correct) + sum(wrong))) * 100;
                
            case 'NBA'
                for kk = 1:length(outputs)
                    wrong(kk,:) = length((find([outputs(kk).response(:).correct] == 0 )));
                    correct(kk,:) = length((find([outputs(kk).response(:).correct] == 1 )));
                end
                NBA_ratio(subject, tasknum) = (sum(correct) / (sum(correct) + sum(wrong))) * 100;
                
            case 'SID'
                if strcmp(group, 'easy')
                    for kk = 1:length(outputs)
                        wrong(kk,:) = length((find([outputs(kk).response(:).correct] == 0 )));
                        correct(kk,:) = length((find([outputs(kk).response(:).correct] == 1 )));
                    end
                    SID_ratio(subject, tasknum) = (sum(correct) / (sum(correct) + sum(wrong))) * 100;
                    
                else
%                     
                    correctCounter = 0;
                    wrongCounter = 0;
                    
                    
                    for kk = 1:length(outputs) % for every trial
                        for ll = 1:length(outputs(kk).response) % for every sound
                            
                            % check if it was a que sound, and which if the case
                            if strcmp(outputs(kk).response(ll).side, 'x')
                                coherentcat = str2double(outputs(kk).response(ll).stim(1));
                            end
                            
                            try % extract the response key, if any
                                resp =  find(outputs(kk).response(ll).keys);
                            catch
                                resp = 0;
                            end
                            
                            switch resp
                                case 42 % if replied left
                                    % and sound of coherent category was presented to the left, then correct
                                    if  outputs(kk).response(ll).side == 1  && any(strcmp(outputs(kk).response(ll).stim, sounds{coherentcat, :}))
                                        correctCounter = correctCounter+1;
                                        % also if replied left when a sound of incoherent category was presented to the right
                                    elseif outputs(kk).response(ll).side ==  9 && all((strcmp(outputs(kk).response(ll).stim, sounds{coherentcat, :})) == 0)
                                        correctCounter = correctCounter+1;
                                    else % otherwise wrong
                                        wrongCounter = wrongCounter+1;
                                    end
                                    
                                case 45  % if replied right
                                    % and sound of coherent category was presented to the right, then correct
                                    if  outputs(kk).response(ll).side == 9  && any(strcmp(outputs(kk).response(ll).stim, sounds{coherentcat, :}))
                                        correctCounter = correctCounter+1;
                                        % if replied right to incoherent sound played to the left
                                    elseif outputs(kk).response(ll).side ==  1 && all((strcmp(outputs(kk).response(ll).stim, sounds{coherentcat, :})) == 0)
                                        correctCounter = correctCounter+1;
                                        
                                    else % otherwise wrong
                                        wrongCounter = wrongCounter+1;
                                    end
                                    
                                case 0
                                    % if they didn't reply to a non target sound, correct
                                    if    outputs(kk).response(ll).target == 0 && isnan(outputs(kk).response(ll).rt)
                                        correctCounter = correctCounter+1;
                                    else % otherwise wrong
                                        wrongCounter = wrongCounter+1;
                                    end
                                otherwise
                                    warning('something wrong with diff. side extraction of perf')
                                    pause
                            end
                        end
                    end
                    
                    SID_ratio(subject, tasknum) = (correctCounter / (correctCounter + wrongCounter)) * 100;
                 end
                
        end
        clear wrong correct correctCounter wrongCounter
    end
    cd ..
    cd ..
end

clearvars -except NBA_ratio SID_ratio SIM_ratio

% overall performance in audio tasks, per group
mean(nonzeros(NBA_ratio(1:2:48, :)))
mean(nonzeros(NBA_ratio(2:2:48, :)))

mean(nonzeros(SID_ratio(1:2:48, :)))
mean(nonzeros(SID_ratio(2:2:48, :)))

mean(nonzeros(SIM_ratio(1:2:48, :)))
mean(nonzeros(SIM_ratio(2:2:48, :)))


% to do group wise comparisons
ez_nba = NBA_ratio(1:2:48, :);
ez_nba(ez_nba == 0) = nan;
ez_nba = nanmean(ez_nba, 2);

hrd_nba = NBA_ratio(2:2:48, :);
hrd_nba(hrd_nba == 0) = nan;
hrd_nba = nanmean(hrd_nba, 2);

[~, p_nback,~, stats_nback] = ttest2(ez_nba, hrd_nba);
effsize_nback = computeCohen_d(ez_nba, hrd_nba);


% simon
ez_simon = SIM_ratio(1:2:48, :);
ez_simon(ez_simon == 0) = nan;
ez_simon = nanmean(ez_simon, 2);

hrd_simon = SIM_ratio(2:2:48, :);
hrd_simon(hrd_simon == 0) = nan;
hrd_simon = nanmean(hrd_simon, 2);

[~, p_simon,~, stats_simon] = ttest2(ez_simon, hrd_simon);
effsize_simon = computeCohen_d(ez_simon, hrd_simon);

% side
ez_side = SID_ratio(1:2:48, :);
ez_side(ez_side == 0) = nan;
ez_side = nanmean(ez_side, 2);

hrd_side = SID_ratio(2:2:48, :);
hrd_side(hrd_side == 0) = nan;
hrd_side = nanmean(hrd_side, 2);

[~, p_side, ~, stats_side] = ttest2(ez_side, hrd_side);
effsize_side = computeCohen_d(ez_side, hrd_side);


