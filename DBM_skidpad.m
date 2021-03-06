%%車両諸元
m = 280.0; %質量
Iz = 160.0;%yaw inertia
wd = 0.45;%weight distrubution
WB = 1.75;%Wheel Base
Tr = 1.25;%Track
lf = WB*(1.0-wd);
lr = WB*wd;
Cf = 39000;%コーナリング係数
Cr = 42000;%コーナリング係数
%%
%simulation parameter
dt = 0.01;
Lfc = 3;%前方注視距離
eR = 1;%許容旋回誤差
Ka = 0.5;%加速速度
Kb = 0.6;%減速速度
timeout = 6;%終了時間
n = timeout/dt;%要素数
%%
%記憶領域
a = zeros(n,1);
delta = zeros(n,1);
beta = zeros(n,1);
Fy = zeros(n,2);% Fyf Fyr
pose = zeros(n,3);%x y theta
v = zeros(n,3);%vx,vy,omega
rear_posi = zeros(n,2);% x y
%%
%Initial condition
pose(1,1) = 0.0;    pose(1,2) = 0.0;     pose(1,3) = pi/2; 
v(1,1) = 10;        v(1,2) = 1.0;        v(1,3) = 1.25; 
delta(1,1) = 80*pi/180; 
a(1,1) = 0.0; 
Fy(1,1)=-455.0;     Fy(1,2)=-455.0;

%%
%コースを導入
skidpad;

% figure
% plot(path(:,1),path(:,2))
% hold on
%%
%frameの条件

% Determine vehicle frame size to most closely represent vehicle with plotTransforms
vizRate = rateControl(1/dt);
frameSize = WB/0.8;


%%
goal = path(end,:);
goalr = 1;
%%
%パスに沿った前方注視点座標を取得

controller = controllerPurePursuit('LookaheadDistance',Lfc,'Waypoints',path);
%%
%Dynamic Bicycle Modelの更新式
t=zeros(n,1);
t(1,1)=0.0;
for i= 1:n-1
    if(v(i+1,1) == 0)
        v(i+1,1) = 0.1;
    end
    pose(i+1,1) = pose(i,1) + v(i,1)*cos(pose(i,3))*dt - v(i,2)*sin(pose(i,3))*dt;
    pose(i+1,2) = pose(i,2) + v(i,1)*sin(pose(i,3))*dt + v(i,2)*cos(pose(i,3))*dt;
    pose(i+1,3) = pose(i,3) + v(i,3)*dt;
    
    v(i+1,1) = v(i,1) + (a(i,1) - Fy(i,1)*sin(delta(i,1))/m + v(i,2)*v(i,3))*dt;
    v(i+1,2) = v(i,2) + (Fy(i,2)/m + Fy(i,1)*cos(delta(i,1))/m - v(i,1)*v(i,3))*dt;
    v(i+1,3) = v(i,3) + dt/Iz*(Fy(i,1)*lf - Fy(i,2)*lr);
    rear_posi(i+1,1) = pose(i,1) -(lr*cos(pose(i,3)));
    rear_posi(i+1,2) = pose(i,2) -(lr*sin(pose(i,3)));
   
    
    %pure pursuit controller 
    [vel,angvel,Lp] = controller(pose(i+1,:));
    %軌跡と車の角度
    X = Lp(1,1)-rear_posi(i+1,1);
    Y = Lp(1,2)-rear_posi(i+1,2);
    alp = atan2(Y,X) - pose(i+1,3);
    %舵角計算
    delta(i+1,1) = atan2(2*Tr*sin(alp),Lfc);
    if(delta(i+1) < -pi/2)
        delta(i+1) = -pi/2;
    end
    if(delta(i+1) >= pi/2)
        delta(i+1) = pi/2;
    end
    
    %加減速制御
    rho = (1-m/(2*WB^2)*(lf*Cf-lr*Cr)/(Cf*Cr)*(v(i+1,1)^2+v(i+1,2)^2))*WB/abs(delta(i+1,1)*180/pi);
    
    if(rho <R)%eRは許容膨れ
        v(i+1,1) = v(i+1,1) + Ka*dt;%Kは加速速度
        a(i+1,1) = Ka;
    elseif(rho>R+eR)%eRは許容膨れ
        v(i+1,1) = v(i+1,1) + Kb*dt;%Kは減速速度
        a(i+1,1) = -Kb;
    else
        a(i+1) = 0;
    end
    
    %　スリップアングル計算
    beta(i) = atan2(v(i+1,2), v(i+1,1));
    betaf(i) = beta(i) + lf*v(i+1,3)/sqrt(v(i+1,1)^2+v(i+1,2)^2) - delta(i+1,1);
    betar(i) = beta(i) - lr*v(i+1,3)/sqrt(v(i+1,1)^2+v(i+1,2)^2);
    betaf(i) = betaf(i)*180/pi;
    betar(i) = betar(i)*180/pi;
    %タイヤ力
    Fy(i+1,1) = -Cf*(atan2(v(i+1,2),v(i+1,1)) + lf*v(i+1,3)/v(i+1,1) - delta(i+1,1));
    Fy(i+1,2) = -Cr*(atan2(v(i+1,2),v(i+1,1)) - lr*v(i+1,3)/v(i+1,1));
    
    %逐次プロット
%     plotTrVec = [pose(i+1,1:2)'; 0];
%     plotRot = axang2quat([0 0 1 pose(i+1,3)]);
%     plotTransforms(plotTrVec', plotRot, "MeshFilePath", "groundvehicle.stl", "Parent", gca, "View","2D", "FrameSize", frameSize);
%     
%     xlim([-15 35])
%     ylim([-20 20])
%     axis equal
%     
%     
%    
%     waitfor(vizRate);
    
  
     t(i+1,1)= t(i,1)+dt;
     txt = [ "t="  num2str( t(i+1,1) )  "s "];
     text(.5,.5,txt,'Position',[25,25,0]);
     
     %終了条件
    distanceToGoal = norm(pose(i+1,1:2) - goal);
    if(distanceToGoal < goalr && t(i+1,1)>3)
        t_end = t(i+1,1);
        break
    end
%     if(distanceToGoal < goalr/10 && t(i+1,1)<4)
%         t_str = t;
%     end
    if( t(i+1,1) >8 )
        t_end = t(i+1,1);
        break
    end
    
   
    
end
%%

t_end
plot(betar(:))
hold on
