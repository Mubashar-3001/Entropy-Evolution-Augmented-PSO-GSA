function make_cti_all(sysnames)
%MAKE_CTI_ALL  Per-pair Tp, Tb and CTI-threshold figures from the printed settings.
%   make_cti_all            -> all four systems
%   make_cti_all({'30'})    -> 30-bus only
%
%   Self-contained: reads only
%     data/sysN_pairs.csv               (primary, If_primary_A, backup, If_backup_A)
%     data/sysN_ct.csv                  (relay, ctr)
%     data/sysN_certified_TMS_PS.csv    (relay, TMS, PS)  -- printed 4-decimal settings
%   and writes
%     results/pairs_sysN_check.csv      (pair, primary, backup, Tp_s, Tb_s, margin_s)
%     figs/cti_margin_Nbus.{fig,pdf,png}
%   It also prints the check reported in Table 7 of the paper:
%   T_op of the printed settings, minimum margin and number of CTI violations.
%   Run from the matlab/ folder.

if nargin < 1, sysnames = {'3','8','15','30'}; end
CTI = 0.2;
if ~exist('figs','dir'),    mkdir('figs');    end
if ~exist('results','dir'), mkdir('results'); end

for k = 1:numel(sysnames)
    s = sysnames{k};
    P = readtable(fullfile('data', ['sys' s '_pairs.csv']));
    C = readtable(fullfile('data', ['sys' s '_ct.csv']));
    X = readtable(fullfile('data', ['sys' s '_certified_TMS_PS.csv']));

    ctr = zeros(max(C.relay),1); ctr(C.relay) = C.ctr;
    tms = zeros(max(X.relay),1); ps = tms;
    tms(X.relay) = X.TMS;        ps(X.relay) = X.PS;

    n  = height(P);
    Tp = zeros(n,1); Tb = zeros(n,1);
    for i = 1:n
        Tp(i) = iec_time(tms(P.primary(i)), ps(P.primary(i)), ctr(P.primary(i)), P.If_primary_A(i));
        Tb(i) = iec_time(tms(P.backup(i)),  ps(P.backup(i)),  ctr(P.backup(i)),  P.If_backup_A(i));
    end
    mg = Tb - Tp;

    % objective: near-end time of each primary relay (first scenario of each primary)
    [~, ia] = unique(P.primary, 'stable');
    Top = sum(Tp(ia));
    fprintf('%3s-bus: T_op(printed) = %.4f s | min margin = %.5f s | CTI violations = %d | non-operative = %d\n', ...
        s, Top, min(mg), sum(mg < CTI - 1e-12), sum(~isfinite(mg)));

    out = table((1:n)', P.primary, P.backup, Tp, Tb, mg, ...
        'VariableNames', {'pair','primary','backup','Tp_s','Tb_s','margin_s'});
    writetable(out, fullfile('results', ['pairs_sys' s '_check.csv']));

    % ---------------- figure ----------------
    labels = strcat('R', string(P.primary), '\rightarrowR', string(P.backup));
    fig = figure('Color','w','Position',[80 80 max(700, 16*n) 420]);
    hold on; box on; grid on;
    x = 1:n;
    bar(x-0.19, Tp, 0.36, 'FaceColor', [0.18 0.43 0.71], 'DisplayName', 'T_p (primary)');
    bar(x+0.19, Tb, 0.36, 'FaceColor', [0.88 0.48 0.22], 'DisplayName', 'T_b (backup)');
    plot(x, Tp + CTI, 'k--', 'LineWidth', 1.1, ...
        'DisplayName', sprintf('T_p + CTI (%.1f s) threshold', CTI));
    if max(Tb) > 5*median(Tb), set(gca,'YScale','log'); end    % keeps an outlier bar readable
    set(gca, 'XTick', x, 'XTickLabel', labels, 'XTickLabelRotation', 90, ...
        'FontSize', max(5, min(8, 500/n)));
    xlim([0.3, n+0.7]);
    ylabel('Time (s)');
    title(sprintf('IEEE %s-bus: T_p, T_b and CTI threshold per pair (Stage B, printed settings)', s));
    legend('Location','northeast','FontSize',8);

    base = fullfile('figs', sprintf('cti_margin_%sbus', s));
    savefig(fig, [base '.fig']);
    set(fig,'PaperPositionMode','auto');
    print(fig, base, '-dpdf', '-bestfit');
    print(fig, base, '-dpng', '-r300');
    close(fig);
end
disp('Done: figs/cti_margin_*bus.{fig,pdf,png} and results/pairs_sys*_check.csv');
end

function t = iec_time(tms, ps, ctr, If)
%IEC 60255-151 standard inverse: T = 0.14*TMS / (M^0.02 - 1), M = If/(PS*CTR)
M = If / (ps * ctr);
if M <= 1
    t = inf;            % relay cannot pick up (coverage violated)
else
    t = 0.14 * tms / (M^0.02 - 1);
end
end
