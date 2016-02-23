%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% x = x0    0 =< t < T1
% x = (1/2) * a0 * t ^ 2 + x0   T1 =< t < T2
% x = (a0 * T2) * t + (1/2) * a0 * T2 ^ 2 + x0  t >= T2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function x = SmoothHinge(param,T)
x0 = param(1);
T1 = param(2);
a0 = param(3);
T2 = param(4);

for i = 1:length(T)
    
    if T(i) < T1 && T(i) >= 0
        x(i) = x0;
    elseif T(i) >= T1 && T(i) < T2
        x(i) = 0.5 * a0 * (T(i) - T1)^2 + x0;
    elseif T(i) >= T2
        x(i) = (a0 * (T2 - T1)) * (T(i) - T2) + 0.5 * a0 * (T2 - T1)^2 + x0;      
    end
end

end