function [responseTime,keyCode] = checkKey(taskKeyCodes)
persistent keyPressed
if isempty(keyPressed)
    keyPressed = false;
end

escKey = KbName('ESCAPE');
[keyIsDown, secs, keyCode] = KbCheck;
responseTime=NaN;
if ~keyPressed && keyIsDown
    keyPressed = true;
    if any(keyCode(taskKeyCodes))
        responseTime = GetSecs;
    elseif keyCode(escKey)
        psychFinish
        return;
    end
elseif keyPressed && ~keyIsDown
    keyPressed = false;
end
end