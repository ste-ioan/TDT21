function stopTrial = runNBACK(tt0,firstFrame,N)
persistent stims sounds targets

%%%%%%%%%%% DO NOT CHANGE THIS PART %%%%%%%%%%%%%%
global wPtr soundBuffer
persistent output

s = GetSecs;
if firstFrame
    output = struct;
end
stopTrial = false;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%% constants %%%%%%%%%%%%%%
if N == 1
    N = 0; %changed this so that task difficulty 1 2 works for all tasks
elseif N == 2
    N = 3;    
end

%general constants
stimsPerTrial = 12;
targKey = KbName('f');%1
distrKey = KbName('j');%2

%Durations
duration = 1.25;
timings = cumsum(repmat(duration,stimsPerTrial+1,1));
timings = timings+3;
% trial lasts 15 seconds, has 12 stimuli, 2 seconds distance between trials

%%%%%%%%%%%%%%% loads sounds on first execution %%%%%%%%%%%%%%
if isempty(sounds)
    d='/Data/home/ownCloud/MATLAB/Scripts/TDT/original/';
    f=strfind(d,'/');
    alphabetPath = [d(1:f(end)) 'alphabet/'];
    for ch = double('A'):double('Z')
        [tmp,Fs] = audioread([alphabetPath char(ch) '.wav']);
        sounds{ch} = resample(tmp,44100,Fs);
    end
end

%%%%%%%%%%%%%%%% makes sequences %%%%%%%%%%%%
if firstFrame
    stims='';
    targsPerTrial = ceil(rand*4)-1;
    
    tmp=randperm(stimsPerTrial);
    tmp=tmp(tmp>N);
    lettertargetPositions = tmp(1:targsPerTrial);
    difix=max([1 N]);
    if N==0
        allStims = 'ABCDFGHKOPQRSTUVWZ';
        refStim='X';
        stims = allStims(randi(length(allStims),1,stimsPerTrial));
        stims(lettertargetPositions) = refStim;
    else
        allStims = 'ABCDFGHKOPQRSTUVWXZ';
        for ll = 1:difix
            stims(ll) = allStims(randi(length(allStims)));
        end
        for ll = (difix+1):stimsPerTrial
            
            
            refStim = stims(ll-difix);
            
            remainingLetters = setdiff(allStims,refStim);
            if any(lettertargetPositions==ll)
                stims(ll) = refStim;
            else
                stims(ll) = remainingLetters(randi(length(allStims)-1));
            end
        end
        
    end
    targets = zeros(1,stimsPerTrial);
    targets(lettertargetPositions) = 1;
end

%%%%%%%%%%%%%% PHASES OF THE TASK %%%%%%%%%%%%%%%%%%
if s-tt0 <= timings(1)
    if ~isfield(output,'display') || length(output.display)<1
        output.display(1).onset = s;
        output.display(1).name = 'FIX';
    end
    DrawFormattedText(wPtr, '+', 'center', 'center', [255 255 255]);
elseif s-tt0 <= timings(end)
    currentStim = find(timings<(s-tt0),1,'last');
    if length(output.display)<(currentStim+1) %onset of new letter, plus one is because of first onset being just fixation
        output.display(currentStim+1).onset = s;
        output.display(currentStim+1).name = ['LETTER' num2str(currentStim)];
        
        PsychPortAudio('FillBuffer',soundBuffer, ...
            repmat(sounds{double(stims(currentStim))},1,2)');
        PsychPortAudio('Start', soundBuffer);
        output.response(currentStim).time = NaN;
        output.response(currentStim).rt = NaN;
        output.response(currentStim).keys.key = NaN;
        output.response(currentStim).correct = NaN;
        output.response(currentStim).stim = stims(currentStim);
    end
    DrawFormattedText(wPtr, '+', 'center', 'center', [255 255 255]);
    
    rt = (s-output.display(currentStim+1).onset)*1000;
    
    %%response
    [responseTime,keyCode] = checkKey(targKey);
    if ~isnan(responseTime)
        output.response(currentStim).time = responseTime;
        output.response(currentStim).rt = rt;
        output.response(currentStim).keys = keyCode;
        if targets(currentStim)
            output.response(currentStim).correct = 1;
        else
            output.response(currentStim).correct = 0;
        end
        
    elseif isnan(output.response(currentStim).correct) && targets(currentStim)
        output.response(currentStim).correct = 0;
    end
    
    
else
    %%%%%%%%%%%% DO NOT CHANGE THIS %%%%%%%%%%%%%
    stopTrial = true;
    assignin('caller','output',output)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
end
