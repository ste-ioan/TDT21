function newdata = keepTrack(Data)

newdata = Data;

for sesh = 1:3
for subj = 1:48
    if iscell(Data{subj,sesh}.cfg.previous.previous.previous)
    try
    file = getfield(Data{subj,sesh}.cfg.previous.previous.previous{1,1}.previous.previous.previous, 'dataset');
    catch
    file = getfield(Data{subj,sesh}.cfg.previous.previous.previous{1,1}.previous.previous.previous.previous, 'dataset');      
    end 
    
    else % if you applied a transformation such as log to the data, adding a cfg in the history
    try
    file = getfield(Data{subj,sesh}.cfg.previous.previous.previous.previous{1,1}.previous.previous.previous, 'dataset');
    catch
    file = getfield(Data{subj,sesh}.cfg.previous.previous.previous.previous{1,1}.previous.previous.previous.previous, 'dataset');      
    end 
    
    end
newdata{subj,sesh}.dataset = file;
end
end
end