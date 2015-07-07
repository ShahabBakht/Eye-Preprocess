%% Basic Parameters
% set these parameters carefully.

winWidth        =   650;
winHeight       =   700;
PPD_X           =   20;             % Pixels per degree
PPD_Y           =   20;
FixationTimeMin =   1000;
FixationTimeMax =   1500;
TestName        =   '15070608';
PatientName     =   'Jubinville';

%% ASCII File Information
filename = ['D:\Data\Eye Tracking\Patients\',PatientName,'\Eye Data\' TestName '.asc'];
SaveLocation = ['D:\Data\Eye Tracking\Patients\',PatientName,'\Eye Data\EyePreProcessed\'];
delimiter = '\t';
formatSpec = '%s%s%s%*s%*s%*s%*s%*s%*s%[^\n\r]';


%% Read ASCII
fprintf('######################################################################################## \n')
fprintf(['Loading Data ' TestName ' ... '])
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);
fclose(fileID);

VarName1 = dataArray{:, 1};
VarName2 = dataArray{:, 2};
VarName3 = dataArray{:, 3};

%% Cut Data and make the Trigger signal -- Trigger signals the start of an event
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
     
%% Align Data
fprintf(['Align to the Trigger ... '])

for i = 1:length(X)
    Tr = Trigger{i}(:);
    Xnotrig = X{i}(:);
    Ynotrig = Y{i}(:);
    I = find(Tr);
    NumCutSamples = I - FixationTimeMin;
    Xtrig{i} = Xnotrig(NumCutSamples:end); 
    LX(i) = length(Xnotrig(NumCutSamples:end));
    Ytrig{i} = Ynotrig(NumCutSamples:end);
    LY(i) = length(Ynotrig(NumCutSamples:end));
    clear Tr Xnotrig Ynotrig I NumCutSamples
end

%% Cut to conditions
fprintf(['Cut to Conditions ... '])
StimulusObjectDir = ['D:\Data\Eye Tracking\Patients\',PatientName,'\Stimulus Object\'];
StimulusObject = load([StimulusObjectDir '\' TestName]);
StimulusOrder = StimulusObject.S.order;
NumConditions = length(StimulusObject.S.type);
NumTrials = floor(max(StimulusObject.S.order)./NumConditions);
TrialsLabels = reshape(1:max(StimulusObject.S.order),NumTrials,NumConditions);
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

%% Save to file
fprintf(['Save to File ... '])
EyePreProcessed.X = Xtc;EyePreProcessed.Y = Ytc;
EyePreProcessed.Xtrunc = XtcTrunc;EyePreProcessed.Ytrunc = YtcTrunc;

save([SaveLocation '\EyePreProcessed_' TestName],'EyePreProcessed'); 
fprintf('\n######################################################################################## \n')
clear all;


