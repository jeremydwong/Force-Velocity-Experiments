function [x_out,y_out] = cost_hip_com(hip,fi,P)
% function out = position_4_com(hip,fi,P)
[x,y]=xyc4([fi(:);hip],zeros(4,1),zeros(4,1),zeros(2,1),zeros(2,1),zeros(2,1),P.sk.l);
[x_out,y_out] = kinematics_4_com(x,y,zeros(5,1),zeros(5,1),zeros(5,1),zeros(5,1),P.sk.l,P.sk.d,P.sk.mass);
x_out = x_out.^2;
