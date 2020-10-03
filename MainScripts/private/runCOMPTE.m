function stopTrial = runCOMPTE(tt0,firstFrame,condition)
persistent timings tone

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
if nargin<3
    condition = 1;
end
%general constants
keys = KbName({'f','j'});
Fs = 44100;

beepDuration= 0.020; % en sec
responseTimeOut = 10;

trial_length = 2.5; % gonna need 10*60/trial_length trials for 10 mins

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sequence & durations
if firstFrame
    
    %1 is easy, 2 is hard
    if condition==1
        counts = [4 5 7 8];
        %         silence = 0.360;  %, 0.440, 0.550]; % en sec, entre les bips
    elseif condition==2
        counts = [12 13 15 16];
        %         silence = .180; %[0.120, 0.150, 0.180]; % en sec, entre les bips
    end
    
    %     silence= Shuffle(silence);
    counts= Shuffle(counts);
    amorce = 0.7;
    sil_duration = (trial_length-amorce)/counts(1);
    
    % this way silence is dependent on counts..
    
    % 16 counts ~ .1125 / 12 counts ~.15
    % 4 counts ~ .45 / 8 counts ~ .225
    
    % beep duration(.020) isn't taken into account!
    
    timings = linspace(amorce,trial_length,counts(1)+1)+[0, 0.2*sil_duration*(2*rand(1,counts(1)-1)-1), 0];
    
    
    
    %          timings = cumsum([amorce ones(1,counts(1))*beepDuration+silence(1)])
    tones = Shuffle([1000, 800, 600, 400, 1200, 1400]);
    tone = tones(1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PHASES OF THE TASK
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
        
        countBeep = TDTbeep(Fs, beepDuration, tone);
        countBeep = [countBeep;countBeep];
        
        PsychPortAudio('FillBuffer',soundBuffer, ...
            countBeep);
        PsychPortAudio('Start', soundBuffer);
        output.display(currentStim+1).name = ['BEEP' num2str(currentStim)];
        
    end
    DrawFormattedText(wPtr, '+', 'center', 'center', [255 255 255]);
    
elseif (s-tt0 <= (timings(end)+responseTimeOut)) && (~isfield(output,'response') || ~isfield(output.response,'time') || (length([output.response.time])<1))
    ix = length(timings)+1;
    if length(output.display)<ix
        output.display(ix).onset = s;
        output.display(ix).name = 'RESP';
        %         output.response.sequence = sequence;
        %         output.response.correlatedSequence = correlSeq;
    end
    
    rt = (s-output.display(ix).onset)*1000;
    
    %%response
    [responseTime,keyCode] = checkKey(keys);
    resp=find(keyCode(keys));
    if ~isnan(responseTime) && ~isempty(resp)
        output.response.time = responseTime;
        output.response.rt = rt;
        output.response.keys = keyCode;
        output.response.resps = resp;
        
        if (length(output.display)-2)<10 && resp==1
            output.response.correct = 1;
        elseif (length(output.display)-2)>10 && resp==2
            output.response.correct = 1;
        else
            output.response.correct = 0;
        end
    end
    
    DrawFormattedText(wPtr, '+', 'center', 'center', [255 255 255]);
else
    %%%%%%%%%%%% DO NOT CHANGE THIS %%%%%%%%%%%%%
    stopTrial = true;
    assignin('caller','output',output)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
end
