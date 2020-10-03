s = input('baseline?', 's');
if s == 'y'
cd('D:\satuTDT_EEG_files\cleanEEG\WithBaseline\')    
else
cd('D:\satuTDT_EEG_files\cleanEEG\')
end
files = dir('*.mat');
% files(1:find(strcmp('Subject01.mat',{files.name}))-1) = [];

subjects = length(files);

FirstQuadrantSat = [(1:8:subjects)';(2:8:subjects)';(7:8:subjects)';(8:8:subjects)'];
FirstQuadrantSat = sort(FirstQuadrantSat);


for k = 1:48
    load(files(k).name);

if strcmp(s, 'y')
    cfgbsl.trials = find(dataclean.trialinfo == 81)';
    firstbaseline.session(1) =  ft_selectdata(cfgbsl, dataclean);
    cfgbsl.trials = find(dataclean.trialinfo == 82)';
    firstbaseline.session(2) =  ft_selectdata(cfgbsl, dataclean);
    cfgbsl.trials = find(dataclean.trialinfo == 83)';
    firstbaseline.session(3) =  ft_selectdata(cfgbsl, dataclean);
    
    cfgbsl.trials = find(dataclean.trialinfo==91)';
    secondbaseline.session(1) = ft_selectdata(cfgbsl, dataclean);
    cfgbsl.trials = find(dataclean.trialinfo==92)';
    secondbaseline.session(2) = ft_selectdata(cfgbsl, dataclean);
    cfgbsl.trials = find(dataclean.trialinfo==93)';
    secondbaseline.session(3) = ft_selectdata(cfgbsl, dataclean);
end   
    
    
    
    cfg.trials = find(dataclean.trialinfo==11)';
    firstquad.session(1) = ft_selectdata(cfg, dataclean);
    cfg.trials = find(dataclean.trialinfo==12)';
    firstquad.session(2) = ft_selectdata(cfg, dataclean);
    cfg.trials = find(dataclean.trialinfo==13)';
    firstquad.session(3) = ft_selectdata(cfg, dataclean);
    
    cfg.trials = find(dataclean.trialinfo==21)';
    secondquad.session(1) = ft_selectdata(cfg, dataclean);
    cfg.trials = find(dataclean.trialinfo==22)';
    secondquad.session(2) = ft_selectdata(cfg, dataclean);
    cfg.trials = find(dataclean.trialinfo==23)';
    secondquad.session(3) = ft_selectdata(cfg, dataclean);
    
    %% frequency analysis
%     cfghigh = [];
%     cfghigh.output  = 'pow';
%     cfghigh.method  = 'mtmfft';
%     cfghigh.taper   = 'dpss'; % hanning single taper is good for low frequencies, while for high is best to use multitapers 'dpss'
%     cfghigh.tapsmofrq  = .017; % this is more appropiate to use with 'dpss' taper
%     cfghigh.foi = 60:1:80; % gamma visual peak
%     cfghigh.channel = dataclean.label(1:32);
%     cfghigh.pad = ceil(max(cellfun(@numel, dataclean.time)/dataclean.fsample));
% %     cfghigh.pad='nextpow2';
   
    cfglow = [];
    cfglow.output  = 'pow';
    cfglow.method  = 'mtmfft';
    cfglow.taper   = 'hanning'; 
     cfglow.foilim =    [8 12]; % alpha, [2 6]% theta
    cfglow.channel = dataclean.label(1:32);
    cfglow.pad = ceil(max(cellfun(@numel, dataclean.time)/dataclean.fsample));   
    
    for run = 1:3  
        if any(k == FirstQuadrantSat)
%             DataSaturated{k, run} = ft_freqanalysis(cfghigh, firstquad.session(run));
            DataSaturated{k, run} = ft_freqanalysis(cfglow, firstquad.session(run));

%             BaselineSaturated{k, run} = ft_freqanalysis(cfghigh, firstbaseline.session(run));
%              BaselineSaturatedLow{k, run} = ft_freqanalysis(cfglow, firstbaseline.session(run));

            
%             Data_NotSaturated{k, run} = ft_freqanalysis(cfghigh, secondquad.session(run));
            Data_NotSaturated{k, run} = ft_freqanalysis(cfglow, secondquad.session(run));
            
%             Baseline_NotSaturated{k, run} = ft_freqanalysis(cfghigh, secondbaseline.session(run));
%             Baseline_NotSaturatedLow{k, run} = ft_freqanalysis(cfglow, secondbaseline.session(run));

         else       
            
%             DataSaturated{k, run} = ft_freqanalysis(cfghigh, secondquad.session(run));
             DataSaturated{k, run} = ft_freqanalysis(cfglow, secondquad.session(run));
            
%             BaselineSaturated{k, run} = ft_freqanalysis(cfghigh, secondbaseline.session(run));
%             BaselineSaturatedLow{k, run} = ft_freqanalysis(cfglow, secondbaseline.session(run));


            
%             Data_NotSaturated{k, run} = ft_freqanalysis(cfghigh, firstquad.session(run));
              Data_NotSaturated{k, run} = ft_freqanalysis(cfglow, firstquad.session(run));
            
%             Baseline_NotSaturated{k, run} = ft_freqanalysis(cfghigh, firstbaseline.session(run));
%              Baseline_NotSaturatedLow{k, run} = ft_freqanalysis(cfglow, firstbaseline.session(run));

        end
        

    end
    
clearvars -except k files Data_NotSaturated Data_NotSaturatedLow DataSaturated DataSaturatedLow  FirstQuadrantSat ...
    Baseline_NotSaturatedLow Baseline_NotSaturatedHigh BaselineSaturatedHigh BaselineSaturatedLow s
end