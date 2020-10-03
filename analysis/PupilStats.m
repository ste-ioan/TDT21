% needs output from pupilTrialByTrial

clearvars -except allData 

easy = 1;
hard = 2;

side = 1;
nback = 2;
simon = 3;

session1= 1;
session2 = 2;
zerosec = 11;

% sixsec = 71;

% secondsSIDez = ~30 sec

% secondsNBA = ~15 sec

% secondsSIMez = ~2.7 sec

% simonhard = ~8.9 sec

% sidehard = ~18 sec


[p, ~,statsside] = ranksum(nanmean([nanmean(allData(zerosec:311,:,easy,session1,side));nanmean(allData(zerosec:311,:,easy,session2,side))]), ...
    nanmean([nanmean(allData(zerosec:191,:,hard,session1,side));nanmean(allData(zerosec:191,:,hard,session2,side))]));

[p, ~,statsnback] = ranksum(nanmean([nanmean(allData(zerosec:161,:,easy,session1,nback));nanmean(allData(zerosec:161,:,easy,session2,nback))]), ...
    nanmean([nanmean(allData(zerosec:161,:,hard,session1,nback));nanmean(allData(zerosec:161,:,hard,session2,nback))]))

[p, ~,statssimon] = ranksum(nanmean([nanmean(allData(zerosec:38,:,easy,session1,simon));nanmean(allData(zerosec:38,:,easy,session2,simon))]), ...
    nanmean([nanmean(allData(zerosec:100,:,hard,session1,simon));nanmean(allData(zerosec:100,:,hard,session2,simon))]))
