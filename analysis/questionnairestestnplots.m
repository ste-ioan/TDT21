% script to extract questionnaire results, correct for their different sign
% direction (positive change will be towards fatigue, across all items) 
% then plot some scatterplots with behaviour/eeg and eventually correlate

% cd('C:\Users\MococoEEG\Downloads')
% results = readtable('results - questionnaires.csv');
results = readtable('~/Downloads/results - questionnaires.csv');

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
    tmp_post(:,k) = eval(['results.MFI',num2str(negative_items(k)),'_Post']);
end

for jj = 1:length(tmp_pre)

for ll = 1:numel(negative_items)
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

for ll = 1:numel(negative_items)
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

MFI_pre = [results.MFI1_Pre,tmp_pre(:,1),results.MFI3_Pre,tmp_pre(:,2),...
    results.MFI5_Pre, results.MFI6_Pre, tmp_pre(:,3), results.MFI8_Pre,...
    results.MFI9_Pre, tmp_pre(:,4), tmp_pre(:,5), tmp_pre(:,6),tmp_pre(:,7),...
    tmp_pre(:,8), results.MFI15_Pre];

MFI_post = [results.MFI1_Post,tmp_post(:,1),results.MFI3_Post,tmp_post(:,2),...
    results.MFI5_Post, results.MFI6_Post, tmp_post(:,3), results.MFI8_Post,...
    results.MFI9_Post, tmp_post(:,4), tmp_post(:,5), tmp_post(:,6),tmp_post(:,7),...
    tmp_post(:,8), results.MFI15_Post];

T_MFI = array2table([mean(MFI_pre,2), mean(MFI_post,2)]);
T_MFI (:,end+1) = cell2table(repmat({'easy','hard'}', 24,1));

T_MFI.Properties.VariableNames = {'Pre', 'Post', 'group'};

cd('~/Documents/jamovi analyses/TDT/Questionnaires/')
writetable(T_MFI)

% let's try to correlate it with behaviour
Behaviour = readtable('~/ownCloud/MATLAB/Scripts/TDT/original/private/analysis/data_extracted/Tables/Behavior/RAWTABLE.txt');

DeltaSaturationBeg = Behaviour.SATbeg- Behaviour.NONSATbeg;
DeltaSaturationFin = Behaviour.SATfin - Behaviour.NONSATfin;
DeltaBehavior = DeltaSaturationFin - DeltaSaturationBeg;

deltaMFI = mean(MFI_post-MFI_pre,2);
color = rgb('dark green');
plot(DeltaBehavior,deltaMFI,'Color', color, 'Marker', '.', 'MarkerSize', 30, 'LineStyle', 'none')
[rhomfi, corrpvalmfi] = corr(deltaMFI,DeltaBehavior);

mycorr = @(deltaMFI,DeltaofDeltaBehav) corr(deltaMFI,DeltaofDeltaBehav);
nIterations = 10000;
corr_ci = bootci(nIterations,{mycorr,deltaMFI,DeltaBehavior});

% for the figure and data sharingg
% data = table(deltaMFI,DeltaBehavior);
% data.Properties.VariableNames = {'MFI', 'Behaviour'};
% writetable(data, '~/ownCloud/MATLAB/Scripts/TDT/original/private/analysis/data_extracted/Tables/Behavior/QuestioCorrel.txt')

% do corr on sleepiness scores
[rhoKaro, corrpvalKaro] = corr(deltaKarolinska,DeltaBehavior, 'type', 'Spearman');
