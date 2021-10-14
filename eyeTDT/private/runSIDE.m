function stopTrial = runSIDE(tt0,firstFrame,condition)

% presenting sounds to left/right headphone, divided by categories{1,2}
% and signalled by cue sounds (hard mode) which indicate if subject must answer
% coherently to presentation of a certain category, and incoherently to the
% other, with a third category{3} of distractor sounds to which n  ot answer
% TSTART = tic;
%%%%%%%%%%% DO NOT CHANGE THIS PART %%%%%%%%%%%%%%
global wPtr soundBuffer path
persistent outputtemplate output indexbegin indexfinish trialchunk allsounds
% debug = false;
% msg = '';
% if debug,msg = [msg 'step 1 \n'];save(fullfile(path,'msglogtask.mat'),'msg');end
if isempty(outputtemplate)
    outputtemplate.display(1).onset = [];
    outputtemplate.display(1).name = '';
end
s = GetSecs;
if firstFrame
    output = outputtemplate;
end
stopTrial = false;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% constants %%%%%%%%%%%%%%
% tGlobalsandPers = toc(TSTART);


stimsPerTrial =  5;
keys = KbName({'f','j'});

%durations
if condition == 1
    duration = 5.9;
elseif condition == 2
    duration = 3.5;
end
timings= floor(cumsum(repmat(duration,stimsPerTrial+1,1)));
timings= timings + 3; % 3 seconds between trials
% if debug,msg = [msg 'step 2 \n'];save(fullfile(path,'msglogtask.mat'),'msg');end
%%%%%%%%%%%%%%% loads sounds on first execution %%%%%%%%%%%%%%
if isempty(allsounds)
allsounds = sounds_extraction(condition);
end
% tAllsoundsisEmpty = toc(TSTART);

% if debug,msg = [msg 'step 3 \n'];save(fullfile(path,'msglogtask.mat'),'msg');end

% feed chunk of sounds to be reproduced by trial
%attempting to use less persistent variables
% idx = 1:stimsPerTrial:length(allsounds);

if firstFrame
    if isempty(indexbegin)
        indexbegin = 1;
        indexfinish = stimsPerTrial;
    end
%     if debug,msg = [msg 'step 4 \n'];save(fullfile(path,'msglogtask.mat'),'msg');end
    trialchunk = allsounds(indexbegin:indexfinish);
end
% tidxandchunk=toc(TSTART);

% if debug,msg = [msg 'step 5 \n'];save(fullfile(path,'msglogtask.mat'),'msg');end
%%%%%%%%%%%%%% PHASES OF THE TASK %%%%%%%%%%%%%%%%%%
%beginning of task, time elapsed (s-tt0) is less than first timing,
%fixation cross is shown
if s-tt0 <= timings(1)
    %disp('1')
%     if debug,msg = [msg 'loop 1 \n'];save(fullfile(path,'msglogtask.mat'),'msg');end
    if ~isfield(output,'display') || length(output.display)==1
        output.display(1).onset = s;
        output.display(1).name = 'FIX';
    end
    DrawFormattedText(wPtr, '+', 'center', 'center', [255 255 255]);

%     if debug,msg = [msg 'step 6 \n'];save(fullfile(path,'msglogtask.mat'),'msg');end
elseif s-tt0 <= timings(end) %call stimuli until the end
    %disp('2')
%     if debug,msg = [msg 'loop 2 \n'];save(fullfile(path,'msglogtask.mat'),'msg');end
    
    currentStim = find(timings<(s-tt0),1,'last');
%     tCurrentstim=toc(TSTART);
    if length(output.display)<(currentStim+1) %onset of new sound, plus one is because of first onset being just fixation
%         disp('newsound')
        output.display(currentStim+1).onset = s;
        output.display(currentStim+1).name = ['SOUND' trialchunk(currentStim).name(1:end-4)];
%         if debug,msg = [msg 'sound' num2str(currentStim) ' 1\n'];save(fullfile(path,'msglogtask.mat'),'msg');end
        PsychPortAudio('FillBuffer',soundBuffer, ...
            trialchunk(currentStim).Y');
%         startCue = 0;
%         waitForDeviceStart = 1;
%         if debug,msg = [msg 'sound' num2str(currentStim) ' 2\n'];save(fullfile(path,'msglogtask.mat'),'msg');end
        PsychPortAudio('Start', soundBuffer);%,1,startCue,waitForDeviceStart);
%         if debug,msg = [msg 'sound' num2str(currentStim) ' 3\n'];save(fullfile(path,'msglogtask.mat'),'msg');end
        output.response(currentStim).time = NaN;
        output.response(currentStim).rt = NaN;
        output.response(currentStim).keys.key = NaN;
        output.response(currentStim).side = trialchunk(currentStim).side;
        output.response(currentStim).target = trialchunk(currentStim).target;
        output.response(currentStim).correct = NaN;
        output.response(currentStim).stim = trialchunk(currentStim).name;
    end
%     tSound=toc(TSTART);
    DrawFormattedText(wPtr, '+', 'center', 'center', [255 255 255]);
%     tCross=toc(TSTART);
    rt = (s-output.display(currentStim+1).onset)*1000;
%     if debug,msg = [msg 'step 7 \n'];save(fullfile(path,'msglogtask.mat'),'msg');end
    %%response
    [responseTime,keyCode] = checkKey(keys);
%     tResp=toc(TSTART);
    if ~isnan(responseTime)
        output.response(currentStim).time = responseTime;
        output.response(currentStim).rt = rt;
        output.response(currentStim).keys = keyCode;
        if trialchunk(currentStim).target == 1
            if trialchunk(currentStim).response == 42 && any(find(output.response(currentStim).keys) == 42) || trialchunk(currentStim).response == 45 && any(find(output.response(currentStim).keys) == 45)
                output.response(currentStim).correct = 1;
            else
                output.response(currentStim).correct = 0;
            end
        elseif trialchunk(currentStim).target == 0
            output.response(currentStim).correct = 0;
        end
    end
%     tFinish=toc(TSTART);
%     if tFinish>0.01
%         disp(['GlePers' num2str(tGlobalsandPers) 'Empty' num2str(tAllsoundsisEmpty) 'IdxChnk' num2str(tidxandchunk) 'CrrntStm' num2str(tCurrentstim) 'Sound' num2str(tSound) 'Cross' num2str(tCross) 'Resp' num2str(tResp) 'Fnt' num2str(tFinish)])
%     end
%     if debug,msg = [msg 'step 8 \n'];save(fullfile(path,'msglogtask.mat'),'msg');end
else
%     disp('3')
%     if debug,msg = [msg 'loop 3 \n'];save(fullfile(path,'msglogtask.mat'),'msg');end
    % update trial-wise indices
    indexbegin = indexfinish+1;
    indexfinish = indexfinish+stimsPerTrial;
    
    % loop for when they dont answer at a target
    for p = 1:length(output.response)        
        if isnan(output.response(p).rt)
            if output.response(p).target == 1
                output.response(p).correct = 0;
            elseif output.response(p).target == 0
                output.response(p).correct = 1;
            end
        end
    end
%     if debug,msg = [msg 'step 9 \n'];save(fullfile(path,'msglogtask.mat'),'msg');end
    %%%%%%%%%%%% DO NOT CHANGE THIS %%%%%%%%%%%%%
    stopTrial = true;
    assignin('caller','output',output)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     if debug,msg = [msg 'step 10 \n'];save(fullfile(path,'msglogtask.mat'),'msg');end
end
end