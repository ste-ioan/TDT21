% new tdt training script (separate from test because of staircase procedure)
% stempio september 2020

function trainingTDT(subnumber,satQuadrant)
global wPtr path distance screenrect screenheight
%% inputs
% if no arguments are supplied, call a prompt to input them manually
if nargin == 0
    prompt = {'Subject''s Number:', 'saturated Quadrant',...
        'Distance Eye-Screen'};
    defaults = {'test', '1', '120'};
    answer = inputdlg(prompt, 'training TDT', 1, defaults);
    [subnumber, satQuadrant, distance] = deal(answer{:}); % these are strings
end

% debug option
if strcmp('test',subnumber)
    debug = true;
else
    debug = false;
end

% if function was called outside of MasterScript, create the path
if isempty(path)
    path = ['~/ownCloud/MATLAB/Data/TDT/newTDT/',subnumber];
end
%% csv file
% assign path to the csv file to stash data
if ~debug
    outputname = [path 'trainingTDT_', 'subj', subnumber '.csv'];
else
    outputname = '~/ownCloud/MATLAB/Data/TDT/newTDT/test/trainingTDT_subjtest.csv';
end

% check that the csv file doesn't already exist
if ~debug
    if exist(outputname, 'file')==2 % check to avoid overiding an existing file
        fileproblem = input('That file already exists! Append a .x (1), overwrite (2), or break (3/default)?');
        if isempty(fileproblem) || fileproblem==3
            return;
        elseif fileproblem==1
            outputname = [outputname '.x'];
        end
    end
end

% create the file and give variable(columns) names
outfile = fopen(outputname,'w'); % open a file for writing data out
delimiter = ',';
fprintf(outfile, ['subnumber' delimiter 'distance' delimiter 'height' delimiter]);
fprintf(outfile, ['quadrant' delimiter 'satQuadrantYN' delimiter 'block' delimiter 'trial' delimiter 'targetalignment' delimiter 'block_eye' delimiter 'SOA' delimiter]);
fprintf(outfile, ['Resp' delimiter 'RespKEY' delimiter 'RESPtar' delimiter 'ACCtar' delimiter 'RTtar' delimiter 'SOATime' delimiter]);
fprintf(outfile, ['FixTime' delimiter 'BlankTime' delimiter 'StimTime' delimiter 'MaskTime' delimiter 'ClockTime' delimiter 'intercept' delimiter 'slope' '\n']);
%% screen
% now we initialize the screen variables
% make variables for a bunch of colors that we'll use
black = [0 0 0]; white = [255 255 255]; blue = [0 0 255];
% two screens 1/2 one screen 1
doubleScreenRatio = 1/2;
% use psychInit function to initialize the screen and get screen measures

if ~debug
    eyelinkflag = 1;
else
    eyelinkflag = 0;
end

[screenrect]=psychInit(eyelinkflag,black,doubleScreenRatio);
[~, height]=Screen('DisplaySize', 0);
screenheight = height/10; % convert to cm
resolution = screenrect(3:4);
center = [screenrect(3)/2 screenrect(4)/2];

% this is the background, we're filling a blacksquare on the screen (wPtr)
Screen('FillRect', wPtr, black)
Screen(wPtr, 'Flip');
%% response keys
% define response keys
key1 = KbName('f'); key2 = KbName('j'); % ( f = vertical, j = horizontal)
spaceKey = KbName('space'); escKey = KbName('ESCAPE');

%% timing variables
% Measure the vertical refresh rate of the monitor
ifi = Screen('GetFlipInterval', wPtr); %framerate
% Retreive the maximum priority number
topPriorityLevel = MaxPriority(wPtr);
Priority(topPriorityLevel);
HideCursor;

% Accurate Timing definitions
blank = 0.250; % blank screen 250ms
blankframes = round(blank/ifi);
mask = 0.100; % mask: 100 ms
maskframes = round(mask/ifi);
resploop = 1; % max duration of response loop (seconds)

WaitFixationCross = 0.450; % fixation cross

%% experiment constants
rng('shuffle') %for true random numbers, doesn't matter where i put it

% adaptive difficulty
conds = {linspace(-.6,.6,61)}; % for the bayesian staircase, all possible SOA's
% perhaps i should remove 0
conds{1,1}(conds{1,:} == 0) = [];

% lines (stimuli) size
LineWidth = 6;
% 2 slow blocks, 4 real ones to get perf level
nblocks = 6;
commandwindow

% make tha grid
if isempty(distance)
    distance = '120';
end
[X,Y,length,x,masklength] = makeKarniGrid(str2double(distance));

% eye condition
if ~debug
    if any(str2double(subnumber)==1:8)
        eye_blocks = repmat({'L','R'},1,3);
    else
        eye_blocks = repmat({'R','L'},1,3);
    end
else
    eye_blocks = repmat({'L','R'},1,3);
end
%% show task instructions on screen
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

%% block loop starts here
for k = 1:nblocks
    if k < 3
        ntrials = 62;
    else
        ntrials = 80;
    end
    
    % in case you wanna live debug
    if debug
        ntrials = 10;
    end
    
    % initialize adaptive procedure variables at start of loop
    pastSoa = nan(ntrials,1);
    pastResponse = nan(ntrials,1);
    
    % compute target positions in the matrix, their orientations
    % (randomized and balanced)
    targetcoordinates = newtargetPositions(ntrials);
    targetpos = targetcoordinates(1,:);
    targetalignment = targetcoordinates(2,:);
    
    %% trial loop starts here
    for j = 1:ntrials
        %% randomize the coordinates of the matrix
        %add jitter to the raw, scaled coordinates
        RandomMatrix1 = (rand(size(X))*length/2) - (length/4);
        RandomMatrix2 = (rand(size(X))*length/2) - (length/4);
        XR = X + RandomMatrix1;
        YR = Y + RandomMatrix2;
        
        %Split in four coordinates and add length to the line (only the x-coordinates)
        %We need four coordinates to draw each lines in the grid
        
        % we add jitter to the horizontal background lines to make task
        % tougher since we only have 2 target locations (one per quadrant)
        jitterRange = pi/6; % smaller the divider, greater the eccentricity
        theta = -(jitterRange/2)+(rand(size(XR))*jitterRange);
        cs = cos(theta);
        sn = sin(theta);
        
        x1 = XR - (length/2)*cs;
        x2 = XR + (length/2)*cs;
        y1 = YR - (length/2)*sn;
        y2 = YR + (length/2)*sn;
        
        %Reshape each 19x19 coordinate matrix into on 4x361 coordinate matrix where
        %each column contains the four coordinates for a line (for all 361 cells in the grid)
        numDots = numel(x);
        PositionMatrix = [reshape(x1, 1, numDots); reshape(y1, 1, numDots); reshape(x2, 1, numDots); reshape(y2, 1, numDots)];
        b = PositionMatrix; %4x361 matrix;
        
        % centering each of the four coordinates
        b(1,:) = PositionMatrix(1,:) + (resolution(1)/2); %add half of full x pixels to x1 coordinate (begin of line)
        b(3,:) = PositionMatrix(3,:) + (resolution(1)/2); %add half of full x pixels to x2 coordinate (end of line)
        b(2,:) = PositionMatrix(2,:) + (resolution(2)/2); %add half of full y pixels to y1 cooridnate (begin of line)
        b(4,:) = PositionMatrix(4,:) + (resolution(2)/2); %add half of full y pixels to y1 cooridnate (end of line)
        
        % now we draw onto the screen
        %% fixation cross
        if debug
            DrawFormattedText(wPtr, 'FIX CROSS', 'center', 'center', [0 255 0]); % different color to distinguish
        else
            DrawFormattedText(wPtr, '+', 'center', 'center', white); %keep fixation until end
        end
        FixTime = Screen('Flip',wPtr); % Fix distance between the onset of each trial
        WaitSecs(WaitFixationCross);
        %% blank time before stim
        Screen('FillRect', wPtr, black);
        if debug
            DrawFormattedText(wPtr, 'PRE BLANK', 'center', 'center', [0 128 0]); % different color to distinguish
        else
            DrawFormattedText(wPtr, '+', 'center', 'center', white); %keep fixation until end
        end
        
        BlankTime = Screen('Flip',wPtr);
        %% now draw the lines
        vectorOfLinePositions = 1:numDots;
        vectorOfLinePositions(181) = []; % remove central stim so it doesn't overlap w fix cross
        for i = vectorOfLinePositions
            if targetalignment(j) == 1 %target vertical
                if i == targetpos(j) || i == (targetpos(j)+1) || i == (targetpos(j)-1) % to get three lines +1 and -1
                    
                    % line orientation
                    theta = pi/4;
                    
                    
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
                
            elseif targetalignment(j) == 2 % target horizontal
                if i == targetpos(j) || i == (targetpos(j)+19) || i == (targetpos(j)-19) % to get three lines minus and plus 19
                    
                    % line orientation
                    theta = pi/4;
                    
                    
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
        
        if k < 3 && j < 30 % half trials of the first 2 blocks
            stim = 0.34; % stim time is 10 times longer than normal
        else
            stim = 0.034;
        end
        
        stimframes = round(stim/ifi);
        
        if debug
            DrawFormattedText(wPtr, 'STIM', 'center', 'center', [255 255 0]); % different color to distinguish
        else
            DrawFormattedText(wPtr, '+', 'center', 'center', white); %keep fixation until end
        end
        
        StimTime = Screen('Flip',wPtr, BlankTime + (blankframes-0.5) * ifi);
        
        % if you want to freeze onto the stim screen
        if ~debug
            
            if j<3 && k < 3 %debug
                commandwindow
                pause
            end
        end
        
        %% SOA
        % first 2 blocks use max SOA
        if k < 3
            soa = .6;
        else   % 1st trial of other blocks, half of that
            if j == 1
                soa = .3;
            end
        end
        soaframes = round(abs(soa)/ifi);
        
        if soaframes>0
            Screen('FillRect', wPtr, black);
            if debug
                DrawFormattedText(wPtr, 'SOA', 'center', 'center', [128 0 128]); % different color to distinguish
            else
                DrawFormattedText(wPtr, '+', 'center', 'center', white); %keep fixation until end
            end
            SOATime = Screen('Flip',wPtr, StimTime + (stimframes-0.5) * ifi);
        end
        %% mask
        for i = vectorOfLinePositions
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
            
        end
        
        if debug
            DrawFormattedText(wPtr, 'MASK', 'center', 'center', [255 255 0]); % different color to distinguish
        else
            DrawFormattedText(wPtr, '+', 'center', 'center', white); %keep fixation until end
        end
        MaskTime = Screen('Flip',wPtr, SOATime + (soaframes-0.5) * ifi);
        %% response
        Screen('FillRect', wPtr, black);
        
        if debug
            DrawFormattedText(wPtr, 'RESP', 'center', 'center', [255 0 0]); % different color to distinguish
        else
            DrawFormattedText(wPtr, '+', 'center', 'center', white); %keep fixation until end
        end
        
        RespTime = Screen('Flip',wPtr, MaskTime + (maskframes-0.5) * ifi);
        
        %define usable keys and create keyboard queue to gather responses
        keys=[escKey,key1,key2, spaceKey];
        keyboardIndex =  GetKeyboardIndices('USB Keyboard'); % depends on keyboard connected to pc..
        keyboardIndex = keyboardIndex(1);
        
        keylist=zeros(1,256);
        keylist(keys)=1;
        KbQueueCreate(keyboardIndex,keylist);
        KbQueueStart(keyboardIndex); % keyboard
        
        %initialize variable keypressed to ensure the variable exists when no
        %response is made and resets each time. Initialize first response loop
        %variables
        keypressedFirst = 0;
        keyIsDown=0; keyCode=0;
        StartTime = GetSecs(); %time before starting first response loop
        LoopTime = 0; %initialize first looptime variable (=RT)
        KbQueueFlush(keyboardIndex);
        
        if ~debug
            %  poll for the  response
            while LoopTime < resploop %after 'resploop' the loop will stop even without a response
                LoopTime = GetSecs() - StartTime; % calculate the time in the loop
                [keyIsDown, keyCode] = KbQueueCheck(keyboardIndex); % keyIsDown = has a key been pressed (1 or 0), keyCode = 256 logical vector indicating which key was pressed
                
                if keyIsDown == 1 % if a key is pressed (keyIsDown = 1)
                    
                    if  keyCode(key1) || keyCode(key2)
                        keypressedFirst=find(keyCode);
                        break;
                    elseif keyCode(escKey)
                        fclose(outfile);
                        Screen('CloseAll'); return
                    end
                    keyIsDown=0; keyCode=0;
                end
            end % end of while
            
        else %simulate answers in debug mode
            LoopTime = rand;
            WaitSecs(LoopTime); % simulate a random RT
            if rand>.3
                keypressedFirst = keys(randi(2)+1); % randomly simulate F or J
            else
                keypressedFirst = 0; % randomly simulate lack of response
            end
        end
        
        if keypressedFirst == key1 % if the first press was VERTICAL orientation
            Resp = 'target';
            % is the response to the target orientation task the correct response?
            % orientation 1 = vertical; orientation 2 = horizontal;
            if (targetalignment(j) == 1)
                RESPtarget = 1; ACCtarget = 1; RTtarget = LoopTime;
            elseif (targetalignment(j) == 2)
                RESPtarget = 1; ACCtarget = 0; RTtarget = LoopTime;
            end
        elseif keypressedFirst == key2 % if the first press was HORIZONTAL orientation
            Resp = 'target';
            if (targetalignment(j) == 1)
                RESPtarget = 2; ACCtarget = 0; RTtarget = LoopTime;
            elseif (targetalignment(j) == 2)
                RESPtarget = 2; ACCtarget = 1; RTtarget = LoopTime;
            end
        elseif keypressedFirst == 0 %if there was no response at all
            Resp = 'no_res'; RESPtarget = 0; ACCtarget = 0;
            RTtarget = LoopTime;
        end
        
        %% staircase adaptive procedure
        if k > 2
            if keypressedFirst == key1 % vertical
                verticalresp = 1;
            elseif keypressedFirst == key2 % horizontal
                verticalresp = -1;
            else
                verticalresp = nan;
            end
            switch targetalignment(j)
                case 1
                    horizontalaxis = abs(soa); % vertical
                case 2
                    horizontalaxis = -abs(soa); % horizontal
            end
            switch j
                case ntrials % if reached number of trials of the block, wrap up responses to extract weights
                    pastSoa(j) = horizontalaxis;
                    pastResponse(j) = verticalresp;
                    %                     if ~debug
                    [~, w_vb, ~] = adaptiveDifficulty(conds,pastSoa,pastResponse);
                    %                     else
                    %                      w_vb = [1,2];
                    %                     end
                otherwise
                    pastSoa(j) = horizontalaxis;
                    pastResponse(j) = verticalresp;
                    [soa] = adaptiveDifficulty(conds,pastSoa,pastResponse);
            end
        else
            %% FEEDBACK SOUND in first 2 blocks
            if strcmp(Resp, 'no_res')
                Beeper('low', 0.5, 0.25);
            end
        end
        %% final blank
        Screen('FillRect', wPtr, black);
        if debug
            DrawFormattedText(wPtr, 'POST BLANK', 'center', 'center', [0,255,255]); % different color to distinguish
        else
            DrawFormattedText(wPtr, '+', 'center', 'center', white); %keep fixation until end
        end
        Screen('Flip',wPtr);
        % account for parts of the trial with variable length (response time and soa)
        % to have a constant trial length (doesnt work bc staircase computation is
        % variable, still helps doe)
        if k> 2
            WaitSecsBlank = ((resploop-RTtarget) + (.6 - abs(pastSoa(j))));
        else % there's no past soa in first 2 blocks
            % for some reason this doesn't work; shorter rt cause
            % differences in trial duration, do we care?
            WaitSecsBlank = (resploop-RTtarget);
        end
        
        WaitSecs(WaitSecsBlank);
        %% define variables to be written on csv file
        if targetpos(j) == 289
            quadrant = 1;
        else
            quadrant = 2;
        end
        
        if quadrant == str2double(satQuadrant)
            satquadrantyesno = 1;
        else
            satquadrantyesno = 0;
        end
        %% write to csv file
        if k == 1 && j == 1
            fprintf(outfile, ['%s' delimiter],subnumber);
        else
            fprintf(outfile, ['\n' '%s' delimiter],subnumber);
        end
        fprintf(outfile, ['%s' delimiter],num2str(distance), num2str(screenheight));
        fprintf(outfile, ['%d' delimiter], quadrant, satquadrantyesno , k, j, targetalignment(j));
        fprintf(outfile, ['%s' delimiter], eye_blocks{k});
        fprintf(outfile, ['%6.3f' delimiter],soaframes*ifi);
        fprintf(outfile, ['%s' delimiter],Resp);
        fprintf(outfile, ['%d' delimiter],keypressedFirst, RESPtarget, ACCtarget);
        fprintf(outfile, ['%6.3f' delimiter], RTtarget, (MaskTime-SOATime));
        fprintf(outfile, ['%6.4f' delimiter], (BlankTime-FixTime), (StimTime-BlankTime), (SOATime-StimTime), (RespTime-MaskTime));
        fprintf(outfile, ['%6.4f' delimiter], FixTime);
        if j == ntrials && k > 2
            fprintf(outfile, ['%6.4f' delimiter], w_vb(1), w_vb(2));
        else
            fprintf(outfile, ['%6.4f' delimiter], nan, nan);
        end
        
    end
    %% BREAK PERIOD OF 20s AS A CONTROL BLOCK CONDITION %%%%%%%%%%%%%%
    if k < 6
    DrawFormattedText(wPtr, 'changer d oeil', 'center', 'center', white);
    FixTime = Screen('Flip',wPtr);
    
    if ~debug
        waitForSpaceKey
        
        DrawFormattedText(wPtr, '+', 'center', 'center', blue);
        Screen('Flip',wPtr);
        
        if k == nblocks
            WaitSecs(7)
        else
            WaitSecs(5);
            Beeper('high', 0.3, 0.15);
            WaitSecs(2);
        end
    end
end
    % clear pastSoa and Responses between blocks so that adaptive weights
    % are calculated for the new block
    clear pastSoa pastResponse
end
%% close file
fclose(outfile);
sca

clc

previousSOA = extractSOA(outputname);
disp(['estimated SOA: ', num2str(previousSOA)])
disp(' ')

end

