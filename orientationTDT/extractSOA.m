function previousSOA = extractSOA(filepath)

if nargin<1
    filepath = '~/ownCloud/MATLAB/Data/TDT/newTDT/test/trainingTDT_subjtest.csv';
end

opts = detectImportOptions(filepath, 'NumHeaderLines',0);
opts.ExtraColumnsRule = 'ignore';
opts.VariableNamesLine = 1;
opts.VariableTypes(22) = {'double'};
opts.VariableTypes(23) = {'double'};

results = readtable(filepath, opts);

% we want only that of the best training block, [increased from .7/.3]
previousSOA = round(log(.8/.2) / max(results.slope),2);