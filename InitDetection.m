function Tinit = InitDetection(TestName,PatientName)

I = Eye(TestName,PatientName);
I.LoadEyeFlag = true;
I.LoadPreProcessedEye;

X = I.PreProcessedEye.EyePreProcessed.Xtrunc;

NumConditions = size(X,1);
NumTrials = size(X,2);
Tinit = nan(NumConditions,NumTrials,3);

for c = 1:NumConditions
    for tr = 1:NumTrials
        x = squeeze(X(c,tr,1500:2000));
        plot(x,'r');hold on
        title('set the beginning of the pursuit:')
        [t_init,~] = ginput(1);
        pause(0.1);close
        Tinit(c,tr) = t_init;
                
    end
end


end