%% Set the Experiment Information Here

TestName        =   '15070604';
PatientName     =   'Jubinville';

%% What do you want to do?
ToDo = struct(...
    'preprocess', 0, ...
    'load', 1, ...
    'show', 0 ...
    );

%%
I = Eye(TestName,PatientName);

if ToDo.preprocess
    I.DoEyePreProcess;
end
if ToDo.load
    I.LoadEyeFlag = true;
    I.LoadPreProcessedEye;
end

if ToDo.show
    I.ShowEye;
end
