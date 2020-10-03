cd('D:\satuTDT_EEG_files\cleanEEG\WithBaseline\')    

files = dir('*.mat');
% files(1:find(strcmp('Subject01.mat',{files.name}))-1) = [];

subjects = length(files);

FirstQuadrantSat = [(1:8:subjects)';(2:8:subjects)';(7:8:subjects)';(8:8:subjects)'];
FirstQuadrantSat = sort(FirstQuadrantSat);


for k = 1:48
    load(files(k).name);


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
    cfgfft = [];
    cfgfft.output  = 'pow';
    cfgfft.method  = 'mtmfft';
    cfgfft.taper   = 'dpss'; % hanning single taper is good for low frequencies, while for high is best to use multitapers 'dpss'
    cfgfft.tapsmofrq  = .017; % this is more appropiate to use with 'dpss' taper
    cfgfft.foi = 60:1:80; % gamma visual peak
    cfgfft.channel = dataclean.label(1:32);
    cfgfft.pad = ceil(max(cellfun(@numel, dataclean.time)/dataclean.fsample));
   
    
    for run = 1:3  
        if any(k == FirstQuadrantSat)
            DataSaturated{k, run} = ft_freqanalysis(cfgfft, firstquad.session(run));

            BaselineSaturated{k, run} = ft_freqanalysis(cfgfft, firstbaseline.session(run));
            
            Data_NotSaturated{k, run} = ft_freqanalysis(cfgfft, secondquad.session(run));
            
            Baseline_NotSaturated{k, run} = ft_freqanalysis(cfgfft, secondbaseline.session(run));

         else       
            
            DataSaturated{k, run} = ft_freqanalysis(cfgfft, secondquad.session(run));
            
            BaselineSaturated{k, run} = ft_freqanalysis(cfgfft, secondbaseline.session(run));
            
            Data_NotSaturated{k, run} = ft_freqanalysis(cfgfft, firstquad.session(run));
            
            Baseline_NotSaturated{k, run} = ft_freqanalysis(cfgfft, firstbaseline.session(run));

        end
        

    end
    
clearvars -except k files Data_NotSaturated Data_NotSaturatedLow DataSaturated DataSaturatedLow  FirstQuadrantSat ...
    Baseline_NotSaturatedLow Baseline_NotSaturatedHigh BaselineSaturatedHigh BaselineSaturatedLow s
end