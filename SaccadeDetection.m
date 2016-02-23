function S = SaccadeDetection(TestName,PatientName,Method)

global X SampleRate FixationTime

I = Eye(TestName,PatientName);
I.LoadEyeFlag = true;
I.LoadPreProcessedEye;
if isfield(I.StimulusObject.S,'FixationTimeMin')
    FixationTime = I.StimulusObject.S.FixationTimeMin;
elseif isfield(I.StimulusObject.S,'FixationTimeMin_noDots')
    FixationTime = I.StimulusObject.S.FixationTimeMin_noDots;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SampleRate = 0.001;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


X = I.PreProcessedEye.EyePreProcessed.Xtrunc;
NumConditions = size(X,1);
NumTrials = size(X,2);

% Selecting bad trials


switch Method
    case 'manual'
        
        S = DoManualSaccadeDetection(TestName,PatientName);
        
    case 'automatic'
        
        S = DoAutomaticSaccadeDetection(TestName,PatientName);
        
    case 'semi-automatic'
        S = DoAutomaticSaccadeDetection(TestName,PatientName);
        for c = 1:NumConditions
            for tr = 1:NumTrials
                if ~isnan(S(c,tr,3)) && S(c,tr,3)~=inf
                    figure(1);plot(squeeze(X(c,tr,:))','--k');hold on;plot(S(c,tr,2),X(c,tr,round(S(c,tr,2))),'+r');title(['Initiation - trial ',num2str(tr),' condition ',num2str(c)])
                    [t_init,x_init] = ginput(1);
                    close 1
                    figure(2);plot(squeeze(X(c,tr,:))','--k');hold on;plot(S(c,tr,3),X(c,tr,round(S(c,tr,3))),'+r');title('End')
                    [t_end,x_end] = ginput(1); 
                    close 2
                    if ~isempty(t_init)
                        S(c,tr,2) = t_init;
                    elseif ~isempty(t_end)
                        S(c,tr,3) = t_end;
                    end
                    
                    S(c,tr,1) = abs(X(c,tr,round(S(c,tr,3))) - X(c,tr,round(S(c,tr,2))));
                        
                end
            end
        end
        
        
end
end

function S = DoManualSaccadeDetection(TestName,PatientName)
global X
NumConditions = size(X,1);
NumTrials = size(X,2);
S = nan(NumConditions,NumTrials,3);


ToRemoveList = RemoveBadTrials(TestName,PatientName);
for c = 1:NumConditions
            ThisBadTrials = ToRemoveList{c};
            for tr = 1:NumTrials
                x = squeeze(X(c,tr,:));
                if sum(ThisBadTrials == tr) == 0
                    plot(x,'r');hold on
                    title(['set the beginning of the saccade (cond ', num2str(c),' trial ', num2str(tr) ':'])
                    [t_init,x_init] = ginput(1);
                    plot(t_init,x_init,'*k');
                    title(['set the end of the saccade (cond ', num2str(c),' trial ', num2str(tr) ':'])
                    [t_end,x_end] = ginput(1);
                    plot(t_end,x_end,'*k');
                    pause(0.1);close
                else
                    t_init= [];
                    x_init = [];
                    t_end = [];
                    x_end = [];
                    
                    if ~isempty(t_init)
                        SaccadeAmplitude = abs(x_end - x_init);
                        SaccadeInitiationTime = t_init;
                        SaccadeEndTime = t_end;
                        clear x_end x_init t_init t_end
                        S(c,tr,1) = SaccadeAmplitude;
                        S(c,tr,2) = SaccadeInitiationTime;
                        S(c,tr,3) = SaccadeEndTime;
                    else
                        S(c,tr,1) = nan;
                        S(c,tr,2) = nan;
                        S(c,tr,3) = nan;
                    end
                end
            end
end
        
end

function S = DoAutomaticSaccadeDetection(TestName,PatientName)

global X SampleRate FixationTime
NumConditions = size(X,1);
NumTrials = size(X,2);
S = nan(NumConditions,NumTrials,3);


ToRemoveList = RemoveBadTrials(TestName,PatientName);

for c = 1:NumConditions
    ThisBadTrials = ToRemoveList{c};
    for tr = 1:NumTrials
        x = squeeze(X(c,tr,:));
        if sum(ThisBadTrials == tr) == 0
            if sum(isnan(x)) > 0
                for i = 1:length(x)
                    if isnan(x(i)) && i>1
                        x(i) = x(i-1);
                    elseif isnan(x(i)) && i==1
                        x(i) = 0;
                    end
                end
            end
            %                 try
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
            SEtimesLate = SEtimes((SEtimes - FixationTime) > 700);
            SItimesEarly = SItimes((SItimes - FixationTime) < 100);
            SEtimesEarly = SEtimes((SEtimes - FixationTime) < 200);
            SItimesInit = SItimes((SItimes - FixationTime) <= 600 & (SItimes - FixationTime) >= 100);
            SEtimesInit = SEtimes((SEtimes - FixationTime) <= 700 & (SEtimes - FixationTime) >= 100);
            if isempty(SItimesInit) || isempty(SEtimesInit)
                SaccadeEndTime = inf;
                SaccadeInitiationTime = inf;
                SaccadeAmplitude = 0;
                S(c,tr,1) = SaccadeAmplitude;
                S(c,tr,2) = SaccadeMidWay - 20;%SaccadeInitiationTime;
                S(c,tr,3) = SaccadeMidWay + 40;%SaccadeEndTime;
            else
                [~, idx1] = max(a(SItimesInit));
                SaccadeInitiationTime = SItimesInit(idx1);
                [~, idx2] = min(a(SEtimesInit));
                SaccadeEndTime = SEtimesInit(idx2);
                
                % (2) Slow Initial Saccades
%                 if (SaccadeEndTime - SaccadeInitiationTime) > 75
%                     SaccadeEndTime = inf;
%                     SaccadeInitiationTime = inf;
%                     
%                 end
                % (3) Saccades too close (< 60 ms)
                % not coded yet!!
                %
                SaccadeMidWay = (SaccadeInitiationTime + SaccadeEndTime)./2;
                if SaccadeEndTime~=inf
                    SaccadeAmplitude = abs(x(SaccadeEndTime) - x(SaccadeInitiationTime));
                else
                    SaccadeAmplitude =0;
                end
                S(c,tr,1) = SaccadeAmplitude;
                S(c,tr,2) = SaccadeMidWay - 20;%SaccadeInitiationTime;
                S(c,tr,3) = SaccadeMidWay + 40;%SaccadeEndTime;
            end
            
            
            
            if isnan(S(c,tr,2))
                figure;
                subplot(2,2,1);plot(a,'--k');hold on;plot(S(c,tr,2),a(S(c,tr,2)),'+b');plot(S(c,tr,3),a(S(c,tr,3)),'+r')
                subplot(2,2,2);plot(v,'--k');hold on;plot(S(c,tr,2),v(S(c,tr,2)),'+b');plot(S(c,tr,3),v(S(c,tr,3)),'+r')
                subplot(2,2,3);plot(x,'--k');hold on;plot(S(c,tr,2),x(S(c,tr,2)),'+b');plot(S(c,tr,3),x(S(c,tr,3)),'+r')
                pause
                close all
            end
            %                 catch
            %                     figure;plot(a);
            %                     figure;plot(v);
            %                     figure;plot(x);
            %                     pause;close all
            %               end
        else
            S(c,tr,1) = nan;
            S(c,tr,2) = nan;
            S(c,tr,3) = nan;
        end
    end
    
end
end

function ToRemoveList = RemoveBadTrials(TestName,PatientName)

I = Eye(TestName,PatientName);
I.LoadEyeFlag = true;
I.LoadPreProcessedEye;
if isfield(I.StimulusObject.S,'FixationTimeMin')
    FixationTime = I.StimulusObject.S.FixationTimeMin;
elseif isfield(I.StimulusObject.S,'FixationTimeMin_noDots')
    FixationTime = I.StimulusObject.S.FixationTimeMin_noDots;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SampleRate = 0.001;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

X = I.PreProcessedEye.EyePreProcessed.Xtrunc;


NumConditions = size(X,1);
NumTrials = size(X,2);
ToRemoveList = cell(1,NumConditions);
for c = 1:NumConditions
    figure('units','normalized','outerposition',[0 0 1 1])
    for tr = 1:NumTrials
        
        subplot(ceil(sqrt(NumTrials)),ceil(sqrt(NumTrials)),tr);
        plot(squeeze(X(c,tr,1000:1700)));title(num2str(tr));
    
    end
    ToRemove = inputdlg('Enter the trials to remove');
    ToRemoveList{c} = str2num(ToRemove{1});
    close
end

end