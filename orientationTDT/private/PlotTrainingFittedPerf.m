% script to plot newTDT training performances (flag), calculate some descriptives
% and export a txt for Jamovi (flag)
trainingplotflag = false;
newfileflag = true; 

clc

if trainingplotflag
    close all
    cd('~/ownCloud/MATLAB/Data/TDT/newTDT/')
    data_carpets = dir();
    data_carpets = data_carpets(4:end);
    
    alltriallengths = [];
    for jj = 1:length(data_carpets)
        cd([cd,'/',data_carpets(jj).name])
        
        csv_files = dir('*.csv');
        for f = 1:length(csv_files)
            if strcmp('training', csv_files(f).name(1:8))
                trainingfile = csv_files(f).name;
            end
        end
        % load da training data
        actual_data = readtable(trainingfile, 'Delimiter', 'comma',  'ReadVariableNames', 0);
        actual_data(:,end) = [];
        
        actual_data.Properties.VariableNames = {'subnumber', 'distance',...
            'height',	'quadrant',	'satQuadrantYN',	'block',...
            'trial',	'targetalignment',	'targetorientation',	'SOA',...
            'Resp',	'firstKEY',	'RESPtar',	'ACCtar',	'RTtar',...
            'SOATime',	'PreBlankTime',	'FixTime',	'StimTime',	'MaskTime',	'ClockTime', 'intercept', 'slope'};
        
        bayweights(jj,:) = actual_data.slope(~isnan(actual_data.slope));
        bayintercepts(jj,:) = actual_data.intercept(~isnan(actual_data.intercept));
        
        % make soa negative for horizontal targets
        actual_data.SOA(actual_data.targetalignment == 2) = -actual_data.SOA(actual_data.targetalignment == 2);
        
        if ~isempty(actual_data.SOA(actual_data.targetalignment == 2 & actual_data.SOA == 0))
            actual_data.SOA(actual_data.targetalignment == 2 & actual_data.SOA == 0)   = -.001;
        end
        
        % nan for lack of responses
        actual_data.RESPtar(strcmp('no_res', actual_data.Resp)) = NaN;
        
        % fit the model
        conds = linspace(-.6,.6,61);
        
        % extract the soa to plot it onto the fit
        if numel(csv_files) > 1
            temp = readtable(csv_files(f-1).name, 'Delimiter', 'comma',  'ReadVariableNames', 0);
            adaptiveSOA = mean(temp.Var11);
        end
        
        
        
        % don't actually need any of this, only bayesian to eyeball how well it extracted
        % the soa
        
        % bothmnr(:,jj) = mnrfit(actual_data.SOA, actual_data.RESPtar);
        %
        % figure
        % plot(actual_data.SOA ,actual_data.ACCtar,'s','color',rgb('coral'), 'MarkerSize', 6.5, 'Markerfacecolor', rgb('forest green'))
        % yhat_freq = mnrval(bothmnr(:,jj),conds');
        % hold on
        % plot(conds,yhat_freq(:,1), 'Color', rgb('dodger blue'), 'LineWidth', 3)
        
        % we don't do the average here, rather look at best perf (like in extractSOA)
        [~,idx] = max(bayweights(jj,:));
        yhatest1 = mnrval([bayintercepts(jj,idx); bayweights(jj,idx)], conds');
        plot(conds,yhatest1(:,1), 'Color', rgb('bright red'),'LineStyle', '--', 'LineWidth', 3)
        hold on
        
        axis([-.6 .6 0 1])
        if exist('adaptiveSOA', 'var')
            data_line = get(gca, 'Children');
            [~, plot_idx] = min(abs(data_line.XData - adaptiveSOA));
            plot(adaptiveSOA, data_line.YData(plot_idx), 'bo', 'MarkerSize', 10,'LineWidth', 2,'color', rgb('dodger blue'))
            legend('best training data block', 'extracted SOA', 'Location', 'NorthWest')
            hold on
            line([data_line.XData(1) data_line.XData(plot_idx)], [data_line.YData(plot_idx) data_line.YData(plot_idx)], 'Color', 'k','LineWidth', 1.5, 'LineStyle', ':')
        end
        
        % legend('responses','frequentist', 'bayesian', 'Location', 'NorthWest')
        title(['sat subj', data_carpets(jj).name,' training sesh '])
        disp(['subject', data_carpets(jj).name, ' replied correctly to ', num2str(round(sum(actual_data.ACCtar(actual_data.block>2))/numel(actual_data.ACCtar(actual_data.block>2))*100),2), '% of trials'])
        pause
        close
        
        clear adaptiveSOA temp
        cd ..
    end
end

cd('/Users/mococomac/ownCloud/MATLAB/Scripts/TDT/newTDT/private')
[baseline, quadrant_regardless_of_orientation, non_saturated_quadrant, saturated_quadrant] = matrixForJamovi(newfileflag);

Looper = 1;

while Looper
    firstlist = {'baseline', 'quadrant_regardless_of_orientation', 'non_saturated_quadrant', 'saturated_quadrant'};
    idx = listdlg('ListString', firstlist, 'OKString', 'choose', 'PromptString', 'Thy choice master?', 'CancelString', 'none');
    try
    firstchoice = firstlist{idx};
    catch
    firstchoice = 'none';   
    end
    
    switch firstchoice
        case 'none'
            break
            
        otherwise
            while Looper
                secondlist = {'mean', 'median'};
                idx2 = listdlg('ListString', secondlist,'OKString', 'calculate', 'PromptString', 'Desired parameter?', 'CancelString', 'that is enough');
                try
                secondchoice = secondlist{idx2};
                catch
                secondchoice = 'none';
                end
                
                switch secondchoice
                    case 'none'
                        break
                    case 'mean'
                        disp([upper(firstchoice), ' ', upper(secondchoice)])
                        disp(varfun(@mean, eval(firstchoice), 'GroupingVariable', 'subgroup'))
                    case 'median'
                        disp([upper(firstchoice), ' ', upper(secondchoice)])
                        disp(varfun(@median, eval(firstchoice), 'GroupingVariable', 'subgroup'))
                end
                
            end
    end
    
end

clearvars -except baseline quadrant_regardless_of_orientation orientation_regardless_of_quadrant saturated_quadrant