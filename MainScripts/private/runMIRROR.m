function stopTrial = runMIRROR(tt0,firstFrame,condition)
persistent sequence correlSeq

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
    condition = 3;%('d�tec (1), discrim. sans transpo (2), ou discrim avec transpo (3) ?  ');
end

%general constants
keys = KbName({'1','2'});
Fs = 44100;
ref_basse = 700; % fr�quence de r�f�rence (i.e., centrale) basse
ref_haute = 1665; % fr�quence de r�f�rence (i.e., centrale) haute, 15 demi-tons au-dessus de ref_basse
% (les fr�quences 700 et 1665 Hz �taient aussi utilis�es dans melos4, 5, etc)
ref_medium = (ref_basse * ref_haute)^0.5;
semitones = 2;%('pas fr�quentiel, en demi-tons :  ');
if condition < 3
    transpo = 0; % �cart des deux fr�quences de r�f�rence, en demi-tons
    F_ref = ref_medium;
    beepDuration = 0.080; % dur�e totale d'un pip en secondes
else
    transpo = 12 * log2(ref_haute/ref_basse);
    F_ref = ref_basse;
    beepDuration = 0.040; % dur�e totale d'un pip en secondes
end

repet = 20; % c'est la moiti� du nb total de pips dans chacun des 2 intervalles du choix forc�
responseTimeOut = 10;

%%%%%%%%%%%%%%%% makes sequences %%%%%%%%%%%%
if firstFrame
    alea = rand;
    correlSeq = 1+(alea > 0.5);
    if correlSeq==1 % correl=1 dans l'intervalle 1
        correl = 1;
        sequence(:,:,1) = makeSequence(condition, repet, F_ref, semitones, transpo, correl);
        correl = 0;
        sequence(:,:,2) = makeSequence(condition, repet, F_ref, semitones, transpo, correl);
    elseif correlSeq==2 % correl=1 dans l'intervalle 2
        correl = 0;
        sequence(:,:,1) = makeSequence(condition, repet, F_ref, semitones, transpo, correl);
        correl = 1;
        sequence(:,:,2) = makeSequence(condition, repet, F_ref, semitones, transpo, correl);
    end
end

%%%%%% timings %%%%%%%%%%
amorce = 0.7;
silence_intersequences = 1.2;
timings = cumsum([amorce ones(1,size(sequence,2))*beepDuration*1.5 silence_intersequences ones(1,size(sequence,2))*beepDuration*1.5]);

%%%%%%%%%%%%%% PHASES OF THE TASK %%%%%%%%%%%%%%%%%%
if s-tt0 <= timings(1)
    if ~isfield(output,'display') || length(output.display)<1
        output.display(1).onset = s;
        output.display(1).name = 'FIX';
    end
    DrawFormattedText(wPtr, '+', 'center', 'center', [255 255 255]);
elseif s-tt0 <= timings(end)
    currentStim = find(timings<(s-tt0),1,'last');
    beepIndex = currentStim;
    if beepIndex>size(sequence,2)
        beepIndex=beepIndex-(size(sequence,2)+1);
        seqIndex=2;
    else
        seqIndex=1;
    end
    if length(output.display)<(currentStim+1) %onset of new letter, plus one is because of first onset being just fixation
        output.display(currentStim+1).onset = s;
        if beepIndex>0
            stereoTone = sequence(:,beepIndex,seqIndex);
            if ~isnan(stereoTone(1))
                [beepL] = TDTbeep(Fs, beepDuration, stereoTone(1));
            else
                beepL=[];
            end
            if ~isnan(stereoTone(2))
                [beepR] = TDTbeep(Fs, beepDuration, stereoTone(2));
            else
                beepR=[];
            end
            L=max([length(beepL) length(beepR)]);
            if isempty(beepL),beepL = zeros(1,L);end
            if isempty(beepR),beepR = zeros(1,L);end
            beepVector = [beepL;beepR];
            PsychPortAudio('FillBuffer',soundBuffer, ...
                beepVector);
            PsychPortAudio('Start', soundBuffer);
            output.display(currentStim+1).name = ['SEQ' num2str(seqIndex) 'BEEP' num2str(beepIndex)];
        else
            output.display(currentStim+1).name = ['INTERSEQ'];
        end
        
    end
    DrawFormattedText(wPtr, '+', 'center', 'center', [255 255 255]);
    
elseif (s-tt0 <= (timings(end)+responseTimeOut)) && (~isfield(output,'response') || ~isfield(output.response,'time') || (length([output.response.time])<1))
    ix = length(timings)+1;
    if length(output.display)<ix
        output.display(ix).onset = s;
        output.display(ix).name = 'RESP';
        output.response.sequence = sequence;
        output.response.correlatedSequence = correlSeq;
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
        output.response.correct = resp(1)==correlSeq;
    end
    DrawFormattedText(wPtr, '+', 'center', 'center', [255 255 255]);
else
    %%%%%%%%%%%% DO NOT CHANGE THIS %%%%%%%%%%%%%
    stopTrial = true;
    assignin('caller','output',output)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
end

function sequence = makeSequence(condition, repet, F_ref, semitones, transpo, correl)
pipnul = NaN;
melodiegauche = [ ];
melodiedroite = [ ];
for i = 1:repet
    if condition==1
        F = F_ref;
    else
        alea = floor(3*rand); % 0, 1, ou 2
        if alea==0
            F = F_ref * 2^(-semitones/12);
        elseif alea==1
            F = F_ref;
        else
            F = F_ref * 2^(semitones/12);
        end
    end
    
    if condition < 3
        melodiegauche = [melodiegauche F];
        melodiedroite = [melodiedroite F];
    else
        melodiegauche = [melodiegauche F];
        melodiedroite = [melodiedroite pipnul];       
    end
    if correl==1 
        F = F * 2^(transpo/12);
    else % correl==0
        alea = floor(3*rand); 
        if alea==0
            F = F_ref * 2^((transpo-semitones)/12);
        elseif alea==1
            F = F_ref * 2^(transpo/12);
        elseif alea==2
            F = F_ref * 2^((transpo+semitones)/12);
        end 
    end
    if condition < 3
        melodiegauche = [melodiegauche F];
        melodiedroite = [melodiedroite F];
    else
        melodiegauche = [melodiegauche pipnul];
        melodiedroite = [melodiedroite F];       
    end
end
sequence = [melodiegauche ; melodiedroite];
end