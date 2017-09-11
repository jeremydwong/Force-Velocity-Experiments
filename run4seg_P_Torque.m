function [height,stack]=run4seg_P_Torque(state_cur, P,varargin)

% tor_spline = [];
% for i_tor = 1:size(length(a'))
%     tor_
% end;
% tor = ppval(t_and_stim(:,1),t_and_stim(:,2:end));
% t_cur =0;

%%TEMPLATE VARARGIN
%%only 1 optional argument, doFlight.
numvarargs = length(varargin);
num_maxvarargs = 1;
if numvarargs > num_maxvarargs
    error(['scoreETF:TooManyInputs', ...
        'requires at most ',num2str(num_maxvarargs),' optional inputs']);
end
% set defaults for optional inputs
doFlight0=0;
optargs = {doFlight0};
% now put these defaults into the optargs cell array,
% and overwrite the ones specified in varargin.
optargs(1:numvarargs) = varargin;
% or ...
% [optargs{1:numvarargs}] = varargin{:};

% Place optional args in memorable variable names used below.
[doFlight] = optargs{:};
% %%/TEMPLATE VARARGIN


t_cur = 0;
air = 0;
P.air = air;

stack = struct;
stack.state = state_cur(:)';
stack.state_dt = zeros(1,12);
for iu =1:length(P.U)
    stack.tor(iu) = ppval(P.U{iu},0);
end
while t_cur < .7
    %check to see if we've left the ground
    if air & ~doFlight
        break
    else
        stepsize=0.001;
        fun = @ode_4_pend;
        fun_num_int=@heun;
        [t_new,state_new]=fun_num_int(fun,t_cur,state_cur,stepsize,P);
        [state_dt,sol,o]=ode_4_pend(t_cur,state_cur(:),P);
        if sol(5)<0
            air =1;
            P.air=air;

%             fprintf('left the ground');
        end;
        
        %store the value.
        stack.state = [stack.state;state_new(:)'];
        stack.state_dt = [stack.state_dt;state_dt(:)'];
        stack.tor = [stack.tor;o.tor(:)';];
        %reset the states.
        t_cur = t_new;
        state_cur = state_new;
    end;
    
end;
nseg = 4;
fi=      stack.state(:,1:nseg)';
fip=     stack.state(:,nseg+1:2*nseg)';
fidp=    stack.state_dt(:,nseg+1:2*nseg)';
xbase=   stack.state(:,2*nseg+1:2*nseg+2)';
xbasep=  stack.state(:,2*nseg+3:2*nseg+4)';
xbasedp= stack.state_dt(:,2*nseg+3:2*nseg+4)';

[x,y,xp,yp,xdp,ydp]=xyc4(fi,fip,fidp,xbase,xbasep,xbasedp,P.sk.l);
[cmx,cmy,cmxp,cmyp,cmxdp,cmydp]=cm4(x,y,xp,yp,xdp,ydp,P.sk.l,P.sk.d,P.sk.mass(:));
height=-(cmy(end)+0.5/9.81*cmyp(end)^2);
fprintf('height is: %.4f\n',height);

if doFlight
    height = -max(cmy);
end;

stack.x = x';
stack.y = y';
stack.cmy = cmy';
stack.cmx = cmx';
stack.cmyp = cmyp';
stack.cmxp = cmxp';
%return height value.