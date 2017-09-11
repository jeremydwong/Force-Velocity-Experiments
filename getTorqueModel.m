function [height,tor_sim,P] = getTorqueModel(state,o,P)
% function [height,tor_sim,P] = getTorqueModel(state,o,P)
% get the torque model from the info. 
tor = o.tor;
t_tor = o.t';%t_tor = [0;t_tor(:)];
inds = find(diff(t_tor)~=0);
t_tor = t_tor(inds);
P.tor = tor(inds,:);%i shouldn't be flipping this goddamn thing.
P.t_tor = t_tor;
P.U = {};
for i =1:4
    P.U{i} = spline(t_tor,P.tor(:,i));
end;
[height,tor_sim]=run4segTorque(state(1,1:12),P,0);
