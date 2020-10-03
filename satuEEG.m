%% EEG data collection for satuTask (within MasterScript)
% show lines on both quadrants for a couple of minutes
function satuEEG(eyetracker, startQuadrant)
% take this out for exp
debug = 0;

global wPtr screenrect screenheight distance path

rng('shuffle') %for true random numbers

if isempty(screenrect)
    [screenrect]=psychInit(eyetracker,[0 0 0],1/2);
    [width, height]=Screen('DisplaySize', 0);
    screenheight = height/10;%cm
end

if isempty(distance)
    distance = 120; % watch out for distance here
elseif ischar(distance)
    distance = str2double(distance);
end

resolution = screenrect(3:4);
center = [screenrect(3)/2 screenrect(4)/2]; % center coordinates (note: left top coordinates = [x=0 y=0])

PixelsPerDegree = 180*2*atan(screenheight/(2*distance))/pi;
[X,Y,sizeline,x]=makeKarniGrid(distance);
LineWidth = 6;

%% stimulation parameters

stimFreq = 8; %changed this to 15 for oleg2
alignOnScreen = true;
frameTotal = 0;
stimFrames = 8;% should have put this to 4 instead
cycleRefresh = Screen('GetFlipInterval',wPtr);

%%
col = [255 255 255];
fixationRadius = 5*PixelsPerDegree;


nblocks = 4; %one per quadrant CHANGED FROM 2 FROM
ntrials = 1;
if startQuadrant == 1
    quadrants = [1 2 1 2];
elseif startQuadrant == 2
    quadrants = [2 1 2 1];
end
diodeSquareSize = 40;
dnow = datestr(now,'dd-mm-yyyy_HH-MM-SS');

outputname3 = ['satuEEG_' dnow];


DrawFormattedText(wPtr,'Manually trigger on EEG pc', 'center', 'center', [128 128 128]);
Screen('Flip',wPtr);
if~debug
    waitForSpaceKey;
end

if eyetracker
    Eyelink('StartRecording');
end

t = GetSecs;
for k = 1:nblocks
    angle = 1;
    quadrant = quadrants(k); % take one or two, in order
    targetpos = targetPositions(quadrant);
    [new_point,size_point,newdrawpoint] = makeRandomGrid(sizeline,X,Y,x,screenrect,targetpos,quadrant,angle,center);
    if ~alignOnScreen
        diffc2 = 0;
        c = (1+sin(GetSecs * 2 * pi * stimFreq))/2;
    end
    if eyetracker
            Eyelink('Message',sprintf('Baselining Quadrant #%d:',quadrant));
    end
    Screen('FillRect', wPtr, [0 0 0]);
    Screen('Flip',wPtr);
    
    if ~debug
        WaitSecs(5); % 5 seconds of darkness before each stimulation
    end
    sendSerial(num2str(quadrant)) %put it here so trigger is at stim
    
    for j = 1:ntrials
        stopTrial=false;
        trialStart = GetSecs;
        lineCoords = [];
        fixation = [];
        displayOnset = [];
        frameNum = 0;
        
        while ~stopTrial
            frameNum = frameNum+1;
            %             frameTotal = frameTotal+1;
            s = GetSecs;
            if alignOnScreen
                c = (1+sin((frameNum/stimFrames) * 2 * pi))/2;
            else
                c2 = (1+sin(s * 2 * pi * stimFreq))/2;
                diffc = c2-c;
                c=c2;
            end
            
            if eyetracker
                fixBroken = checkFixation(fixationRadius);
                if fixBroken
                    if ~stopTrial
                        DrawFormattedText(wPtr, '+', 'center', 'center', [255 128 128]);
                    end
                    fixation(end+1)=s;
                end
            end
            
            if alignOnScreen
                if mod(frameTotal,stimFrames)==0
                    [new_point,size_point,newdrawpoint] = makeRandomGrid(sizeline,X,Y,x,screenrect,targetpos,quadrant,angle,center);
                end
            else
                if diffc2<0 && diffc>=0
                    [new_point,size_point,newdrawpoint] = makeRandomGrid(sizeline,X,Y,x,screenrect,targetpos,quadrant,angle,center);
                end
            end
            
            lineCoords(frameNum,:,:) = new_point;
            lineIntensities(frameNum,:) = round(col * c);
            
            for id = 1:size_point(1)
                if newdrawpoint(id)
                    Screen('DrawLine', wPtr,col*c, new_point(id,1),new_point(id,2),new_point(id,3),new_point(id,4),LineWidth);
                end
            end
            
            Screen('FillRect',wPtr,round(col * c),[resolution(1)-diodeSquareSize resolution(2)-diodeSquareSize resolution(1) resolution(2)])
            
            if ~debug
                if (GetSecs-trialStart)>=60 % 2 minutes CHANGED FOR ALEX FAST RUN
                    stopTrial = true;
                end
            else
                if (GetSecs-trialStart)>=2 %2 seconds in debug mode
                    stopTrial = true;
                end
            end
            
            DrawFormattedText(wPtr, '+', 'center', 'center', [255 255 255]); %keep fixation until mask
            
            ttt=t;
            
            if ~alignOnScreen
                diffc2=diffc;
            end
            
            t = Screen('Flip',wPtr); % Fix distance between the onset of each trial
            frameTotal = frameTotal+round((t-ttt)/cycleRefresh);
            
            if (t-ttt)>(cycleRefresh+0.002)
                disp(['******' num2str(t-ttt) '************'])
            end
            
            displayOnset(end+1) = t;
            
        end
        
        
        alldisplayOnsets{k,j} = displayOnset;
        allLineCoords{k,j} = lineCoords;
        allLineIntensities{k,j} = lineIntensities;
        brokenFixations{k,j} = fixation;
        
    end
    
    Screen('FillRect', wPtr, [0 0 0]);
    Screen('Flip',wPtr);
    %
    %     if ~debug
    % %         WaitSecs(5); %10 seconds of darkness before stimulation (start recording)
    %     end
    
end

if eyetracker
    Eyelink('StopRecording');
    saveEyelink(path,[outputname3 '.edf']);
    Eyelink('CloseFile')
end
try
    save([path outputname3 '.mat']);
catch
    disp('no path specified, so not saving')
end
Screen('FillRect', wPtr, [0 0 0]);
Screen('Flip',wPtr);

