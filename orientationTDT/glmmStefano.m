clear
cd('/Users/mococomac/Documents/jamovi analyses/TDT/orientationTDT')
loader = readtable('study3_data.csv');
%study2data = convertvars(study2data,{'session','targetorientation','satQuadrantYN'},'categorical');

tbl = table(loader.ACCtar,categorical(loader.session),categorical(loader.targetorientation),...
    categorical(loader.satQuadrantYN),categorical(loader.subnumber),'VariableNames',{'ACCtar','session','targetorientation','satQuadrantYN','subnumber'});
lme1 = fitglme(tbl,'ACCtar ~ session * targetorientation * satQuadrantYN + ( 1 + satQuadrantYN + session + targetorientation | subnumber)',...
    'Distribution','Binomial');

lme2 = fitglme(tbl,'ACCtar ~ session * satQuadrantYN + ( 1 + satQuadrantYN + session | subnumber)',...
    'Distribution','Binomial','Exclude',tbl.targetorientation==categorical(135));
a2=anova(lme2);
lme3 = fitglme(tbl,'ACCtar ~ session * satQuadrantYN + ( 1 + satQuadrantYN + session | subnumber)',...
    'Distribution','Binomial','Exclude',tbl.targetorientation==categorical(45));
a3=anova(lme3);
lme4 = fitglme(tbl,'ACCtar ~ session * targetorientation + ( 1 + targetorientation + session | subnumber)',...
    'Distribution','Binomial','Exclude',tbl.satQuadrantYN==categorical(1));
a4=anova(lme4);
lme5 = fitglme(tbl,'ACCtar ~ session * targetorientation + ( 1 + targetorientation + session | subnumber)',...
    'Distribution','Binomial','Exclude',tbl.satQuadrantYN==categorical(0));
a5=anova(lme5);
lme6 = fitglme(tbl,'ACCtar ~ session * targetorientation + ( 1 + targetorientation + session | subnumber)',...
    'Distribution','Binomial','Exclude',((tbl.satQuadrantYN==categorical(0))&(tbl.targetorientation==categorical(45)))|((tbl.satQuadrantYN==categorical(1))&(tbl.targetorientation==categorical(135))));
a6=anova(lme6);
lme7 = fitglme(tbl,'ACCtar ~ session * targetorientation + ( 1 + targetorientation + session | subnumber)',...
    'Distribution','Binomial','Exclude',((tbl.satQuadrantYN==categorical(0))&(tbl.targetorientation==categorical(135)))|((tbl.satQuadrantYN==categorical(1))&(tbl.targetorientation==categorical(45))));
a7=anova(lme7);


pvalues = table(6*a2.pValue(end),min(1,1*a3.pValue(end)),3*a4.pValue(end),5*a5.pValue(end),4*a6.pValue(end),min(1,2*a7.pValue(end)),...
    'VariableNames',{'orient45_SATvsNONSAT','orient135_SATvsNONSAT','NONSAT_45vs135','SAT_45vs135','SAT45vsNONSAT135','NONSAT45vsSAT135'})