classdef codegen_simulink_tests < matlab.unittest.TestCase
    %Test the Simulink code generation

    properties
        basedir
        tol

    end

    methods(TestMethodSetup)
        function setup_problem(testCase)
            % Create the GRT hook
            testCase.basedir = cd();

            prevwarn = warning('off', 'MATLAB:MKDIR:DirectoryExists');
            mkdir( 'testTemp' );
            warning( prevwarn );

            copyfile( '../simulink/block/osqp_makeRTWHook.m', './testTemp/grt_make_rtw_hook.m');

            % Setup tolerance
            testCase.tol = 1e-05;
        end
    end

    methods (Test)
        function quadcopter(testCase)
            % Test the quadcopter example
            cd( 'testTemp' );

            % Load the code generation example
            load_system( '../../simulink/examples/quadcopter_example_codegen.mdl' );
            evalc( 'slbuild(''quadcopter_example_codegen'', ''StandaloneCoderTarget'',  ''ForceTopModelBuild'', true);' );
            evalc( 'sim( gcs );' );

            evalc( 'system( ''./quadcopter_example_codegen'' );' );
            load( 'quadcopter_example_codegen.mat' )

            [~, n] = size( rt_states.signals.values );
            for i=1:1:n
                simNorm = norm( states.signals.values(:,i) );
                rtNorm = norm( rt_states.signals.values(:,i) );

                testCase.verifyEqual( rtNorm, simNorm, 'AbsTol', testCase.tol );
            end

            cd( testCase.basedir );
        end

        function crane(testCase)
            % Test the crane example
            cd( 'testTemp' );

            % Load the code generation example
            load_system( '../../simulink/examples/nonlinear_crane_example_codegen.mdl' );
            evalc( 'slbuild(''nonlinear_crane_example_codegen'', ''StandaloneCoderTarget'',  ''ForceTopModelBuild'', true);' );
            evalc( 'sim( gcs );' );

            evalc( 'system( ''./nonlinear_crane_example_codegen'' );' );
            load( 'nonlinear_crane_example_codegen.mat' );

            [~, n] = size( rt_states.signals.values );
            for i=1:1:n
                simNorm = norm( states.signals.values(:,i) );
                rtNorm = norm( rt_states.signals.values(:,i) );

                testCase.verifyEqual( rtNorm, simNorm, 'AbsTol', testCase.tol );
            end

            cd( testCase.basedir );
        end
    end

end
