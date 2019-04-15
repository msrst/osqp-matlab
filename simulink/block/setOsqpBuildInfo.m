function setOsqpBuildInfo( buildInfo )
%SETOSQPBUILDINFO Add the generated OSQP sources and includes to the RTW build process
%
% This function will add the OSQP generated source files and includes to the
% Matlab build path.
% 
% This function is designed to be called as the PostCodeGenCommand for a Simulink model.
% This setting can be found in Configuration Parameters->Code Generation (Advanced Parameters)
%

  disp('  Adding OSQP files and paths to the build process');

  %% Get the directory where the build is happening
  buildDir = RTW.getBuildDir(bdroot).BuildDirectory;
  osqpDir = fullfile(buildDir, 'osqp_code');
  
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

  %% Add a define to say if nonfinite number support is included by RTW
  nonfinite = get_param('quadcopter_example', 'SupportNonFinite');
  switch (nonfinite)
  case 'on'
    buildInfo.addDefines('-DOSQP_NONFINITE');
  case 'off'

  otherwise
    error('Unable to determine if nonfinite numbers are supported');
  end

end
