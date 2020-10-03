cd('D:\satuTDT_EEG_files\')

files = dir('*.bdf');
[~,index] = sortrows({files.name}.'); files = files(index); clear index
for k = 21%1:length(files)
    filename = files(k).name;
    header = ft_read_header(filename);
    % find the triggers
    events = ft_read_event(filename);
    trgrs = find(strcmp({events.type},'STATUS'));
    
    % exclude extra triggers
    extratrgr = find(diff([events(trgrs(1):end).sample]) < 10000)+trgrs(1);
    events(extratrgr) = [];
    trgrs = find(strcmp({events.type},'STATUS'));
    if filename == 'Subject15.bdf' % extra trigger after first 4
        trgrs(5) = [];
    end
    
    EEGtestOnset = [events(trgrs).sample];
    EEGtestOffset = EEGtestOnset + header.Fs*60; % take signal jusqu'a 1 min after trigger
    if strcmp(files(k).name,'Subject40.bdf') % extra starting trigger
        EEGtestOnset(1) =[];
        EEGtestOffset(1) =[];
    end
    
    phCh = logical(strcmp('Erg1',header.label));
    dat = ft_read_data(filename, 'header', header);
    
 % we make new 3 sec trials that are the baselines to the stimulations
 BaselineOnsets = EEGtestOnset' - 3.5*header.Fs; % 3.5 seconds before stim
 BaselineOffsets = EEGtestOnset' - .5*header.Fs; % .5 seconds before stim
 
 AllOnsets = sort([BaselineOnsets;EEGtestOnset'] ,'ascend');
 AllOffsets = sort([BaselineOffsets;EEGtestOffset'] ,'ascend');
 
    cfgprepro = [];
    cfgprepro.dataset = filename;
    cfgprepro.trl = [AllOnsets AllOffsets zeros(length(AllOnsets),1) [81;11;91;21;81;11;91;21;82;12;92;22;82;12;92;22;83;13;93;23;83;13;93;23]]; % start of sample, finish of sample, trigger offset
    cfgprepro.continuous = 'yes';
    cfgprepro.dftfilter = 'yes';
    cfgprepro.hpfilter        = 'yes';
    cfgprepro.hpfreq          = 1; % bio semi said 1 hz here is good for sweat artfcts
    cfgprepro.lpfilter        = 'yes';
    cfgprepro.lpfreq          = 100;
    cfgprepro.reref = 'yes';
    cfgprepro.refchannel = header.label(1:32);
    cfgprepro.refmethod = 'avg';
    
    data = ft_preprocessing(cfgprepro);
    
    data.label(1:32) = {'Fp1', 'AF3', 'F7', 'F3', 'FC1', 'FC5', 'T7', 'C3', 'CP1', ...
        'CP5', 'P7', 'P3', 'Pz', 'PO3', 'O1', 'Oz', 'O2', 'PO4', 'P4', 'P8', 'CP6', 'CP2', 'C4' ...
        'T8', 'FC6', 'FC2', 'F4', 'F8', 'AF4', 'Fp2', 'Fz', 'Cz'};
    data.hdr.label(1:32) = {'Fp1', 'AF3', 'F7', 'F3', 'FC1', 'FC5', 'T7', 'C3', 'CP1', ...
        'CP5', 'P7', 'P3', 'Pz', 'PO3', 'O1', 'Oz', 'O2', 'PO4', 'P4', 'P8', 'CP6', 'CP2', 'C4' ...
        'T8', 'FC6', 'FC2', 'F4', 'F8', 'AF4', 'Fp2', 'Fz', 'Cz'};
    
    if strcmp(files(k).name,'Subject03.bdf') % messed up this subj by 'recording' 266 channels
        data.label(33:256) = [];
        for bibbi = 1:24
            data.trial{1,bibbi}(33:256,:) =[];
        end
        data.cfg.channel = [header.label(1:32);'EXG1';'EXG2';'EXG3';'EXG4';'EXG5';'EXG6'; 'EXG7'; 'EXG8'; 'Erg1'; 'Status'];
        header.label =data.cfg.channel;
    end
    
    cfgbrowse =[];
    cfgbrowse.channel = data.label(1:32);
    cfgbrowse.layout = 'biosemi32.lay';
    cfgbrowse.viewmode = 'vertical';
    cfgbrowse.artifactalpha = 0.8;
    artif = ft_databrowser(cfgbrowse, data);
    [indx, ~] = listdlg('ListString', {'None','Fp1', 'AF3', 'F7', 'F3', 'FC1', 'FC5', 'T7', 'C3', 'CP1', ...
    'CP5', 'P7', 'P3', 'Pz', 'P03', '01', '0z', '02', 'P04', 'P4', 'P8', 'CP6', 'CP2', 'C4' ...
    'T8', 'FC6', 'FC2', 'F4', 'F8', 'AF4', 'Fp2', 'Fz', 'Cz'});

    if indx == 1
    artif.badchannel = [];
    else
    artif.badchannel = data.label(indx-1);
    end
    
    if ~isempty(artif.badchannel)
        cfg = [];
        cfg.badchannel = artif.badchannel;
        cfg.method = 'weighted';
        cfg_neighb = [];
        cfg_neighb.method    = 'distance';
        cfg_neighb.layout = 'biosemi32.lay';
        cfg_neighb.neighbourdist = .16;
        cfg.neighbours       = ft_prepare_neighbours(cfg_neighb, data);
        cfg.layout = 'biosemi32';
        data = ft_channelrepair(cfg, data);
    end
    
    cfg =[];
    cfg.artfctdef.reject = 'nan';
    if isfield(artif.artfctdef, 'visual')
        cfg.artfctdef.visual.artifact = artif.artfctdef.visual.artifact;
    end
    data = ft_rejectartifact(cfg, data);
    
    cfg =[];
    cfg.prewindow = 1;
    cfg.postwindow = 1;
    data = ft_interpolatenan(cfg, data);
    
    % at this point we run the ICA
    cfg=[];
    cfg.method  = 'fastica';
    cfg.channel = data.label(1:38);
    datacomp = ft_componentanalysis(cfg, data); % this guy demeans by default
    cfg = [];
    cfg.layout = 'biosemi32.lay';
    cfg.viewmode = 'component';
    ft_databrowser(cfg, datacomp);
    component=input('Which component do you wish to remove?','s');
    cfg = [];
    cfg.component = str2num(component); % to be removed component(s)
    dataclean = ft_rejectcomponent(cfg, datacomp);
    
    cd('D:\satuTDT_EEG_files\cleanEEG\WithBaseline\')
    save(filename(end-5:end-4),'dataclean');
    
       
    clearvars -except k files 
        cd ..
        cd ..
end