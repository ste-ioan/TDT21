% script to extract questionnaire results, correct for their different sign
% direction (positive change will be towards fatigue, across all items) 
% then plot some scatterplots with behaviour/eeg and eventually correlate

% cd('C:\Users\MococoEEG\Downloads')
% results = readtable('results - questionnaires.csv');
results = readtable('~/Downloads/results - questionnaires.csv');

% i will put the tests in a coherent way. all answers are 1 yes 5 no
% positive change = more tired

% item 1 'i feel very active' 
DeltaQuestio(:,1) = abs(results.MFI1_Pre - results.MFI1_Post); 
% item 2 'physically i don't feel like doing much' 
DeltaQuestio(:,2) = results.MFI2_Pre - results.MFI2_Post;
% item 3 'i feel very active'
DeltaQuestio(:,3) = abs(results.MFI3_Pre - results.MFI3_Post);
% item 4 'i feel tired'
DeltaQuestio(:,4) = results.MFI4_Pre - results.MFI4_Post;
% item 5 'i can concentrate generally'
DeltaQuestio(:,5) = abs(results.MFI5_Pre - results.MFI5_Post);
% item 6 'i can do alot physically)
DeltaQuestio(:,6) = abs(results.MFI6_Pre - results.MFI6_Post);
% item 7 'i'd like to avoid doing things'
DeltaQuestio(:,7) = results.MFI7_Pre - results.MFI7_Post;
% item 8 'i can concentrate now'
DeltaQuestio(:,8) = abs(results.MFI8_Pre - results.MFI8_Post);
% item 9 'i feel rested'
DeltaQuestio(:,9) = abs(results.MFI9_Pre - results.MFI9_Post);
% item 10 'i struggle with concentrating on something'
DeltaQuestio(:,10) = results.MFI10_Pre - results.MFI10_Post;
% item 11 'i feel physically bad'
DeltaQuestio(:,11) = results.MFI11_Pre - results.MFI11_Post;
% item 12 'i fatigue easily'
DeltaQuestio(:,12) = results.MFI12_Pre - results.MFI12_Post;
% item 13 'i don't feel like doing anything'
DeltaQuestio(:,13) = abs(results.MFI13_Pre - results.MFI13_Post);
% item 14 'my thoughts cross easily'
DeltaQuestio(:,14) = abs(results.MFI13_Pre - results.MFI13_Post);
% item 15 'i feel perfect physically'
DeltaQuestio(:,15) = results.MFI13_Pre - results.MFI13_Post;

% karolinska scale, higher number = more sleepiness
Karolinska = results.KarolinskaPost - results.KarolinskaPre;


tiredchange = mean(DeltaQuestio,2);
[hgrp,pgrp, ~, statsgrp] = ttest(tiredchange(1:2:48), tiredchange(2:2:48))
[psleepy, hsleepy, statsleepy] = ranksum(Karolinska(1:2:48), Karolinska(2:2:48))

% not sure if it's best to mean (or median?) across items or across subjects??
% it's always significant anyways..

[pkaro,hkaro, statskaro] = signrank(Karolinska) % Karolinska
effsizekaro = statskaro.zval/sqrt(length(Karolinska))

[hmfi,pmfi, ~, statsmfi] = ttest(mean(DeltaQuestio')) % MFI items
cohen = mean(DeltaQuestio')/std(DeltaQuestio');
% let's try to correlate it with behaviour (and eeg?)
% cd('C:\Users\MococoEEG\ownCloud\MATLAB\Scripts\TDT\private\analysis\data_extracted\Tables\Behavior')
% Behaviour = readtable('RAWTABLE.txt');
Behaviour = readtable('~/ownCloud/MATLAB/Scripts/TDT/private/analysis/data_extracted/Tables/Behavior/RAWTABLE.txt');

DeltaSaturationBeg = Behaviour.SATbeg- Behaviour.NONSATbeg;
DeltaSaturationFin = Behaviour.SATfin - Behaviour.NONSATfin;
% in delta of delta is positive, large values indicate a substantial 
% difference in scores across
% saturation condition AND session
DeltaofDelta = DeltaSaturationFin - DeltaSaturationBeg;
% order of deltaing does not change outcome
color = rgb('dark green')
plot(mean(DeltaQuestio'),DeltaofDelta,'Color', color, 'Marker', '.', 'MarkerSize', 30, 'LineStyle', 'none')
[rhomfi, corrpvalmfi] = corr(mean(DeltaQuestio')',DeltaofDelta)

data = table(mean(DeltaQuestio')',DeltaofDelta);
data.Properties.VariableNames = {'MFI', 'Behaviour'};

writetable(data, '~/ownCloud/MATLAB/Scripts/TDT/private/analysis/data_extracted/Tables/Behavior/QuestioCorrel.txt')

