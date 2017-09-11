function [vnew,isterminal,direction] = events_jumper(t,state,P)
% function out = events_jumper(t,state,P)
% handle flags. 
if P.i_progress < 7
    vnew = t - P.t_stim_sorted(P.i_progress);
    isterminal = 1;
    direction = 1;
elseif P.i_progress ==7
    [~,sol]=ode_jumper(t,state,P);
    vnew = sol(5);
    isterminal = 1;
    direction = -1;
else
    vnew = t-P.t_max;
    isterminal = 1;
    direction = 1;
end;
