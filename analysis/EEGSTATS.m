% final TDT EEG data stats script (of course not)
% stempio may 2020
clear
%% load preprocessed frequency files
cd('D:\satuTDT_EEG_files\results\WithBaseline\')

freqs = {'gamma', 'stimfreq'};
idx = listdlg('ListString', freqs);

range = freqs{idx};
load(range)

switch range
    case 'stimfreq'
        DataSaturated = DataSaturated_7dot5;
        Data_NotSaturated = Data_NotSaturated_7dot5;
        stimfreq = 1;
    case 'gamma'
        DataSaturated = DataSaturatedGamma;
        Data_NotSaturated = Data_NotSaturatedGamma;
end

clearvars -except range DataSaturated Data_NotSaturated stimfreq
%% set stats constants
cfgstats.parameter = 'powspctrm';
cfgstats.method = 'montecarlo';
cfgstats.correctm         = 'cluster';
cfgstats.clusteralpha     = 0.05;
cfgstats.clusterstatistic = 'maxsum';
cfgstats.tail             = 0;
cfgstats.clustertail      = 0;
cfgstats.alpha            = 0.05;
cfgstats.correcttail = 'prob';
cfgstats.numrandomization = 1000;
cfgstats.statistic        = 'ft_statfun_depsamplesT';
design(1,:) = [ones(1,24), repmat(2, 1, 24)];
design(2,:) = [1:24, 1:24];
cfgstats.design = design;
cfgstats.ivar = 1;
cfgstats.uvar = 2;

cfg_neighb = [];
cfg_neighb.method    = 'distance';
cfg_neighb.layout = 'biosemi32.lay';
cfg_neighb.neighbourdist = .16;
cfgstats.neighbours       = ft_prepare_neighbours(cfg_neighb,DataSaturated{1});

if exist('stimfreq', 'var')
    cfgstats.frequency = [7.495 7.505];
else
    cfgstats.avgoverfreq = 'yes';
end

%% topoplot constants
cfgtopoplot = [];
cfgtopoplot.alpha  = .05;
cfgtopoplot.parameter = 'stat';
cfgtopoplot.layout = 'biosemi32.lay';

%% log transform the data
if ~exist('stimfreq','var')
cfglog = [];
cfglog.operation = 'log10';
cfglog.parameter = 'powspctrm';

for run = 1:3
    for bibbo = 1:48
        loggedData_Sat{bibbo,run} = ft_math(cfglog, DataSaturated{bibbo,run});
        loggedData_NonSat{bibbo,run} = ft_math(cfglog, Data_NotSaturated{bibbo,run});
    end
end
else
    loggedData_Sat = DataSaturated;
    loggedData_NonSat = Data_NotSaturated;
end
clear cfglog DataSaturated Data_NotSaturated
%% calculate the delta saturation
cfgdelta = [];
cfgdelta.operation = 'subtract';
cfgdelta.parameter = 'powspctrm';

for sesh = 1:3
for bibbo = 1:48
    DeltaSaturation{bibbo,sesh} = ft_math(cfgdelta, loggedData_Sat{bibbo,sesh}, loggedData_NonSat{bibbo,sesh});
end
end

clear loggedData_Sat loggedData_NonSat bibbo sesh
%% stats
[statsdep12hard] = ft_freqstatistics(cfgstats, DeltaSaturation{2:2:48,1}, DeltaSaturation{2:2:48,2});

[statsdep12easy] = ft_freqstatistics(cfgstats, DeltaSaturation{1:2:48,1}, DeltaSaturation{1:2:48,2});

[statsdep23easy] = ft_freqstatistics(cfgstats, DeltaSaturation{1:2:48,2}, DeltaSaturation{1:2:48,3});

[statsdep13hard] = ft_freqstatistics(cfgstats, DeltaSaturation{2:2:48,1}, DeltaSaturation{2:2:48,3});

% try
%     ft_clusterplot(cfgtopoplot, statsdep12hard);
% catch
%     disp(['no hard 1 vs 2 results ', range])
% end

try
    subplot(1,2,1)
    ft_clusterplot(cfgtopoplot, statsdep12easy);
catch
    disp(['no easy 1 vs 2 results ', range])
end

% try
%     ft_clusterplot(cfgtopoplot, statsdep23easy);
% catch
%     disp(['no easy 2 vs 3 results ', range])
% end

try
    subplot(1,2,2)
    ft_clusterplot(cfgtopoplot, statsdep13hard);
catch
    disp(['no hard 1 vs 3 results ', range])
end

%% to calculate effect size, we take average of signal in the significant clusters in the 
% two conditions, then do the difference of these and divide by pooled std
% (cohen's D)
easy = 1:2:48;
for i = 1:24
x1_ez(i) = mean(mean(DeltaSaturation{easy(i),1}.powspctrm(statsdep12easy.mask,:),2));
x2_ez(i) = mean(mean(DeltaSaturation{easy(i),2}.powspctrm(statsdep12easy.mask,:),2));
end
ez_cohensd = mean(x1_ez - x2_ez) ./ std(x1_ez-x2_ez);

hard = 2:2:48;
for i = 1:24
x1_hrd(i) = mean(mean(DeltaSaturation{hard(i),1}.powspctrm(statsdep13hard.mask,:),2));
x2_hrd(i) = mean(mean(DeltaSaturation{hard(i),3}.powspctrm(statsdep13hard.mask,:),2));
end
hrd_cohensd = mean(x1_hrd - x2_hrd) ./ std(x1_hrd-x2_hrd);