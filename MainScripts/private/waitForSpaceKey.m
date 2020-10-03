function waitForSpaceKey
spaceKey = KbName('space'); escKey = KbName('ESCAPE');
[keyIsDown, secs, keyCode] = KbCheck;
while keyIsDown
    [keyIsDown, secs, keyCode] = KbCheck;
end
while true
    [keyIsDown, secs, keyCode] = KbCheck;
    if keyIsDown
        if keyCode(spaceKey)
            break ;
        elseif keyCode(escKey)
            ShowCursor;
            fclose(outfile);
            Screen('CloseAll');
            return;
        end
    end
end
end