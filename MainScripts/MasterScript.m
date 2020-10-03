% Master script
% "one script to rule them all"

% Unique script for the saturation experiment, 
% calls eeg-TDT-satu-eeg-TDT-satu-eeg-TDT

clear
global path stopExp distance

prompt = {'Subject''s Number:', 'saturated Quadrant',...
    'Session', 'Distance Eye-Screen', 'Eye-Tracker', 'Task Difficulty', 'First satuEEG Quadrant'};
defaults = {'test', '1', '0', '120', '0', '1', ''};
answer = inputdlg(prompt, 'TDT', 1, defaults);
[subnumber, satQuadrant, session, distance, eyetracker, TaskDifficulty, startQuadrant] = deal(answer{:}); % these are strings

options.subnumber = subnumber;
options.satQuadrant = str2double(satQuadrant);
options.eyetracker = str2double(eyetracker);
options.TaskDifficulty = str2double(TaskDifficulty);

if TaskDifficulty == '1'
    path = ['~/ownCloud/MATLAB/Data/TDT/' subnumber '/' 'easy' '/'];
elseif TaskDifficulty == '2'
    path = ['~/ownCloud/MATLAB/Data/TDT/' subnumber '/' 'hard' '/'];
end  
 
if ~isdir(path)
    mkdir(path)
end

rng('shuffle')
% create task variable for saturation and randomize it
task{1} = 'simon';
task{2} = 'nback';
task{3} = 'side';


tasks = [task(randperm(numel(task))),task(randperm(numel(task))),task(randperm(numel(task)))];

% satuEEG 1
if ~isempty(startQuadrant)
    satuEEG(str2double(eyetracker), str2double(startQuadrant))
end

satu_TDT(subnumber, satQuadrant, eyetracker, TaskDifficulty, session); %set default session as 1 in prompt

% Saturation tasks  Training
save(fullfile(path,'backup.mat'));
if session == '0'
    options.Training = 1;
for trainingrun = 1:3
saturationTask(tasks{trainingrun}, options);
end


else % saturation Tasks 1 costants
    stopExp = false;
    run = 1;
    options.Training = 0;
    expBeginning = GetSecs;
    options.expBeg = expBeginning;
    
    % saturation Tasks 1 cycle
    while ~stopExp
        saturationTask(tasks{run}, options);
        run = run +1;
        save(fullfile(path,'backup.mat'));
    end
  
    if stopExp
    % satu EEG 2
    % exiting abruptly from satu task messes up satu eeg 2 and 3 eyelink
    % file
    if eyetracker
    Eyelink('StopRecording');
    saveEyelink(path,'LastSatuTask1.edf');
    Eyelink('CloseFile');
    
    eyelinkInit([0 0 0],0)
    end
    end
        
    satuEEG(str2double(eyetracker), str2double(startQuadrant))
    save(fullfile(path,'backup.mat'));

    % TDT session 2
    [~, ~, ~, ~, session] = satu_TDT(subnumber, satQuadrant, eyetracker, str2double(TaskDifficulty), '2'); %change this to 2
    save(fullfile(path,'backup.mat'));

    % reshuffle the Tasks
    rng('shuffle')
    tasks = [task(randperm(numel(task))),task(randperm(numel(task))),task(randperm(numel(task)))];
    
    % second saturation cycle
    expBeginning = GetSecs;
    save(fullfile(path,'backup.mat'));
    stopExp = false;
%     run = 1;
    options.expBeg = expBeginning;
    while ~stopExp
        saturationTask(tasks{run}, options);
        run = run +1;
        save(fullfile(path,'backup.mat'));
    end
    
    if stopExp
    % satu EEG 2
    % exiting abruptly from satu task messes up satu eeg 2 and 3 eyelink
    % file
    if eyetracker
    Eyelink('StopRecording');
    saveEyelink(path,'LastSatuTask2.edf');
    Eyelink('CloseFile');
    
    eyelinkInit([0 0 0],0)
    end
    end
    
   % Satu EEG 3
    satuEEG(str2double(eyetracker), str2double(startQuadrant))
    save(fullfile(path,'backup.mat'));

    
    % TDT session 3
    [~, ~, ~, ~, session] = satu_TDT(subnumber, satQuadrant, eyetracker, str2double(TaskDifficulty), '3'); %change this to 3
end
psychFinish
