clc;
clear all;
tic
%[ glu ham rec vas gas sol]
a=getJumperParams;
P_orig = getJumperStruct(a);
P = overwriteparams2017(P_orig);
[h_base,state_base,o_base,t_stim_base,fi22]=getBaselineJumpData();
t_stim_base = t_stim_base - min(t_stim_base)+.001;
[h_base2,state_base2,o_base2]=run4seg_P(t_stim_base,[fi22,state_base(1,5:end)],...
    o_base.stim(:,1),P);

% getBaselineJumpData runs 
% t_stim_base=t_stim_base - min(t_stim_base)+0.001;
power_base = energy_power(o_base,state_base,P);
%% KVS check.
olddat = load('kvs_fix_opt.mat');
state_old = olddat.state_kvs;
o_old = olddat.o_kvs;
o_old.mom = o_old.mom';
%% just verify that the old KVS code is the same as the new cleaned up code.
plot(state_old(:,13:18),'color','r','linewidth',2);
hold on;
plot(state_base2(:,13:18),'color','b','linewidth',1);

%%
o = o_base;
state = state_base;
tor = o.mom;
t_tor = o.t';%t_tor = [0;t_tor(:)];
P.tor = -tor;
P.t_tor = t_tor;
P.U = {};
for i =1:4
P.U{i} = spline(t_tor,P.tor(:,i));
end;
bump = zeros(1,12);
% bump(1) = -.05;
[height_tor_orig,tor_sim]=run4segTorque(state_base(1,1:12)+bump,P,0);

%% test TOR: bump the initial conditions and re-run the torque simulation.
% this section typically takes 18 s to run. 2016 macbookpro.
% it goes so fast now though. something is up. 
delta=-5.0/180*pi:.5/180*pi:5.0/180*pi;
l=length(delta);

tic;
for ip =1:4
    for il = 1:l
        fi22p=fi22;
        fi22p(ip)=fi22p(ip)+delta(il);
        [height_tor(il,ip),tor_sim]=run4segTorque([fi22p,state(1,5:12)],P);
        tors{ip}=tor_sim.state;
    end;
    
end;
toc; 
height_tor = -height_tor_orig + height_tor;

%% test MUS: bump the initial conditions and run the muscle stimulation.
% this section typically takes 2.5x as torque sim. really not terrible.
% but we are doing finite fixed step size. 
tic;
height_mus = [];

for ip =1:4
    for il = 1:l
        fi22p=fi22;
        fi22p(ip)=fi22p(ip)+delta(il);
        [height_mus(il,ip),states]=run4seg_P(t_stim_base,[fi22p,state(1,5:end)],o.stim(:,1),P);
        musc{ip}=states';
    end;
end;
toc;
height_mus = -h_base + height_mus;

%%
titles = {'toe','ank','kne','hip'};
figure;
ax = [-.6,.1;
    -.35,.1;
    -.6,.2;
    -.1,.02;];
% ax = [-.6,.1;
%     -.6,.1;
%     -.6,.1;
%     -.6,.1;];
    
for i_f=1:4
    subplot(2,2,i_f);
    plot(delta,-height_mus(:,i_f),'b');hold on;
     plot(delta,-height_tor(:,i_f),'r');
    title(titles(i_f));
    
    xlabel('delta angle');
    ylabel('delta height (m)');
    axis([xlim,ax(i_f,:)]);
    grid on;
end;
subplot(2,2,1);
legend('muscle','torque','location','south');
toc;