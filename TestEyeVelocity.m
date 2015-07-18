
x = squeeze(X(1,7,:));
f1 = 50;
sr = 1000;
[b,a]=ellip(5,0.1,40,f1*2/(sr),'low');
xf=filtfilt(b,a,x);

q = 5;
xdata = iddata(xf,[],0.001);
xdataR = resample(xdata,1,q,5);
x = xdataR.OutputData;
fmax_detect = 10;
sr = 1000/q;

[b,a]=ellip(5,0.1,40,fmax_detect*2/(sr),'low');

xf=filtfilt(b,a,x);
% xr = decimate(x,10,'fir');
% xr = resample(xr,2,1);
% [b,a]=butter(1,fmax_detect*2/sr,'low');
% [b,a] = ellip(8,5,40,fmax_detect*2/sr,'low');
% freqz(b,a)
% [b,a] = besself(20,fmax_detect*2/(sr/1));

v = gradient(xf,1/sr);
vf=filtfilt(b,a,v);



