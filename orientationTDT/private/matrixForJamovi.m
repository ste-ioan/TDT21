function [a,b,c,d] = matrixForJamovi(newfileflag)
if nargin < 1
    newfileflag = false;
end

cd('~/ownCloud/MATLAB/Data/TDT/newTDT/')
data_carpets = dir();
data_carpets = data_carpets(4:end);
data_carpets((strcmp('test',{data_carpets.name})))= [];
container = [];

for jj = 1:length(data_carpets)
cd([cd,'/',data_carpets(jj).name])
csv_files = dir('*.csv');

for kk = 1:length(csv_files)
    bigT = find(csv_files(kk).name == 'T');
    typefile = csv_files(kk).name(1:bigT-1);
if strcmp('test', typefile)    
actual_data = readtable(csv_files(kk).name, 'Delimiter', 'comma');
if width(actual_data) == 23
actual_data.Properties.VariableNames = {'subnumber', 'distance',...
    'height',	'session',	'quadrant',	'satQuadrantYN',	'block',...
    'trial',	'targetalignment',	'targetorientation',	'SOA',...
    'Resp',	'firstKEY',	'RESPtar',	'ACCtar',	'RTtar',...
    'SOATime',	'PreBlankTime',	'FixTime',	'StimTime',	'MaskTime',	'ClockTime', 'nothing'};
actual_data.nothing = [];
elseif width(actual_data) == 22
    actual_data.Properties.VariableNames = {'subnumber', 'distance',...
    'height',	'session',	'quadrant',	'satQuadrantYN',	'block',...
    'trial',	'targetalignment',	'targetorientation',	'SOA',...
    'Resp',	'firstKEY',	'RESPtar',	'ACCtar',	'RTtar',...
    'SOATime',	'PreBlankTime',	'FixTime',	'StimTime',	'MaskTime',	'ClockTime'};
end


container = [container;actual_data];
end
end
cd ..
end

if logical(newfileflag)
container = sortrows(container,1);
cd('/Users/mococomac/Documents/jamovi analyses/TDT/newTDT')
writetable(container)
end

tableVariablenames = {'sat', 'not_sat', 'SOA', 'subgroup'};
group = [ones(12,1); repmat(2,12,1)];
completed_participants = max(unique(container.subnumber));

% estimate the % change between sessions, for quadrant, orientation, saturation ..
a = nan(completed_participants,2);
for subj = 1:completed_participants
a(subj,1) = sum(container.ACCtar(container.subnumber == subj & container.session == 1 & container.satQuadrantYN == 1))/320 * 100;
a(subj,2) = sum(container.ACCtar(container.subnumber == subj & container.session == 1 & container.satQuadrantYN == 0))/320 * 100;
a(subj,3) = mean(container.SOA(container.subnumber == subj));
end
a(:,end+1) = group;
a = array2table(a, 'VariableNames', tableVariablenames);

b = nan(completed_participants, 2);
for subj = 1:completed_participants
    b(subj,1) = (sum(container.ACCtar(container.subnumber == subj & container.session == 2 & container.satQuadrantYN == 1))/320 * 100) ...
        - (sum(container.ACCtar(container.subnumber == subj & container.session == 1 & container.satQuadrantYN == 1))/320 * 100);
    
    b(subj,2) = (sum(container.ACCtar(container.subnumber == subj & container.session == 2 & container.satQuadrantYN == 0))/320 * 100) ...
        - (sum(container.ACCtar(container.subnumber == subj & container.session == 1 & container.satQuadrantYN == 0))/320 * 100);
end
b(:,end+1) = group;
tableVariablenames = {'sat_quad', 'not_sat_quad', 'subgroup'};
b = array2table(b, 'VariableNames', tableVariablenames);

c = nan(completed_participants,2);
for subj = 1:completed_participants
    c(subj,1) = (sum(container.ACCtar(container.subnumber == subj & container.session == 2 & container.satQuadrantYN == 0 & container.targetorientation == 45))/160 * 100) ...
        - (sum(container.ACCtar(container.subnumber == subj & container.session == 1 & container.satQuadrantYN == 0 & container.targetorientation == 45))/160 * 100);
    
    c(subj,2) = (sum(container.ACCtar(container.subnumber == subj & container.session == 2 & container.satQuadrantYN == 0 & container.targetorientation == 135))/160 * 100) ...
        - (sum(container.ACCtar(container.subnumber == subj & container.session == 1 & container.satQuadrantYN == 0 & container.targetorientation == 135))/160 * 100);
end  
c(:,end+1) = group;
tableVariablenames = {'sat_orientation', 'not_sat_orientation', 'subgroup'};
c = array2table(c, 'VariableNames', tableVariablenames);

d = nan(completed_participants,2);
for subj = 1:completed_participants
    d(subj,1) = (sum(container.ACCtar(container.subnumber == subj & container.session == 2 & container.satQuadrantYN == 1 & container.targetorientation == 45))/160 * 100) ...
        - (sum(container.ACCtar(container.subnumber == subj & container.session == 1 & container.satQuadrantYN == 1 & container.targetorientation == 45))/160 * 100);
    
    d(subj,2) = (sum(container.ACCtar(container.subnumber == subj & container.session == 2 & container.satQuadrantYN == 1 & container.targetorientation == 135))/160 * 100) ...
        - (sum(container.ACCtar(container.subnumber == subj & container.session == 1 & container.satQuadrantYN == 1 & container.targetorientation == 135))/160 * 100);
end

d(:,end+1) = group;
tableVariablenames = {'sat_orientation', 'not_sat_orientation', 'subgroup'};
d = array2table(d, 'VariableNames', tableVariablenames);

cd('/Users/mococomac/ownCloud/MATLAB/Scripts/TDT/newTDT/private')
