%% correlate new tiny tdt (eye) questionnaire w/performance, 

load('/Users/mococomac/Documents/jamovi analyses/TDT/eyeTDT/behaviour/tdt_sat_perf.mat');

eyeTdtperf = sat_perf_delta;

results = readtable('~/Documents/jamovi analyses/TDT/eyeTDT/questionnaires/scores.csv');

negative_items = [2, 4, 7, 10, 11, 12, 13, 14];

for k = 1:numel(negative_items)
    tmp_pre(:,k) = eval(['results.MFI',num2str(negative_items(k)),'_Pre']);
    tmp_post(:,k) = eval(['results.MFI',num2str(negative_items(k)),'_Post']);
end

for jj = 1:length(tmp_pre)
    
    for ll = 1:numel(negative_items)
        switch tmp_pre(jj, ll)
            case 5
                tmp_pre(jj, ll) = 1;
            case 4
                tmp_pre(jj, ll) = 2;
            case 2
                tmp_pre(jj, ll) = 4;
            case 1
                tmp_pre(jj, ll) = 5;
        end
    end
end

for jj = 1:length(tmp_post)
    
    for ll = 1:numel(negative_items)
        switch tmp_post(jj, ll)
            case 5
                tmp_post(jj, ll) = 1;
            case 4
                tmp_post(jj, ll) = 2;
            case 2
                tmp_post(jj, ll) = 4;
            case 1
                tmp_post(jj, ll) = 5;
        end
    end
end

MFI_pre = [results.MFI1_Pre,tmp_pre(:,1),results.MFI3_Pre,tmp_pre(:,2),...
    results.MFI5_Pre, results.MFI6_Pre, tmp_pre(:,3), results.MFI8_Pre,...
    results.MFI9_Pre, tmp_pre(:,4), tmp_pre(:,5), tmp_pre(:,6),tmp_pre(:,7),...
    tmp_pre(:,8), results.MFI15_Pre];

MFI_post = [results.MFI1_Post,tmp_post(:,1),results.MFI3_Post,tmp_post(:,2),...
    results.MFI5_Post, results.MFI6_Post, tmp_post(:,3), results.MFI8_Post,...
    results.MFI9_Post, tmp_post(:,4), tmp_post(:,5), tmp_post(:,6),tmp_post(:,7),...
    tmp_post(:,8), results.MFI15_Post];

T_MFI = array2table([mean(MFI_pre,2), mean(MFI_post,2)]);

[~, pval_fat, ci_fat, stats_fat] = ttest(T_MFI.Var1, T_MFI.Var2);

deltaMFI = mean(MFI_post-MFI_pre,2);

plot(eyeTdtperf,deltaMFI,'Color', rgb('coral'), 'Marker', '.', 'MarkerSize', 30, 'LineStyle', 'none')

% correlates! neat.
[rho,pval] = corr(eyeTdtperf,deltaMFI)

% cis of correlation (diagonal value)
[~,~, lowr, uppr] = corrcoef(eyeTdtperf,deltaMFI);

% this is correlValues
cd('/Users/mococomac/Documents/jamovi analyses/TDT/eyeTDT/pupil/')
writetable(table([(eyeTdtperf*100),deltaMFI]));


%% correlate performance with pupil (eyeTDT)
load('/Users/mococomac/Documents/jamovi analyses/TDT/eyeTDT/pupil/unfilttaskpupils.mat');

eyeTdtpupil = avgd_pupil_from_trials.nanmean_mean;

clear sat_perf_delta avgd_pupil_from_trials


[rho2,pval2] = corr(eyeTdtperf,eyeTdtpupil)

% this is correlValuesPupil
writetable(table([(eyeTdtperf*100),eyeTdtpupil]));


%% correlate performance with pupil (orientationTDT)
load('/Users/mococomac/Documents/jamovi analyses/TDT/orientationTDT/behaviour/tdt_sat_perf.mat');

orientationTdtperf = sat_perf_delta;

load('/Users/mococomac/Documents/jamovi analyses/TDT/orientationTDT/pupil/unfilttaskpupils.mat');

orientationTdtpupil = avgd_pupil_from_trials.nanmean_mean;

clear sat_perf_delta avgd_pupil_from_trials

[rho3,pval3] = corr(orientationTdtperf,orientationTdtpupil)
