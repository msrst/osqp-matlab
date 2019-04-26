function osqp_makeRTWHook(hookMethod, modelName,...
                          rtwroot, templateMakefile,...
                          buildOpts, buildArgs, buildInfo)
%%OSQP_MAKERTWHOOK RTW hook to configure the OSQP build process
%
% This function is the hook used during the code generation processes to 
% configure the build directories and paths to contain the OSQP files.
% To use, copy this file into the working directory and rename to
%   TMF_make_rtw_hook.m
% where TMF is the name of the template makefile used (e.g. grt for the 
% generic real-time environment, raccel for the Rapid Accelerator, etc.)

  switch hookMethod
   case 'error'
    % Called if an error occurs anywhere during the build. Valid arguments
    % at this stage are hookMethod and modelName.

   case 'entry'
    % Called at start of code generation process (before anything happens.)
    % Valid arguments at this stage are hookMethod, modelName, and buildArgs.
    
   case 'before_tlc'
    % Called just prior to invoking TLC Compiler (actual code generation.)
    % Valid arguments at this stage are hookMethod, modelName, and
    % buildArgs
    
   case 'after_tlc'
    % Called just after to invoking TLC Compiler (actual code generation.)
    % Valid arguments at this stage are hookMethod, modelName, and
    % buildArgs
    
    % Add the OSQP sources to the build process
    osqp_setBuildInfo( buildInfo );

   case 'before_make'
    % Called after code generation is complete, and just prior to kicking
    % off make process (assuming code generation only is not selected.)  All
    % arguments are valid at this stage.

   case 'after_make'
    % Called after make process is complete. All arguments are valid at 
    % this stage.
    
   case 'exit'
    % Called at the end of the build process.  All arguments are valid
    % at this stage.

  end

