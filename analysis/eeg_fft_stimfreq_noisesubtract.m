% function [DataSaturatedLow, Data_NotSaturatedLow, Baseline_NotSaturatedLow, Baseline] = eeeg_wholespectrum
cd('D:\satuTDT_EEG_files\cleanEEG\WithBaseline\')    

files = dir('*.mat');
% files(1:find(strcmp('Subject01.mat',{files.name}))-1) = [];

subjects = length(files);

FirstQuadrantSat = [(1:8:subjects)';(2:8:subjects)';(7:8:subjects)';(8:8:subjects)'];
FirstQuadrantSat = sort(FirstQuadrantSat);


for k = 1:subjects
    load(files(k).name);
    %% frequency analysis
    cfg2 = [];
    cfg2.output  = 'pow';
    cfg2.method  = 'mtmfft';
    cfg2.taper   = 'hanning'; % hanning single taper is good for low frequencies, while for high is best to use multitapers 'dpss'
    cfg2.channel = dataclean.label(1:32);
    cfg2.foi = [7.1:.1:7.9];  
    cfg2.pad = ceil(max(cellfun(@numel, dataclean.time)/dataclean.fsample));   

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
 
    
    for run = 1:3  
        if any(k == FirstQuadrantSat)
            DataSaturated{k, run} = ft_freqanalysis(cfg2, firstquad.session(run));

            BaselineSaturated{k, run} = ft_freqanalysis(cfg2, firstbaseline.session(run));

            
            Data_NotSaturated{k, run} = ft_freqanalysis(cfg2, secondquad.session(run));
            
            Baseline_NotSaturated{k, run} = ft_freqanalysis(cfg2, secondbaseline.session(run));

        else       
            
            DataSaturated{k, run} = ft_freqanalysis(cfg2, secondquad.session(run));
            
            BaselineSaturated{k, run} = ft_freqanalysis(cfg2, secondbaseline.session(run));


            
            Data_NotSaturated{k, run} = ft_freqanalysis(cfg2, firstquad.session(run));
            
            Baseline_NotSaturated{k, run} = ft_freqanalysis(cfg2, firstbaseline.session(run));

        end
        

    end
    
            % find index for stimfreq
    STIMFREQ = 7.499755867322027;
    f=find(round(DataSaturated{k,1}.freq,2)==round(STIMFREQ,2));
        %% NOISE SUBTRACT
    for s = 1:3
        for ch = 1:length(cfg2.channel)         
        DataSaturated{k,s}.powspctrm(ch,f) = 1.25*DataSaturated{k,s}.powspctrm(ch,f)-nansum(DataSaturated{k,s}.powspctrm(ch,[f-2 f f+2]),2)/4;
        Data_NotSaturated{k,s}.powspctrm(ch,f) = 1.25*Data_NotSaturated{k,s}.powspctrm(ch,f)-nansum(Data_NotSaturated{k,s}.powspctrm(ch,[f-2 f f+2]),2)/4;
        
        BaselineSaturated{k,s}.powspctrm(ch,f) = 1.25*BaselineSaturated{k,s}.powspctrm(ch,f)-nansum(BaselineSaturated{k,s}.powspctrm(ch,[f-2 f f+2]),2)/4;        
        Baseline_NotSaturated{k,s}.powspctrm(ch,f) = 1.25*Baseline_NotSaturated{k,s}.powspctrm(ch,f)-nansum(Baseline_NotSaturated{k,s}.powspctrm(ch,[f-2 f f+2]),2)/4;        

        end
    end
    
clearvars -except k files Data_NotSaturated DataSaturated  FirstQuadrantSat ...
    Baseline_NotSaturated BaselineSaturated s
end
% end