%add q sounds to matrix
function allsounds = qinsert(allsounds,Qsounds)

rng('shuffle')

soundmatrix = [];
vector = Shuffle(1:1:15);
vector2 = [0,cumsum(vector)];

% randomly insert some ques, enforcing that first sound is a q
for i = 1:length(vector)
    if i == 15
        soundmatrix = [soundmatrix, Qsounds(ceil(rand*2)), allsounds(vector2(i)+1:vector2(end))];
    else
        soundmatrix = [soundmatrix, Qsounds(i), allsounds(vector2(i)+1:vector2(i+1))];
    end
end
allsounds = soundmatrix;

%add coherency and response
q_idx = find([allsounds.cue]);
q_idx =[q_idx length(allsounds)+1];

for j = 1:length(q_idx)-1   
    for k = q_idx(j):q_idx(j+1)-1
        
        if allsounds(k).category == allsounds(q_idx(j)).category
            allsounds = setfield(allsounds, {k}, 'coherent',1);
        else
            allsounds = setfield(allsounds, {k}, 'coherent',0);
        end
        
        if allsounds(k).target == 1 && allsounds(k).coherent == 1
            switch allsounds(k).side
                case 1
                    allsounds = setfield(allsounds, {k}, 'response', 42);
                case 9
                    allsounds = setfield(allsounds, {k}, 'response', 45);
            end
            
        elseif allsounds(k).target == 1 && allsounds(k).coherent == 0
            switch allsounds(k).side
                case 1
                    allsounds = setfield(allsounds, {k}, 'response', 45);
                case 9
                    allsounds = setfield(allsounds, {k}, 'response', 42);
            end
            
        elseif allsounds(k).target == 0
            allsounds(k).response = 0;
        end
    end
end