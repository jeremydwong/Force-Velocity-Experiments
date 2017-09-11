function[tout,yout]=heun(FunFcn, t, state, step_size, data)
% function[tout,yout]=heun(FunFcn, t, y, h, data) 
% heun approximation to state derivative.
% approximation improves quadratically with step-size.
state=state(:);
s1=feval(FunFcn,t,state,data);
s2=feval(FunFcn,t+step_size,state+step_size*s1,data);

tout=t+step_size;
yout=state+step_size*(s1(:)+s2(:))/2;
