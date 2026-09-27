function rename_lit_methods()
%RENAME_LIT_METHODS  Align bar-chart method labels with the paper (run once).
%   SA -> Seeker (seeker algorithm), MINLP -> MILP, IDA -> TLBO. Then run make_figures.
for s = {'3','8','15','30'}
    f = fullfile('data', ['sys' s{1} '_lit_bars.csv']);
    x = fileread(f);
    x = regexprep(x, '^SA,',    'Seeker,', 'lineanchors');
    x = regexprep(x, '^MINLP,', 'MILP,',   'lineanchors');
    x = regexprep(x, '^IDA,',   'TLBO,',   'lineanchors');
    fid = fopen(f, 'w'); fwrite(fid, x); fclose(fid);
end
disp('lit_bars method names updated.');
end
