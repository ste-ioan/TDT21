% final TDT EEG data stats script (of course not)
% stempio may 2020
clear
%% load preprocessed frequency files
cd('D:\satuTDT_EEG_files\results\WithBaseline\')

        DataSaturated = DataSaturated_7dot5;
        Data_NotSaturated = Data_NotSaturated_7dot5;
        stimfreq = 1;

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
cfgstats.frequency = [7.495 7.505];


%% topoplot constants
cfgtopoplot = [];
cfgtopoplot.alpha  = .05;
cfgtopoplot.parameter = 'stat';
cfgtopoplot.layout = 'biosemi32.lay';

%% calculate the delta saturation
cfgdelta = [];
cfgdelta.operation = 'subtract';
cfgdelta.parameter = 'powspctrm';

for sesh = 1:3
for bibbo = 1:48
    DeltaSaturation{bibbo,sesh} = ft_math(cfgdelta, DataSaturated{bibbo,sesh}, Data_NotSaturated{bibbo,sesh});
end
end

clear DataSaturated Data_NotSaturated bibbo sesh
%% stats
easy = 1:2:48;
hard = 2:2:48;

[statsdep12easy] = ft_freqstatistics(cfgstats, DeltaSaturation{easy,1}, DeltaSaturation{easy,2});
[statsdep12hard] = ft_freqstatistics(cfgstats, DeltaSaturation{hard,1}, DeltaSaturation{hard,2});

[statsdep23easy] = ft_freqstatistics(cfgstats, DeltaSaturation{easy,2}, DeltaSaturation{easy,3});
[statsdep23hard] = ft_freqstatistics(cfgstats, DeltaSaturation{hard,2}, DeltaSaturation{hard,3});

[statsdep13easy] = ft_freqstatistics(cfgstats, DeltaSaturation{easy,1}, DeltaSaturation{easy,3});
[statsdep13hard] = ft_freqstatistics(cfgstats, DeltaSaturation{hard,1}, DeltaSaturation{hard,3});

try
    subplot(1,2,1)
    ft_clusterplot(cfgtopoplot, statsdep12easy);
catch
    disp('no easy 1 vs 2 results ')
end

try
    ft_clusterplot(cfgtopoplot, statsdep12hard);
catch
    disp('no hard 1 vs 2 results ')
end

try
    ft_clusterplot(cfgtopoplot, statsdep23easy);
catch
    disp('no easy 2 vs 3 results ')
end

try
    ft_clusterplot(cfgtopoplot, statsdep23hard);
catch
    disp('no hard 2 vs 3 results ')
end

try
    subplot(1,2,2)
    ft_clusterplot(cfgtopoplot, statsdep13easy);
catch
    disp('no easy 1 vs 3 results ')
end

try
    subplot(1,2,2)
    ft_clusterplot(cfgtopoplot, statsdep13hard);
catch
    disp('no hard 1 vs 3 results ')
end