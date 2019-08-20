function osqp_setBuildInfo( buildInfo )
%OSQP_SETBUILDINFO Add the generated OSQP sources and includes to the RTW build process
%
% This function will add the OSQP generated source files and includes to the
% Matlab build path using the buildInfo object.
% 
% By default, this function is called using a make_rtw_hook function. A sample hook
% can be found in osqp_makeRTWHook.m. If desired, this function can be called from a
% user-written make_rtw_hook function by placing the command
%   osqp_setBuildInfo( buildInfo );
% inside the case for the after-tlc hook.
%

  disp('  Adding OSQP files and paths to the build process');

  %% Find the directory that the OSQP files were exported to
  dirFile = [RTW.getBuildDir(bdroot).BuildDirectory, filesep, 'osqpdir.mat'];
  if( exist(dirFile, 'file') )
    load(dirFile);
  else
    buildDir = RTW.getBuildDir(bdroot).BuildDirectory;
    osqpDir = fullfile(buildDir, 'osqp_code');
  end
  
  
  %% Get the directories where the OSQP sources and includes are located
  osqpIncPath = fullfile(osqpDir, 'include');
  osqpSrcPath = fullfile(osqpDir, 'src', 'osqp');


  %% Add those directories to the build spec
  buildInfo.addIncludePaths( osqpIncPath );
  buildInfo.addSourcePaths(  osqpSrcPath );


  %% Add the source files to the build spec
  srcFiles = dir(osqpSrcPath);
  for ( i = 1:1:length(srcFiles) )
    % See if the file is a .c or .cpp file
  	if ( isempty( regexpi( srcFiles(i).name, '(.c$)|(.cpp$)' ) ) )
  		% If it isn't, then skip it
      continue
  	end

    buildInfo.addSourceFiles( srcFiles(i).name );
  end


  %% If running on linux, include the c99 option so GCC uses c99 to compile
  if ( ~ismac() && isunix() )
    buildInfo.addCompileFlags('-std=c99', 'OPTS');
  end

end
