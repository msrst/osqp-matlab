function blkStruct = slblocks
    % Add the OSQP library to the library browser in Simulink
    blkStruct.Name        = 'OSQP Solver';
    blkStruct.MaskDisplay = ['OSQP' sprintf('\n') 'Solver'];
    blkStruct.OpenFcn     = 'osqp_library';
    
    blkStruct.Browser(1).Library = 'osqp_library';
    blkStruct.Browser(1).Name    = 'OSQP Solver';