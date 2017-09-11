function [height_mus,state,o,t_stim,fi22]=getBaselineJumpData% optimize muscle stimulations for jump height.
clear all
x0=ones(1,6)*0.1;

%[ glu ham rec vas gas sol]
one6 = ones(6,1);
a=getJumperParams;
P = getJumperStruct(a);
P = overwriteparams2017(P);
% initial state of joints

fi22=[2.5277    0.8295    2.5385    0.7504];
% fi=[2.28376000E+00;8.36850000E-01;2.59113000E+00;7.31983000E-01];
% t_stim = optimal stimulation timings
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
t_stim = zeros(6,1);
REDO_OPT_STIM = 0;
if REDO_OPT_STIM
    t_stim = fminsearch(@(t_stim)run4seg_P_optstart(t_stim,fi22,P,0),x0);
else
    %     [0.1109
%     0.1082
%     0.0980
%     0.1008
%     0.0953
%     0.0879];

% slightly better jump:1.433
    t_stim =[0.0127
    0.1269
    0.0144
    0.1503
    0.0508
    0.0095];

%stims that closely-replicate van soest. in vanSoest1993. 
% t_stim = [0.1109
%     0.1082
%     0.0980
%     0.1008
%     0.0953
%     0.0879];

end;
%get output.
%% simulate the final solution.
[height_mus,state,o]=run4seg_P_optstart(t_stim,fi22,P,0);