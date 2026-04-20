clc
clear
close all

%% VIDEO SETUP
video = VideoWriter('chandrayaan_final_polish.mp4','MPEG-4');
video.FrameRate = 25;
open(video);

%% PARAMETERS
g = 1.62;
dt = 0.05;

x = -25; y = 60;
vx = 3; vy = -2;

target_x = 0;

% CONTROL GAINS
Kpx = 0.08; Kdx = 0.6;
Kpy = 0.5;  Kdy = 0.8;

%% FIGURE
fig = figure('Color','black');
axis([-40 40 0 70])
hold on
axis off

%% PAUSE CONTROL
global isPaused
isPaused = false;
set(fig,'KeyPressFcn',@pauseControl);

%% 🌌 STARS
num_stars = 250;
star_x = rand(1,num_stars)*80 - 40;
star_y = rand(1,num_stars)*70;
stars = plot(star_x, star_y, 'w.', 'MarkerSize',5);

%% 🪐 PLANETS
theta = linspace(0,2*pi,50);
fill(25+5*cos(theta),55+5*sin(theta),[0.2 0.4 1])
fill(-30+3*cos(theta),50+3*sin(theta),[1 0.5 0.2])

%% 🌕 TERRAIN
terrain_x = linspace(-40,40,400);
terrain_y = 2 + 0.8*sin(0.15*terrain_x) + 0.4*sin(0.5*terrain_x);

fill([terrain_x fliplr(terrain_x)],...
     [terrain_y zeros(size(terrain_y))],[0.6 0.6 0.6])

%% 🎯 TARGET
plot(target_x, interp1(terrain_x,terrain_y,target_x)+0.5,...
     'ro','MarkerSize',8,'LineWidth',2)

%% 🚀 LANDER
body_x = [-1 1 1 -1];
body_y = [0 0 2 2];
lander = fill(body_x + x, body_y + y, [0.9 0.9 0.9]);

leg1 = plot([-1 -1.5]+x,[0 -1]+y,'w','LineWidth',2);
leg2 = plot([1 1.5]+x,[0 -1]+y,'w','LineWidth',2);

%% 🔥 FLAME
flame = fill([0 0 0],[0 0 0],'yellow');

%% 📈 TRAJECTORY
traj_x = [];
traj_y = [];
traj_plot = plot(0,0,'c','LineWidth',1);

%% TEXT
status = text(-35,65,'Autonomous Landing...','Color','white');
vel_text = text(-35,60,'','Color','white');
pos_text = text(-35,55,'','Color','white');

%% STORE FRAMES FOR REPLAY
frames = {};

%% MAIN LOOP
while true
    
    % PAUSE FEATURE
    while isPaused
        pause(0.1)
    end
    
    ground = interp1(terrain_x,terrain_y,x);
    height = y - ground;
    
    if height <= 0
        break
    end
    
    % CONTROL
    error_x = target_x - x;
    ax = Kpx*error_x - Kdx*vx;
    
    if height > 30
        vy_des = -6;
    elseif height > 15
        vy_des = -3;
    else
        vy_des = -0.8;
    end
    
    ay_control = Kpy*(vy_des - vy) - Kdy*vy;
    ay = ay_control - g;
    
    % UPDATE
    vx = vx + ax*dt;
    vy = vy + ay*dt;
    x = x + vx*dt;
    y = y + vy*dt;
    
    % LANDER UPDATE
    set(lander,'XData',body_x+x,'YData',body_y+y)
    set(leg1,'XData',[-1 -1.5]+x,'YData',[0 -1]+y)
    set(leg2,'XData',[1 1.5]+x,'YData',[0 -1]+y)
    
    % FLAME
    thrust = max(0, ay_control);
    if thrust > 0
        set(flame,'XData',[-0.4 0.4 0]+x,...
                  'YData',[y y y-3*thrust],...
                  'FaceColor',[1 0.5 0])
    else
        set(flame,'XData',[0 0 0],'YData',[0 0 0])
    end
    
    % STARS TWINKLE
    set(stars,'MarkerSize',3 + 5*rand)
    
    % TRAJECTORY
    traj_x(end+1)=x;
    traj_y(end+1)=y;
    set(traj_plot,'XData',traj_x,'YData',traj_y)
    
    % DUST CLOUD
    if height < 3
        for k = 1:20
            plot(x+randn, ground+rand*2,'.','Color',[0.8 0.8 0.8])
        end
    end
    
    % ZOOM
    if height < 20
        axis([x-15 x+15 0 40])
    end
    
    % TEXT
    set(vel_text,'String',sprintf('Vx: %.2f | Vy: %.2f',vx,vy))
    set(pos_text,'String',sprintf('Height: %.2f',height))
    
    drawnow
    
    % SAVE FRAME
    frame = getframe(gcf);
    writeVideo(video,frame);
    frames{end+1} = frame;
end

%% LANDING RESULT
if abs(vy)<2 && abs(vx)<1 && abs(x-target_x)<3
    set(status,'String','SOFT LANDING ✅','Color','green')
else
    set(status,'String','HARD LANDING ❌','Color','red')
end

%% HOLD FINAL FRAME
for i=1:40
    frame = getframe(gcf);
    writeVideo(video,frame);
end

%% 🎞️ SLOW MOTION REPLAY
for i = 1:length(frames)
    imshow(frames{i}.cdata)
    drawnow
    pause(0.02)
end

close(video)

disp('🎬 chandrayaan_final_polish.mp4 created')

%% PAUSE FUNCTION
function pauseControl(~,event)
    global isPaused
    if strcmp(event.Key,'space')
        isPaused = ~isPaused;
    end
end