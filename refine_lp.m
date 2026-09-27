function [fbest, tms, ps] = refine_lp(S, X, maxSweeps)
%REFINE_LP Stage-B polish: tap-conditional LP + tap coordinate descent.
%   Starting from solution X = [TMS, PS] (PS snapped by EVALUATE_POP), the
%   plug-setting taps are fixed and the TMS sub-problem -- which is exactly
%   linear -- is solved to optimality with CERTIFY_LP.  A monotone
%   coordinate descent over the discrete tap grid (one relay at a time,
%   re-certifying by LP) then improves the tap assignment until no single-
%   tap move helps.  Every returned solution therefore carries its own LP
%   optimality certificate for the final tap assignment, and is feasible
%   and deployable by construction.
if nargin < 3, maxSweeps = 6; end
m  = S.m;
ps = X(m+1:end)';  ps = cover_repair(S, ps);                       % column, already on the tap grid
[fbest, tms, ef] = certify_lp(S, ps);
if ef ~= 1
    fbest = inf;
    % Phase 0: slack-LP feasibility restoration -- descend taps on total
    % CTI violation (an LP with slack variables) until a feasible tap
    % assignment is found, then continue with objective descent below.
    v = viol_lp(S, ps);
    for sw = 1:maxSweeps
        moved = false;
        for i = 1:m
            cur = ps(i);
            for tt = S.taps
                if tt == cur, continue; end
                ps(i) = tt; vn = viol_lp(S, ps);
                if vn < v - 1e-9, v = vn; cur = tt; moved = true; else, ps(i) = cur; end
            end
            ps(i) = cur;
        end
        if v <= 1e-9 || ~moved, break; end
    end
    [fbest, tms, ef] = certify_lp(S, ps);
    if ef ~= 1, fbest = inf; end
end
for sweep = 1:maxSweeps
    improved = false;
    for i = 1:m
        cur = ps(i);
        for t = S.taps
            if t == cur, continue; end
            ps(i) = t;
            [f, x, ef] = certify_lp(S, ps);
            if ef == 1 && f < fbest - 1e-9
                fbest = f; tms = x; cur = t; improved = true;
            else
                ps(i) = cur;
            end
        end
        ps(i) = cur;
    end
    if ~improved, break; end
end
end


function v = viol_lp(S, ps)
%VIOL_LP Minimum total CTI violation at fixed taps (LP with slacks).
beta = 0.02; gm = 0.14; kfun = @(M) gm ./ (M.^beta - 1);
A = []; b = []; nc = 0;
for i = 1:S.M
    Mb = S.If_b(i) / (ps(S.pi_b(i)) * S.ctr_b(i));
    if Mb <= 1, continue; end
    nc = nc + 1;
    Mp = S.If_p(i) / (ps(S.pi_p(i)) * S.ctr_p(i));
    row = zeros(1, S.m);
    row(S.pi_p(i)) = kfun(Mp); row(S.pi_b(i)) = -kfun(Mb);
    A = [A; row]; b = [b; -S.cti]; %#ok<AGROW>
end
Af = [A, -eye(nc)];                       % kp*Tp - kb*Tb - sl <= -CTI
c  = [zeros(S.m,1); ones(nc,1)];
lb = [S.tms_lo*ones(S.m,1); zeros(nc,1)];
ub = [S.tms_hi*ones(S.m,1); inf(nc,1)];
opts = optimoptions('linprog','Display','none');
[~, v, ef] = linprog(c, Af, b, [], [], lb, ub, opts);
if ef ~= 1, v = inf; end
end


function ps = cover_repair(S, ps)
%COVER_REPAIR Lower any tap whose relay cannot pick up its assigned duty.
for it = 1:12
    Mb = S.If_b ./ (ps(S.pi_b).*S.ctr_b);  Mp = S.If_p ./ (ps(S.pi_p).*S.ctr_p);
    bb = find(Mb <= 1); bp = find(Mp <= 1);
    if isempty(bb) && isempty(bp), return; end
    for k = bb(:)'
        rr = S.pi_b(k); cand = S.taps(S.taps < S.If_b(k)/S.ctr_b(k) - 1e-9);
        if isempty(cand), return; end
        ps(rr) = max(cand);
    end
    for k = bp(:)'
        rr = S.pi_p(k); cand = S.taps(S.taps < S.If_p(k)/S.ctr_p(k) - 1e-9);
        if isempty(cand), return; end
        ps(rr) = max(cand);
    end
end
end
