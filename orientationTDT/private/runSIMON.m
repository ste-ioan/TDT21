  function stopTrial = runSIMON(tt0,firstFrame,option)
persistent sequence N

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
if firstFrame
if option == 1 % changed so that task difficulty 1 2 works for all tasks
    N = 2;
elseif option == 2 % randomly assign an N from 5 to 8 in hard condition
    N = randperm(6);
    N = N(N>3);
    N = N(1);
end
end

%general constants
keys = KbName({'d','f','j','k'});
ref=400;%A4
beepNotes = [-10 -5 5 10];% in semitones
beepFreqs = ref .* 2.^(beepNotes/12);
Fs = 44100;
    
%Durations
beepDuration = .2;
if option == 1
beepInterval = 1;
else
beepInterval = .5;
end
beepTotal = beepDuration+beepInterval;
timings = cumsum(repmat(beepTotal,N+1,1));
timings = timings + 3; % 3 seconds between trials
responseTimeOut = 10;

%%%%%%%%%%%%%%%% makes sequences %%%%%%%%%%%%
if firstFrame
    sequence = ceil(rand(N,1)*length(beepNotes));
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
        [beepVector] = TDTbeep(Fs, beepDuration, beepFreqs(sequence(currentStim)));
        PsychPortAudio('FillBuffer',soundBuffer, ...
            repmat(beepVector,2,1));
        PsychPortAudio('Start', soundBuffer);
        output.display(currentStim+1).onset = s;
        output.display(currentStim+1).name = ['BEEP' num2str(currentStim)];
    end
    DrawFormattedText(wPtr, '+', 'center', 'center', [255 255 255]);

elseif (s-tt0 <= (timings(end)+responseTimeOut)) && (~isfield(output,'response') || ~isfield(output.response,'time') || (length([output.response.time])<length(sequence)))
    ix = length(timings)+1;
    if length(output.display)<ix
        output.display(ix).onset = s;
        output.display(ix).name = 'RESP';
        for ii = 1:length(sequence)
            output.response(ii).stims = sequence(ii);
            output.response(ii).freqs = beepFreqs(sequence(ii));
        end
    end
    DrawFormattedText(wPtr, '+', 'center', 'center', [255 255 255]);
    rt = (s-output.display(ix).onset)*1000;
    
    %%response
    [responseTime,keyCode] = checkKey(keys);
    resp=find(keyCode(keys));
    if ~isnan(responseTime) && ~isempty(resp)
        if isfield(output.response,'time')
            rix=length([output.response.time]);
        else
            rix=0;
        end
        rix=rix+1;
        output.response(rix).time = responseTime;
        output.response(rix).rt = rt;
        output.response(rix).keys = keyCode;
        output.response(rix).resps = resp;
        output.response(rix).correct = resp(1)==sequence(rix);
        [beepVector] = TDTbeep(Fs, beepDuration, beepFreqs(resp(1)));
        PsychPortAudio('FillBuffer',soundBuffer, ...
            repmat(beepVector,2,1));
        PsychPortAudio('Start', soundBuffer);
      
    end

else
     % loop for when they dont answer at a target
    for p = 1:length(output.response)        
        if ~isfield(output.response,'rt')           
        output.response(p).correct = 0;         
        end
    end
    %%%%%%%%%%%% DO NOT CHANGE THIS %%%%%%%%%%%%%
    stopTrial = true;
    assignin('caller','output',output)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
end