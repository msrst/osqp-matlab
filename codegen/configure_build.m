function configure_build( target_dir, EMBEDDED_FLAG, FLOAT_FLAG, LONG_FLAG )
%CONFIGURE_BUILD Configure the OSQP build using CMake

% Add embedded flag
cmake_args = sprintf('-DEMBEDDED:INT=%i', EMBEDDED_FLAG);

% Add float flag
cmake_args = sprintf('%s -DDFLOAT:BOOL=%s', cmake_args, FLOAT_FLAG);

% Add long flag
cmake_args = sprintf('%s -DDLONG:BOOL=%s', cmake_args, LONG_FLAG);


% Generate osqp_configure.h file by running cmake
current_dir = pwd;
build_dir = fullfile(target_dir, 'build');
cd(target_dir);
if exist(build_dir, 'dir')
    rmdir('build', 's');
end
mkdir('build');
cd('build');


% Add specific generators for windows linux or mac
if (ispc)
    [status, output] = system(sprintf('%s %s -G "MinGW Makefiles" ..', 'cmake', cmake_args));
else
    [status, output] = system(sprintf('%s %s -G "Unix Makefiles" ..', 'cmake', cmake_args));
end
if(status)
    fprintf('\n');
    disp(output);
    error('Error generating osqp_configure.h');
end
cd(current_dir);

end
