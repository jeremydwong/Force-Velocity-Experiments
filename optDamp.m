function out = optDamp(damp,tstim,fi,P)
P.damp = damp;
out = run4seg_P_optstart(tstim,fi,P);