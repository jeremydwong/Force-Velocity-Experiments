%% load the original model.
clc;
clear all;

%[ glu ham rec vas gas sol]
a=getJumperParams;
P = getJumperStruct(a);
% P = overwriteparams2017(P);
[h_base,state_base,o_base]=getBaselineJumpData();
power_base = energy_power(o_base,state_base,P);
%% optimize for
x0=ones(1,6)*0.1;
% initial state of joints
fi22=[2.5277    0.8295    2.5385    0.7504];
% fi=[2.28376000E+00;8.36850000E-01;2.59113000E+00;7.31983000E-01];
% x = optimal stimulation timings
%%
x0 = rand(6,1)*.1;

REDO_OPT_STIM = 0;
P = getJumperStruct(a);
P = overwriteparams2017(P);
fgain = .62;
% rmfield(P.m,'vcelinear');
% P.m.vcelinear = 0;
P.m.fmax = 1*P.m.fmax;
% P.m = rmfield(P.m,'vcelinear');
% P.m.vcehyperpos = 1;

if REDO_OPT_STIM
    x=fminsearch(@(x)run4seg_P_optstart(x,fi22,P,0),x0);
else
    x =   [0.0127
        0.1269
        0.0144
        0.1503
        0.0508
        0.0095];
    
end;
[h_lin,state_lin,o_lin]=run4seg_P_optstart(x,fi22,P,1);
%%
animateJump(o.x,o.y,o.cmx,o.cmy);
%% animate a jump. right now the knee hyper-extends.
do_bump_sim = 0;
if do_bump_sim
    [height_mus_bumpvid,state_bumpvid,o_bumpvid]=run4seg_P_optstart(x,fi22+[0,0,pi/180,0],P,1);
    animateJump(o_bumpvid.x,o_bumpvid.y,o_bumpvid.cmx,o_bumpvid.cmy);
    
    [height_mus_bumpvid2,state_bumpvid2,o_bumpvid2]=run4seg_P_optstart(x,fi22+[0,0,0,-.1],P,1);
    animateJump(o_bumpvid2.x,o_bumpvid2.y,o_bumpvid2.cmx,o_bumpvid2.cmy);
end
%%
%get output.
[height_mus_orig,state,o]=run4seg_P_optstart(x,fi22,ones(1,6),ones(1,6),P,0);
p = energy_power(o,state,P);
% simulate given initial state.
[height_init,state_init,o_init]=run4seg_P(x,state(1,:),o.stim(:,1),P,0);

%%
tor = o_init.mom;
t_tor = o_init.t';%t_tor = [0;t_tor(:)];
P.tor = -tor;
P.t_tor = t_tor;
P.U = {};
for i =1:4
    P.U{i} = spline(t_tor,P.tor(:,i));
end;
bump = zeros(1,12);
bump(1) = -.00;
[height_tor_orig,tor_sim]=run4seg_P_Torque(state_init(1,1:12)+bump,P,1);
%%
animateJump(tor_sim.x,tor_sim.y,tor_sim.cmx,tor_sim.cmy,'fail');

%% debugging. what's the error between torque and muscle.
%idea1: since we have a difference at time 0, it's the initial torque.
%no that's not it.
%idea2: ppval, splining the torque, is not like what ha
%this appears to resolve the problem: now tor and mus are within 1mm.
%%
% compare the two sims, muscle and torque.
plot(state(:,1:4),'b');hold on;
plot(tor_sim.state(:,1:4),'r');
legend('mus','tor','location','south');xlabel('time');ylabel('angle (rad)');
%%
height_mus = [];
delta=-5.0/180*pi:.2/180*pi:5.0/180*pi;
l=length(delta);
%% bump the initial conditions and re-run the torque simulation.
% this section typically takes 30 s to run. 2016 macbookpro.
tic;
for ip =1:4
    for il = 1:l
        fi22p=fi22;fi22p(ip)=fi22p(ip)+delta(il);
        [height_tor(il,ip),tor_sim]=run4segTorque([fi22p,state(1,5:12)],P);
        tors{ip}=tor_sim.state;
    end;
    
end;
toc;
height_tor = -height_tor_orig + height_tor;
%% test: bump the initial conditions and run the muscle stimulation.
% this section typically takes 4x.
fi22p = fi22+[0,0,0,0];
tic;
for ip =1:4
    for il = 1:l
        fi22p=fi22;fi22p(ip)=fi22p(ip)+delta(il);
        igamma = state(1,end-5:end);
        
        % [height,state,o]=run4seg_P_optstart(x,fi22p,ones(1,6),ones(1,6),P,0);
        [height_mus(il,ip),states]=run4seg_FL_ISTATE_P(x,[fi22p,state(1,5:end)],o.stim(:,1),P,0);
        musc{ip}=states';
    end;
end;
toc;
height_mus = -height_mus_orig + height_mus;
%%
titles = {'toe','ank','kne','hip'};
figure;
ax = [-.6,.1;
    -.35,0;
    -.6,.2;
    -.1,.02;];

for i_f=1:4
    subplot(2,2,i_f);
    plot(delta,-height_mus(:,i_f),'b');hold on;
    %     plot(delta,-height_tor(:,i_f),'r');
    title(titles(i_f));
    
    xlabel('delta angle');
    ylabel('delta height (m)');
    axis([xlim,ax(i_f,:)]);
end;
subplot(2,2,1);
legend('muscle','torque','location','south');