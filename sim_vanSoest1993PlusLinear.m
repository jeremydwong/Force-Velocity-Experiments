%% optimize muscle stimulations for jump height.
clear all
x0=ones(1,6)*0.1;

%[ glu ham rec vas gas sol]
one6 = ones(6,1);
a=getJumperParams;
P = getJumperStruct(a);
P = overwriteparamsRLC201306(P);
% initial state of joints

fi22=[2.5277    0.8295    2.5385    0.7504];
% fi=[2.28376000E+00;8.36850000E-01;2.59113000E+00;7.31983000E-01];
% x = optimal stimulation timings
F_new = [0.05 2.10279 1.71725 0.1 1.14498 0.1849];
F_newThigh=[0.052137 2.38548 2.21668 0.0525546 0.0569753 1.64012];
F_best=[0.127916 2.65777 1.00955 1.7648 1.55416 1.76319];
l_best=[1.52288 1.10562 0.964061 0.0505657 0.606768 0.878352];
%%
% P.m.rlpenul = repmat(1.7,1,6);
%kluge to get the thing to run.
%optimize.
% deltaA0 = .004;
% P.m.rmapar(7,4) = P.m.rmapar(7,4)-deltaA0;
x = zeros(6,1);
REDO_OPT_STIM = 0;
if REDO_OPT_STIM
    x=fminsearch(@(x)run4seg_FL_P(x,fi22,ones(1,6),ones(1,6),P,0),x0);
else
    x_orig =   [0.1109
    0.1082
    0.0980
    0.1008
    0.0953
    0.0879];

end;
x = x_orig-min(x_orig)+0.001;
%get output.
%% simulate the final solution.
[height_mus_orig,state_kvs,o_kvs]=run4seg_FL_P(x,fi22,ones(1,6),ones(1,6),P,0);
[height_init,state_kvs_istate,o_kvs_istate]=run4seg_FL_ISTATE_P(x,state_kvs(1,:),o_kvs.stim(:,1),ones(1,6),ones(1,6),P,0);

%%
tor = o_kvs_istate.mom';
t_tor = o_kvs_istate.t';%t_tor = [0;t_tor(:)];
P.tor = -tor;
P.t_tor = t_tor;
P.U = {};
for i =1:4
P.U{i} = spline(t_tor,P.tor(:,i));
end;
[height_tor_orig,tor_sim]=run4segTorque(state_kvs_istate(1,1:12),P)
%% debugging. what's the error between torque and muscle.
%idea1: since we have a difference at time 0, it's the initial torque.
%no that's not it.
%idea2: ppval, splining the torque, is not like what ha
%this appears to resolve the problem: now tor and mus are within 1mm.
%%
% compare the two sims, muscle and torque.
plot(state_kvs(:,1:4),'b');hold on;
plot(tor_sim.state(:,1:4),'r');
legend('mus','tor','location','south');xlabel('time');ylabel('angle (rad)');
%%
delta=-10.0/180*pi:.2/180*pi:10.0/180*pi;
l=length(delta);
%% bump the initial conditions and re-run the torque simulation.
% % this section typically takes 30 s to run. 2015 macbookpro; roughly
% twice that of Kombucha same on Kombucha, 2016 desktop 3.5ghz. 
tic;
for ip =1:4
    for il = 1:l
        fi22p=fi22;fi22p(ip)=fi22p(ip)+delta(il);
        [height_tor(il,ip),tor_sim]=run4segTorque([fi22p,state_kvs(1,5:12)],P);
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
        igamma = state_kvs(1,end-5:end);
        
        % [height,state,o]=run4seg_FL_P(x,fi22p,ones(1,6),ones(1,6),P,0);
        [height_mus(il,ip),states]=run4seg_FL_ISTATE_P(x,[fi22p,state_kvs(1,5:end)],o_kvs.stim(:,1),ones(1,6),ones(1,6),P,0);
        musc{ip}=states';
    end;
end;
toc;
height_mus = -height_mus_orig + height_mus;
%%
x = zeros(6,1);
P_linear = P;
P_linear.m.vcelinear = 1;
REDO_LINEAR_OPT = 1;
if REDO_LINEAR_OPT
    tstim_lin_orig=fminsearch(@(x)run4seg_FL_P(x,fi22,ones(1,6),ones(1,6),P_linear,0),x0);
else
    tstim_lin_orig = [];
end;
tstim_lin= tstim_lin_orig - min(tstim_lin_orig) + 0.001;
%%
[~,state_lin,o_lin]=run4seg_FL_P(tstim_lin,fi22,ones(1,6),ones(1,6),P_linear,0);
[height_lin_unpert,state_lin_init,o_lin_init]=run4seg_FL_ISTATE_P(tstim_lin,state_lin(1,:),...
    o_lin.stim(:,1),ones(1,6),ones(1,6),P_linear,0);
tic;
for ip =1:4
    for il = 1:l
        fi22p=fi22;fi22p(ip)=fi22p(ip)+delta(il);
        igamma = state_kvs(1,end-5:end);
        
        % [height,state,o]=run4seg_FL_P(x,fi22p,ones(1,6),ones(1,6),P,0);
        [height_lin(il,ip),states_lin]=run4seg_FL_ISTATE_P(tstim_lin,[fi22p,...
            state_lin(1,5:end)],o_lin.stim(:,1),ones(1,6),ones(1,6),P_linear,0);
        musc_lin{ip}=states';
    end;
end;
toc;
height_lin = -height_lin_unpert + height_lin;
%%
titles = {'toe','ank','kne','hip'};
figure;
ax = [-.6,.1;
    -.35,0;
    -.6,.2;
    -.1,.02;];
    
ax = [-.3,.1;
    -.3,.1;
    -.3,.1;
    -.3,.1;];
for i_f=1:4
    subplot(2,2,i_f);
    plot(delta,-height_mus(:,i_f),'b','linewidth',2);hold on;
    plot(delta,-height_tor(:,i_f),'r','linewidth',2);
    plot(delta,-height_lin(:,i_f),'g','linewidth',2);
    title(titles(i_f));
    
    xlabel('delta angle');
    ylabel('delta height (m)');
    axis([-.1,.1,ax(i_f,:)]);
end;
subplot(2,2,1);
legend('muscle','torque','location','south');