function osqp_sfun(block)
% Level-2 MATLAB file S-Function for OSQP.

  setup(block);

%endfunction

function setup(block)

  % basic problem sizes
  m  = block.DialogPrm(1).Data;
  n  = block.DialogPrm(2).Data;

  %% Register number of input and output ports
  block.NumInputPorts  = 9;  %refactor,warmstart,Px,Px_idx,Ax,Ax_idx,q,l,u
  block.NumOutputPorts = 17; %x,y,prim_inf_cert,dual_inf_cert, various info values

  %outputPortSize = [n,m,n,m,ones(1,14)];

  % Register the parameters.
  block.NumDialogPrms     = 9; %m,n,P,A,q,l,u, emptysolver, options
  block.DialogPrmsTunable = repmat({'Tunable'},[1 block.NumDialogPrms]);

  %% Setup functional port properties to dynamically
  %% inherited.
  block.SetPreCompInpPortInfoToDynamic;
  block.SetPreCompOutPortInfoToDynamic;

  %Set input port properties
  for i = 1:block.NumInputPorts
    block.InputPort(i).DirectFeedthrough = true;
    block.InputPort(i).DatatypeID  = 0;  % double
    block.InputPort(i).Complexity  = 'Real';
  end

  %Set output port properties

  %initialise all sizes to scalar
  outdims = ones(1,block.NumOutputPorts);

  %The first four output ports are x,y,prim_cert, dual_cert.
  %everything else is scalar
  outdims(1:4) = [n m m n];

  for i = 1:block.NumOutputPorts
    block.OutputPort(i).DatatypeID  = 0;  % double
    block.OutputPort(i).Complexity  = 'Real';
    block.OutputPort(i).SamplingMode = 'Sample';
    block.OutputPort(i).Dimensions = outdims(i);
  end

  %% Set block sample time to inherited
  block.SampleTimes = [-1 0];

  %% Set the block simStateCompliance to default (i.e., same as a built-in block)
  block.SimStateCompliance = 'DefaultSimState';

  %% Run accelerator on TLC
  block.SetAccelRunOnTLC(true);

  %% Register methods
  block.RegBlockMethod('Outputs',@Output);
  block.RegBlockMethod('PostPropagationSetup', @DoPostPropSetup);
  block.RegBlockMethod('SetInputPortSamplingMode', @SetInpPortFrameData);
  block.RegBlockMethod('SetInputPortDimensions', @SetInpPortDims);
  block.RegBlockMethod('WriteRTW', @WriteRTW);

%endfunction

function SetInpPortDims(block, idx, di)
  block.InputPort(idx).Dimensions = di;
%endfunction

function DoPostPropSetup(block)

  %solver setup

  %the solver object is created as a parameter,
  %since there is seemingly no place to stash it in the
  %internal memory of the block.   In C it would be possible
  %to store it in pwork, but there's no .m s function analogy
%   m       = block.DialogPrm(1).Data;
%   n       = block.DialogPrm(2).Data;
  P       = block.DialogPrm(3).Data;
  A       = block.DialogPrm(4).Data;
  q       = block.DialogPrm(5).Data;
  l       = block.DialogPrm(6).Data;
  u       = block.DialogPrm(7).Data;
  solver  = block.DialogPrm(8).Data;
  opts    = block.DialogPrm(9).Data;

  if(iscell(opts))
    solver.setup(P,q,A,l,u,opts{:})
  else
    solver.setup(P,q,A,l,u,opts)
  end

%endfunction



function Output(block)

  %grab all of the external signals
  %-----------------------------------------------------
  refactor  = block.InputPort(1).Data;
  warmstart = block.InputPort(2).Data;
  Px_idx    = block.InputPort(3).Data;
  Px        = block.InputPort(4).Data;
  Ax_idx    = block.InputPort(5).Data;
  Ax        = block.InputPort(6).Data;
  q         = block.InputPort(7).Data;
  l         = block.InputPort(8).Data;
  u         = block.InputPort(9).Data;


  %grab parameters and solver data
  %-----------------------------------------------------
  m      = block.DialogPrm(1).Data;
  n      = block.DialogPrm(2).Data;
  solver = block.DialogPrm(8).Data;


  %construct data updates lists
  %-----------------------------------------------------
  %a list of updates to push to the solver
  updates = {};

  %if refactoring is enabled, then add updates to Px etc
  if(refactor)
      updates = [updates,{'Px',Px,'Px_idx',Px_idx,'Ax',Ax,'Ax_idx',Ax_idx}];
  end

  %add updates to q/l/u if they are not NaN valued
  if(~any(isnan(q))), updates = [updates,{'q',q}]; end
  if(~any(isnan(l))), updates = [updates,{'l',l}]; end
  if(~any(isnan(u))), updates = [updates,{'u',u}]; end

  if(length(updates) > 0)
      solver.update(updates{:})
  end

  %reset variables to zero on cold start
  %-----------------------------------------------------
  if(~warmstart)
      solver.warm_start('x',zeros(n,1),'y', zeros(m,1));
  end

  %solve and map to outputs
  %-----------------------------------------------------
  sol = solver.solve();
  %will be gathered in first bus
  block.OutputPort(01).Data = sol.x;
  block.OutputPort(02).Data = sol.y;
  block.OutputPort(03).Data = sol.prim_inf_cert;
  block.OutputPort(04).Data = sol.dual_inf_cert;

  %will be gathered in second bus
  block.OutputPort(05).Data = sol.info.iter;
  block.OutputPort(06).Data = sol.info.status_val;
  block.OutputPort(07).Data = sol.info.status_polish;
  block.OutputPort(08).Data = sol.info.obj_val;
  block.OutputPort(09).Data = sol.info.pri_res;
  block.OutputPort(10).Data = sol.info.dua_res;
  block.OutputPort(11).Data = sol.info.setup_time;
  block.OutputPort(12).Data = sol.info.solve_time;
  block.OutputPort(13).Data = sol.info.update_time;
  block.OutputPort(14).Data = sol.info.polish_time;
  block.OutputPort(15).Data = sol.info.run_time;
  block.OutputPort(16).Data = sol.info.rho_updates;
  block.OutputPort(17).Data = sol.info.rho_estimate;

%endfunction

function SetInpPortFrameData(block, idx, fd)

  block.InputPort(idx).SamplingMode = fd;
  block.OutputPort(1).SamplingMode  = fd;

%endfunction

function WriteRTW(block)
  % This function is called by Simulink when code generation is going to occur
  disp('Calling OSQP code generation routines');

  % Get the parent block (that has the mask)
  parentBlock = get_param(gcb, 'Parent');

  %% Extract the parameters
  m       = block.DialogPrm(1).Data;
  n       = block.DialogPrm(2).Data;
  P       = block.DialogPrm(3).Data;
  A       = block.DialogPrm(4).Data;
  q       = block.DialogPrm(5).Data;
  l       = block.DialogPrm(6).Data;
  u       = block.DialogPrm(7).Data;
  solver  = block.DialogPrm(8).Data;
  opts    = block.DialogPrm(9).Data;

  %% Save the problem parameters to the RTW file for code generation.
  block.WriteRTWParam('matrix', 'numCon', m);
  block.WriteRTWParam('matrix', 'numVar', n);
  block.WriteRTWParam('matrix', 'numnnzP', nnz(P));
  block.WriteRTWParam('matrix', 'numnnzA', nnz(A));
  %block.WriteRTWParam('matrix', 'P', full(P));
  %block.WriteRTWParam('matrix', 'A', full(A));
  %block.WriteRTWParam('matrix', 'q', q);

  % Save the bounds (after converting to OSQP_INFTY)
  l = max(l, osqp.constant('OSQP_INFTY'));
  %block.WriteRTWParam('matrix', 'l', l);
  u = min(u, osqp.constant('OSQP_INFTY'));
  %block.WriteRTWParam('matrix', 'u', u);

  % Save the solver options
  opts = block.DialogPrm(9).Data;
  for (i=1:1:length(opts))
    if ( ~ischar(opts{i}) )
      opts{i} = num2str( opts{i} );
    end
  end
  optsstr = strjoin(opts, ',');
  %block.WriteRTWParam('string', 'opts', optsstr);


  %% Go through the mask and determine the settings for the solver
  %----------------------------------------------------------------
  % Determine if the matrices are updated
  refactor_style = get_param(parentBlock,'refactor_style');
  switch refactor_style
    case {'Never'}
      updateAP = 0;
      updateParam = 'vectors';

    case {'Always'}
      updateAP = 1;
      updateParam = 'matrices';

    case {'Triggered'}
      updateAP = 2;
      updateParam = 'matrices';

    otherwise
      error('Unrecognized refactorisation');

  end
  block.WriteRTWParam('matrix', 'updateAP', updateAP);

  % Determine if warmstarting is used
  warmstart_style  = get_param(parentBlock,'warmstart_style');
  switch warmstart_style
    case {'Never'}
      warmstart = 0;

    case {'Always'}
      warmstart = 1;

    case {'Triggered'}
      warmstart = 2;

    otherwise
      error('Unrecognized warmstart option');

  end
  block.WriteRTWParam('matrix', 'warmstart', warmstart);

  % Determine if the q vector is updated
  has_external_q_input = get_param(parentBlock,'has_external_q_input');
  switch has_external_q_input
    case {'off'}
      updateq = 0;

    case {'on'}
      updateq = 1;

    otherwise
      error('Unrecognized q update');

  end
  block.WriteRTWParam('matrix', 'updateq', updateq);

  % Determine if the bounds are updated
  has_external_bound_input = get_param(parentBlock,'has_external_bound_input');
  switch has_external_bound_input
    case {'off'}
      updatelu = 0;

    case {'on'}
      updatelu = 1;

    otherwise
      error('Unrecognized bounds update');

  end
  block.WriteRTWParam('matrix', 'updatelu', updatelu);


  %% Determine the data types to use
  %----------------------------------------------------------------

  % Determine if long long is supported
  longLongYes = get_param(bdroot, 'ProdLongLongMode');
  useLongLong = false;
  if ( strcmp(longLongYes, 'on') )
    useLongLong = true;
    block.WriteRTWParam('string', 'uselonglong', 'true');
    disp('  Using long long data type');

  else
    useLongLong = false;
    block.WriteRTWParam('string', 'uselonglong', 'false');
    disp('  Disabling long long data type');
  end


  % Determine the floating point data type to use
  dt = get_param(gcb, 'CompiledPortDataTypes');

  isdoublei = all( cellfun( @(x) strcmp(x, 'double'), dt.Inport) );
  isdoubleo = all( cellfun( @(x) strcmp(x, 'double'), dt.Outport) );
  isfloati  = all( cellfun( @(x) strcmp(x, 'single'), dt.Inport) );
  isfloato  = all( cellfun( @(x) strcmp(x, 'single'), dt.Outport) );

  if (isdoublei && isdoubleo)
    % All inputs and outputs are double
    useFloat = false;
    block.WriteRTWParam('string', 'useFloat', 'false');
    disp('  Using double data type');

  elseif (isfloati && isfloato)
    % All inputs and outputs are single
    useFloat = true;
    block.WriteRTWParam('string', 'useFloat', 'true');
    disp('  Using float data type');

  else
    % The inputs and outputs do not match
    disp(['   Input types: ', dt.Inport]);
    disp(['  Output types: ', dt.Outport]);
    error('All inputs and outputs must be the same data type');
  end

  % Determine if nonfinite numbers are supported
  nonfinite = get_param(bdroot, 'SupportNonFinite');
  switch (nonfinite)
  case 'on'
    block.WriteRTWParam('matrix', 'nonfinite', 1);
    disp('  Enabling OSQP support for nonfinite MATLAB numbers')
  case 'off'
    block.WriteRTWParam('matrix', 'nonfinite', 0);
    disp('  Disabling OSQP support for nonfinite MATLAB numbers')
  otherwise
    error('Unable to determine if nonfinite numbers are supported');
  end


  %% Create the OSQP code
  %----------------------------------------------------------------

  workspaceName = 'workspace';

  % The file where the custom OSQP build directory is saved
  dirFile = [RTW.getBuildDir(bdroot).BuildDirectory, filesep, 'osqpdir.mat'];
  if( exist(dirFile, 'file') )
    delete(dirFile);
  end

  % Figure out where to export the OSQP sources to
  p = Simulink.Mask.get(parentBlock);
  isCustom = p.Parameters(11).Value;

  if ( strcmp(isCustom, 'on') )
    % User-specified export location
    osqpDir = p.Parameters(12).Value;
    osqpDir = osqpDir(2:end-1);

    % Save the OSQP directory for the hook file
    save(dirFile, 'osqpDir');
  else
    % Default export location
    buildDir = RTW.getBuildDir(bdroot).BuildDirectory;
    osqpDir  = fullfile(buildDir, 'osqp_code');
  end

  disp(['  Generating OSQP source files into ', osqpDir]);

  % Call the code generation routine for the solver
  solver.codegen(osqpDir,...
                 'parameters', updateParam,...
                 'project_type', '',...
                 'mexname', 'emosqp',...
                 'force_rewrite', true,...
                 'FLOAT', useFloat,...
                 'LONG', useLongLong);


  % Tell the TLC where the code is and what the osqp workspace is called
  block.WriteRTWParam('string', 'osqp_code_dir', osqpDir);
  block.WriteRTWParam('string', 'osqp_src_dir', fullfile(osqpDir, 'src', 'osqp') );
  block.WriteRTWParam('string', 'osqp_inc_dir', fullfile(osqpDir, 'include') );
  block.WriteRTWParam('string', 'osqp_workspace', workspaceName);
  block.WriteRTWParam('string', 'osqp_workspaceFile', fullfile(osqpDir, 'src', 'osqp', workspaceName) );


  %% Check to make sure that the hook file is on the path and error if not
  %----------------------------------------------------------------
  tmf = get_param(bdroot, 'SystemTargetFile');
  [~, tar, ~] = fileparts(tmf);
  hookName = [tar, '_make_rtw_hook.m'];

  eval(['hookExist = which(''', hookName, ''');'])
  if ( isempty(hookExist) )
      errTxt = ['Unable to find the file ', hookName, ' on the path.'];
      errTxt = [errTxt, ' Please copy the file simulink/block/osqp_makeRTWHook.m'];
      errTxt = [errTxt, ' to your working directory and rename it to ' hookName];
      error(errTxt);
  end


%endfunction
