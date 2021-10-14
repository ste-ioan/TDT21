function [new_point,size_point,newdrawpoint] = makeRandomGrid(length,X,Y,x,screenrect,targetpos,quadrant,angle,center)


%%%%%%%%%%%% RANDOMIZING COORDINATES MATRIX (entire grid) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%add jitter to the raw, scaled coordinates
RandomMatrix1 = (rand(19,19)*length/2) - (length/4);
RandomMatrix2 = (rand(19,19)*length/2) - (length/4);
XR = X + RandomMatrix1;
YR = Y + RandomMatrix2;

%Split in four coordinates and add length to the line (only the x-coordinates)
%We need four coordinates to draw each lines in the grid
x1 = XR-(0.5*length); %start X coordinate of each line, subtract half of the line lenght
x2 = XR+(0.5*length); %end X coordinate of each line, add half of the line length
y1 = YR; %start Y coordinate of each line
y2 = YR; %end Y coordinate of each line

%Reshape each 19x19 coordinate matrix into on 4x361 coordinate matrix where
%each column contains the four coordinates for a line (for all 361 cells in the grid)
numDots = numel(x);
PositionMatrix = [reshape(x1, 1, numDots); reshape(y1, 1, numDots); reshape(x2, 1, numDots); reshape(y1, 1, numDots)];
b = PositionMatrix; %4x361 matrix;

% centering each of the four coordinates
b(1,:) = PositionMatrix(1,:) + (screenrect(3)/2); %add half of full x pixels to x1 coordinate (begin of line)
b(3,:) = PositionMatrix(3,:) + (screenrect(3)/2); %add half of full x pixels to x2 coordinate (end of line)
b(2,:) = PositionMatrix(2,:) + (screenrect(4)/2); %add half of full y pixels to y1 cooridnate (begin of line)
b(4,:) = PositionMatrix(4,:) + (screenrect(4)/2); %add half of full y pixels to y1 cooridnate (end of line)

%%%%%%%%%%%%%%%%%%% STIMULI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%DRAW ALL THE OTHER HORIZONTAL LINES (BACKGROUND LINES) + DIAGONAL LINES (TARGET LINES)
point = zeros(numDots,4);
drawpoint = zeros(1,numDots);
for i = 1:numDots
    
    if any (i == targetpos|i==targetpos+1|i==targetpos-1|i==targetpos+19|i==targetpos-19)
        
        DrawQuadrant=false;
        if quadrant==1
            if X(i)>0 && Y(i)<0
                DrawQuadrant=true;
            end
        elseif quadrant==2
            if X(i)<0 && Y(i)<0
                DrawQuadrant=true;
            end
        elseif quadrant==3
            if X(i)<0 && Y(i)>0
                DrawQuadrant=true;
            end
        elseif quadrant==4
            if X(i)>0 && Y(i)>0
                DrawQuadrant=true;
            end
        end
        
        %change orientation
        if angle == 1
            theta = pi/4; %45�
        elseif angle == 2
            theta = pi/-4; %135�
        end
        cs = cos(theta);
        sn = sin(theta);
        
        bx1 = -length/2;
        by1 = 0;
        
        bx2 = length/2;
        by2 = 0;
        
        rbx1 = bx1 * cs - by1 * sn;
        rby1 = bx1 * sn + by1 * cs;
        
        rbx2 = bx2 * cs - by2 * sn;
        rby2 = bx2 * sn + by2 * cs;
        
        if DrawQuadrant
            point(i,:) = [rbx1+X(i)+center(1)+RandomMatrix1(i),rby1+Y(i)+center(2)+RandomMatrix2(i), rbx2+X(i)+center(1)+RandomMatrix1(i), rby2+Y(i)+center(2)+RandomMatrix2(i)];
        end
        drawpoint(i)=DrawQuadrant;
        
    end
end

%%Variables for drawing lines on grid
value = find(point(:,1)); %indexes x1 values of lines in trgt positions
new_point = point(value,:);%takes whole coordinates
size_point = size(new_point);%size of these coordinates
newdrawpoint = drawpoint(value);% ?? no idea

end

