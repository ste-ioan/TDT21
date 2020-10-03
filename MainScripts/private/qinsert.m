%add q sounds to matrix
function allsounds = qinsert(allsounds,Qsounds)

rng('shuffle')

soundmatrix = [];
vector = Shuffle(1:1:15);
vector2 = [0,cumsum(vector)];

for i = 1:length(vector)
if i == 15
soundmatrix = [soundmatrix, Qsounds(ceil(rand*2)), allsounds(vector2(i)+1:vector2(end))];    
    
else
soundmatrix = [soundmatrix, Qsounds(i), allsounds(vector2(i)+1:vector2(i+1))];    
end    
    
end

allsounds = soundmatrix;

%add coherency and response
    q_idx = [];
    
    for j = 1:length(allsounds)
        if allsounds(j).cue == 1
            q_idx = [q_idx, j];
        end
    end
    
    for l = 1:length(allsounds)
        for k = q_idx(1):q_idx(2)
            if allsounds(k).category == allsounds(q_idx(1)).category
                allsounds(k).coherent = 1;
            else
                allsounds(k).coherent = 0;
            end
        end
        for k = q_idx(2)+1:q_idx(3)
            if allsounds(k).category == allsounds(q_idx(2)).category
                allsounds(k).coherent = 1;
                
            else
                allsounds(k).coherent = 0;
            end
        end
        for k = q_idx(3)+1:q_idx(4)
            if allsounds(k).category == allsounds(q_idx(2)).category
                allsounds(k).coherent = 1;
                
            else
                allsounds(k).coherent = 0;
            end
        end
        for k = q_idx(4)+1:q_idx(5)
            if allsounds(k).category == allsounds(q_idx(2)).category
                allsounds(k).coherent = 1;
                
            else
                allsounds(k).coherent = 0;
            end
        end
        for k = q_idx(5)+1:q_idx(6)
            if allsounds(k).category == allsounds(q_idx(2)).category
                allsounds(k).coherent = 1;
                
            else
                allsounds(k).coherent = 0;
            end
        end
        for k = q_idx(6)+1:q_idx(7)
            if allsounds(k).category == allsounds(q_idx(2)).category
                allsounds(k).coherent = 1;
                
            else
                allsounds(k).coherent = 0;
            end
        end
        for k = q_idx(7)+1:q_idx(8)
            if allsounds(k).category == allsounds(q_idx(2)).category
                allsounds(k).coherent = 1;
                
            else
                allsounds(k).coherent = 0;
            end
        end
        for k = q_idx(8)+1:q_idx(9)
            if allsounds(k).category == allsounds(q_idx(2)).category
                allsounds(k).coherent = 1;
                
            else
                allsounds(k).coherent = 0;
            end
        end
        for k = q_idx(9)+1:q_idx(10)
            if allsounds(k).category == allsounds(q_idx(2)).category
                allsounds(k).coherent = 1;
                
            else
                allsounds(k).coherent = 0;
            end
        end
        for k = q_idx(10)+1:q_idx(11)
            if allsounds(k).category == allsounds(q_idx(2)).category
                allsounds(k).coherent = 1;
                
            else
                allsounds(k).coherent = 0;
            end
        end
        for k = q_idx(11)+1:q_idx(12)
            if allsounds(k).category == allsounds(q_idx(2)).category
                allsounds(k).coherent = 1;
                
            else
                allsounds(k).coherent = 0;
            end
        end
        for k = q_idx(12)+1:q_idx(13)
            if allsounds(k).category == allsounds(q_idx(2)).category
                allsounds(k).coherent = 1;
                
            else
                allsounds(k).coherent = 0;
            end
        end
        for k = q_idx(13)+1:q_idx(14)
            if allsounds(k).category == allsounds(q_idx(2)).category
                allsounds(k).coherent = 1;
                
            else
                allsounds(k).coherent = 0;
            end
        end
         for k = q_idx(14)+1:q_idx(15)
            if allsounds(k).category == allsounds(q_idx(2)).category
                allsounds(k).coherent = 1;
                
            else
                allsounds(k).coherent = 0;
            end
        end
        for k = q_idx(15)+1:length(allsounds)
            if allsounds(k).category == allsounds(q_idx(2)).category
                allsounds(k).coherent = 1;
                
            else
                allsounds(k).coherent = 0;
            end
        end
        
        if allsounds(l).target == 1 && allsounds(l).coherent == 1
            if allsounds(l).side == 1
                allsounds(l).response = 42;
            elseif allsounds(l).side == 9
                allsounds(l).response = 45;
            end
        elseif allsounds(l).target == 1 && allsounds(l).coherent == 0
            if allsounds(l).side == 1
                allsounds(l).response = 45;
            elseif allsounds(l).side == 9
                allsounds(l).response = 42;
            end
        elseif allsounds(l).target == 0
            allsounds(l).response = 0;            
        end
    end
