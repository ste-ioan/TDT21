function testTDT(subnumber, satQuadrant, session, previousSOA)
global wPtr path screenrect screenheight distance eyelinkflag

%% inputs and path
% Login prompt if not called thru MasterScript
if nargin == 0
    prompt = {'Subject''s Number:', 'saturated Quadrant',...
        'Session', 'Distance Eye-Screen', 'Eye-Tracker', 'Previous SOA'};
    defaults = {'test', '1', '1', '120', '0', '.16'};
    answer = inputdlg(prompt, 'test TDT', 1, defaults);
    [subnumber, satQuadrant, session, distance, eyetracker, previousSOA] = deal(answer{:}); % these are strings
end

if isempty(eyelinkflag)
    eyelinkflag = str2num(eyetracker);
end
% assign variable name depending on session
if strcmp(session, '1')
    Sessione = 'Baseline';
elseif strcmp (session, '2')
    Sessione = 'Conclusion';
end

% if previousSOA is inputted as character, convert it to double
if ischar(previousSOA)
    previousSOA = str2double(previousSOA);
end

% debug option
if strcmp('test',subnumber)
    debug = true;
else
    debug = false;
end
rng('shuffle') %for true random numbers

% path should be assigned before calling this function, thru MasterScript
if isempty(path)
    path = ['~/ownCloud/MATLAB/Data/TDT/newTDT/', subnumber, '/']; %check this
end

%%%% start file
    dnow = datestr(now,'dd-mm-yyyy_HH-MM-SS');
    outputname = [path 'testTDT_', Sessione, '_subj', subnumber, '_', dnow '.csv'];
    
    if debug
        outputname = ['~/ownCloud/MATLAB/Data/TDT/newTDT/test/testTDT_subjtest_', Sessione, '.csv'];
    end
    %% csv file
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
    
    outfile = fopen(outputname,'w'); % open a file for writing data out
    delimiter = ',';
    fprintf(outfile, ['subnumber' delimiter 'distance' delimiter 'height' delimiter 'session' delimiter]);
    fprintf(outfile, ['quadrant' delimiter 'satQuadrant Y/N' delimiter 'block' delimiter 'trial' delimiter 'targetalignment' delimiter 'targetorientation' delimiter 'SOA' delimiter]);
    fprintf(outfile, ['Resp' delimiter '1stKEY' delimiter 'RESPtar' delimiter 'ACCtar' delimiter 'RTtar' delimiter 'SOATime' delimiter]);
    fprintf(outfile, ['PreBlankTime' delimiter 'FixTime' delimiter 'StimTime' delimiter 'MaskTime' delimiter 'ClockTime' '\n']);

%% screen
% Open the Screen, retrieve the resolution (screenrect)
black = [0 0 0]; white = [255 255 255]; blue = [0 0 255];
doubleScreenRatio = 1/2;

if isempty(screenrect) % first run
    [screenrect]=psychInit(logical(eyelinkflag),black,doubleScreenRatio);
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

%% keyboard
key1 = KbName('f'); key2 = KbName('j'); % key for the task ( 1 = vertical, 2 = horizontal)
spaceKey = KbName('space');

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

LineWidth = 6;

%%%%%%%%% INITIALIZE EXPERIMENT VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nblocks = 4;
ntrials = 160;

% if debug
%     ntrials = 32;
% end

% fixed SOA
soa = previousSOA;

if ischar(distance)
    [X,Y,length,x,masklength] = makeKarniGrid(str2double(distance));
else
    [X,Y,length,x,masklength] = makeKarniGrid(distance);
end

% start up the eyelink in case of second sesh
if eyelinkflag
    eyelinkInit(black,1)
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

%%%%%%% START OF BLOCK LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for k = 1:nblocks
    if eyelinkflag
        Eyelink('StartRecording');
    end
        %% RANDOMIZE TARGET POSITON %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    targetcoordinates = newtargetPositions(ntrials,1);
    targetpos = targetcoordinates(1,:);
    targetalignment = targetcoordinates(2,:);
    targetorientation = targetcoordinates(3,:);
    ITI = targetcoordinates(end,:);
    %% %%%%% START OF TRIAL LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for j = 1:ntrials
        if eyelinkflag
            Eyelink('Message', sprintf('STARTTRIAL #%d:  %s  (see "TRIALSYNCTME" msg below for actual onset)',j, datestr(now,'yyyy-mm-dd HH:MM:SS')));
        end
        WaitFixationCross = ITI(j); % variable ITI
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
        
        %% %%%%%%%%%%%%%%%%%%% START OF DRAWING TO SCREEN %%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%% FIX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if ~debug
            DrawFormattedText(wPtr, '+', 'center', 'center', white);
        else
            DrawFormattedText(wPtr, 'ITI', 'center', 'center',  [0,255,255]);
        end
        
        FixTime = Screen('Flip',wPtr); % Fix distance between the onset of each trial
        WaitSecs(WaitFixationCross);
        
        if eyelinkflag
            Eyelink('Message', 'TRIALSYNCTME %d_%d', k, j); % onset of fixation for session X block X trial X
        end
        
        %%%%%%%%%%%%%%%%%%%% BLANK & STIM BACKGROUND %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Screen('FillRect', wPtr, black);
        if ~debug
            DrawFormattedText(wPtr, '+', 'center', 'center', white); %keep fixation until end
        else
            DrawFormattedText(wPtr, 'PREBLANK', 'center', 'center', white);
        end
        
        PreBlankTime = Screen('Flip',wPtr);
        
        if eyelinkflag
            Eyelink('Message', 'BLANK %d_%d', k, j); % onset of blank screen of session X block X trial X
        end
        
        %% %%%%%%%%%%%%%%%%% STIMULI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %DRAW ALL THE OTHER HORIZONTAL LINES (BACKGROUND LINES) + DIAGONAL LINES (TARGET LINES)
        vectorOfLinePositions = 1:numDots;
        vectorOfLinePositions(181) = []; % remove central stim so it doesn't overlap w fix cross
        for i = vectorOfLinePositions
            if targetalignment(j) == 1 % draw the target vertically
                if i == targetpos(j) || i == (targetpos(j)+1) || i == (targetpos(j)-1) % to get three lines +1 and -1
                    
                    if targetorientation(j)==1
                        theta = pi/4; %45
                    elseif targetorientation(j)==2
                        theta = pi/-4; %135
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
                
            elseif targetalignment(j) == 2 % draw the target horizontally
                if i == targetpos(j) || i == (targetpos(j)+19) || i == (targetpos(j)-19) % to get three lines minus and plus 19
                    
                    %change orientation
                    if targetorientation(j) == 1
                        theta = pi/4; %45
                    elseif targetorientation(j) == 2
                        theta = pi/-4; %135
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
        stim = 0.034;
        
        stimframes = round(stim/ifi);
        
        if ~debug
            DrawFormattedText(wPtr, '+', 'center', 'center', white); %keep fixation until end
        else
            DrawFormattedText(wPtr, 'STIM', 'center', 'center', white);
        end
        
        StimTime = Screen('Flip',wPtr, PreBlankTime + (blankframes-0.5) * ifi);
        
        if eyelinkflag
            Eyelink('Message', 'STIM %d_%d',k,j); % onset of stimulus for session X block X trial X
        end
        
        %% %%%%%%%%%%%%%%%SOA IS FIXED%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        soaframes = round(abs(soa)/ifi);
        %% %%%%%%%%%%%%%%% SOA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Screen('FillRect', wPtr, black);
        if ~debug
            DrawFormattedText(wPtr, '+', 'center', 'center', white); %keep fixation until end
        else
            DrawFormattedText(wPtr, 'SOA', 'center', 'center', [128 0 128]);
        end
        
        SOATime = Screen('Flip',wPtr, StimTime + (stimframes-0.5) * ifi);
        
        if eyelinkflag
            Eyelink('Message', 'SOA %d_%d',k,j); % onset of SOA for session X block X trial X
        end
        
        %% %%%%%%%%%%%%%% MASK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
        
        if ~debug
            DrawFormattedText(wPtr, '+', 'center', 'center', white); %keep fixation until end
        else
            DrawFormattedText(wPtr, 'MASK', 'center', 'center', [255 255 0]);
        end
        
        MaskTime = Screen('Flip',wPtr, SOATime + (soaframes-0.5) * ifi);
        
        
        if eyelinkflag
            Eyelink('Message', 'MASK %d_%d',k,j);% onset of mask for session X block X trial X
        end

        %%%%%%%%%%%%% RESPONSE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Screen('FillRect', wPtr, black);
        if ~debug
            DrawFormattedText(wPtr, '+', 'center', 'center', white); %keep fixation until end
        else
            DrawFormattedText(wPtr, 'RESP', 'center', 'center', [255 0 0]);
        end
        
        RespTime = Screen('Flip',wPtr, MaskTime + (maskframes-0.5) * ifi);
        if eyelinkflag
            Eyelink('Message', 'RESP %d_%d',k,j); % onset of blank response window for session X block X trial X
        end
        
        %define uble keys and create keyboard queue to gather responses
        keys=[key1,key2, spaceKey];
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
        
        %%%%%%%%%%poll for the  response%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if ~debug
            while LoopTime < resploop %after 'resploop' the loop will stop even without a response
                LoopTime = GetSecs() - StartTime; % calculate the time in the loop
                [keyIsDown, keyCode] = KbQueueCheck(keyboardIndex); % keyIsDown = has a key been pressed (1 or 0), keyCode = 256 logical vector indicating which key was pressed
                
                if keyIsDown == 1 % if a key is pressed (keyIsDown = 1)
                    
                    if  keyCode(key1) || keyCode(key2)
                        keypressedFirst=find(keyCode);
                        break;
                    end
                    keyIsDown=0; keyCode=0;
                end
            end % end of while
            
            if eyelinkflag
                Eyelink('Message', 'RESP1 %d_%d',k,j); % time of first response
            end
            
        else %simulate answers in debug mode
            LoopTime = rand;
            WaitSecs(LoopTime); % simulate a random RT
            if rand>.3
                keypressedFirst = keys(randi(2)+1); % randomly simulate F or J
            else
                keypressedFirst = 0; % randomly simulate lack of response
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%Answer Accuracy n RTs%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if keypressedFirst == key1 % if the first press was VERTICAL orientation
            Resp = 'target';
            %is the response to the target orientation task the correct response?
            %orientation 1 = vertical; orientation 2 = horizontal;
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
        
        %% %%%%%%%%%%%% BLANK for the differential between response and end of resploop %%%%%%%%%%%%%%%%
        Screen('FillRect', wPtr, black);
        % %                 if ~debug
        DrawFormattedText(wPtr, '+', 'center', 'center', white); %keep fixation until end
        %                 else
        %                 DrawFormattedText(wPtr, 'CATCHUP', 'center', 'center', [0,255,255]);
        %                 end
        Screen('Flip',wPtr);
        
        if eyelinkflag
            Eyelink('Message', 'TRIAL_RESULT %d', j); % mark end of trial
            Eyelink('Message', 'FINAL_BLANK %d_%d', k, j); % onset of the last blank interstimulus interval before next fixation (trial)
        end
        
        % add differential response time, SOA and ITI, not ITI though or it's
        % useless.. dunno bout MRI cause trial lengths will vary a little (.6 sec
        % max difference)
        WaitSecsBlank = (resploop-RTtarget) +(.6 - previousSOA); %(.8 - ITI(j));
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
        
        if targetorientation(j) == 1
            orientation = 45;
        else
            orientation = 135;
        end
        %% %%%%%%%%%%%%%% WRITE TO LOGFILE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if k == 1 && j == 1
            fprintf(outfile, ['%s' delimiter],subnumber);
        else
            fprintf(outfile, ['\n' '%s' delimiter],subnumber);
        end
        fprintf(outfile, ['%s' delimiter],num2str(distance), num2str(screenheight), session);
        fprintf(outfile, ['%d' delimiter], quadrant, satquadrantyesno , k, j, targetalignment(j), orientation);
        fprintf(outfile, ['%6.3f' delimiter],soaframes*ifi);
        fprintf(outfile, ['%s' delimiter],Resp);
        fprintf(outfile, ['%d' delimiter],keypressedFirst, RESPtarget, ACCtarget);
        fprintf(outfile, ['%6.3f' delimiter], RTtarget, (MaskTime-SOATime));
        fprintf(outfile, ['%6.4f' delimiter], (PreBlankTime-FixTime), (StimTime-PreBlankTime), (SOATime-StimTime), (RespTime-MaskTime));
        fprintf(outfile, ['%6.4f' delimiter], FixTime);
        
        if eyelinkflag
            Eyelink('Message',sprintf('STOPTTRIAL #%d:  %s',j, datestr(now,'yyyy-mm-dd HH:MM:SS')));
        end
        
    end %end of trial loop
    
    disp(['block ', num2str(k), 'finished']) 
    %% %%%%% ADD BREAK PERIOD OF 20s AS A CONTROL BLOCK CONDITION %%%%%%%%%%%%%%
    DrawFormattedText(wPtr, '+', 'center', 'center', blue);
    FixTime = Screen('Flip',wPtr);
    % Fix distance between the onset of each trial
    if ~debug
        if k < nblocks
            WaitSecs(18);
            Beeper('high', 0.3, 0.15);
            WaitSecs(2);
        end
    end

end %end of block loop
    %% %%%% CLOSE LOG FILE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fclose(outfile);
    
if eyelinkflag
    Eyelink('StopRecording');
    saveEyelink(path,['eyeTDT_' Sessione, '_sub', subnumber '_' dnow '.edf']);
    Eyelink('CloseFile')
end

end
