%% check for more than 25 no_resp in TDT results

cd('~/ownCloud/MATLAB/Data/TDT')
data_carpets = dir();
data_carpets = data_carpets(4:end-4);

threshold = 25;

for jj = 1:length(data_carpets)
cd([cd,'/',data_carpets(jj).name])
difficulty_folder = dir;
cd(difficulty_folder(end).name)
csv_files = dir('*.csv');

for kk = 2:4
actual_data = readtable(csv_files(kk).name, 'Delimiter', 'comma',  'ReadVariableNames', 0);
if sum(strcmp(actual_data.Var11(1:80),'no_res'))>=threshold
    disp(['Block 1 of ', csv_files(kk).name(1:5), ' subject ', num2str(jj), ' must be rejected because of ', ...
        num2str(sum(strcmp(actual_data.Var11(1:80),'no_res'))), ' failed trials'])    
end
if sum(strcmp(actual_data.Var11(82:161),'no_res'))>=threshold
   disp(['Block 2 of ', csv_files(kk).name(1:5), ' subject ', num2str(jj), ' must be rejected because of ', ...
        num2str(sum(strcmp(actual_data.Var11(82:161),'no_res'))), ' failed trials'])    
end
if sum(strcmp(actual_data.Var11(163:242),'no_res'))>=threshold
   disp(['Block 3 of ', csv_files(kk).name(1:5), ' subject ', num2str(jj), ' must be rejected because of ', ...
        num2str(sum(strcmp(actual_data.Var11(163:242),'no_res'))), ' failed trials'])    
end
if sum(strcmp(actual_data.Var11(244:end),'no_res'))>=threshold
   disp(['Block 4 of ', csv_files(kk).name(1:5), ' subject ', num2str(jj), ' must be rejected because of ', ...
        num2str(sum(strcmp(actual_data.Var11(244:end),'no_res'))), ' failed trials'])    
end

end
cd ..
cd ..

end
