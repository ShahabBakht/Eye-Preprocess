function S = SaccadeDetection(TestName,PatientName,Method)

I = Eye(TestName,PatientName);
I.LoadEyeFlag = true;
I.LoadPreProcessedEye;
FixationTime = I.StimulusObject.S.FixationTimeMin;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SampleRate = 0.001;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

X = I.PreProcessedEye.EyePreProcessed.Xtrunc;


NumConditions = size(X,1);
NumTrials = size(X,2);
S = nan(NumConditions,NumTrials,3);

switch Method
    case 'manual'
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
        
    case 'automatic'
        
        for c = 1:NumConditions
            for tr = 1:NumTrials
                x = squeeze(X(c,tr,:));
                if sum(isnan(x)) > 0
                    for i = 1:length(x)
                        if isnan(x(i))
                            x(i) = x(i-1);
                        end
                    end
                end
                try
                    [b,a] = butter(6,20*2*SampleRate);
                    xfit = filtfilt(b,a,x);
                    % calculate v and a
                    v = gradient(xfit,SampleRate);
                    a = gradient(v,SampleRate);
                    
                    if max(v) > 0
                        SItimes = find(a > .5e4);
                        SEtimes = find(a < -.5e4);
                    else
                        SItimes = find(a < -.5e4);
                        SEtimes = find(a > +.5e4);
                    end
                    
                    
                    
                    % Groh et al criteria for detecting the initial saccade
                    % (1) Late and Early Saccades
                    SItimesLate = SItimes((SItimes - FixationTime) > 600);
                    SEtimesLate = SEtimes((SItimes - FixationTime) > 600);
                    SItimesEarly = SItimes((SItimes - FixationTime) < 100);
                    SEtimesEarly = SItimes((SItimes - FixationTime) < 100);
                    SItimesInit = SItimes((SItimes - FixationTime) <= 600 & (SItimes - FixationTime) >= 100);
                    SEtimesInit = SEtimes((SItimes - FixationTime) <= 600 & (SItimes - FixationTime) >= 100);
                    
                    [~, idx1] = max(a(SItimesInit));
                    SaccadeInitiationTime = SItimesInit(idx1);
                    [~, idx2] = min(a(SEtimesInit));
                    SaccadeEndTime = SEtimesInit(idx2);
                    
                    % (2) Slow Initial Saccades
                    if (SaccadeEndTime - SaccadeInitiationTime) > 75
                        SaccadeEndTime = nan;
                        SaccadeInitiationTime = nan;
                        SaccadeAmplitude = nan;
                    end
                    % (3) Saccades too close (< 60 ms)
                    % not coded yet!!
                    %
                    SaccadeMidWay = (SaccadeInitiationTime + SaccadeEndTime)./2;
                    SaccadeAmplitude = abs(x(SaccadeEndTime) - x(SaccadeInitiationTime));
                    S(c,tr,1) = SaccadeAmplitude;
                    S(c,tr,2) = SaccadeMidWay - 20;%SaccadeInitiationTime;
                    S(c,tr,3) = SaccadeMidWay + 40;%SaccadeEndTime;
%                     figure;
%                     subplot(2,2,1);plot(a,'--k');hold on;plot(S(c,tr,2),a(S(c,tr,2)),'+b');plot(S(c,tr,3),a(S(c,tr,3)),'+r')
%                     subplot(2,2,2);plot(v,'--k');hold on;plot(S(c,tr,2),v(S(c,tr,2)),'+b');plot(S(c,tr,3),v(S(c,tr,3)),'+r')
%                     subplot(2,2,3);plot(x,'--k');hold on;plot(S(c,tr,2),x(S(c,tr,2)),'+b');plot(S(c,tr,3),x(S(c,tr,3)),'+r')
%                     pause
%                     close all
                catch
%                     figure;plot(a);
%                     figure;plot(v);
%                     figure;plot(x);
%                     pause;close all
                end
            end
            
        end
        
        
        
        
end
end