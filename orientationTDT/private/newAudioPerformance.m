% clear
% clc
animalsounds = dir('~/ownCloud/MATLAB/Scripts/TDT/original/sounds/1/');
animalsounds = animalsounds(3:end);
animalsounds = {animalsounds(:).name};

carsounds  = dir('~/ownCloud/MATLAB/Scripts/TDT/original/sounds/2/');
carsounds = carsounds(3:end);
carsounds = {carsounds(:).name};

sounds = {animalsounds;carsounds};

datafolder = '~/ownCloud/MATLAB/Data/TDT/newTDT'; %'~/Desktop/tdt_data_backup/'
cd(datafolder)

data_carpets = dir();
data_carpets = data_carpets(4:end);
% [~,index] = sortf({data_carpets.name}.'); data_carpets = data_carpets(index); clear index
% data_carpets(3).date = '04-Oct-2020 17:44:25';
% [~,index] = sortrows({data_carpets.date}.'); data_carpets = data_carpets(index); clear index

for subject = 1:length(data_carpets)
    cd([cd,filesep,num2str(subject)])
    
    tasks = dir('*.mat');
    tasks(strcmp({tasks.name}, 'backup.mat')) = []; %remove backupfile

    [~,index] = sortrows({tasks.date}.'); tasks = tasks(index); clear index  
    for tasknum = 1:length(tasks)
        load(tasks(tasknum).name)
        
        switch task           
            case 'SIMON' 
                for kk = 1:length(outputs)
                    wrong(kk,:) = length((find([outputs(kk).response(:).correct] == 0 )));
                    correct(kk,:) = length((find([outputs(kk).response(:).correct] == 1 )));
                end
                SIM_ratio(subject, tasknum) = (sum(correct) / (sum(correct) + sum(wrong))) * 100;
                
            case 'NBACK'
                for kk = 1:length(outputs)
                    wrong(kk,:) = length((find([outputs(kk).response(:).correct] == 0 )));
                    correct(kk,:) = length((find([outputs(kk).response(:).correct] == 1 )));
                end
                NBA_ratio(subject, tasknum) = (sum(correct) / (sum(correct) + sum(wrong))) * 100;
                
            case 'SIDE'
                    correctCounter = 0;
                    wrongCounter = 0;
                                        
                    for kk = 1:length(outputs) % for every trial
                        for ll = 1:length(outputs(kk).response) % for every sound
                            
                            % check if it was a que sound, and which if the case
                            if strcmp(outputs(kk).response(ll).side, 'x')
                                if strcmp(outputs(kk).response(ll).stim, 'animaux.wav')
                                    coherentcat = 1;
                                else
                                    coherentcat = 2;
                                end
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
        clear wrong correct correctCounter wrongCounter resp
    end
    cd ..
%     cd ..
end

% clearvars -except NBA_ratio SID_ratio SIM_ratio

%performance in audio tasks (not keeping subj order)
mean(nonzeros(NBA_ratio(~isnan(NBA_ratio))))

mean(nonzeros(SID_ratio))

mean(nonzeros(SIM_ratio(:, :)))
