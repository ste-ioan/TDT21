function targetpos = newtargetPositions(ntrials, ITI)
%%%%%% RANDOMIZE TARGET POSITON %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% vector of target start positions are defined as cells in the grid
% see excel 'TDT_Grid' to get a visual where these positions are in the grid
% these position are all at quasi the same radial distance
if nargin <2
    ITI = false;
end

rng('shuffle')

Q1 = 289; % position code for quadrant 1 target
Q2 = 61; % position code for quadrant 2 target

% we'll also add target alignment info here to have an equal number per
% condition and target, which we will then shuffle

% position in grid matrix
targetpos(1,:) = [repmat(Q1, 1, ntrials/2),repmat(Q2, 1, ntrials/2)]; 
% target alignment, horizontal or vertical
targetpos(2,:) = repmat([1 2], 1, ntrials/2);
% shuffle them
targetpos =Shuffle(targetpos,1);

% line orientations
temp = nan(1,ntrials);
for b = 1:2
  temp(targetpos(1,:) == Q1 & targetpos(2,:) == b) = Shuffle(repmat([1 2], 1, ntrials/8));
  temp(targetpos(1,:) == Q2 & targetpos(2,:) == b) = Shuffle(repmat([1 2], 1, ntrials/8));
end 
 targetpos(3,:) = temp;
% now we have a balanced randomized matrix with all target info

if ITI
temp = nan(1,ntrials);

    % this is working code with orientation
for b = 1:2
for k = [Q1 Q2]
temp(targetpos(1,:) == k & targetpos(2,:) == 1 & targetpos(3,:) ==b) = Shuffle(repmat([.2 .4 .6 .8], 1, (ntrials/8)/4));     
temp(targetpos(1,:) == k & targetpos(2,:) == 2 & targetpos(3,:) ==b) = Shuffle(repmat([.2 .4 .6 .8], 1, (ntrials/8)/4));     
end
end
 % without orientation here
% for b = 1:2
% for k = [Q1 Q2]
% temp(targetpos(1,:) == k & targetpos(2,:) == b) = Shuffle(repmat([.2 .4 .6 .8], 1, (ntrials/4)/4)); %ntrials divided by number of conditions, divided by number of ITIs     
% end
% end

targetpos(end+1,:) = temp;
end

