%% Set the Experiment Information Here

TestName        =   '15072204';
PatientName     =   'Test';

%% What do you want to do?                                                                                                                                                                                                                   
ToDo = struct(...
    'preprocess', 0, ...    % for converting, cutting, and triggering the eye traces
    'load', 1, ...          % for loading the preprocessed data   
    'show', 0, ...          % for displaying the eye traces 
    'velocity', 0 ...       % for computing the velocity from the eye traces
    );

%%
I = Eye(TestName,PatientName);

if ToDo.preprocess
    I.DoEyePreProcess;
end

if ToDo.velocity
    I.ComputeEyeVelocity;
end

if ToDo.load
    I.LoadEyeFlag = true;
    I.LoadPreProcessedEye;
end

if ToDo.show
    I.ShowEye;
end