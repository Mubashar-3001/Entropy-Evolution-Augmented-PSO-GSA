function make_cti_figure(sysnames)
%MAKE_CTI_FIGURE  Per-pair Tp, Tb and CTI-margin bar chart for the
%   certified PSO-GSA-EE solution, one figure per system.
%   Reads results/pairs_sys<k>_check.csv, written by VERIFY_CERTIFIED.m
%   (columns: pair, primary, backup, Tp_s, Tb_s, margin_s).
%   Run this from the matlab/ folder, AFTER verify_certified.m has been
%   run at least once (main_run_all.m already calls it).
if nargin < 1, sysnames = {'3','8','15','30'}; end
if ~exist('figs','dir'), mkdir('figs'); end
CTI = 0.2;

for k = 1:numel(sysnames)
    s = sysnames{k};
    fn = fullfile('results',['pairs_sys' s '_check.csv']);
    if ~exist(fn,'file')
        warning('%s not found -- run verify_certified.m first.', fn); continue;
    end
    Tb = readtable(fn);
    n = height(Tb);
    Tp = Tb.Tp_s;
    Tbk = Tb.Tb_s;                       % 'inf' rows are non-operative (n.o.) backups
    isOp = isfinite(Tbk);
    labels = strcat(string(Tb.primary), '\rightarrow', string(Tb.backup));

    fig = figure('Color','w','Position',[80 80 max(700, 16*n) 420]);
    hold on; box on; grid on;
    x = 1:n;
    bar(x-0.19, Tp, 0.36, 'FaceColor', [0.18 0.43 0.71], 'DisplayName', 'T_p (primary)');
    Tbk_plot = Tbk; Tbk_plot(~isOp) = 0;
    bar(x+0.19, Tbk_plot, 0.36, 'FaceColor', [0.88 0.48 0.22], 'DisplayName', 'T_b (backup)');
    plot(x, Tp + CTI, 'k--', 'LineWidth', 1.1, 'DisplayName', sprintf('T_p + CTI (%.1fs) threshold', CTI));
    if any(~isOp)
        xno = x(~isOp);
        plot(xno, zeros(size(xno)), 'rx', 'MarkerSize', 9, 'LineWidth', 1.5, ...
             'DisplayName', 'non-operative (n.o.)');
    end
    set(gca, 'XTick', x, 'XTickLabel', labels, 'XTickLabelRotation', 90, ...
        'FontSize', max(5, min(8, 500/n)));
    xlim([0.3, n+0.7]);
    ylabel('Time (s)');
    title(sprintf('IEEE %s-bus: T_p, T_b and CTI margin per pair (certified PSO-GSA-EE)', s));
    legend('Location','northeast','FontSize',8);

    feasOp = sum((Tbk(isOp) - Tp(isOp)) >= CTI - 1e-6);
    fprintf('%s-bus: %d/%d operative pairs meet CTI >= %.1fs (min margin %.3fs)\n', ...
        s, feasOp, sum(isOp), CTI, min(Tbk(isOp)-Tp(isOp)));

    % --- .fig save, first and defensively checked ---
    figpath = fullfile('figs', sprintf('cti_margin_%sbus.fig', s));
    try
        savefig(fig, figpath);
        assert(exist(figpath,'file')==2, 'file not found after savefig');
        fprintf('  saved %s\n', figpath);
    catch ME
        fprintf(2, '  FAILED to save %s : %s\n', figpath, ME.message);
    end

    set(fig,'PaperPositionMode','auto');
    print(fig, fullfile('figs', sprintf('cti_margin_%sbus', s)), '-dpdf', '-bestfit');
    print(fig, fullfile('figs', sprintf('cti_margin_%sbus', s)), '-dpng', '-r300');
    close(fig);
end
disp('Done. Check the "saved .../.fig" lines above to confirm each .fig actually wrote.');
end