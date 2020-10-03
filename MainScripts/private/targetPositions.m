function targetpos = targetPositions(quadrant,ntrials)
%%%%%% RANDOMIZE TARGET POSITON %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% vector of target start positions are defined as cells in the grid
% see excel 'TDT_Grid' to get a visual where these positions are in the grid
% these position are all at quasi the same radial distance
% quadrant: 1 = top right; 2 = top left; 3 = bottom left; 4 = bottom right

if nargin==1
    ntrials = 50;
end

List1 = [213 233 253 273 293]; %list of position targets for quadrant 1
List2 = [65 83 101 119 137]; %list of position targets for quadrant 2
List3 = [69 89 109 129 149];
List4 = [225 243 261 279 297];

rep = ceil(ntrials/5);
largeList1 = repmat(List1, 1, rep); % repeat the vector so it contains 50 trials in a balanced way (each position has the same amount of probability)
largeList2 = repmat(List2, 1, rep);
largeList3 = repmat(List3, 1, rep);
largeList4 = repmat(List4, 1, rep);

NumberList1 = Shuffle(largeList1); % shuffle the order of target positions
NumberList2 = Shuffle(largeList2);
NumberList3 = Shuffle(largeList3);
NumberList4 = Shuffle(largeList4);

%Quadrants
if quadrant == 1 %top right
    targetpos=NumberList1;
elseif quadrant == 2 %top left
    targetpos=NumberList2;
elseif quadrant == 3 % bottom left
    targetpos=NumberList3;
elseif quadrant == 4 %bottow right
    targetpos=NumberList4;
end
end
