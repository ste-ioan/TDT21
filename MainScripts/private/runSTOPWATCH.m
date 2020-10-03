function stopTrial = runSTOPWATCH(tt0,firstFrame,opt)
global wPtr
persistent screenOnsets response

%%%%%% stpwatch params %%%%%%%%%%%%%%
screen_size = Screen('Resolution',wPtr); % red rectangle in the center
center_poz = [screen_size.width/4 screen_size.height/2];
size_rect = [center_poz(1)-50 center_poz(2)-10 center_poz(1)+50 center_poz(2)+20];
stpwtchFreq = 8;
col = [255 255 255];
timings = [0.450 7];
size_rect = size_rect;
keyCode =  KbName('space');
delayPostResponse = 1000;

s = GetSecs;
if firstFrame
    screenOnsets = [];
    response = struct;
end
stopTrial = false;

if s-tt0 <= timings(1)
    if length(screenOnsets)<1
        screenOnsets(1) = s;
    end
    DrawFormattedText(wPtr, '+', 'center', 'center', [255 255 255]);
elseif s-tt0 <= timings(2) && ~isfield(response,'time')
    if length(screenOnsets)<2
        screenOnsets(2) = s;
    end
    Screen(wPtr,'FrameRect',[255 0 0], size_rect);
    rt = (s-screenOnsets(2))*1000;
    DrawFormattedText(wPtr,num2str(round(rt)) ,'center','center',[255 255 0]);
    
    %%response
    [responseTime,keyCode] = checkKey(keyCode);
    if ~isnan(responseTime)
        response.time = responseTime;
        response.rt = rt;
        response.key = keyCode;
        if rt > 4900 && rt < 5100
            %Beeper('high',0.5,0.25);
            response.correct = 1;
        else
            %Beeper('low', 0.5, 0.25);
            response.correct = 0;
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif ~isfield(response,'time') % timeout passed
    if length(screenOnsets)<3
        screenOnsets(3) = s;
    end
    %Beeper('low', 0.5, 0.25);
    response.time = screenOnsets(3);
    response.rt = NaN;
    response.key = NaN;
    response.correct = 0;
    DrawFormattedText(wPtr, '+', 'center', 'center', [255 0 0]);
elseif isfield(response,'time') && ((s-response.time)*1000 <= delayPostResponse)
    if length(screenOnsets)<3
        screenOnsets(4) = s;
    end
    if response.correct
        DrawFormattedText(wPtr, '+', 'center', 'center', [0 255 0]);
    else
        DrawFormattedText(wPtr, '+', 'center', 'center', [255 0 0]);
    end
else
    stopTrial = true;
    assignin('caller','response',response)
    assignin('caller','screenOnsets',screenOnsets)
end
end
