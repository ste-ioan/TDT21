function [allsounds, Qsounds] = sounds_extraction(condition)

rng('shuffle')

%%%%%%%%%%%%%%% loads sounds on first execution %%%%%%%%%%%%%%
d = '~/ownCloud/MATLAB/Scripts/TDT/original/';
f = strfind(d,'/');
soundPath = [d(1:f(end)) 'sounds/'];
privatePath = [d(1:f(end)-9) 'newTDT/private'];
%background choice & playing moved to satutask

%cd to folders with sounds
cd (soundPath)
categories = cell(1,3);
categories{1} = 1;
categories{2} = 2;
categories{3} = 3;

%load 1st category of sounds
cd ([soundPath , num2str(categories{1})])
files = dir('*.wav');
C1nsounds = length(files);
cat1sounds=struct('Y',[], 'Fs', [], 'name', []);

for i=1:C1nsounds
    [cat1sounds(i).Y, cat1sounds(i).Fs] = audioread(files(i).name);
    if cat1sounds(i).Fs ~= 44100
        cat1sounds(i).Y = resample(cat1sounds(i).Y,44100,cat1sounds(i).Fs);
    end
    cat1sounds(i).Y = single(cat1sounds(i).Y);
    cat1sounds(i).name = files(i).name;
    cat1sounds(i).target = 1;
    cat1sounds(i).cue = 0;
    cat1sounds(i).category = categories{1};
%     if length(cat1sounds(i).Y) > 90734
%         cat1sounds(i).Y = cat1sounds(i).Y(1:90734,:); %tried doing this to reduce and impose size
%     end
end
% for i=1:C1nsounds
% cat1sounds(i).Y(:,2) =  cat1sounds(i).Y;
% end

% load distractor 'Computer' sounds
cd ([soundPath , num2str(categories{3})])
files = dir('*.wav');
Dnsounds = length(files);
distractorsounds=struct('Y',[], 'Fs', [], 'name', []);

for i=1:Dnsounds
    [distractorsounds(i).Y, distractorsounds(i).Fs] = audioread(files(i).name);
    if distractorsounds(i).Fs ~= 44100
        distractorsounds(i).Y = resample(distractorsounds(i).Y,44100,distractorsounds(i).Fs);
    end
    distractorsounds(i).Y = single(distractorsounds(i).Y);
    distractorsounds(i).name = files(i).name;
    distractorsounds(i).target = 0;
    distractorsounds(i).cue = 0;
    distractorsounds(i).category = categories{3};
%     if length(distractorsounds(i).Y) > 90734
%         distractorsounds(i).Y = distractorsounds(i).Y(1:90734,:); %tried doing this to reduce and impose size
%     end
end

%load the 2nd category sounds
cd ([soundPath , num2str(categories{2})])
files = dir('*.wav');
C2nsounds = length(files);
cat2sounds=struct('Y',[], 'Fs', [], 'name', []);

for i=1:C2nsounds
    [cat2sounds(i).Y, cat2sounds(i).Fs] = audioread(files(i).name);
    if cat2sounds(i).Fs ~= 44100
        cat2sounds(i).Y = resample(cat2sounds(i).Y,44100,cat2sounds(i).Fs);
    end
    cat2sounds(i).Y = single(cat2sounds(i).Y);
    cat2sounds(i).name = files(i).name;
    cat2sounds(i).target = 1;
    cat2sounds(i).cue = 0;
    cat2sounds(i).category = categories{2};
%     if length(cat2sounds(i).Y) > 90734
%         cat2sounds(i).Y = cat2sounds(i).Y(1:90734,:); %tried doing this to reduce and impose size
%     end
end

%load the cue sounds
if condition == 2
    cd ([soundPath , 'cue'])
    files = dir('*.wav');
    Qnsounds = length(files);
    Qsounds=struct('Y',[], 'Fs', [], 'name', []);
    
    for i=1:Qnsounds
        [Qsounds(i).Y, Qsounds(i).Fs] = audioread(files(i).name);
        if Qsounds(i).Fs ~= 44100
            Qsounds(i).Y = single(resample(Qsounds(i).Y,44100,Qsounds(i).Fs));
        end
        Qsounds(i).Y = single(Qsounds(i).Y);
        Qsounds(i).name = files(i).name;
        Qsounds(i).cue = 1;
        if strcmp(Qsounds(i).name(1:end-4), 'animaux')
        Qsounds(i).category = 1;
        else
        Qsounds(i).category = 2;    
        end
        Qsounds(i).side = 'x';
        Qsounds(i).target = 0;
    end
    Qsounds = [Qsounds, Qsounds, Qsounds, Qsounds, Qsounds, Qsounds, Qsounds];
    if ceil(rand*2) == 1
        Qsounds = flip(Qsounds);
    end
end
%make first matrix of sounds which will be shuffled
if condition == 1
    if ceil(rand*2)==1
        sounds = [Shuffle(cat1sounds) , Shuffle(cat1sounds)];
    else
        sounds = [Shuffle(cat2sounds), Shuffle(cat2sounds)];
    end
elseif condition == 2
    sounds = [Shuffle(cat1sounds), Shuffle(distractorsounds), Shuffle(cat2sounds)];
end


%make left and right sound vectors side 1 = left, side 9 = right
right_sounds = Shuffle(sounds);
for i=1:length(sounds)
    right_sounds(i).Y(:,1) = 0;
    right_sounds(i).side = 9;
end

left_sounds = Shuffle(sounds);
for i = 1:length(sounds)
    left_sounds(i).Y(:,2) = 0;
    left_sounds(i).side = 1;
end

%glue them together again and shuffle whole thing
allsounds = [right_sounds, left_sounds];
allsounds = Shuffle(allsounds);

%let's add coherency field and response
if condition == 1
    for l = 1:length(allsounds)
        if allsounds(l).target == 1 && allsounds(l).side == 1
            allsounds(l).response = 42;
        elseif allsounds(l).target == 1 && allsounds(l).side == 9
            allsounds(l).response = 45;
        elseif allsounds(l).target == 0
            allsounds(l).response = 0;
        end
        allsounds(l).coherent = 1;
    end
end
%remove sample rate field, useless (changed thru resampling)
allsounds = rmfield(allsounds, 'Fs');
if condition == 2
    Qsounds = rmfield(Qsounds, 'Fs');
    cd(privatePath)        
    allsounds = qinsert(allsounds, Qsounds);
    cd(privatePath(1:end-8))        
end
end