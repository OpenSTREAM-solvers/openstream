classdef PythonSetupTest < matlab.unittest.TestCase
    
    properties (Constant)
        PackageName = "CoolProp";
    end

    methods(TestClassSetup)
        % Shared setup for the entire test class
    end
    
    methods(TestMethodSetup)
        % Setup for each test
    end
    
    methods(Test)
        % Test methods
        
        function testPythonEnvironment(testCase)
            % Test 1: verify the python environment is working
            
            try
                [passes, msg] = testCase.checkPythonEnvironment();
                testCase.verifyTrue(passes, msg)

            catch ME
                testCase.assertFail( ...
                    "Python environment test failed: " + ME.message);
            
            end
        end

        function testPackageInstalled(testCase)
            % Test 2: verify the packages are installed
            %   Only run if Test 1 passes

            testCase.assumeTrue( ...
                testCase.checkPythonEnvironment(), ...
                "SKIPPED: Python environment unavailable");
            
            try
                [passes, msg] = testCase.checkPackagesInstalled();
                testCase.verifyTrue(passes, msg);

            catch ME
                testCase.assertFail( ...
                    "Python packages installed test failed: " + ME.message);
            end

        end
        
        function testPackageFunction(testCase)
            % Test 3: verify basic package function
            %   Only run if Test 1 and 2 passes

            testCase.assumeTrue( ...
                testCase.checkPythonEnvironment(), ...
                "SKIPPED: Python environment unavailable");
            testCase.assumeTrue( ...
                testCase.checkPackagesInstalled(), ...
                "SKIPPED: at least 1 package missing");

            import matlab.unittest.constraints.IsGreaterThan
            import matlab.unittest.constraints.IsLessThan

            try
                cp = py.importlib.import_module("CoolProp.CoolProp");
                T = double(cp.PropsSI( ...
                    "T", "P", 101325, "Q", 0, "Water"));
                testCase.verifyThat(T, ...
                    IsGreaterThan(373) & IsLessThan(374), ...
                    "Coolprop returned an unreasonable value.");
            catch ME
                testCase.verifyFail( ...
                    "CoolProp functionality test failed: " + ME.message);
            end

        end

    end
    
    methods (Access = private)

        function [tf, msg] = checkPythonEnvironment(~)
            % Helper function to check python environment by querying the
            % Python version. Returns true if environment passes test.
            % Returns false is failure, along with any related messages as
            % msg.

            tf = false;

            try
                pe = pyenv;

                if isempty(pe.Version)
                    msg = "Python version is not available when using pyenv";
                    return
                end

                ver = py.sys.version;

                if isempty(ver)
                    msg = "Python version is not available when using py.sys.version";
                    return
                end

                tf = true;
                msg = "";

            catch ME
                tf = false;
                msg = ME.message;
            end

        end


        function [tf, msg] = checkPackagesInstalled(testCase)
            % Helper function to check python packages by importing the
            % Python package. Returns true if environment passes test.
            % Returns false is failure, along with any related messages as
            % msg.

            tf = false;

            try
                py.importlib.import_module(testCase.PackageName);
                tf = true;
                msg = "";
            catch ME
                tf = false;
                msg = ME.message;
            end
        end

    end
end