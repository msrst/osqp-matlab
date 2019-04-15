function makeInfo = rtwmakecfg() 
%%RTWMAKECFG This function is designed to add the OSQP sources to the
%makefile for the code generation

	disp('  Adding OSQP files and paths to the build process');

	%% Get the directory where the build is happening
	buildDir = RTW.getBuildDir(bdroot).BuildDirectory;
	osqpDir = fullfile(buildDir, 'osqp_code');

	%% Get the directories where the OSQP sources and includes are located
	osqpIncPath = fullfile(osqpDir, 'include');
	osqpSrcPath = fullfile(osqpDir, 'src', 'osqp');

	makeInfo.includePath = {osqpIncPath};
	makeInfo.sourcePath  = {osqpSrcPath};

  %% Add the source files to the build spec
  srcFiles = dir(osqpSrcPath);
  src = {};
  for ( i = 1:1:length(srcFiles) )
    % See if the file is a .c or .cpp file
  	if ( isempty( regexpi( srcFiles(i).name, '(.c$)|(.cpp$)' ) ) )
  		% If it isn't, then skip it
      continue
  	end

    src = [src, srcFiles(i).name];
  end
	makeInfo.sources = src;

	makeInfo.precompile = 0;
	makeInfo.linkLibsObjs = {};



end
