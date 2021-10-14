% newTDT Master Script
clear vars
clear global
global path stopExp distance eyelinkflag
hq = pwd;

% take sub number, distance and eyetracker as inputs
prompt = {'Subject''s Number:', 'Distance Eye-Screen', 'Eye-Tracker'};
defaults = {'#', '120', '1'};

answer = inputdlg(prompt, 'Master TDT Experiment', 1, defaults);
[subnumber, distance, eyetracker] = deal(answer{:}); % these are strings

% odd participants saturated in quad 1
% even participants saturated in quad 2
if any(str2double(subnumber) == 1:2:100)
satQuadrant = '1';
elseif any(str2double(subnumber) == 2:2:100)
satQuadrant = '2'; 
else
disp('debug mode, quadrant randomly chosen.. press any key to continue')
rng('shuffle')
satQuadrant = num2str(randi(2));
pause
end

eyelinkflag = str2double(eyetracker);
% create folder where to stash data files
path = ['~/ownCloud/MATLAB/Data/TDT/newTDT/', subnumber, '/'];
if ~isfolder(path)
    mkdir(path)
end

% create path of the trainingfile
trainfilepath = [path 'trainingTDT_', 'subj', subnumber '.csv'];
%% if training file does not exist, then do trainingTDT
if exist(trainfilepath, 'file') ~= 2
trainingTDT(subnumber, satQuadrant);
else
%% if not training, then run baseline TDT, saturation, conclusion TDT
% satu task short training here, set options
    options.subnumber = subnumber;
    options.satQuadrant = str2double(satQuadrant);
    options.eyetracker = str2double(eyetracker);
    options.TaskDifficulty = 2; % only hard satu tasks
%     options.Session = session;
    options.Training = '1';
%     

            saturationTask('side', options);
            saturationTask('nback', options);
            saturationTask('simon', options);

%load previousSOA 
previousSOA = extractSOA(trainfilepath);
disp(previousSOA)
% 
if previousSOA > .6 || strcmp(subnumber, 'test')
    previousSOA = .6;
end

% baseline tdt
testTDT(subnumber, satQuadrant, '1', previousSOA)

% saturation phase constants
    stopExp = false;
    run = 1;
    options.Training = '0';
    expBeginning = GetSecs;
    options.expBeg = expBeginning;
    
    rng('shuffle')
    task{1} = 'simon';
    task{2} = 'nback';
    task{3} = 'side';
    tasks = [task(randperm(numel(task))),task(randperm(numel(task))),task(randperm(numel(task)))];
    
    % saturation cycle
    while ~stopExp
        cd(hq)
        saturationTask(tasks{run}, options);
        run = run +1;
        save(fullfile(path,'backup.mat'));
    end

% conclusion tdt
cd(hq)
testTDT(subnumber, satQuadrant, '2', previousSOA)

end

psychFinish