
clc;
clear all;
plot_lines = {'linewidth',2};
%% loads into memory sims:
% state_base, o_base, t_stim_base, 
% tor_base
% fi22

a=getJumperParams;
P_orig = getJumperStruct(a);
P = overwriteparams2017(P_orig);
[h_base,state_nonshift,o_nonshift,tstim_nonshift,fi22]=getBaselineJumpData();
%%
% KVS check.
% olddat = load('kvs_fix_opt.mat');
% state_old = olddat.state_kvs;
% o_old = olddat.o_kvs;
% o_old.mom = o_old.mom';
% % just verify that the old KVS code is the same as the new cleaned up code.
% plot(state_old(:,13:18),'color','r',plot_lines{:});
% hold on;
% plot(state_nonshift(:,13:18),'color','b','linewidth',1);
% pause;

tstim_base = tstim_nonshift - min(tstim_nonshift)+.002;
[h_base,state_base,o_base]=run4seg_P(tstim_base,[fi22,state_nonshift(1,5:end)],...
    o_nonshift.stim(1,:),P);

e_base = energy(state_base,o_base,P);

[height_tor_orig,tor_base,P_tor] = getTorqueModel(state_base,o_base,P);
%% perturbation tests. load heights_tor. 
% test TOR: bump the initial conditions and re-run the torque simulation.
% this section typically takes 18 s to run. 2016 macbookpro.
% it goes so fast now though. something is up.
delta=-5.0/180*pi:.5/180*pi:5.0/180*pi;
l=length(delta);

for ip =1:4
    for il = 1:l
        fi22p=fi22;
        fi22p(ip)=fi22p(ip)+delta(il);
        [heights_tor(il,ip),temp_tor_sim]=run4segTorque([fi22p,state_base(1,5:12)],P_tor);
        tors{ip}=temp_tor_sim.state;
    end;
    
end;
heights_tor = -height_tor_orig + heights_tor;
%% peturb hill. 
% test MUS: bump the initial conditions and run the muscle stimulation.
% this section typically takes 2.5x as torque sim. really not terrible.
% but we are doing finite fixed step size.
heights_hill = [];

for ip =1:4
    for il = 1:l
        fi22p=fi22;
        fi22p(ip)=fi22p(ip)+delta(il);
        [heights_hill(il,ip),states,temp_fwd_hill]=run4seg_P(tstim_base,[fi22p,state_base(1,5:end)],o_base.stim(1,:),P);
        musc{ip}=states';
        if ~temp_fwd_hill.flag_pe
            ts_dur_hill(il,ip) = temp_fwd_hill.t(end);
        end;
    end
end;
heights_hill = -h_base + heights_hill;
ts_dur_hill = ts_dur_hill - o_base.t(end);
%% optimize linear. 
P_linear = overwriteparams2017(P_orig);
P_linear.m.vcelinear = 1;
REDO_LINEAR_OPT = 1;
x0=tstim_base;
if REDO_LINEAR_OPT
    tstim_lin_orig=fminsearch(@(x)run4seg_P_optstart(x,fi22,P_linear),x0);
else
    tstim_lin_orig = [];
end;
tstim_lin= tstim_lin_orig - min(tstim_lin_orig) + 0.001;
[~,state_lin,o_lin]=run4seg_P_optstart(tstim_lin,fi22,P_linear,0);
%% perturb linear
[height_lin_unpert,state_lin_unpert,o_lin_unpert]=...
    run4seg_P(tstim_lin,state_lin(1,:),...
    o_lin.stim(1,:),P_linear);

for ip =1:4
    for il = 1:l
        fi22p=fi22;fi22p(ip)=fi22p(ip)+delta(il);
        igamma = state_lin(1,end-5:end);
        
        [heights_lin(il,ip),states_lin,temp_fwd_lin]=run4seg_P(tstim_lin,[fi22p,...
            state_lin(1,5:end)],o_lin.stim(1,:),P_linear);
        musc_lin{ip}=states_lin';
        if ~temp_fwd_lin.flag_pe
            ts_dur_lin(il,ip) = temp_fwd_lin.t(end);
        end;
        
    end;
end;
heights_lin = -height_lin_unpert + heights_lin;
ts_dur_lin = ts_dur_lin - o_lin_unpert.t(end);
%% sim linear half. perturb.
P_vlh = overwriteparams2017(P_orig);
P_vlh.m.vcelinearhalf = 1;
REDO_LINEAR_OPT = 1;
x0=tstim_base;
if REDO_LINEAR_OPT
    tstim_vlh_orig=fminsearch(@(x)run4seg_P_optstart(x,fi22,P_vlh),x0);
else
    tstim_vlh_orig = [];
end;
tstim_vlh= tstim_vlh_orig - min(tstim_vlh_orig) + 0.001;
[~,state_vlh,o_vlh]=run4seg_P_optstart(tstim_vlh,fi22,P_vlh,0);

[height_vlh_unpert,state_vlh_init,o_vlh_init]=...
    run4seg_P(tstim_vlh,state_vlh(1,:),...
    o_vlh.stim(1,:),P_vlh);

for ip =1:4
    for il = 1:l
        fi22p=fi22;fi22p(ip)=fi22p(ip)+delta(il);
        igamma = state_vlh(1,end-5:end);
        
        % [height,state,o]=run4seg_FL_P(x,fi22p,ones(1,6),ones(1,6),P,0);
        [heights_vlh(il,ip),states_vlh]=run4seg_P(tstim_vlh,[fi22p,...
            state_vlh(1,5:end)],o_vlh.stim(1,:),P_vlh);
        musc_vlh{ip}=states_vlh';
    end;
end;

heights_vlh = -height_vlh_unpert+ heights_vlh;


%%
titles = {'toe','ank','kne','hip'};
figure;
ax = [-.6,.1;
    -.35,.1;
    -.6,.2;
    -.1,.02;];
ax = [-.3,.1;
    -.3,.1;
    -.3,.1;
    -.3,.1;];

for i_f=1:4
    subplot(2,2,i_f);
    plot(delta,-heights_hill(:,i_f),'b',plot_lines{:});hold on;
    plot(delta,-heights_tor(:,i_f),'r',plot_lines{:});
    plot(delta,-heights_lin(:,i_f),'g',plot_lines{:});
    plot(delta,-heights_vlh(:,i_f),'m',plot_lines{:});
    title(titles(i_f));
    
    xlabel('delta angle');
    ylabel('delta height (m)');
    axis([xlim,ax(i_f,:)]);
    grid on;
end;
subplot(2,2,1);
legend('muscle','torque','linear','linear-half','location','south');

%% ANALYSIS: INDIVIDUAL JUMP. 
% take the starting position and optimized forces.
% perturb the starting knee and perturb it by -0.05. check the fail.
% check the states of the system.
fi22
fi22pk = fi22;
fi22pk(3) = fi22pk(3)+0.05; %graphically this looks bad.

[h_hill,states_hill,fwd_hill]=run4seg_P(tstim_base,[fi22,...
    state_base(1,5:end)],o_base.stim(1,:),P);

[h_hill_k,states_hill_k,fwd_hill_k]=run4seg_P(tstim_base,[fi22pk,...
    state_base(1,5:end)],o_base.stim(1,:),P);

[h_lin,states_lin,fwd_lin]=run4seg_P(tstim_lin,[fi22,...
    state_lin(1,5:end)],o_lin.stim(1,:),P_linear);

[h_lin_k,states_lin_k,fwd_lin_k]=run4seg_P(tstim_lin,[fi22pk,...
    state_lin(1,5:end)],o_lin.stim(1,:),P_linear);

[h_tor_k,tor_sim]=run4segTorque([fi22pk,state_base(1,5:12)],P_tor);

e_hill = energy(states_hill,fwd_hill,P);
e_hill_k = energy(states_hill_k,fwd_hill_k,P);

e_lin = energy(states_lin,fwd_lin,P);
e_lin_k = energy(states_lin_k,fwd_lin_k,P);

% [height_vlh,states_vlh,fwd_vlh]=run4seg_P(tstim_vlh,[fi22,...
%     state_vlh(1,5:end)],o_vlh.stim(1,:),P_vlh);
% 
% [height_vlh_k,states_vlh_k,fwd_vlh_k]=run4seg_P(tstim_vlh,[fi22pk,...
%     state_vlh(1,5:end)],o_vlh.stim(1,:),P_vlh);


%% ANALYSIS: 
% the bump in knee position moves the com 1 10/th of a mm away from toe. 
% fix the start by slightly changing the 
% result: h_lin_k_stab is much much better than h_lin_k
fi22pk = fi22;
fi22pk(3) = fi22pk(3)+0.05; %graphically this looks bad.
hip_opt = fminsearch(@(x)cost_hip_com(x,fi22pk(1:3),P),fi22pk(4));
cost_hip_com(hip_opt,fi22pk(1:3),P);
finew2 = [fi22pk(1:3),hip_opt];
[h_lin_k_stab,s_lin_k_stab,fwd_lin_k_stab]=run4seg_P_optstart(tstim_lin,finew2,P_linear);
e_lin_k_stab = energy(s_lin_k_stab,fwd_lin_k_stab,P_linear);
[h_hill_k_stab,s_hill_k_stab,fwd_hill_k_stab]=run4seg_P_optstart(tstim_base,finew2,P);
e_hill_k_stab = energy(s_hill_k_stab,fwd_hill_k_stab,P);
% now plot the energy diff between LIN models: lin_k_stab and lin
figure;
plot(e_lin.works_mus,plot_lines{:});hold on;
ax = gca();ax.ColorOrderIndex=1;
plot(e_lin_k_stab.works_mus,'-.',plot_lines{:});
figure;
plot(e_hill.works_mus,plot_lines{:});hold on;
ax = gca();ax.ColorOrderIndex=1;
plot(e_hill_k_stab.works_mus,'-.',plot_lines{:});

ylim([-10,300]);
legend_joints();
xlabel('time (ms)');
ylabel('cumulative work (J)');
%% can we optimize damping parameter for jumpheight
[h]=run4seg_P_optstart(tstim_lin,finew2,P_linear);
damp0=5;
% for i = 1:100
%     hs(i)=optDamp(i*.001,tstim_lin,finew2,P_linear);
% end
damp_best = fminsearch(@(x)optDamp(x,tstim_lin,finew2,P_linear),damp0);
optDamp(damp_best,tstim_lin,finew2,P_linear)
%%
% muscle velocities over time
figure;
plot(fwd_hill_k_stab.vcerel,plot_lines{:});hold on;
ax = gca();ax.ColorOrderIndex=1;
plot(fwd_lin_k_stab.vcerel,'-.',plot_lines{:});
legend_muscles();
%%
% plot joints over time
figure;
plot(s_hill_k_stab(:,1:4),plot_lines{:});hold on;
ax = gca();ax.ColorOrderIndex=1;
plot(s_lin_k_stab(:,1:4),'-.',plot_lines{:});
legend_joints()
%%
% q afo time 
figure;
plot(fwd_hill_k_stab.q,plot_lines{:});hold on;
ax = gca();ax.ColorOrderIndex=1;
plot(fwd_lin_k_stab.q,'-.',plot_lines{:});
legend_muscles()

%%
%%%%%%%%%%% plots %%%%%%%%%%% 
%%%%%%%%%%% plots %%%%%%%%%%% 
%%%%%%%%%%% plots %%%%%%%%%%% 
%%%%%%%%%%% plots %%%%%%%%%%% 
%%%%%%%%%%% plots %%%%%%%%%%% 

plot(e_hill.works_tor,plot_lines{:});hold on;
ax=gca();
ax.ColorOrderIndex = 1;
plot(e_hill_k.works_tor,'-.',plot_lines{:});
ylim([-10,500]);
xlabel('time (ms)');
ylabel('cumulative work (J)');

figure;
plot(e_lin.works_tor,plot_lines{:});hold on;
ax=gca();
ax.ColorOrderIndex = 1;
plot(e_lin_k.works_tor,'-.',plot_lines{:});
ylim([-10,500]);
legend_joints();
xlabel('time (ms)');
ylabel('cumulative work (J)');

%% compare work done by muscles
figure;
plot(e_hill.works_mus,plot_lines{:});hold on;
ax=gca();
ax.ColorOrderIndex = 1;
plot(e_hill_k.works_mus,'-.',plot_lines{:});
xlabel('time (ms)');
ylabel('cumulative work (J)');
ylim([-10,400]);
legend_muscles()
figure;
% linear case
plot(e_lin.works_mus,plot_lines{:});hold on;
ax=gca();
ax.ColorOrderIndex = 1;
plot(e_lin_k.works_mus,'-.',plot_lines{:});
xlabel('time (ms)');
ylabel('cumulative work (J)');
ylim([-10,400]);
legend_muscles()
%%
figure;hold on;
plot(sum(e_hill.work_tor,2));
plot(sum(e_hill_k.work_tor,2));
legend('original','perturbed')
ylim([-100,800]);
figure;hold on;
plot(sum(e_lin.work_tor,2));
plot(sum(e_lin_k.work_tor,2));
legend('original','perturbed')
ylim([-100,800]);
%% look at vas velocity.
% prediction: vas in the perturbed case is delivering much less work. that
% basically means it has to be contracting less. 
plotcompxy(fwd_hill_k,fwd_lin_k,'t','lcerel')
% from above it's clear that a perturbation at the knee 
%% 
x0 = ones(6,1)*.1;
OPT_FOR_BUMP_KNEE = 1;
if OPT_FOR_BUMP_KNEE
    tstim_hill_k=fminsearch(@(x)run4seg_P(x,[fi22pk,state_base(1,5:end)],...
        o_base.stim(1,:),P),tstim_base);
else
    tstim_hill_k = [];
end;
%% compare torque model and 2.9 deg away torque model.
% why?
% it should look similar. but there could be many local minima too. 
[h_temp,state_temp,o_temp]=run4seg_P(tstim_hill_k,[fi22pk,state_base(1,5:end)],...
        o_base.stim(1,:),P);
[h,tor_opt_k,P_tor]=getTorqueModel(state_temp,o_temp,P)
% now look at the torque of the nearby. 
plot(tor_base.tor,plot_lines{:});hold on;
ax = gca;ax.ColorOrderIndex=1;
plot(tor_opt_k.tor,'-.'); 

%% plot work loops. 
plotcompxy(fwd_hill,fwd_hill_k,'lcerel','fse'); 
subplot(3,2,1);title('hill');
plotcompxy(fwd_lin,fwd_lin_k,'lcerel','fse');
subplot(3,2,1);title('linear');

