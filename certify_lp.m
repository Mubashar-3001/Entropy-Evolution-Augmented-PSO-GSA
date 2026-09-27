function [fmin, tms, exitflag] = certify_lp(S, ps)
%CERTIFY_LP Tap-assignment-conditional LP certificate (Section 5.1).
%   With PS fixed on the tap grid, each operating time is linear in TMS:
%   T = k(M) * TMS.  Minimising the sum of near-end primary times subject
%   to every operative-pair CTI constraint and TMS box bounds is an LP,
%   solved here to optimality with LINPROG.  The returned FMIN is the
%   certified minimum T_op for this tap assignment; the released certified
%   solutions attain it exactly (verify with VERIFY_CERTIFIED).
if nargin < 2, ps = S.cert_ps; end
beta = 0.02; gm = 0.14;
kfun = @(M) gm ./ (M.^beta - 1);
c = zeros(S.m, 1);
Mo = S.obj_If ./ (ps(S.obj_relay) .* S.ctr_o);
for i = 1:S.mo
    c(S.obj_relay(i)) = c(S.obj_relay(i)) + kfun(Mo(i));
end
A = []; b = [];
for i = 1:S.M
    Mb = S.If_b(i) / (ps(S.pi_b(i)) * S.ctr_b(i));
    if Mb <= 1                                % COVERAGE violated at these taps
        tms = []; fmin = inf; exitflag = -2; return
    end
    Mp = S.If_p(i) / (ps(S.pi_p(i)) * S.ctr_p(i));
    row = zeros(1, S.m);
    row(S.pi_p(i)) = row(S.pi_p(i)) + kfun(Mp);
    row(S.pi_b(i)) = row(S.pi_b(i)) - kfun(Mb);
    A = [A; row]; b = [b; -S.cti]; %#ok<AGROW>
end
opts = optimoptions('linprog', 'Display', 'none');
[tms, fmin, exitflag] = linprog(c, A, b, [], [], ...
    S.tms_lo * ones(S.m,1), S.tms_hi * ones(S.m,1), opts);
end
