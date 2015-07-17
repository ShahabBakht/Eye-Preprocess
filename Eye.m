classdef Eye < handle
    
    properties
        TestName
        PatientName
        RawEyeFile      % address to the location of the raw file
        PreProcessFile  % address to the location of the preprocessed file
        PreProcessedEye
       	LoadEyeFlag     % true if you want to load the PreProcessedEye
        StimulusObject
        
    end
    
    methods
        function I = Eye(TestName,PatientName)
            
            I.TestName = TestName;
            I.PatientName = PatientName;
            StimulusObjectDir = ['D:\Data\Eye Tracking\Patients\',PatientName,'\Stimulus Object\'];
            I.StimulusObject = load([StimulusObjectDir '\' TestName]);
           	I.RawEyeFile = ['D:\Data\Eye Tracking\Patients\',I.PatientName,'\Eye Data\' I.TestName '.asc'];
            I.PreProcessFile = ['D:\Data\Eye Tracking\Patients\',I.PatientName,'\Eye Data\EyePreProcessed\'];

                      
        end
        
        function DoEyePreProcess(I)
            
            delimiter = '\t';
            formatSpec = '%s%s%s%*s%*s%*s%*s%*s%*s%[^\n\r]';
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % change these two if otherwise
            winWidth        =   650;
            winHeight       =   700;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            PPD_X = I.StimulusObject.S.PPD_X;
            PPD_Y = I.StimulusObject.S.PPD_Y;
            
            if strcmp(I.StimulusObject.S.Type,'RandomDotsPursuit')
                FixationTimeMax = I.StimulusObject.S.FixationTimeMax_noDots + I.StimulusObject.S.FixationTimeMax_withDots;
                FixationTimeMin = I.StimulusObject.S.FixationTimeMin_noDots + I.StimulusObject.S.FixationTimeMin_withDots;
            else
                FixationTimeMax = I.StimulusObject.S.FixationTimeMax;
                FixationTimeMin = I.StimulusObject.S.FixationTimeMin;
            end
            SaveLocation = I.PreProcessFile;
            
            % Read ASCII
            fprintf('######################################################################################## \n')
            fprintf(['Loading Data ' I.TestName ' ... '])
            filename = I.RawEyeFile;
            fileID = fopen(filename,'r');
            dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);
            fclose(fileID);
            
            VarName1 = dataArray{:, 1};
            VarName2 = dataArray{:, 2};
            VarName3 = dataArray{:, 3};
            
            % Cut Data and make the Trigger signal -- Trigger signals the start of an event
            fprintf(['Trigger and Cut ... '])
            
            trialcount = 0;
            StartFlag = false;
            
            for counter = 1:length(VarName1)
                if strcmp(VarName1{counter},'START')    % If the trial has began:
                    StartTime = str2double(VarName2{counter});
                    Time = StartTime;
                    trialcount = trialcount + 1;
                    n = 0;
                    StartFlag = true;   % this flag shows that we are inside a trial.
                    TriggerFlag = true; % this flag shows that we should look for the trigger; when found this will be put to false.
                end
                if strcmp(VarName1{counter},'END')  % If the trial is finished:
                    StartFlag = false;
                end
                
                if StartFlag
                    
                    if str2double(VarName1{counter}) == Time    % collecting eye position
                        n = n + 1;
                        if strcmp(VarName1{counter - 1},'MSG') && strcmp(VarName2{counter - 1},[num2str(Time) ' SYNCTIME']) && TriggerFlag  % looking for the trigger
                            Trigger{trialcount}(n) = 1;TriggerFlag = false;
                        else
                            Trigger{trialcount}(n) = 0;
                        end
                        
                        if isempty(str2double(VarName2{counter}))
                            X{trialcount}(n) = nan;
                        else
                            X{trialcount}(n) = (str2double(VarName2{counter}) - winWidth)./PPD_X;
                        end
                        
                        if isempty(str2double(VarName3{counter}))
                            Y{trialcount}(n) = nan;
                        else
                            Y{trialcount}(n) = (str2double(VarName3{counter}) - winHeight)./PPD_Y;
                        end
                        Time = Time + 1;
                        
                    else
                        continue
                    end
                end
                
            end
            
            % Align Data
            fprintf(['Align to the Trigger ... '])
            
            for i = 1:length(X)
                Tr = Trigger{i}(:);
                Xnotrig = X{i}(:);
                Ynotrig = Y{i}(:);
                Ii = find(Tr);
                NumCutSamples = Ii - FixationTimeMin;
                Xtrig{i} = Xnotrig(NumCutSamples:end);
                LX(i) = length(Xnotrig(NumCutSamples:end));
                Ytrig{i} = Ynotrig(NumCutSamples:end);
                LY(i) = length(Ynotrig(NumCutSamples:end));
                clear Tr Xnotrig Ynotrig Ii NumCutSamples
            end
            
            % Cut to conditions
            fprintf(['Cut to Conditions ... '])
            
            % cutting to conditions is different for different types of
            % stimuli
            if strcmp(I.StimulusObject.S.Type,'StepRamp') || strcmp(I.StimulusObject.S.Type,'RandomDotsPursuit')
                StimulusOrder = I.StimulusObject.S.order;
                NumConditions = length(I.StimulusObject.S.type);
                NumTrials = floor(max(I.StimulusObject.S.order)./NumConditions);
                TrialsLabels = reshape(1:max(I.StimulusObject.S.order),NumTrials,NumConditions);
                Xtc = cell(NumConditions,NumTrials);
                Ytc = cell(NumConditions,NumTrials);
                Lx = zeros(NumConditions,NumTrials);
                Ly = zeros(NumConditions,NumTrials);
                for condcount = 1:NumConditions
                    
                    for trialcount = 1:NumTrials
                        Xtc{condcount,trialcount} = Xtrig{StimulusOrder == TrialsLabels(trialcount,condcount)};
                        Lx(condcount,trialcount) = length(Xtc{condcount,trialcount});
                        Ytc{condcount,trialcount} = Ytrig{StimulusOrder == TrialsLabels(trialcount,condcount)};
                        Ly(condcount,trialcount) = length(Ytc{condcount,trialcount});
                    end
                    
                end
                MinL = min(min([Lx,Ly]));
                XtcTrunc = nan(NumConditions,NumTrials,MinL);
                YtcTrunc = nan(NumConditions,NumTrials,MinL);
                for condcount = 1:NumConditions
                    for trialcount = 1:NumTrials
                        
                        XtcTrunc(condcount,trialcount,:) = Xtc{condcount,trialcount}(1:MinL);
                        YtcTrunc(condcount,trialcount,:) = Ytc{condcount,trialcount}(1:MinL);
                        
                    end
                end
            % ATTENTION!!    
            % For DoubleStepRamp, the cutting to conditions is not coded in the best possible way.
            % Only the simplest case is assumed. The experiment starts with
            % the preLearn condition. preLearn condition is only one
            % condition. Then the Learn condition starts. It only has one
            % condition as well. After all the trials of the Learn
            % condition, the testLearn condition starts. 
            % For more complicated configurations, in order to have this
            % method working, some major modifications are needed.
            
            elseif strcmp(I.StimulusObject.S.Type,'DoubleStepRamp') 
                
                preLearnNumTrials = I.StimulusObject.S.preLearnNumTrials;
                LearnNumTrials = I.StimulusObject.S.LearnNumTrials;
                testLearnNumTrials = I.StimulusObject.S.testLearnNumTrials;
                
                
                Xtrig_preLearn = Xtrig(1,1:preLearnNumTrials);
                Xtrig_Learn = Xtrig((preLearnNumTrials + 1):(preLearnNumTrials + LearnNumTrials));
                Xtrig_testLearn = Xtrig((preLearnNumTrials + LearnNumTrials + 1):(preLearnNumTrials + LearnNumTrials + testLearnNumTrials));
                
                Ytrig_preLearn = Ytrig(1:preLearnNumTrials);
                Ytrig_Learn = Ytrig((preLearnNumTrials + 1):(preLearnNumTrials + LearnNumTrials));
                Ytrig_testLearn = Ytrig((preLearnNumTrials + LearnNumTrials + 1):(preLearnNumTrials + LearnNumTrials + testLearnNumTrials));
                
                
                for tr = 1:preLearnNumTrials
                    Lx(tr) = length(Xtrig_preLearn{tr});
                    Ly(tr) = length(Ytrig_preLearn{tr});
                end
                MinL = min(min([Lx,Ly]));
                Xtrunc_preLearn = zeros(preLearnNumTrials,MinL);
                Ytrunc_preLearn = zeros(preLearnNumTrials,MinL);
                for tr = 1:preLearnNumTrials
                    Xtrunc_preLearn(tr,:) = Xtrig_preLearn{tr}(1:MinL);
                    Ytrunc_preLearn(tr,:) = Ytrig_preLearn{tr}(1:MinL);
                end
                clear Lx Ly MinL;
                for tr = 1:LearnNumTrials
                    Lx(tr) = length(Xtrig_Learn{tr});
                    Ly(tr) = length(Ytrig_Learn{tr});
                end
                MinL = min(min([Lx,Ly]));
                Xtrunc_Learn = zeros(LearnNumTrials,MinL);
                Ytrunc_Learn = zeros(LearnNumTrials,MinL);
                for tr = 1:LearnNumTrials
                    Xtrunc_Learn(tr,:) = Xtrig_Learn{tr}(1:MinL);
                    Ytrunc_Learn(tr,:) = Ytrig_Learn{tr}(1:MinL);
                end
                clear Lx Ly MinL;
                for tr = 1:testLearnNumTrials
                    Lx(tr) = length(Xtrig_testLearn{tr});
                    Ly(tr) = length(Ytrig_testLearn{tr});
                end
                MinL = min(min([Lx,Ly]));
                Xtrunc_testLearn = zeros(testLearnNumTrials,MinL);
                Ytrunc_testLearn = zeros(testLearnNumTrials,MinL);
                for tr = 1:testLearnNumTrials
                    Xtrunc_testLearn(tr,:) = Xtrig_testLearn{tr}(1:MinL);
                    Ytrunc_testLearn(tr,:) = Ytrig_testLearn{tr}(1:MinL);
                end
                
                
            end
            
            % Save to file
            
            % Different variables will be saved to EyePreProcessed in the
            % case of different stimuli.
            if strcmp(I.StimulusObject.S.Type,'StepRamp') || strcmp(I.StimulusObject.S.Type,'RandomDotsPursuit')
                fprintf(['Save to File ... '])
                EyePreProcessed.X = Xtc;EyePreProcessed.Y = Ytc;
                EyePreProcessed.Xtrunc = XtcTrunc;EyePreProcessed.Ytrunc = YtcTrunc;
            elseif strcmp(I.StimulusObject.S.Type,'DoubleStepRamp')
                fprintf(['Save to File ... '])
                
                EyePreProcessed.Xtrunc_preLearn =  Xtrunc_preLearn;
                EyePreProcessed.Ytrunc_preLearn =  Ytrunc_preLearn;
                
                EyePreProcessed.Xtrunc_Learn =  Xtrunc_Learn;
                EyePreProcessed.Ytrunc_Learn =  Ytrunc_Learn;
                
                EyePreProcessed.Xtrunc_testLearn =  Xtrunc_testLearn;
                EyePreProcessed.Ytrunc_testLearn =  Ytrunc_testLearn;
                
            end
            
            save([SaveLocation '\EyePreProcessed_' I.TestName],'EyePreProcessed');
            fprintf('\n######################################################################################## \n')
            
            if I.LoadEyeFlag
                I.PreProcessedEye = EyePreProcessed;
            end

            
        end
        function LoadPreProcessedEye(I)
            
            SaveLocation = I.PreProcessFile;
            if I.LoadEyeFlag
                I.PreProcessedEye = load([SaveLocation, 'EyePreProcessed_',I.TestName, '.mat']);
            else
                error('LoadEyeFlag variable is not set to 1');
            end
            
        end
        
        function ShowEye(I)
            
            Type = I.StimulusObject.S.Type;
            SampleRate = 0.001;
            
            if I.LoadEyeFlag
                switch Type
                    case 'StepRamp'
                        X = I.PreProcessedEye.EyePreProcessed.Xtrunc;
                        Y = I.PreProcessedEye.EyePreProcessed.Ytrunc;
                        NumTimeSamples = length(X);
                        T = 0:SampleRate:(NumTimeSamples - 1)*SampleRate;
                        NumConditions = I.StimulusObject.S.NumConditions;
                        NumTrials = I.StimulusObject.S.NumTrials;
                        for cond = 1:NumConditions
                            
                            figure;
                            subplot(2,1,1);plot(T,squeeze(X(cond,:,:))','Color',[0.5,0.5,0.5]);ylabel('X (degree)');xlabel('time')
                            hold on;
                            subplot(2,1,1);plot(T,squeeze(nanmean(X(cond,:,:),2)),'Color',[1,0,0]);
                            subplot(2,1,2);plot(T,squeeze(Y(cond,:,:))','Color',[0.5,0.5,0.5]);ylabel('Y (degree)');xlabel('time')
                            hold on;
                            subplot(2,1,2);plot(T,squeeze(nanmean(Y(cond,:,:),2)),'Color',[1,0,0]);
                            
                        end
                    case'DoubleStepRamp'
                        X_preLearn = I.PreProcessedEye.EyePreProcessed.Xtrunc_preLearn;
                        NumTimeSamples_preLearn = length(X_preLearn);
                        X_Learn = I.PreProcessedEye.EyePreProcessed.Xtrunc_Learn;
                        NumTimeSamples_Learn = length(X_Learn);
                        X_testLearn = I.PreProcessedEye.EyePreProcessed.Xtrunc_testLearn;
                        NumTimeSamples_testLearn = length(X_testLearn);
                        
                        Y_preLearn = I.PreProcessedEye.EyePreProcessed.Ytrunc_preLearn;
                        Y_Learn = I.PreProcessedEye.EyePreProcessed.Ytrunc_Learn;
                        Y_testLearn = I.PreProcessedEye.EyePreProcessed.Ytrunc_testLearn;
                        
                        T_preLearn = 0:SampleRate:(NumTimeSamples_preLearn - 1)*SampleRate;
                        T_Learn = 0:SampleRate:(NumTimeSamples_Learn - 1)*SampleRate;
                        T_testLearn = 0:SampleRate:(NumTimeSamples_testLearn - 1)*SampleRate;
                        
                        figure;title('preLearn condition');subplot(2,1,1);plot(T_preLearn,X_preLearn,'r');ylabel('X(degree)');xlabel('Time');
                        subplot(2,1,2);plot(T_preLearn,Y_preLearn,'r');ylabel('Y(degree)');xlabel('Time')
                        
                        figure;title('Learn condition');subplot(2,1,1);plot(T_Learn,X_Learn','Color',[0.5,0.5,0.5]);ylabel('X(degree)');xlabel('Time')
                        subplot(2,1,2);plot(T_Learn,Y_Learn','Color',[0.5,0.5,0.5]);ylabel('Y(degree)');xlabel('Time')
                        
                        figure;title('testLearn condition');subplot(2,1,1);plot(T_testLearn,X_testLearn,'b');ylabel('X(degree)');xlabel('Time')
                        subplot(2,1,2);plot(T_testLearn,Y_testLearn,'b');ylabel('Y(degree)');xlabel('Time')
                        
                        
                end
                
            else
                switch Type{1}
                    case 'StepRamp'
                        SaveLocation = I.PreProcessFile;
                        load([SaveLocation, 'EyePreProcessed_',I.TestName, '.mat']);
                        X = EyePreProcessed.Xtrunc;
                        Y = EyePreProcessed.Ytrunc;
                        NumTimeSamples = length(X);
                        T = 0:SampleRate:(NumTimeSamples - 1)*SampleRate;
                        NumConditions = I.StimulusObject.S.NumConditions;
                        NumTrials = I.StimulusObject.S.NumTrials;
                        for cond = 1:NumConditions
                            
                            figure;
                            subplot(2,1,1);plot(T,squeeze(X(cond,:,:))','Color',[0.5,0.5,0.5]);ylabel('X (degree)');xlabel('time')
                            hold on;
                            subplot(2,1,1);plot(T,squeeze(nanmean(X(cond,:,:),2)),'Color',[1,0,0]);
                            subplot(2,1,2);plot(T,squeeze(Y(cond,:,:))','Color',[0.5,0.5,0.5]);ylabel('Y (degree)');xlabel('time')
                            hold on;
                            subplot(2,1,2);plot(T,squeeze(nanmean(Y(cond,:,:),2)),'Color',[1,0,0]);
                            
                        end
                        clear EyePreProcessed
                    case 'DoubleStepRamp'
                        SaveLocation = I.PreProcessFile;
                        load([SaveLocation, 'EyePreProcessed_',I.TestName, '.mat']);
                        X_preLearn = EyePreProcessed.Xtrunc_preLearn;
                        X_Learn = EyePreProcessed.Xtrunc_Learn;
                        X_testLearn = EyePreProcessed.Xtrunc_testLearn;
                        Y_preLearn = EyePreProcessed.Ytrunc_preLearn;
                        Y_Learn = EyePreProcessed.Ytrunc_Learn;
                        Y_testLearn = EyePreProcessed.Ytrunc_testLearn;
                        
                        NumTimeSamples_preLearn = length(X_preLearn);
                        NumTimeSamples_Learn = length(X_Learn);
                        NumTimeSamples_testLearn = length(X_testLearn);
                        
                        T_preLearn = 0:SampleRate:(NumTimeSamples_preLearn - 1)*SampleRate;
                        T_Learn = 0:SampleRate:(NumTimeSamples_Learn - 1)*SampleRate;
                        T_testLearn = 0:SampleRate:(NumTimeSamples_testLearn - 1)*SampleRate;
                        
                        figure;subplot(2,1,1);plot(T_preLearn,X_preLearn,'r');title('preLearn condition');ylabel('X(degree)');xlabel('Time')
                        subplot(2,1,2);plot(T_preLearn,Y_preLearn,'r');ylabel('Y(degree)');xlabel('Time')
                        
                        figure;subplot(2,1,1);plot(T_Learn,X_Learn','Color',[0.5,0.5,0.5]);title('Learn condition');ylabel('X(degree)');xlabel('Time')
                        subplot(2,1,2);plot(T_Learn,Y_Learn','Color',[0.5,0.5,0.5]);ylabel('Y(degree)');xlabel('Time')
                        
                        figure;subplot(2,1,1);plot(T_testLearn,X_testLearn,'b');title('testLearn condition');ylabel('X(degree)');xlabel('Time')
                        subplot(2,1,2);plot(T_testLearn,Y_testLearn,'b');ylabel('Y(degree)');xlabel('Time')
                        
                        clear EyePreProcessed
                end
            end
            
        end
    end
    

end