function make_emosqp(target_dir, mex_cfile)
% Matlab MEX makefile for code generated solver.


% Get make and mex commands
mex_cmd = sprintf('mex -O -silent');

% Add arguments to mex compiler
mexoptflags = '-DMATLAB';

% Set optimizer flag
if (~ispc)
    mexoptflags = sprintf('%s %s', mexoptflags, 'COPTIMFLAGS=''-O3''');
end

% Include directory
inc_dir = fullfile(sprintf(' -I%s', target_dir), 'include');

% Source files
cfiles = '';
src_files = dir(fullfile(target_dir, 'src', 'osqp', '*c'));
for i = 1 : length(src_files)
    cfiles = sprintf('%s %s', cfiles, ...
        fullfile(target_dir, 'src', 'osqp', src_files(i).name));
end

% Compile interface
fprintf('Compiling and linking osqpmex...');

% Compile command
cmd = sprintf('%s %s %s %s %s', mex_cmd, mexoptflags, inc_dir, mex_cfile, cfiles);

% Compile
eval(cmd);
fprintf('\t\t\t\t[done]\n');


end
