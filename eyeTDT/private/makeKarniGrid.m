function [X,Y,sizeline,x,masklength]=makeKarniGrid(Distance)
global wPtr
%%%%%%% CONSTRUCT COORDINATE MATRIX AND SCALE RELATIVE TO KARNI'S DESIGN %%
% make a 19 by 19 grid centered on 0
dim = 9; % dimensions of the grid in each direction excluding center (leading to a 19x19 matrix)
[x,y] = meshgrid (-dim:1:dim,-dim:1:dim);

% make a scaling variable: rescale these raw grid coordinates to screen coordinates
% use the vertical length to calculate this(screenrect(4))
% we use vertical length because usually height<width with displays and thus the grid
% cannot be larger than the height
screenrect=Screen('Rect',wPtr);
pixelScale = screenrect(4) / (dim * 2 + 2); % vertical length divided by 20 (19 and one cell extra for spacing at the border of the screen)
[width, height]=Screen('DisplaySize', 0);
Screenheight = height/10;%cm
if nargin<1
Distance = 70;%cm
end

% pixelScale is now the amount of pixels between cells of the grid
% now we need another scaling variable to make the scale comparable to
% Karni's design. The pixelScale is also actually the spacing of the lines
% in Karni's design. It was reported that lines were 0.70� spaced apart.
% Note: 0.70� * 20 = 14� = the angle of the total display in Karni

VisualangleScreenheight = 2*atand(Screenheight/(2*Distance)); %this is the amount of visual angles the whole height of the screen currently takes
pixelperangle = VisualangleScreenheight/screenrect(4); % the amount of pixels per angle
KarnipixelScale = 0.70; %the scale that we want to achieve
pixelScale2angle = pixelScale*pixelperangle; %the scale that we currently have
Factor = KarnipixelScale/pixelScale2angle;
pixelScale = pixelScale*Factor;% Finally multiply the pixelscale with the factor. Now the stimulus grid should be the same size as in Karni (14�)

% to achieve same relative length of lines as Karni a fixed factor of 0.6 was calculated
% In Karni the points in the grid are spaced 0.70� apart in a total display
% of 14 by 14�
% (0.70�*20(19cells+1)= 14� of visual display)
% This spacing between points is here the pixelScale
% The lines themselves were 0.42
% => 0.70 * 0.6 = 0.42 and 0.70 * 0.5 = 0.35 for the mask stimuli
% in this way the length will scale along with the display size
length = pixelScale * 0.6;
masklength = pixelScale * 0.5;


% Now multiply by our simple meshgrid to get the final true coordinates
X = x .* pixelScale;
Y = y .* pixelScale;

%%%%%%% VISUAL ANGLE OF STIMULI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Because of previous calculation, the stimuli will be scaled according to the information
%%% about your setup (screen height, distance from screen) and the Scaling factors implemented here above
%%% So, even on different set-ups the stimuli should be the same amount of
%%% visual angles as in Karni's design. Always fill in the screenheight and
%%% distance in the login prompt correctly though!!

Visualangleheight = 2*atand(Screenheight/(2*Distance));
pixelperangle = Visualangleheight/screenrect(4);
%size of the grid with stimuli in angles
sizegrid = pixelScale*20;
sizegrid2angle = sizegrid*pixelperangle;
%size of the horizontal lines in angles
sizeline = length;
sizeline2angle = sizeline*pixelperangle;
%size of the spaces between lines in angles
sizespace = pixelScale;
sizespace2angle = sizespace*pixelperangle;
%average eccentricity of the target in angles
sizetargeteccx = pixelScale * 6;
sizetargeteccx2angle= sizetargeteccx*pixelperangle;
end