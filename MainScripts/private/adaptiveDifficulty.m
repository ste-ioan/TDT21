function [features, w_vb, V_vb] = adaptiveDifficulty( conds, x, y, model  )
% [features, w_vb, V_vb] = adaptivePsychometric( features, response, model  )
% conditions are cell arrays with one cell per condition, containing all
% possible values for the adaptive features
%
% X is the N x P data with N trials and P features. Intercept and interactions should not be
% included! 
% y is the response data
% model can be 'BMA','logit' or 'mnrfit'
%
% output contains next feature values, estimated coeffs and their variance

MINTRIALS = 5;
allnanFlag=false;

if nargin<=3
    model = 'logit';
end

y = double(y);
u = unique(y(~isnan(y)));
if length(u)==2
    y(y==u(1)) = -1;
    y(y==u(2)) = 1;
elseif length(u)==1
    y(y==u(1)) = 1;
elseif all(isnan(y)) || isempty(y)
    warning('No data')
else
    error('Response is not binary');
end
y = y(:);

ok = ~any(isnan(x),2) & ~isnan(y);
if (sum(ok)>MINTRIALS)
    T = conditionTable( conds{:} );
    M = nanmean(T,1);
    T = bsxfun(@minus,T,M);% center conditions
    S = nanmax(abs(T),[],1);
    T = bsxfun(@rdivide,T,S);
    tt = [1:size(T,2)];
    if size(T,2)==2
        T(:,3) = T(:,1).*T(:,2);
    elseif size(T,2)==3
        T(:,4) = T(:,1).*T(:,2);
        T(:,5) = T(:,1).*T(:,3);
        T(:,6) = T(:,2).*T(:,3);
    elseif size(T,2)>3
        warning('Interaction are not taken into account because there are too many conditions');
    end
    T = [ones(size(T,1),1) T];
    tt=tt+1;
    
    X = bsxfun(@minus,x(ok,:),M); % center data
    X = bsxfun(@rdivide,X,S);
    if size(X,2)==2
        X(:,3) = X(:,1).*X(:,2);
    elseif size(X,2)==3
        X(:,4) = X(:,1).*X(:,2);
        X(:,5) = X(:,1).*X(:,3);
        X(:,6) = X(:,2).*X(:,3);
    elseif size(X,2)>3
        warning('Interaction are not taken into account because there are too many conditions');
    end
    X = [ones(size(X,1),1) X];
    
    % too computationnally demanding
    
    switch model
        case 'BMA'
            [w_vb,V_vb,pred] = bayesianModelAveraging(X,y,T);
        case 'logit'
            [w_vb,V_vb] = vb_logit_fit(X, y(ok));
            %pred = vb_logit_pred(T, w_vb, V_vb, invV);
        case 'mnrfit'
            w_vb = mnrfit(X(:,2:end),1+(y(ok)==-1));
    end
    
    %
    %             N = unique(T(:,3));
    %
    %             figure(12)
    %             for nn = 1:length(N)
    %                 subplot(floor(sqrt(length(N))),ceil(sqrt(length(N))),nn);
    %                 plot(T(T(:,3)==N(nn),2),pred(T(:,3)==N(nn)));
    %             end
    %             pause(1);
    
    for ss = 1:size(T,1)
        [h(ss),kl(ss),w_vbp(:,ss),V_vbp(:,:,ss),w_vbq(:,ss),V_vbq(:,:,ss),pp(:,ss)] = evaluatePsi(w_vb,V_vb,T(ss,:),X,y(ok),model);
    end
    kl = kl-min(kl);
    kl = kl/max(kl);
    %[~,m] = max(kl);
    a = -10;
    m = cumsum(exp(-a*kl)./sum(exp(-a*kl)));% softmax
    m = find(m>=rand,1);
    features=(T(m,tt).*S)+M;
    
else
    features = [];
    for cc = 1:length(conds)
        s = length(conds{cc});
        features = [features conds{cc}(randi(s))];
    end
end
end

function [W_VB,V_VB,pred] = bayesianModelAveraging(X,y,T)
S = size(X,2);
model='logit';
switch model
    case 'logit'
        switch S
            case 1
                [w_vb, V_vb, invV, logdetV, E_a, L1] = vb_logit_fit(X, y);
            case 2
                ix = 0;
                LIST = [];
                for ii = 1:S
                    for jj = ii:S
                        ix = ix+1;
                        u = unique([ii jj]);
                        u(length(u)+1:S) = 0;
                        LIST = [LIST; u];
                        [w_vb([ii jj],ix), V_vb([ii jj],[ii jj],ix), invV, logdetV, E_a, L(ix)] = vb_logit_fit(X(:,[ii jj]), y);
                        
                    end
                end
                [C,IA,IC] = unique(LIST,'rows');
                w_vb = w_vb(:,IA);
                V_vb = V_vb(:,:,IA);
                L = L(IA);
            case 3
                ix = 0;
                LIST = [];
                for ii = 1:S
                    for jj = ii:S
                        for kk = jj:S
                            ix = ix+1;
                            u = unique([ii jj kk]);
                            u(length(u)+1:S) = 0;
                            LIST = [LIST; u];
                            [w_vb([ii jj kk],ix), V_vb([ii jj kk],[ii jj kk],ix), invV, logdetV, E_a, L(ix)] = vb_logit_fit(X(:,[ii jj kk]), y);
                            
                        end
                    end
                end
                [C,IA,IC] = unique(LIST,'rows');
                w_vb = w_vb(:,IA);
                V_vb = V_vb(:,:,IA);
                L = L(IA);
            case 4
                ix = 0;
                LIST = [];
                for ii = 1:S
                    for jj = ii:S
                        for kk = jj:S
                            for ll = kk:S
                                ix = ix+1;
                                u = unique([ii jj kk ll]);
                                u(length(u)+1:S) = 0;
                                LIST = [LIST; u];
                                [w_vb([ii jj kk ll],ix), V_vb([ii jj kk ll],[ii jj kk ll],ix), invV, logdetV, E_a, L(ix)] = vb_logit_fit(X(:,[ii jj kk ll]), y);
                            end
                        end
                    end
                end
                [C,IA,IC] = unique(LIST,'rows');
                w_vb = w_vb(:,IA);
                V_vb = V_vb(:,:,IA);
                L = L(IA);
        end
        
    case 'linear'
        error('To do');
end
w = exp(L)./sum(exp(L));
W_VB = (w*w_vb')';
V_VB = V_vb(:,:,1)*0;
for ii = 1:length(w)
    V_VB = V_VB + w(ii)*V_vb(:,:,ii);
end
pred = vb_logit_pred(T, W_VB, V_VB, inv(V_VB));

end


function [h,kl,w_vbp,V_vbp,w_vbq,V_vbq,p] = evaluatePsi(w_vb,V_vb,C,D,Y,model)
logit = @(X) 1 ./ (1 + exp(-X));
KL = @(w1,w2,S1,S2) 0.5 * ( log(det(S2)/det(S1)) - length(w1) + trace(S2\S1) + (w2-w1)'*(S2\(w2-w1)));
%ENTROPY = @(w,S) (length(w)/2) + (length(w)/2)*log(2*pi) + 0.5*log(det(S));
ENTROPY = @(S) 0.5 * log(det(2*pi*exp(1)*S));

p = logit(w_vb(:)'*C(:));
Dd = [D; C];
switch model
    case {'logit','logit_fit','BMA'}
        [w_vbp, V_vbp] = vb_logit_fit(Dd, [Y;1]);
        [w_vbq, V_vbq] = vb_logit_fit(Dd, [Y;-1]);
    case 'mnrfit'
        Y = 1+(Y==-1);
        [w_vbp,DEV,STATS] = mnrfit(Dd(:,2:end),[Y;1]);%1 is right
        V_vbp = STATS.covb;
        [w_vbq,DEV,STATS] = mnrfit(Dd(:,2:end),[Y;2]);%2 is left
        V_vbq = STATS.covb;
    case 'linear'
        error('Too do');
end

h = p*ENTROPY(V_vbp) + (1-p)*ENTROPY(V_vbq);
kl = p*KL(w_vb,w_vbp,V_vb,V_vbp) + (1-p)*KL(w_vb,w_vbq,V_vb,V_vbq);

end