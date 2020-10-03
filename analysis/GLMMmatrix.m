% script to make a big matrix for GLMM
clear
clc
cd('~/Desktop/tdt_data_backup/')
data_carpets = dir();
data_carpets = data_carpets(4:end-1);
container = [];

for jj = 1:length(data_carpets)
cd([cd,'/',data_carpets(jj).name])
difficulty_folder = dir;
cd(difficulty_folder(end).name)
csv_files = dir('*.csv');
for kk = 2:4
% load da data
actual_data = readtable(csv_files(kk).name, 'Delimiter', 'comma',  'ReadVariableNames', 0);

if size(actual_data,2)<=22
% remove weight rows
actual_data(end,:) = [];
actual_data(243,:) = [];
actual_data(162,:) = [];
actual_data(81,:) = [];
end

if height(actual_data) == 321
actual_data = readtable(csv_files(kk).name, 'Delimiter', 'comma',  'ReadVariableNames', 0, 'HeaderLines', 1);
actual_data(:,23:end) = [];
end

if height(actual_data) ~= 320
    disp(['Something went wrong in ', csv_files(kk).name])
    pause
end

if any(jj == 1:2:48)
    difficulty = 'easy';
else
    difficulty = 'hard';
end

actual_data.Var23 = cellstr(repmat(difficulty, 320, 1));
if jj == 11 % since it is 49 messes up things a bit
    actual_data.Var1(:) = 11;
end

% subject 22 responded with inverted keys apparently, so we do an old
% flipparoo

if jj == 22
actual_data.Var14(strcmp(actual_data.Var11, 'target')) = abs(actual_data.Var14(strcmp(actual_data.Var11, 'target'))-1);
end

container = [container;actual_data];
end
cd ..
cd ..
end

bigTable = [container(:,1),container(:,4),container(:,6),container(:,9),container(:,10),container(:,11), container(:,14)...
    ,container(:,13), container(:,23), container(:,7)];

bigTable.Properties.VariableNames =  {'Sujet','Session', 'SatYN', 'target', 'SOA','RespYN', 'CorrectResp','RespVertHor', 'Difficulty', 'block'};

% index no resps, horizontal responses, and horizontal target
% noRespIndex = find(strcmp('no_res', bigTable.RespYN));
% horizontalResp = find(bigTable.RespVertHor == 2);
% horizontalIndex = find(bigTable.target == 2);
% 
% % index zeros that came with horizontal target, cannot be changed to
% % negative so gotta transform them slightly
% Horizontalzeros = find(bigTable.SOA == 0 & bigTable.target == 2);

% here i'm excluding the missed responses, dunno if it's ideal
% bigTable.CorrectResp(noRespIndex) = NaN;
% bigTable.RespVertHor(noRespIndex) = NaN;


% bigTable.RespVertHor(horizontalResp) = 0;
% bigTable.SOA(Horizontalzeros) = 0.01;

% make them negative for soa
% bigTable.SOA(horizontalIndex) = - bigTable.SOA(horizontalIndex);

% 
% cd('~/ownCloud/MATLAB/Scripts/TDT/private/analysis/data_extracted/Tables/Behavior/')
% writetable(bigTable)


shorted = varfun(@sum,bigTable(bigTable.SOA<.06,:),'InputVariables','CorrectResp',...
       'GroupingVariables',{'SatYN', 'Difficulty', 'SOA', 'Session'})