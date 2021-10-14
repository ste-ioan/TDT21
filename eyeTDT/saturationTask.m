function saturationTask(task, options) % added inputs for MasterScript
global wPtr soundBuffer screenrect screenheight distance path stopExp

% taken out Background buffer from side task to reduce crashing ??__??
debugTime = false;
%%%SATURATION/VARIOUS TASKS%%%
if nargin==2
    if isstruct(options)
        field = fieldnames(options);
        for ff = 1:length(field)
            eval([field{ff} '= options.(field{ff});']);
        end
    elseif isscalar(options)
        TaskDifficulty = options;
        if isstr(TaskDifficulty)
            TaskDifficulty = str2double(TaskDifficulty);
        end
    end
end

task = upper(task);

%%%%%%% START UP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% LOGIN PROMPT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Login prompt
vars = {'subnumber', 'satQuadrant', 'eyetracker','TaskDifficulty', 'Training'};
prompt = { 'Subject''s Number: ', 'saturated Quadrant: ', 'Eye-Tracker: ','Task difficulty: ', 'Training:'};
for aa = 1:length(prompt)
    if ~exist(vars{aa}) || isempty(vars{aa})
        answer{aa} = input(prompt{aa}, 's');
        eval([vars{aa} ' = answer{aa};'])
        switch vars{aa}
            case 'satQuadrant'
                satQuadrant = str2double(satQuadrant);
            case 'eyetracker'
                eyetracker = str2double(eyetracker);
            case 'TaskDifficulty'
                TaskDifficulty = str2double(TaskDifficulty);
            case 'Training'
                Training = str2double(Training);
        end
    end
end
if isstr(Training)
    Training = str2double(Training);
end

if Training
    eyetracker = 0;
end

if isempty(path)
    path = ['~/ownCloud/MATLAB/Data/TDT/' subnumber '/'];
end
if ~isdir(path)
    mkdir(path)
end
dnow = datestr(now,'dd-mm-yyyy_HH-MM-SS');
outputname2 = ['SAT_'  subnumber '_' task '_' dnow]; %add task here

% this makes running only satuTask not work
if strcmp('test',subnumber)
    debug = true;
else
    debug = false;
end

EXPDURATION = 41*60; %added one minute to account for intertask saving pauses

if debug
    EXPDURATION = 60; % 1 minutes
end

%%%%%%%% START PTB %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bkgColour = [0 0 0];
doubleScreenRatio = 1/2;
if isempty(screenrect) % psychInit was not yet run
    [screenrect]=psychInit(eyetracker,bkgColour,doubleScreenRatio);
    [width, height]=Screen('DisplaySize', 0);
    screenheight = height/10;%cm
    distance = 120; % makeKarni takes this as input, and i put it in TDT prompt, so will be able to take it out of here eventually
    psychInitFlag = true;
else
    psychInitFlag = false;
    if eyetracker
        eyelinkInit(bkgColour,1)
    end
end
resolution = screenrect(3:4);
center = [screenrect(3)/2 screenrect(4)/2]; % center coordinates (note: left top coordinates = [x=0 y=0])
cycleRefresh = Screen('GetFlipInterval',wPtr);
PixelsPerDegree = 180*2*atan(screenheight/(2*str2double(distance)))/pi;
rng('shuffle') %for true random numbers
PsychPortAudio('Close');
reqLat = 1;
soundBuffer = PsychPortAudio('Open',[],[],reqLat);

%%%%%%%%% INITIALIZE EXPERIMENT VARIABLES%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% blocks n trials
nblocks = 1;  % 5 seconds between blocks
switch task
    case 'SIDE'
        if TaskDifficulty == 1
            ntrials = 16; %from 16
        else
            ntrials = 27; %from 27
        end
    case 'NBACK'
        ntrials = 38; %from 35
    case 'SIMON'
        ntrials = 85; % from 80
    otherwise
        disp('something wrong with the input, cannot figure out n trials')
        pause
end

if debug
    ntrials = 5;
end
%
if Training
    ntrials = 5;
end

if ischar(distance)
    [X,Y,sizeline,x]=makeKarniGrid(str2double(distance));
else
    [X,Y,sizeline,x]=makeKarniGrid(distance);
end
LineWidth = 6;
%% stimulation parameters

stimFreq = 8;
alignOnScreen = true;
frameTotal = 0;
stimFrames = 8;

%%

col = [255 255 255];
testScreen = false;
fixationRadius = 5*PixelsPerDegree;

%%%%%%% INSTRUCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DrawFormattedText(wPtr,['Tache: ' task], 'center', 'center', [128 128 128]);
Screen('Flip',wPtr);
if ~debug
    waitForSpaceKey;
end
DrawFormattedText(wPtr,'Pret?\n Appuyez sur la barre d''espace pour demarrer l''experience!', 'center', 'center', [128 128 128]);
Screen('Flip',wPtr);
if ~debug
    waitForSpaceKey;
end
Screen('FillRect', wPtr, [0 0 0]);
if Training
    DrawFormattedText(wPtr, '+', 'center', 'center', [255 255 255]);
end
Screen('Flip',wPtr);
WaitSecs(1.5);

if eyetracker
    Eyelink('StartRecording');
    Eyelink('Message', ['USEREVENT ', '"',sprintf(task),'"']);
end

% saturation constants
    angle = 1; % 45 degrees
    if satQuadrant == 1
       targetpos = [249 269 289 309 329];   
    elseif satQuadrant == 2
       targetpos = [25 43 61 79 97];
    end
    
%%%%%%% START OF BLOCK LOOP
%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t = GetSecs;
for k = 1:nblocks    
    if ~alignOnScreen
        diffc2 = 0;
        c = (1+sin(GetSecs * 2 * pi * stimFreq))/2;
    end
    [new_point,size_point,newdrawpoint] = makeRandomGrid(sizeline,X,Y,x,screenrect,targetpos,satQuadrant,angle,center);
    
    %%%%%%% START OF TRIAL LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for j = 1:ntrials
        if eyetracker
            Eyelink('Message', sprintf('STARTTRIAL #%d:  %s  (see "TRIALSYNCTME" msg below for actual onset)',j, datestr(now,'yyyy-mm-dd HH:MM:SS')));
        end
        %%%%%%%%%%%%%%%%%%%%% START OF DRAWING TO SCREEN %%%%%%%%%%%%%%%%%%%%%%%%%%
        stopTrial=false;
        tt0 = GetSecs;
        trialOnsets(k,j) = tt0;
        FBflag = 0;
        %%% TASK LOOP %%%
        firstFrame = true;
        frameNum = 0;
        lineCoords = nan(2000,12,4);
        lineIntensities = nan(2000,3);
        fixation = [];
        displayOnset = nan(1,2000);
        
        %%%%%%%
        fbFrames = 0;
        fbDuration = 60;
        msg = '';
        %%%%%%%
        tic;
        while ~stopTrial || (fbFrames < fbDuration)
            if debugTime
                disp('??????????????????')
                toc;tic;
            end
            frameNum = frameNum+1;
            s = GetSecs;
            if alignOnScreen
                c = (1+sin((frameNum/stimFrames) * 2 * pi))/2;
            else
                c2 = (1+sin(s * 2 * pi * stimFreq))/2;
                diffc = c2-c;
                c=c2;
            end
            if debugTime,toc;tic;end
            %%%%%%
            if ~stopTrial
                %                 if debug,msg = ['start task function'];save(fullfile(path,'msglog.mat'),'msg');end
                eval(['stopTrial= run' task '(tt0,firstFrame,TaskDifficulty);']);
                %                 if debug,msg = ['task function ends '];save(fullfile(path,'msglog.mat'),'msg');end
                if debugTime,toc;tic;end
            end
            if stopTrial
                %                 if debug,msg = ['fb display'];save(fullfile(path,'msglog.mat'),'msg');end
                fbFrames = fbFrames+1;
                perf = [num2str(round((1-nanmean([output.response.correct]==0))*100)),'%'];
                Screen('TextSize',wPtr, 14);
                DrawFormattedText(wPtr,perf, 'center', 'center', [255 255 255]);
                Screen('TextSize',wPtr, 24);
            end
            %%%%%%
            
%             if eyetracker
%                 %                 if debug,msg = ['fixation check'];save(fullfile(path,'msglog.mat'),'msg');end
% %                 fixBroken = checkFixation(fixationRadius);
%                 
%                 if fixBroken
%                     %                     if debug,msg = ['fix broken'];save(fullfile(path,'msglog.mat'),'msg');end
%                     if ~stopTrial
%                         DrawFormattedText(wPtr, '+', 'center', 'center', [255 128 128]);
%                     end
%                     fixation(end+1)=s;
%                 end
%             end
            if isempty(Screen('Windows'))
                return;
            end
            if alignOnScreen
                if mod(frameTotal,stimFrames)==0
                    [new_point,size_point,newdrawpoint] = makeRandomGrid(sizeline,X,Y,x,screenrect,targetpos,satQuadrant,angle,center);
                end
            else
                if diffc2<0 && diffc>=0
                    %                     if debug,msg = ['makes new randomgrid '];save(fullfile(path,'msglog.mat'),'msg');end
                    [new_point,size_point,newdrawpoint] = makeRandomGrid(sizeline,X,Y,x,screenrect,targetpos,satQuadrant,angle,center);
                end
            end
            
            %             lineCoords(frameNum,:,:) = new_point;
            %framenum pushes rows e columns of new point to other so that, each line coords
            %slice corresponds to: all lines x1 coordinates / y1 / x2 / y2
            %stempio
            lineIntensities(frameNum,:) = round(col * c);
            
            %             if debug,msg = ['draws lines and square '];save(fullfile(path,'msglog.mat'),'msg');end
            if testScreen
                if diffc2<0 && diffc>=0
                    Screen('FillRect', wPtr, [255 255 255], screenrect );
                else
                    Screen('FillRect', wPtr, [0 0 0], screenrect );
                end
            else
                if ~Training
                    for id = 1:size_point(1)
                        if newdrawpoint(id)
                            Screen('DrawLine', wPtr, round(col * c), new_point(id,1),new_point(id,2),new_point(id,3),new_point(id,4),LineWidth);
                            %                         if Training
                            %                             Screen('DrawLine', wPtr, [0 0 0], new_point(id,1),new_point(id,2),new_point(id,3),new_point(id,4),LineWidth);
                            %                         end
                        end
                    end
                end
            end
            if ~alignOnScreen
                diffc2=diffc;
            end
            %             if debug,msg = ['flips screen'];save(fullfile(path,'msglog.mat'),'msg');end
            ttt=t;
            if debugTime, toc;tic; end
            t = Screen('Flip',wPtr); % Fix distance between the onset of each trial
            frameTotal = frameTotal+round((t-ttt)/cycleRefresh);
            if (t-ttt)>(cycleRefresh+0.002)
                disp(['******' num2str(t-ttt) '************'])
            end
            if debugTime,toc;tic;end
            %%%%%
            if stopTrial && fbFrames==1
                l = length(output.display);
                output.display(l+1).onset = t;
                output.display(l+1).name = 'FB';
            end
            %%%%%
            
            displayOnset(end+1) = t;
            
            if firstFrame
                firstFrame = false;
                if eyetracker
                    %                     if debug,msg = ('sends first trial msg');save(fullfile(path,'msglog.mat'),'msg');end
                    Eyelink('Message',sprintf('TRIALSYNCTIME #%d',j));
                end
            end
            
        end
        
        if eyetracker
            %             if debug,msg = ('stop trial eyelink msg');save(fullfile(path,'msglog.mat'),'msg');end
            Eyelink('Message',sprintf('STOPTTRIAL #%d:  %s',j, datestr(now,'yyyy-mm-dd HH:MM:SS')));
        end
        output.displayOnset = displayOnset;
        outputs(k,j) = output;
        allLineCoords{k,j} = lineCoords;
        allLineIntensities{k,j} = lineIntensities;
        brokenFixations{k,j} = fixation;
        if exist('expBeg', 'var')
            if (GetSecs-expBeg)>=EXPDURATION
                stopExp = true;
                break
            end
        end
        %         if debug,save(fullfile(path,'logs.mat'),'output');end
        
    end %end of trial loop
    
    if debug,disp('Saving data');end
    if ~Training
        save([path outputname2 '.mat']);
    end
    if debug,disp('Data saved');end
    %%%%%%% ADD BREAK PERIOD OF 5s AS A CONTROL BLOCK CONDITION %%%%%%%%%%
    DrawFormattedText(wPtr, '+', 'center', 'center', [0 0 255]);
    FixTime = Screen('Flip',wPtr);
    % Fix distance between the onset of each trial
    WaitSecs(5);%%FROM: 20
    
end %end of block loop for saturation
if eyetracker
    if debug,disp('Stopping Eyelink recording');end
    Eyelink('StopRecording');
    if debug,disp('Eyelink recording stopped');end
    saveEyelink(path,[outputname2 '.edf']);
    if debug,disp('Eyelink finished');end
    Eyelink('CloseFile')
end
% if psychInitFlag
%     psychFinish %if task was run on its own, makes screen crash during
%     training
% end
switch task
    case 'SIDE'
        if debug,disp('Clearing persistent SIDE variable');end
        clear runSIDE % to clean side persistent indices
        if debug,disp('Persistent SIDE variable cleared');end
        % moved it to masterscript, else it crashed
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% END OF BACKBONE %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [new_point,size_point,newdrawpoint] = makeRandomGrid(length,X,Y,x,screenrect,targetpos,satQuadrant,angle,center)


%%%%%%%%%%%% RANDOMIZING COORDINATES MATRIX (entire grid) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%add jitter to the raw, scaled coordinates
RandomMatrix1 = (rand(19,19)*length/2) - (length/4);
RandomMatrix2 = (rand(19,19)*length/2) - (length/4);
XR = X + RandomMatrix1;
YR = Y + RandomMatrix2;

%Split in four coordinates and add length to the line (only the x-coordinates)
%We need four coordinates to draw each lines in the grid
x1 = XR-(0.5*length); %start X coordinate of each line, subtract half of the line lenght
x2 = XR+(0.5*length); %end X coordinate of each line, add half of the line length
y1 = YR; %start Y coordinate of each line
y2 = YR; %end Y coordinate of each line

%Reshape each 19x19 coordinate matrix into on 4x361 coordinate matrix where
%each column contains the four coordinates for a line (for all 361 cells in the grid)
numDots = numel(x);
PositionMatrix = [reshape(x1, 1, numDots); reshape(y1, 1, numDots); reshape(x2, 1, numDots); reshape(y1, 1, numDots)];
b = PositionMatrix; %4x361 matrix;

% centering each of the four coordinates
b(1,:) = PositionMatrix(1,:) + (screenrect(3)/2); %add half of full x pixels to x1 coordinate (begin of line)
b(3,:) = PositionMatrix(3,:) + (screenrect(3)/2); %add half of full x pixels to x2 coordinate (end of line)
b(2,:) = PositionMatrix(2,:) + (screenrect(4)/2); %add half of full y pixels to y1 cooridnate (begin of line)
b(4,:) = PositionMatrix(4,:) + (screenrect(4)/2); %add half of full y pixels to y1 cooridnate (end of line)

%%%%%%%%%%%%%%%%%%% STIMULI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%DRAW ALL THE OTHER HORIZONTAL LINES (BACKGROUND LINES) + DIAGONAL LINES (TARGET LINES)
point = zeros(numDots,4);
drawpoint = zeros(1,numDots);
for i = 1:numDots
    
    if any (i == targetpos|i==targetpos+1|i==targetpos-1|i==targetpos+19|i==targetpos-19)
        
        DrawQuadrant=false;
        if satQuadrant==1
            if X(i)>0 && Y(i)<0
                DrawQuadrant=true;
            end
        elseif satQuadrant==2
            if X(i)<0 && Y(i)<0
                DrawQuadrant=true;
            end
        elseif satQuadrant==3
            if X(i)<0 && Y(i)>0
                DrawQuadrant=true;
            end
        elseif satQuadrant==4
            if X(i)>0 && Y(i)>0
                DrawQuadrant=true;
            end
        end
        
        %change orientation
        if angle == 1
            theta = pi/4; %45???
        elseif angle == 2
            theta = pi/-4; %135???
        end
        cs = cos(theta);
        sn = sin(theta);
        
        bx1 = -length/2;
        by1 = 0;
        
        bx2 = length/2;
        by2 = 0;
        
        rbx1 = bx1 * cs - by1 * sn;
        rby1 = bx1 * sn + by1 * cs;
        
        rbx2 = bx2 * cs - by2 * sn;
        rby2 = bx2 * sn + by2 * cs;
        
        if DrawQuadrant
            point(i,:) = [rbx1+X(i)+center(1)+RandomMatrix1(i),rby1+Y(i)+center(2)+RandomMatrix2(i), rbx2+X(i)+center(1)+RandomMatrix1(i), rby2+Y(i)+center(2)+RandomMatrix2(i)];
        end
        drawpoint(i)=DrawQuadrant;
        
    end
end

%%Variables for drawing lines on grid
value = find(point(:,1)); %indexes x1 values of lines in trgt positions
new_point = point(value,:);%takes whole coordinates
size_point = size(new_point);%size of these coordinates
newdrawpoint = drawpoint(value);% ?? no idea

end