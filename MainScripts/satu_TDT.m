% new satu TDT

%takes sub num, quadrant, difficulty
% and brings that on to saturtionTask (so not to have to prompt that stuff
% again). Here we save locally the session (to distinguish the TDTs not
% only from the timings).

% also bayesian SOA ('adaptiveDifficulty' script) developed by Alex

function [subnumber, satQuadrant, eyetracker, TaskDifficulty,session] = satu_TDT(subnumber, satQuadrant, eyetracker, TaskDifficulty, session)
global wPtr screenrect screenheight distance path
%clear all
%close all; %clearvars; sca;
%Screen('Preference', 'SkipSyncTests', 0); % !!! ONLY FOR TESTING !!!

commandwindow

%%%%%%%% LOGIN PROMPT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Login prompt

if nargin < 5
    prompt = {'Subject''s Number:', 'saturated Quadrant',...
        'Session', 'Distance Eye-Screen', 'Eye-Tracker', 'Task Difficulty'};
    defaults = {'test', '1', '0', '80', '0', '1'};
    answer = inputdlg(prompt, 'TDT', 1, defaults);
    [subnumber, satQuadrant, session, distance, eyetracker, TaskDifficulty] = deal(answer{:}); % these are strings
end

if TaskDifficulty == '1'
    path = ['~/ownCloud/MATLAB/Data/TDT/' subnumber '/' 'easy' '/'];
elseif TaskDifficulty == '2'
    path = ['~/ownCloud/MATLAB/Data/TDT/' subnumber '/' 'hard' '/'];
end

if ~isdir(path)
    mkdir(path)
end

dnow = datestr(now,'dd-mm-yyyy_HH-MM-SS');
outputname = [path 'TDT_', session, '_sub', subnumber '_' dnow '.csv']; %also here

% convert these string variables to numeric for subsequent reference and calculations
if ischar(session)
    Session = str2double(session);end
if ischar(distance)
    distance = str2double(distance);end
if ischar(satQuadrant)
    satQuadrant= str2double(satQuadrant);end
if ischar(eyetracker)
    eyetracker = str2double(eyetracker);
end

%%%%%%%% LOG FILE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist(outputname, 'file')==2 % check to avoid overiding an existing file
    fileproblem = input('That file already exists! Append a .x (1), overwrite (2), or break (3/default)?');
    if isempty(fileproblem) || fileproblem==3
        return;
    elseif fileproblem==1
        outputname = [outputname '.x'];
    end
end

outfile = fopen(outputname,'w'); % open a file for writing data out
delimiter = ',';
fprintf(outfile, ['subnumber' delimiter 'distance' delimiter 'height' delimiter 'session' delimiter]);
fprintf(outfile, ['quadrant' delimiter 'satQuadrant Y/N' delimiter 'block' delimiter 'trial' delimiter 'target' delimiter 'SOA' delimiter]);
fprintf(outfile, ['Resp' delimiter '1stKEY' delimiter 'RESPtar' delimiter 'ACCtar' delimiter 'RTtar' delimiter 'SOATime' delimiter]);
fprintf(outfile, ['FixTime' delimiter 'BlankTime' delimiter 'StimTime' delimiter 'MaskTime' delimiter 'ClockTime' delimiter 'w_vb' delimiter 'w_vb' delimiter 'V_wb' delimiter 'V_wb' delimiter 'V_wb' delimiter 'V_wb' '\n']); %modifs pour test

%%%%%%%% INITIALIZE SCREEN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open the Screen, retrieve the resolution (screenrect)
black = [0 0 0]; white = [255 255 255]; blue = [0 0 255];
doubleScreenRatio = 1/2;
%Screen('Preference', 'SkipSyncTests', 1);
if isempty(screenrect)
    [screenrect]=psychInit(eyetracker,black,doubleScreenRatio);
    [~, height]=Screen('DisplaySize', 0);
    screenheight = height/10;%cm
end

resolution = screenrect(3:4);

Screen('FillRect', wPtr, black)

cycleRefresh = Screen('GetFlipInterval',wPtr);
display(cycleRefresh)

% define background (window-sized rectangle in black)
Screen(wPtr, 'Flip'); % flip screen to effectively show the drawing of the background
center = [screenrect(3)/2 screenrect(4)/2]; % center coordinates (note: left top coordinates = [x=0 y=0])

%%%%%%% INITIALIZE KEYBOARD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
key1 = KbName('f'); key2 = KbName('j'); % key for the task ( 1 = vertical, 2 = horizontal)
keyON = KbName('e'); keyOFF = KbName('r');
spaceKey = KbName('space'); escKey = KbName('ESCAPE');

%%%%%%%%%% TIMING VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Measure the vertical refresh rate of the monitor
ifi = Screen('GetFlipInterval', wPtr); %framerate

% Retreive the maximum priority number <-- what's this for
topPriorityLevel = MaxPriority(wPtr);
Priority(topPriorityLevel);
HideCursor;

% Accurate Timing definitions
blank = 0.250; % blank screen 250ms
blankframes = round(blank/ifi);

mask = 0.100; % mask: 100 ms
maskframes = round(mask/ifi);
resploop = 1; % max duration of response loop (seconds)
WaitFixationCross = 0.450;

% adaptive difficulty costants
conds = {linspace(-.6,.6,61)}; % for the bayesian staircase, all possible SOA's
% diode & lines size
diodeSquareSize = 40;
LineWidth = 6;

% debug option
if strcmp('test',subnumber)
    debug = true;
else
    debug = false;
end

try
    rng('shuffle') %for true random numbers
end

%%%%%%%%% INITIALIZE EXPERIMENT VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch Session
    case 0 %the training session
        nblocks = 2;
        ntrials = 40; % 10 with huge SOA and longer stim, 30 with max SOA, per quadrant
    case 1 % early session
        nblocks = 4;
        ntrials = 80;
    case 2 % mid session
        nblocks = 4;
        ntrials = 80; % only take an even number of trials because of some computations !!!
    case 3 % final session
        nblocks = 4;
        ntrials = 80; % only take an even number of trials because of some computations !!!
end

if debug
    ntrials = 10;
end

% initial SOA
switch Session
    case 0 %training session
        soalist = 1.2;
    otherwise
        soalist = 0.3;
end

%%%%%% INITIALIZE EYE TRACKER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DataEye = strcat('TDT', subnumber, session, '.edf'); % Texture Discrimination subject X session X

% here, it would be nicer to have makeKarniGrid function.
[X,Y,length,x,masklength] = makeKarniGrid(distance);
if eyetracker
    eyelinkInit(black,0)
end
%%%%%%% INSTRUCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DrawFormattedText(wPtr,'Gardez bien le regard fixe sur l''emplacement de la croix centrale.\n \nAppuyez sur F si les 3 lignes peripheriques sont verticales.\n \nAppuyez sur J si elles sont horizontales.\n', 'center', 'center', white);
Screen('Flip',wPtr);
if ~debug
    waitForSpaceKey;
end

Screen('FillRect', wPtr, black);
Screen('Flip',wPtr);
WaitSecs(1.5);

DrawFormattedText(wPtr,'Pret? Appuyez sur la barre d''espace pour demarrer l''experience!', 'center', 'center', white);
Screen('Flip',wPtr);
if ~debug
    waitForSpaceKey;
end

Screen('FillRect', wPtr, black);
Screen('Flip',wPtr);
WaitSecs(1.5);

%%%%%%% CONDITIONS SETTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%columns of condition matrix
angle = 1;
QUADRANT = 1;
rndmQuadrant = randi(2);
%changed this since using satQuadrant showed a bias for keeping
% same quadraants across TDTs within subject runs.. shouldn't affect
% anything else
conditionMatrix(:,QUADRANT) =  [rndmQuadrant,(3-rndmQuadrant), rndmQuadrant,(3-rndmQuadrant)];
% randomize quadrants thru blocks
if Session ~= 0
conditionMatrix = Shuffle(conditionMatrix);
end
%%%%%%% START OF BLOCK LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for k = 1:nblocks
    pastSoa = [];
    pastResponse = [];
    quadrant = conditionMatrix(k,QUADRANT);
    %% shows quadrant
    qu = {'droite','gauche'};
    DrawFormattedText(wPtr,['La cible apparait a ' qu{quadrant}], 'center', 'center', white);
    Screen('Flip',wPtr);
    WaitSecs(1.5);
    Screen('FillRect', wPtr, black);
    Screen('Flip',wPtr);
    WaitSecs(1.5);
    
    if eyetracker
        Eyelink('StartRecording');
    end
    
    %% RANDOMIZE TARGET POSITON %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    targetpos = targetPositions(quadrant,ntrials);
    %% %%%%%%%%%%%%%% RANDOMIZE TARGET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %randomize orientation of target (vertical or horizontal)
    NumberListOrientation = [1 2];
    LargeOrientationList = repmat(NumberListOrientation, 1, ntrials/2);
    orientation=Shuffle(LargeOrientationList);
    
    %% %%%%% START OF TRIAL LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for j = 1:ntrials
        if eyetracker
            Eyelink('Message', sprintf('STARTTRIAL #%d:  %s  (see "TRIALSYNCTME" msg below for actual onset)',j, datestr(now,'yyyy-mm-dd HH:MM:SS')));
        end
        %% %%%%%%%%%% RANDOMIZING COORDINATES MATRIX (entire grid) %%%%%%%%%%%%%%%%%
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
        b(1,:) = PositionMatrix(1,:) + (resolution(1)/2); %add half of full x pixels to x1 coordinate (begin of line)
        b(3,:) = PositionMatrix(3,:) + (resolution(1)/2); %add half of full x pixels to x2 coordinate (end of line)
        b(2,:) = PositionMatrix(2,:) + (resolution(2)/2); %add half of full y pixels to y1 cooridnate (begin of line)
        b(4,:) = PositionMatrix(4,:) + (resolution(2)/2); %add half of full y pixels to y1 cooridnate (end of line)
        
        %% %%%%%%%%%%%%%%%%%%% START OF DRAWING TO SCREEN %%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%% FIX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        DrawFormattedText(wPtr, '+', 'center', 'center', white);
        FixTime = Screen('Flip',wPtr); % Fix distance between the onset of each trial
        WaitSecs(WaitFixationCross);
        
        if eyetracker
            Eyelink('Message', 'FIX %d_%d_%d', Session, k, j); % onset of fixation for session X block X trial X
        end
        
        %%%%%%%%%%%%%%%%%%%% BLANK & STIM BACKGROUND %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Screen('FillRect', wPtr, black);
        DrawFormattedText(wPtr, '+', 'center', 'center', white); %keep fixation until end
        BlankTime = Screen('Flip',wPtr);
        
        if eyetracker
            Eyelink('Message', 'TRIALID %d', j); % real start of trial
            Eyelink('Message', 'BLANK %d_%d_%d', Session, k, j); % onset of blank screen of session X block X trial X
        end
        
        %% %%%%%%%%%%%%%%%%% STIMULI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %DRAW ALL THE OTHER HORIZONTAL LINES (BACKGROUND LINES) + DIAGONAL LINES (TARGET LINES)
        for i = 1:numDots
            if orientation(j) == 1 % draw the target vertically
                if i == targetpos(j) || i == (targetpos(j)+1) || i == (targetpos(j)-1) % to get three lines +1 and -1
                    
                    %change orientation 45???
                    if angle==1
                        theta = pi/4; %45???
                    elseif angle==2
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
                    
                    Screen('DrawLine', wPtr, white, rbx1+X(i)+center(1)+RandomMatrix1(i), rby1+Y(i)+center(2)+RandomMatrix2(i), rbx2+X(i)+center(1)+RandomMatrix1(i), rby2+Y(i)+center(2)+RandomMatrix2(i), LineWidth);
                else %draw all the other horizontal lines
                    Screen('DrawLine', wPtr, white, b(1,i), b(2,i), b(3,i), b(4,i), LineWidth);
                end
                
            elseif orientation(j) == 2 % draw the target horizontally
                if i == targetpos(j) || i == (targetpos(j)+19) || i == (targetpos(j)-19) % to get three lines minus and plus 19
                    
                    %change orientation 45???
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
                    
                    Screen('DrawLine', wPtr, white, rbx1+X(i)+center(1)+RandomMatrix1(i), rby1+Y(i)+center(2)+RandomMatrix2(i), rbx2+X(i)+center(1)+RandomMatrix1(i), rby2+Y(i)+center(2)+RandomMatrix2(i), LineWidth);
                else %draw all the other horizontal lines
                    Screen('DrawLine', wPtr, white, b(1,i), b(2,i), b(3,i), b(4,i), LineWidth);
                end
            end
        end
        
        %% stim time
        if Session == 0 % extended stim time in training session
            if j <= 10
                stim = 0.34; % 10 times longer than normal?
            else
                stim = 0.034;
            end
        else
            stim = 0.034;
        end
        
        stimframes = round(stim/ifi);
        Screen('FillRect',wPtr,white,[resolution(1)-diodeSquareSize resolution(2)-diodeSquareSize resolution(1) resolution(2)])
        DrawFormattedText(wPtr, '+', 'center', 'center', white); %keep fixation until end
        
        StimTime = Screen('Flip',wPtr, BlankTime + (blankframes-0.5) * ifi);
        
        if eyetracker
            Eyelink('Message', 'STIM %d_%d_%d', Session,k,j); % onset of stimulus for session X block X trial X
        end
        
        %% %%%%%%%%%%%%%%%SOA STAIRCASE%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % first trial pre established SOA, then bayesian staircase to
        % adjust difficulty based on performance. (y is response (1
        % vertical 0 horizontal, and x is possible SOA's, negative
        % horizontal, positive vertical)... MOVED TO AFTER RESPONSE
        if Session~=0
            % this way not gonna consider response to first trial for staircase
            if j== 1
                soa = soalist;
            end
        elseif Session == 0
            if j > 10 % in training after first 10 trials SOA decreases from magnitude defined above
                soalist = .6;
            end
            soa = soalist;
        end
        soaframes = round(abs(soa)/ifi);
        % if soa is zero or under, then 1 frame
        if soaframes < 0
            soaframes = 0;
        end
        %% %%%%%%%%%%%%%%% SOA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if soaframes>0
            Screen('FillRect', wPtr, black);
            DrawFormattedText(wPtr, '+', 'center', 'center', white); %keep fixation until end
            SOATime = Screen('Flip',wPtr, StimTime + (stimframes-0.5) * ifi);
            
            if eyetracker
                Eyelink('Message', 'SOA %d_%d_%d', Session,k,j); % onset of SOA for session X block X trial X
            end
        end
        
        %% %%%%%%%%%%%%%% MASK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for i = 1:numDots
            if i == 181 % THIS IS THE CENTER CELL OF THE GRID: COMPOUND LETTER 'T'/'L'
                %vertical line ('T')
                %origin point
                Tax1 = 0; % T = 0; L = -10
                Tay1 = -masklength/2;
                %end point
                Tax2 = 0; % T = 0; L = -10
                Tay2 = masklength/2;
                
                %vertical line ('L')
                %origin point
                Lax1 = -masklength/2; % T = 0; L = -10
                Lay1 = -masklength/2;
                %end point
                Lax2 = -masklength/2; % T = 0; L = -10
                Lay2 = masklength/2;
                
                %horizontal line
                %origin point
                bx1 = -masklength/2;
                by1 = -masklength/2;
                %end point
                bx2 = masklength/2;
                by2 = -masklength/2;
                
                %%Rotation
                theta = 2*pi*rand;
                cs = cos(theta);
                sn = sin(theta);
                
                %origin vertical line 'T'
                Trax1 = Tax1 * cs - Tay1 * sn; % origin X coordinate ROTATED
                Tray1 = Tax1 * sn + Tay1 * cs; % origin Y coordinate
                %end vertical line 'T'
                Trax2 = Tax2 * cs - Tay2 * sn;
                Tray2 = Tax2 * sn + Tay2 * cs;
                
                %origin vertical line 'L'
                Lrax1 = Lax1 * cs - Lay1 * sn; % origin X coordinate ROTATED
                Lray1 = Lax1 * sn + Lay1 * cs; % origin Y coordinate
                %end vertical line 'L'
                Lrax2 = Lax2 * cs - Lay2 * sn;
                Lray2 = Lax2 * sn + Lay2 * cs;
                
                %origin horizontal line
                rbx1 = bx1 * cs - by1 * sn;
                rby1 = bx1 * sn + by1 * cs;
                %end horizontal line
                rbx2 = bx2 * cs - by2 * sn;
                rby2 = bx2 * sn + by2 * cs;
                
                
                Screen('DrawLine', wPtr, white, Trax1+X(i)+center(1)+RandomMatrix1(i), Tray1+Y(i)+center(2)+RandomMatrix2(i), Trax2+X(i)+center(1)+RandomMatrix1(i), Tray2+Y(i)+center(2),LineWidth);
                Screen('DrawLine', wPtr, white, Lrax1+X(i)+center(1)+RandomMatrix1(i), Lray1+Y(i)+center(2)+RandomMatrix2(i), Lrax2+X(i)+center(1)+RandomMatrix1(i), Lray2+Y(i)+center(2),LineWidth);
                Screen('DrawLine', wPtr, white, rbx1+X(i)+center(1)+RandomMatrix1(i), rby1+Y(i)+center(2)+RandomMatrix2(i), rbx2+X(i)+center(1)+RandomMatrix1(i), rby2+Y(i)+center(2)+RandomMatrix2(i),LineWidth);
                
            else
                
                %centered V's randomly varying in orientation
                %coordinates for upside down 'V' as centered on an origin point (0,0)
                xm1 = 0;
                xm2a = -masklength/2;
                xm2b = masklength/2;
                ym1 = -masklength/2;
                ym2 = masklength/2;
                
                %random rotation calculation
                theta = 2*pi*rand; % random rotation angle
                cs = cos(theta);
                sn = sin(theta);
                b1 = xm2a * cs - ym2 * sn;  % rotated coordinates (see wiki on how rotation works)
                b2 = xm2a * sn + ym2  * cs;
                b3 = xm2b * cs - ym2 * sn;
                b4 = xm2b * sn + ym2 * cs;
                c1 = xm1 * cs - ym1 * sn;
                c2 = xm1 * sn + ym1 * cs;
                
                %draw all over !- add grid coordinates (X(i)/Y(i): non-jittered grid coordinates) only here (otherwise faulty vector lengths
                Screen('DrawLine', wPtr, white, c1+X(i)+center(1)+RandomMatrix1(i), c2+Y(i)+center(2)+RandomMatrix2(i), b1+X(i)+center(1)+RandomMatrix1(i), b2+Y(i)+center(2)+RandomMatrix2(i),LineWidth);
                Screen('DrawLine', wPtr, white, c1+X(i)+center(1)+RandomMatrix1(i), c2+Y(i)+center(2)+RandomMatrix2(i), b3+X(i)+center(1)+RandomMatrix1(i), b4+Y(i)+center(2)+RandomMatrix2(i),LineWidth);
                
            end %end of if else
        end % end of MASK
        
        Screen('FillRect',wPtr,white,[resolution(1)-diodeSquareSize resolution(2)-diodeSquareSize resolution(1) resolution(2)])
        
        if soaframes>0
            DrawFormattedText(wPtr, '+', 'center', 'center', white); %keep fixation until end
            
            MaskTime = Screen('Flip',wPtr, SOATime + (soaframes-0.5) * ifi);
        else
            DrawFormattedText(wPtr, '+', 'center', 'center', white); %keep fixation until end
            
            MaskTime = Screen('Flip',wPtr, StimTime + (stimframes-0.5) * ifi);
            SOATime = MaskTime;
        end
        
        if eyetracker
            Eyelink('Message', 'MASK %d_%d_%d', Session,k,j);% onset of mask for session X block X trial X
        end
        
        %% %%%%%%%%%%% RESPONSE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Screen('FillRect', wPtr, black);
        DrawFormattedText(wPtr, '+', 'center', 'center', white); %keep fixation until end
        
        RespTime = Screen('Flip',wPtr, MaskTime + (maskframes-0.5) * ifi);
        if eyetracker
            Eyelink('Message', 'RESP %d_%d_%d', Session,k,j); % onset of blank response window for session X block X trial X
        end
        
        %define usable keys and create keyboard queue to gather responses
        keys=[escKey,key1,key2, spaceKey];
        
        keylist=zeros(1,256);
        keylist(keys)=1;
        KbQueueCreate(10,keylist);
        KbQueueStart(10); % keyboard
        
        %initialize variable keypressed to ensure the variable exists when no
        %response is made and resets each time. Initialize first response loop
        %variables
        keypressedFirst = 0;
        keyIsDown=0; keyCode=0;
        StartTime = GetSecs(); %time before starting first response loop
        LoopTime = 0; %initialize first looptime variable (=RT)
        KbQueueFlush(10);
        
        %%%%%%%%%%poll for the  response%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        while LoopTime < resploop %after 'resploop' the loop will stop even without a response
            LoopTime = GetSecs() - StartTime; % calculate the time in the loop
            [keyIsDown, keyCode] = KbQueueCheck(10); % keyIsDown = has a key been pressed (1 or 0), keyCode = 256 logical vector indicating which key was pressed
            
            if keyIsDown == 1 % if a key is pressed (keyIsDown = 1)
                
                if  keyCode(key1) || keyCode(key2)
                    keypressedFirst=find(keyCode);
                    break;
                elseif keyCode(escKey)
                    fclose(outfile);
                    if eyetracker == 1, stopeyelinkrecord;end
                    Screen('CloseAll'); return
                end
                keyIsDown=0; keyCode=0;
            end
        end % end of while
        
        if eyetracker
            Eyelink('Message', 'RESP1 %d_%d_%d', Session,k,j); % time of first response
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%Answer Accuracy n RTs%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if keypressedFirst == key1 % if the first press was VERTICAL orientation
            Resp = 'target';
            %is the response to the target orientation task the correct response?
            %orientation 1 = vertical; orientation 2 = horizontal;
            if (orientation(j) == 1)
                RESPtarget = 1; ACCtarget = 1; RTtarget = LoopTime;
            elseif (orientation(j) == 2)
                RESPtarget = 1; ACCtarget = 0; RTtarget = LoopTime;
            end
        elseif keypressedFirst == key2 % if the first press was HORIZONTAL orientation
            Resp = 'target';
            if (orientation(j) == 1)
                RESPtarget = 2; ACCtarget = 0; RTtarget = LoopTime;
            elseif (orientation(j) == 2)
                RESPtarget = 2; ACCtarget = 1; RTtarget = LoopTime;
            end
        elseif keypressedFirst == 0 %if there was no response at all
            Resp = 'no_res'; RESPtarget = 0; ACCtarget = 0;
            RTtarget = LoopTime;
        end
        
        
        %%% Staircase w/response
        if Session~=0
            if keypressedFirst == key1 % vertical
                verticalresp = 1;
            elseif keypressedFirst == key2 % horizontal
                verticalresp = -1;
            else
                verticalresp = nan;
            end
            switch orientation(j)
                case 1
                    horizontalaxis = abs(soa); % vertical
                case 2
                    horizontalaxis = -abs(soa); % horizontal
            end
            switch j
                case ntrials
                    pastSoa = [pastSoa;horizontalaxis];
                    pastResponse = [pastResponse;verticalresp];
                    if ~debug
                        [soa, w_vb, V_vb] = adaptiveDifficulty(conds,pastSoa,pastResponse);
                    else
                        [soa, w_vb, V_vb] = adaptiveDifficulty(conds,pastSoa,[1 -1 1 1 -1 1 -1 1 1 -1]);
                    end
                otherwise
                    pastSoa = [pastSoa;horizontalaxis];
                    pastResponse = [pastResponse;verticalresp];
                    [soa] = adaptiveDifficulty(conds,pastSoa,pastResponse);
            end
        end
        %%%%%%%%%%%%%%% FEEDBACK SOUND in to mitigate lack of response %%%%%%%%%%%%%%%%%%%%%%%%%%%%
              
%                     if ACCtarget == 1
%                         Beeper('high',0.5,0.25);
if session == '0'
                    if strcmp(Resp, 'no_res')
                        Beeper('low', 0.5, 0.25);
                    end
end                                    
        %% %%%%%%%%%%%% BLANK for the differential time up to 2 sec %%%%%%%%%%%%%%%%
        Screen('FillRect', wPtr, black);
        Screen('Flip',wPtr);
        
        
        if eyetracker
            Eyelink('Message', 'TRIAL_RESULT %d', j); % mark end of trial
            Eyelink('Message', 'FINAL_BLANK %d_%d_%d', Session, k, j); % onset of the last blank interstimulus interval before next fixation (trial)
        end
        
        %         WaitSecsBlank = 2-(WaitFixationCross + stim + soa + mask + resploop); % in Secs! Fixation + stimulusTime + SOA + Mask + ResponseTime
        WaitSecsBlank = .5;
        WaitSecs(WaitSecsBlank);
        
        if quadrant == satQuadrant
            satquadrantyesno = 1;
        else
            satquadrantyesno = 0;
        end
        
        %% %%%%%%%%%%%%%%% WRITE TO LOGFILE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if ((k == 1) && (j == 1))
            fprintf(outfile, ['%s' delimiter],subnumber);
        else
            fprintf(outfile, ['\n' '%s' delimiter],subnumber);
        end
        fprintf(outfile, ['%s' delimiter],num2str(distance), num2str(screenheight), session);
        fprintf(outfile, ['%d' delimiter], quadrant, satquadrantyesno , k, j, orientation(j));
        fprintf(outfile, ['%6.3f' delimiter],soaframes*ifi);
        fprintf(outfile, ['%s' delimiter],Resp);
        fprintf(outfile, ['%d' delimiter],keypressedFirst, RESPtarget, ACCtarget);
        fprintf(outfile, ['%6.3f' delimiter], RTtarget, (MaskTime-SOATime));
        fprintf(outfile, ['%6.4f' delimiter], (BlankTime-FixTime), (StimTime-BlankTime), (SOATime-StimTime), (RespTime-MaskTime));
        if j<ntrials
            fprintf(outfile, ['%6.4f' delimiter], FixTime); %debug reasons (supression /n
        else
            fprintf(outfile, ['%6.4f' delimiter], FixTime);
        end
        if eyetracker
            Eyelink('Message',sprintf('STOPTTRIAL #%d:  %s',j, datestr(now,'yyyy-mm-dd HH:MM:SS')));
        end
    end %end of trial loop
    %% %%%%% ADD BREAK PERIOD OF 20s AS A CONTROL BLOCK CONDITION %%%%%%%%%%%%%%
    DrawFormattedText(wPtr, '+', 'center', 'center', blue);
    FixTime = Screen('Flip',wPtr);
    % Fix distance between the onset of each trial
    WaitSecs(5);%%FROM: 20
    if Session~=0
        if j == ntrials
            fprintf(outfile, ['%6.4f' delimiter], w_vb);
            fprintf(outfile, ['%6.4f' delimiter], V_vb);
        end
    end
    % clear pastSoa and Responses between blocks so that adaptive weights
    % are calculated for specific quadrant
    clear pastSoa pastResponse
end %end of block loop
if eyetracker
    Eyelink('StopRecording');
end
%% %%%% CLOSE LOG FILE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fclose(outfile);
if eyetracker 
    saveEyelink(path,['eyeTDT_' session, '_sub', subnumber '_' dnow '.edf']); 
    Eyelink('CloseFile') 
end
end
