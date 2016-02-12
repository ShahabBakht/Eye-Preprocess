%% Load X data
X = I.PreProcessedEye.EyePreProcessed.Xtrunc;

%% Automatic Saccade Detection
S = SaccadeDetection(TestName,PatientName,'automatic');

%% Show the detected saccades overlapped on the X data
NumConditions = I.StimulusObject.S.NumConditions;
NumTrials = I.StimulusObject.S.NumTrials;

for c = 1:NumConditions
    for tr = 1:NumTrials
        if ~isnan(S(c,tr,3))
%             figure(1);plot(squeeze(X(c,tr,:))','--k');hold on;plot(S(c,tr,3),X(c,tr,round(S(c,tr,3))),'+b');hold on;plot(S(c,tr,2),X(c,tr,round(S(c,tr,2))),'+r')
%             pause
%             close 1
        end
    end
end

%% Contrast sensitivity of the raction time
figure(2);
plot(repmat(2.^(2:0.5:4),NumTrials,1)',1./squeeze(S([1:2:9],:,3)),'+r');hold on
plot(repmat(2.^(2:0.5:4),NumTrials,1)',1./squeeze(S([2:2:10],:,3)),'+b');
title('Reaction Time Contrast Sensitivity');
xlabel('%Contrast');ylabel('Inverse Reaction Time (1/ms)')
grid on

%% Estimate Velocity
PostSaccadeEnd = 150;
PostSaccadeBegin = 40;

for c = 1:NumConditions
    for tr = 1:NumTrials
        if ~isnan(S(c,tr,3))
        V(c,tr) = abs(X(c,tr,round(S(c,tr,3))+PostSaccadeEnd) - X(c,tr,round(S(c,tr,3))+PostSaccadeBegin))./((PostSaccadeEnd - PostSaccadeBegin)./1000);
%         figure(3);plot(round(S(c,tr,3))+PostSaccadeBegin:round(S(c,tr,3))+PostSaccadeEnd,squeeze(X(c,tr,round(S(c,tr,3))+PostSaccadeBegin:round(S(c,tr,3))+PostSaccadeEnd))','r','LineWidth',2);hold on;plot(squeeze(X(c,tr,:))','--k');pause;close 3
        else
            V(c,tr) = nan;
        end
    end
end

%% Contrast senesitivity of the post-saccadic pursuit gain
figure (4);
plot(repmat(2.^(2:0.5:4),NumTrials,1)',V([1:2:9],:)./20,'+r');hold on;
plot(repmat(2.^(2:0.5:4),NumTrials,1)',V([2:2:10],:)./20,'+b');hold on
title('Post-saccadic Pursuit Gain Contrast Sensitivity');
xlabel('%Contrast');ylabel('Gain')
grid on
