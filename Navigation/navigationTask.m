% Example navigation task

% Copyright 2018 The MathWorks, Inc.

%% Setup
connectToRobot;
% Create publishers and subscribers for navigation
odomSub = rossubscriber(AMCL_POSE);
[vPub,vMsg] = rospublisher(ROBOT_CMD_VEL);
% Reset the odometry to zero
%resetOdometry;
   
%% Path planning
% First, load the presaved map
load myMapMaze
show(map)
%getMapFromROS

% Then, create a probabilistic roadmap (PRM)
prm = robotics.PRM(map);
prm.NumNodes = 300;
prm.ConnectionDistance = 2.5;

% Define a start and goal point
pose = getRobotPose(odomSub.LatestMessage);
startPoint = pose(1:2);
%startPoint = [-1 0];
%goalPoint = [1 1]; % Specify goal as an array
goalPoint = getPosition(impoint); % Get goal interactively

% Find a path
myPath = findpath(prm,startPoint,goalPoint);
show(prm)

%% Perform navigation using Pure Pursuit
% First, create the controller and set its parameters
pp = robotics.PurePursuit;
pp.DesiredLinearVelocity = 0.2;
pp.LookaheadDistance = 0.5;
pp.Waypoints = myPath;

% Navigate until the goal is reached within threshold
show(prm); 
hold on
hPose = plot(pose(1),pose(2),'gx','MarkerSize',15,'LineWidth',2);
while norm(goalPoint-pose(1:2)) > 0.1 
    % Get latest pose
    pose = getRobotPose(odomSub.LatestMessage);     
    % Run the controller
    [v,w] = pp(pose); 
    % Assign speeds to ROS message and send
    vMsg.Linear.X = v;
    vMsg.Angular.Z = w;
    send(vPub,vMsg);   
    % Plot the robot position
    delete(hPose);
    hPose = plot(pose(1),pose(2),'gx','MarkerSize',15,'LineWidth',2);
    drawnow;  
end
disp('Reached Goal!');