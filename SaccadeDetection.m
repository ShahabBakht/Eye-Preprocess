function S = SaccadeDetection(TestName,PatientName)

I = Eye(TestName,PatientName);
I.LoadEyeFlag = true;
I.LoadPreProcessedEye;

X = I.PreProcessedEye.EyePreProcessed.Xtrunc;

NumConditions = size(X,1);
NumTrials = size(X,2);
S = nan(NumConditions,NumTrials,3);

for c = 1:NumConditions
    for tr = 1:NumTrials
        x = squeeze(X(c,tr,:));
        plot(x,'r');hold on
        title(['set the beginning of the saccade (cond ', num2str(c),' trial ', num2str(tr) ':'])
        [t_init,x_init] = ginput(1);
        plot(t_init,x_init,'*k');
        title(['set the end of the saccade (cond ', num2str(c),' trial ', num2str(tr) ':'])
        [t_end,x_end] = ginput(1);
        plot(t_end,x_end,'*k');
        pause(0.1);close
        if ~isempty(t_init)
            SaccadeAmplitude = abs(x_end - x_init);
            SaccadeInitiationTime = t_init;
            SaccadeEndTime = t_end;
            clear x_end x_init t_init t_end
            S(c,tr,1) = SaccadeAmplitude;
            S(c,tr,2) = SaccadeInitiationTime;
            S(c,tr,3) = SaccadeEndTime;
            
        end
    end
end


end