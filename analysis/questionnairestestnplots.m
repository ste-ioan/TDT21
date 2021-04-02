% script to extract questionnaire results, correct for their different sign
% direction (positive change will be towards fatigue, across all items) 
% then plot some scatterplots with behaviour/eeg and eventually correlate

% cd('C:\Users\MococoEEG\Downloads')
% results = readtable('results - questionnaires.csv');
results = readtable('~/Downloads/results - questionnaires.csv');

% i will put the tests in a coherent way. all answers are 1 yes 5 no
% take abs so that positive change = more tired

% item 1 'i feel very in shape' 
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
DeltaQuestio(:,13) = results.MFI13_Pre - results.MFI13_Post; 
% item 14 'my thoughts cross easily'
DeltaQuestio(:,14) = results.MFI14_Pre - results.MFI14_Post;
% item 15 'i feel perfect physically'
DeltaQuestio(:,15) = abs(results.MFI15_Pre - results.MFI15_Post);

% karolinska scale, higher number = more sleepiness
Karopre = results.KarolinskaPre;
Karopost= results.KarolinskaPost;

T_karo = array2table([Karopre, Karopost]);
T_karo(:,end+1) = cell2table(repmat({'easy','hard'}', 24,1));
T_karo.Properties.VariableNames = {'Pre', 'Post', 'group'};

cd('~/Documents/jamovi analyses/TDT/Questionnaires/')
writetable(T_karo)

% harmonize MFI items
negative_items = [2, 4, 7, 10, 11, 12, 13, 14];

for k = 1:numel(negative_items)    
   tmp_pre(:,k) = eval(['results.MFI',num2str(negative_items(k)),'_Pre']);
    tmp_post(:,k) = eval(['results.MFI',num2str(negative_items(k)),'_Pre']);
end

for jj = 1:length(tmp_pre)

for ll = 1:(negative_items)
    switch tmp_pre(jj, ll)       
        case 5
          tmp_pre(jj, ll) = 1;
        case 4
          tmp_pre(jj, ll) = 2;
        case 2
          tmp_pre(jj, ll) = 4;
        case 1
          tmp_pre(jj, ll) = 5;
    end
end
end

for jj = 1:length(tmp_post)

for ll = 1:(negative_items)
    switch tmp_post(jj, ll)       
        case 5
          tmp_post(jj, ll) = 1;
        case 4
          tmp_post(jj, ll) = 2;
        case 2
          tmp_post(jj, ll) = 4;
        case 1
          tmp_post(jj, ll) = 5;
    end
end
end

MFI_pre = [results.MFI1_Pre,results.MFI3_Pre,results.MFI5_Pre,results.MFI6_Pre,...
    results.MFI8_Pre,results.MFI9_Pre,results.MFI15_Pre, tmp_pre];

MFI_post = [results.MFI1_Post,results.MFI3_Post,results.MFI5_Post,results.MFI6_Post,...
    results.MFI8_Post,results.MFI9_Post,results.MFI15_Post, tmp_post];

T_MFI = array2table([mean(MFI_pre,2), mean(MFI_post,2)]);
T_MFI (:,end+1) = cell2table(repmat({'easy','hard'}', 24,1));

T_MFI.Properties.VariableNames = {'Pre', 'Post', 'group'};

cd('~/Documents/jamovi analyses/TDT/Questionnaires/')
writetable(T_MFI)

% let's try to correlate it with behaviour
Behaviour = readtable('~/ownCloud/MATLAB/Scripts/TDT/original/private/analysis/data_extracted/Tables/Behavior/RAWTABLE.txt');

DeltaSaturationBeg = Behaviour.SATbeg- Behaviour.NONSATbeg;
DeltaSaturationFin = Behaviour.SATfin - Behaviour.NONSATfin;
DeltaofDeltaBehav = DeltaSaturationFin - DeltaSaturationBeg;


deltaMFI = mean(DeltaQuestio,2);
color = rgb('dark green');
plot(DeltaofDeltaBehav,deltaMFI,'Color', color, 'Marker', '.', 'MarkerSize', 30, 'LineStyle', 'none')
[rhomfi, corrpvalmfi] = corr(deltaMFI,DeltaofDeltaBehav);

mycorr = @(deltaMFI,DeltaofDeltaBehav) corr(deltaMFI,DeltaofDeltaBehav);
nIterations = 10000;
corr_ci = bootci(nIterations,{mycorr,deltaMFI,DeltaofDeltaBehav});

% for the figure and data sharingg
% data = table(mean(DeltaQuestio,2),DeltaofDelta);
% data.Properties.VariableNames = {'MFI', 'Behaviour'};
% writetable(data, '~/ownCloud/MATLAB/Scripts/TDT/original/private/analysis/data_extracted/Tables/Behavior/QuestioCorrel.txt')

% do corr on sleepiness scores
[rhoKaro, corrpvalKaro] = corr(deltaKarolinska,DeltaofDeltaBehav, 'type', 'Spearman');
