function fix_sys15_feas()
%FIX_SYS15_FEAS  One-off correction of results/sys15_results.mat (run once).
%   The 15-bus rerun script stored Stage-B success in the field .feas; the rest of the
%   pipeline (make_tables.m) expects Stage-A feasibility there. The true Stage-A
%   feasibility was recomputed into results/sys15_stageA.mat. This copies it across.
%   Expected Stage-A feasible counts after the fix: PSO 0, GSA 33, PSO-GSA 0, PSO-GSA-EE 1.
R  = load(fullfile('results','sys15_results.mat'));
SA = load(fullfile('results','sys15_stageA.mat'));
algs = {'PSO','GSA','PSOGSA','PSOGSAEE'};
for a = 1:numel(algs)
    R.(algs{a}).feas = SA.(algs{a}).feas(:);
    fprintf('%-10s Stage-A feasible %2d/50 | reaches optimum %2d/50\n', algs{a}, ...
        sum(R.(algs{a}).feas), sum(abs(R.(algs{a}).finals - 11.954423) < 1e-3));
end
save(fullfile('results','sys15_results.mat'), '-struct', 'R');
disp('sys15_results.mat corrected.');
end
