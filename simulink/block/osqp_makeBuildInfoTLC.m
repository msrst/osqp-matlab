function osqp_makeBuildInfoTLC( osqpDir, buildDir )
%OSQP_MAKEBUILDINFOTLC Make a TLC file to add all the OSQP sources to the build
%
% This function will generate a Target Language Compiler file that will
% automatically add the C source code and include paths for OSQP to the
% build environment.

  disp('  Generating TLC file to add OSQP sources & includes to the build environment');
  
  %% Get the directories where the OSQP sources and includes are located
  osqpIncPath = fullfile(osqpDir, 'include');
  osqpSrcPath = fullfile(osqpDir, 'src', 'osqp');


  %% Create the TLC
  tlcFname = fullfile(osqpDir, 'osqp_build.tlc');
  tlcFile = fopen(tlcFname, 'w');

  fprintf(tlcFile, '%%%% This file is automatically generated by Simulink during the code generation routine.\n');
  fprintf(tlcFile, '%%%% This file will modify the build system to include the OSQP source files and\n');
  fprintf(tlcFile, '%%%% copy the header files onto the include path.\n\n');


  %% Add the source files to the build spec
  srcFiles = dir(osqpSrcPath);
  for ( i = 1:1:length(srcFiles) )
    % See if the file is a .c or .cpp file
  	if ( isempty( regexpi( srcFiles(i).name, '(.c$)|(.cpp$)' ) ) )
  		% If it isn't, then skip it
      continue
  	end

    % See if the file is a workspace file
    if ( ~isempty( regexpi( srcFiles(i).name, 'workspace' ) ) )
      % If it isn't, then skip it
      % These files will be added in the actual TLC
      continue
    end

    % Write the actual file
    [~, srcName, ~] = fileparts(srcFiles(i).name);
    srcName = fullfile(osqpSrcPath, srcName);
    srcName = regexprep(srcName, '([\\])', '\\$1');
    fprintf(tlcFile, '%%<LibAddToModelSources("%s")>\n', srcName);
  end
  fprintf(tlcFile, '\n');


  %% Add the copy of the include files to the build directory to the build spec
  incFiles = dir(osqpIncPath);
  for ( i = 1:1:length(incFiles) )
    % See if the file is a .h or .hpp file
    if ( isempty( regexpi( incFiles(i).name, '(.h$)|(.hpp$)' ) ) )
      % If it isn't, then skip it
      continue
    end

    % Copy the file
    srcName = fullfile(osqpIncPath, incFiles(i).name);
    dstName = fullfile(buildDir,    incFiles(i).name);

    % Escape the strings
    srcName = regexprep(srcName, '([\\])', '\\$1');
    dstName = regexprep(dstName, '([\\])', '\\$1');

    fprintf(tlcFile, '%%assign temp = FEVAL( "copyfile", "%s", "%s" )\n', srcName, dstName);
  end

  fclose(tlcFile);

end