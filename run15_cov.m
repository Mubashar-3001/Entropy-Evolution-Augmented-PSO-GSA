function run15_cov()
S=get_system('15'); Pr=default_params();
algs={'PSO','GSA','PSOGSA','PSOGSAEE'};
if ~exist('results','dir'), mkdir('results'); end
R=struct(); R.sys='15'; R.modes=algs; R.P=Pr; R.S=S;
fid=fopen(fullfile('results','run15_progress.txt'),'w'); fprintf(fid,'START %s\n',datestr(now)); fclose(fid);
for a=1:numel(algs)
  md=algs{a};
  finals=zeros(Pr.nRuns,1); raws=zeros(Pr.nRuns,1); feasv=false(Pr.nRuns,1);
  walls=zeros(Pr.nRuns,1); curves=zeros(Pr.nRuns,Pr.iters); nre=zeros(Pr.nRuns,1);
  bestX=[]; bestFit=inf;
  for s=1:Pr.nRuns
    tt=tic; o=run_optimizer(S,md,s,Pr);
    [fPol,tmsPol,psPol]=refine_lp(S,o.X);
    walls(s)=toc(tt); raws(s)=o.bestFit; curves(s,:)=o.curve; nre(s)=o.nReinit;
    if isfinite(fPol), finals(s)=fPol; feasv(s)=true; xP=[tmsPol(:)' psPol(:)'];
    else, finals(s)=1e9; feasv(s)=false; xP=o.X; end
    if finals(s)<bestFit, bestFit=finals(s); bestX=xP; end
    fid=fopen(fullfile('results','run15_progress.txt'),'a');
    fprintf(fid,'%s %d %.6f %.6f %.1f\n',md,s,raws(s),finals(s),walls(s)); fclose(fid);
  end
  A=struct('finals',finals,'rawFinals',raws,'feas',feasv,'walls',walls,'curves',curves,'bestX',bestX,'bestFit',bestFit,'nReinit',nre);

  R.(md)=A; save(fullfile('results','sys15_results.mat'),'-struct','R');
end
fid=fopen(fullfile('results','run15_progress.txt'),'a'); fprintf(fid,'DONE %s\n',datestr(now)); fclose(fid);
end
