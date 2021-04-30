%PurePursuit 円形のパスを生成
R = 8.5;
counter = 2;
dx = 0.1;
path = zeros(2*R/dx,2);


for x = 0:dx:2*R-dx
        y= sqrt(R^2-(x-R)^2);
     path(counter,1) = x;
     path(counter,2) = y;
     counter = counter + 1;
end
for x = 2*R:-dx:0
        y= -sqrt(R^2-(x-R)^2);
     path(counter,1) = x;
     path(counter,2) = y;
     counter = counter + 1;
end