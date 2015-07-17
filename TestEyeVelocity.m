fmax_detect = 25;
sr = 1000;
x = squeeze(X(1,2,:));
xr = resample(x,1,2);
[b,a]=ellip(2,0.1,40,fmax_detect*2/sr/2,'low');
% [b,a]=butter(10,fmax_detect*2/sr,'low');
% [b,a] = besself(4,fmax_detect*2/(sr/2));
xf=filtfilt(b,a,xr);
v = gradient(xf,0.002);
plot(v)
plot(0:1/(sr/2):(length(v)-1)/(sr/2),v);
hold on;
plot(0:1/(sr/2):(length(v)-1)/(sr/2),xf)