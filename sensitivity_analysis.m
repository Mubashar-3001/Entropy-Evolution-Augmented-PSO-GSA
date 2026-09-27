function sensitivity_analysis(sysnames, nRunsSens)
%SENSITIVITY_ANALYSIS Common sensitivity + complexity figure (Fig. sens).
%   Panel (a): mean final T_op of PSO-GSA-EE, normalised by each system's
%   certified minimum, versus the entropy threshold Hmin.
%   Panel (b): mean wall-clock per run versus problem dimension D for all
%   four algorithms (complexity scaling), from the main experiments.
if nargin < 2, nRunsSens = 20; end   % raise to 50 for the final camera-ready
Hgrid = [0.05 0.1 0.2 0.3 0.5];
cert = containers.Map({'3','8','15','30'}, [1.370341 5.290527 11.954423 33.591593]);
P0 = default_params();
res = zeros(numel(sysnames), numel(Hgrid));
for k = 1:numel(sysnames)
    S = get_system(sysnames{k});
    for h = 1:numel(Hgrid)
        P = P0; P.Hmin = Hgrid(h);
        f = zeros(nRunsSens,1);
        for s = 1:nRunsSens
            o = run_optimizer(S, 'PSOGSAEE', 1000+s, P);
            f(s) = o.bestFit;
        end
        res(k,h) = mean(f) / cert(sysnames{k});
        fprintf('sens %s-bus Hmin=%.2f mean/cert=%.4f\n', sysnames{k}, Hgrid(h), res(k,h));
    end
end
save(fullfile('results','sensitivity.mat'),'res','Hgrid','sysnames','nRunsSens');

figure('Color','w','Position',[80 80 980 400]);
subplot(1,2,1); hold on; box on; grid on;
mk = {'-o','-s','-^','-d'};
for k = 1:numel(sysnames)
    plot(Hgrid, res(k,:), mk{k}, 'LineWidth', 1.6, 'MarkerSize', 6);
end
xlabel('Entropy threshold H_{min}');
ylabel('Mean T_{op} / certified minimum');
legend(cellfun(@(s)['IEEE ' s '-bus'], sysnames, 'UniformOutput', false), ...
       'Location','best');
title('(a) Sensitivity to H_{min}','FontWeight','normal');
set(gca,'FontName','Times','FontSize',10);

subplot(1,2,2); hold on; box on; grid on;
algs = {'PSO','GSA','PSOGSA','PSOGSAEE'};
labs = {'PSO','GSA','PSO-GSA','PSO-GSA-EE'};
Dv = zeros(1,numel(sysnames)); W = zeros(numel(algs), numel(sysnames));
for k = 1:numel(sysnames)
    R = load(fullfile('results',['sys' sysnames{k} '_results.mat']));
    Dv(k) = 2*R.S.m;
    for a = 1:numel(algs), W(a,k) = mean(R.(algs{a}).walls); end
end
[Dv, ix] = sort(Dv); W = W(:, ix);
for a = 1:numel(algs)
    plot(Dv, W(a,:), mk{a}, 'LineWidth', 1.6, 'MarkerSize', 6);
end
xlabel('Problem dimension D (decision variables)');
ylabel('Mean wall-clock per run (s)');
legend(labs, 'Location','northwest');
title('(b) Complexity scaling','FontWeight','normal');
set(gca,'FontName','Times','FontSize',10);
savefig(gcf, fullfile('figs','sens_complexity.fig'));
set(gcf,'PaperPositionMode','auto');
print(gcf, fullfile('figs','sens_complexity'), '-dpdf','-bestfit');
print(gcf, fullfile('figs','sens_complexity'), '-dpng','-r300');
close(gcf);
end
