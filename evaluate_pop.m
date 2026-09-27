function [fit, obj, feas, Xs, vsum] = evaluate_pop(X, S, xi)
%EVALUATE_POP Penalised fitness of a population for one benchmark system.
%   X   : n-by-D matrix, columns [TMS(1..m), PS(1..m)] (PS continuous).
%   S   : struct from GET_SYSTEM.  xi : CTI penalty coefficient (1e4).
%   fit : penalised objective;  obj : raw T_op (sum of near-end primary
%         times);  feas : logical, zero CTI violation over ALL pairs and
%         every primary operative;  Xs : X with PS snapped to the tap grid;
%   vsum: total CTI violation (s).
%
%   Rules (Section 2.5 of the manuscript):
%   * PS is snapped to the nearest discrete tap before any evaluation, so
%     every evaluated/reported solution is directly deployable.
%   * Every primary-backup scenario pair is a constraint.  A backup whose
%     pickup exceeds the scenario fault current (M<=1) is non-operative and
%     the pair is excluded.  A NON-OPERATIVE PRIMARY is never acceptable
%     and attracts a large penalty.

n   = size(X, 1);
m   = S.m;
TMS = min(max(X(:, 1:m), S.tms_lo), S.tms_hi);
PSc = X(:, m+1:end);

% snap PS to nearest tap (n-by-m against 1-by-T grid)
[~, idx] = min(abs(PSc(:) - S.taps), [], 2);
PS  = reshape(S.taps(idx), n, m);
Xs  = [TMS, PS];

beta = 0.02; gamma = 0.14;
ktime = @(M) gamma ./ (M.^beta - 1);          % T = k(M) * TMS

% ---- objective: near-end primary times -------------------------------
Mo   = (ones(n,1) * S.obj_If') ./ (PS(:, S.obj_relay) .* (ones(n,1) * S.ctr_o'));
opOK = Mo > 1;
To   = ktime(max(Mo, 1 + 1e-12)) .* TMS(:, S.obj_relay);
To(~opOK) = 0;                                 % handled via penalty below
obj  = sum(To, 2);
n_nop_primary = sum(~opOK, 2);

% ---- constraints over the complete pair set --------------------------
Mp = (ones(n,1) * S.If_p') ./ (PS(:, S.pi_p) .* (ones(n,1) * S.ctr_p'));
Mb = (ones(n,1) * S.If_b') ./ (PS(:, S.pi_b) .* (ones(n,1) * S.ctr_b'));
Tp = ktime(max(Mp, 1 + 1e-12)) .* TMS(:, S.pi_p);
Tb = ktime(max(Mb, 1 + 1e-12)) .* TMS(:, S.pi_b);

pOK = Mp > 1;                                  % primary must operate
bOK = Mb > 1;                                  % COVERAGE: backup must pick up
v   = max(0, S.cti - (Tb - Tp));
v(~bOK) = 0;      % handled by coverage penalty below (not excluded)
v(~pOK) = 0;                                   % covered by primary penalty
n_nop_primary = n_nop_primary + sum(~pOK, 2) + sum(~bOK, 2);  % + coverage

vsum = sum(v, 2);
fit  = obj + xi * vsum + 1e6 * n_nop_primary;
feas = (vsum <= 1e-6) & (n_nop_primary == 0);
end
