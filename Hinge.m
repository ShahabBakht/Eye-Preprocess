function h = Hinge(param,T)
a = param(1);
v1 = param(2);
v2 = param(3);
for i = 1:length(T)
    
    if T(i) < a
        h(i) = v1;
    else
        h(i) = v2*(T(i)-a)+v1;
    end
end

end