function [new_point,size_point] = jitteringForLocalizer(length,X,Y,x,targetpos,center,orientation,resolution)

%add jitter to the raw, scaled coordinates
    RandomMatrix1 = (rand(size(X))*length/2) - (length/4);
    RandomMatrix2 = (rand(size(X))*length/2) - (length/4);
    XR = X + RandomMatrix1;
    YR = Y + RandomMatrix2;
    
    %Split in four coordinates and add length to the line (only the x-coordinates)
    %We need four coordinates to draw each lines in the grid
    
    % we add jitter to the horizontal background lines to make task
    % tougher since we only have 2 target locations (one per quadrant)
    jitterRange = pi/6; % smaller the divider, greater the eccentricity
    theta = -(jitterRange/2)+(rand(size(XR))*jitterRange);
    cs = cos(theta);
    sn = sin(theta);
    
    x1 = XR - (length/2)*cs;
    x2 = XR + (length/2)*cs;
    y1 = YR - (length/2)*sn;
    y2 = YR + (length/2)*sn;
    
    %Reshape each 19x19 coordinate matrix into on 4x361 coordinate matrix where
    %each column contains the four coordinates for a line (for all 361 cells in the grid)
    numDots = numel(x);
    PositionMatrix = [reshape(x1, 1, numDots); reshape(y1, 1, numDots); reshape(x2, 1, numDots); reshape(y2, 1, numDots)];
    b = PositionMatrix; %4x361 matrix;
    
    % centering each of the four coordinates
    b(1,:) = PositionMatrix(1,:) + (resolution(1)/2); %add half of full x pixels to x1 coordinate (begin of line)
    b(3,:) = PositionMatrix(3,:) + (resolution(1)/2); %add half of full x pixels to x2 coordinate (end of line)
    b(2,:) = PositionMatrix(2,:) + (resolution(2)/2); %add half of full y pixels to y1 cooridnate (begin of line)
    b(4,:) = PositionMatrix(4,:) + (resolution(2)/2); %add half of full y pixels to y1 cooridnate (end of line)
    
    
    %DRAW ALL THE OTHER HORIZONTAL LINES (BACKGROUND LINES) + DIAGONAL LINES (TARGET LINES)
    point = zeros(numDots,4);
    drawpoint = zeros(1,numDots);
    for i = 1:numDots
        
        if any (i == targetpos)
            %change orientation
            if orientation == 1
                theta = pi/4; %45
            elseif orientation == 2
                theta = pi/-4; %135
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
            
            point(i,:) = [rbx1+X(i)+center(1)+RandomMatrix1(i),rby1+Y(i)+center(2)+RandomMatrix2(i), rbx2+X(i)+center(1)+RandomMatrix1(i), rby2+Y(i)+center(2)+RandomMatrix2(i)];
        end
    end
    
    value = find(point(:,1)); %indexes x1 values of lines in trgt positions
    new_point = point(value,:);%takes whole coordinates
    size_point = size(new_point);%size of these coordinates