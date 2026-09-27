function make_figures(sysnames)
%MAKE_FIGURES Convergence, box-plot, and literature bar charts for each
%   system, in the visual style of the previous manuscript's figures.
%   Requires results/sysX_results.mat from RUN_EXPERIMENTS.
%   Outputs figs/conv_<s>bus.[pdf|png], figs/box_<s>bus.*, figs/bar_<s>bus.*

if ~exist('figs', 'dir'), mkdir('figs'); end
certified = containers.Map({'3','8','15','30'}, ...
                           [1.370341, 5.290527, 11.954423, 33.591593]);
algs  = {'PSO', 'GSA', 'PSOGSA', 'PSOGSAEE'};
labs  = {'PSO', 'GSA', 'PSO-GSA', 'PSO-GSA-EE'};

for k = 1:numel(sysnames)
    s = sysnames{k};
    R = load(fullfile('results', ['sys' s '_results.mat']));
    T = size(R.PSOGSAEE.curves, 2);

    % ---------------- convergence: best / average / worst -------------
    C = R.PSOGSAEE.curves;
    [~, ib] = min(C(:, end)); [~, iw] = max(C(:, end));
    figure('Color', 'w', 'Position', [100 100 560 420]); hold on; box on; grid on;
    plot(1:T, C(ib, :), 'b-', 'LineWidth', 1.8);
    plot(1:T, mean(C, 1), 'r-', 'LineWidth', 1.8);
    plot(1:T, C(iw, :), 'Color', [0.93 0.69 0.13], 'LineWidth', 1.8);
    xlabel('Iterations'); ylabel('Stage-A penalised fitness (s)');
    legend({'Best', 'Average', 'Worse'}, 'Location', 'best');
    bt = C(ib, end);
    annotation('textbox', [0.45 0.55 0.34 0.12], 'String', ...
        sprintf('Iteration=%d\nOp-Time=%.4f', T, bt), ...
        'BackgroundColor', 'w', 'EdgeColor', 'k', 'FontSize', 9);
    set(gca, 'FontName', 'Times', 'FontSize', 11);
    savefig_both(gcf, sprintf('conv_%sbus', s));

    % ---------------- box plot: PSO / GSA / PSOGSA / PSOGSAEE ---------
    Fm = zeros(R.P.nRuns, 4); certN = zeros(1,4);
    for a = 1:4
        Fm(:, a) = R.(algs{a}).rawFinals;               % Stage-A distributions
        certN(a) = sum(abs(R.(algs{a}).finals - certified(s)) < 1e-3);
    end
    figure('Color', 'w', 'Position', [100 100 640 460]); hold on; box on;
    lb = cell(1,4); for a=1:4, lb{a} = sprintf('%s (%d/50)', labs{a}, certN(a)); end
    boxplot(Fm, 'Labels', lb, 'Symbol', 'r+');
    if max(Fm(:))/max(min(Fm(:)),eps) > 50, set(gca,'YScale','log'); end
    plot(1:4, mean(Fm, 1), 'd', 'MarkerFaceColor', [0.95 0.85 0.1], ...
         'MarkerEdgeColor', 'k', 'MarkerSize', 7);
    ylabel('Stage-A final penalised fitness (s)'); xlabel(sprintf('IEEE %s-bus System', s));
    pstr = '';
    for a = 1:3
        p = ranksum(Fm(:, a), Fm(:, 4));
        pstr = sprintf('%sp(%s vs EE) = %.2e\n', pstr, labs{a}, p);
    end
    mu = mean(Fm(:, 4)); sd = std(Fm(:, 4));
    ci = 1.96 * sd / sqrt(R.P.nRuns);
    stat = sprintf('PSO-GSA-EE\nMean = %.4f\nSTD = %.4f\n95%% CI = [%.4f, %.4f]', ...
                   mu, sd, mu - ci, mu + ci);
    annotation('textbox', [0.14 0.72 0.30 0.20], 'String', pstr, ...
        'BackgroundColor', 'w', 'FontSize', 8);
    annotation('textbox', [0.62 0.16 0.30 0.20], 'String', stat, ...
        'BackgroundColor', [0.92 0.94 1], 'FontSize', 8);
    set(gca, 'FontName', 'Times', 'FontSize', 11);
    savefig_both(gcf, sprintf('box_%sbus', s));

    % ---------------- literature bar chart ----------------------------
    Tb = readtable(fullfile('data', ['sys' s '_lit_bars.csv']));
    v = Tb.top_s; dg = Tb.dagger; nm = Tb.method;
    figure('Color', 'w', 'Position', [100 100 640 440]); hold on; box on;
    for i = 1:numel(v)
        if strcmp(nm{i}, 'PSO-GSA-EE')
            col = [0.85 0.33 0.10];
        elseif dg(i)
            col = [0.65 0.65 0.65];
        else
            col = [0.20 0.45 0.75];
        end
        bar(i, v(i), 0.65, 'FaceColor', col);
        txt = sprintf('%.2f', v(i)); if dg(i), txt = [txt char(8224)]; end %#ok<AGROW>
        text(i, v(i), txt, 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'bottom', 'FontSize', 8);
    end
    plot(xlim, certified(s) * [1 1], 'k--', 'LineWidth', 1.1);
    text(0.6, certified(s), sprintf(' certified minimum = %.4f s', certified(s)), ...
         'VerticalAlignment', 'bottom', 'FontSize', 8);
    set(gca, 'XTick', 1:numel(v), 'XTickLabel', nm, 'XTickLabelRotation', 30, ...
        'FontName', 'Times', 'FontSize', 10);
    ylabel('Operational Time (s)'); xlabel(sprintf('IEEE %s-Bus System', s));
    title([char(8224) ' bars lie below the certified minimum of the complete-pair formulation (grey)'], ...
          'FontSize', 8, 'FontWeight', 'normal', 'Interpreter', 'none');
    savefig_both(gcf, sprintf('bar_%sbus', s));
end
end

function savefig_both(h, name)
savefig(h, fullfile('figs', [name '.fig']));   % editable .fig for legend/annotation tweaks
set(h, 'PaperPositionMode', 'auto');
print(h, fullfile('figs', name), '-dpdf', '-bestfit');
print(h, fullfile('figs', name), '-dpng', '-r300');
close(h);
end
