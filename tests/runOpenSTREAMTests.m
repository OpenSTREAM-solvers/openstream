%% Run OpenSTREAM automated tests
%
% Run the Python environment tests, unit tests and solver integration
% tests. Display detailed diagnostics and produce a summary table.

clearvars
% clc

% Locate the test root.
runnerFile = mfilename('fullpath');
testFolder = fileparts(runnerFile);

% Create a suite from all tests in the test folder and its subfolders.
testSuite = matlab.unittest.TestSuite.fromFolder( ...
    testFolder, ...
    IncludingSubfolders = true);

% Create a runner that displays test progress and diagnostics
runner = matlab.unittest.TestRunner.withTextOutput;

% Run the complete test suite and measure the total execution time.
suiteTimer = tic;
testResults = runner.run(testSuite);
suiteDuration = toc(suiteTimer);

% Create and display the test summary.
[testSummary,numberNotPassed] = displayTestSummary(testResults);

% Display the total execution time.
fprintf('Total test-suite execution time: %.2f s\n\n',suiteDuration);

% Raise an error if any test failed or did not complete.
if numberNotPassed > 0
    error('OpenSTREAM:TestsFailed', ...
        '%d test(s) failed or did not complete.', ...
        numberNotPassed);
end


%%

function [testSummary,numberNotPassed] = displayTestSummary(testResults)
% DISPLAYTESTSUMMARY
%
% Create and display a compact summary of the OpenSTREAM automated
% test results.
%
% Input:
%   testResults
%       Array of matlab.unittest.TestResult objects returned by the
%       test runner.
%
% Outputs:
%   testSummary
%       Table containing the test class, test method, and status.
%   numberNotPassed
%       Number of tests for which Passed is false.

% Preallocate the summary arrays.
numberOfTests = numel(testResults);

testClass = strings(numberOfTests,1);
testName = strings(numberOfTests,1);
testStatus = strings(numberOfTests,1);

% Extract the test names and determine their status.
for testIndex = 1:numberOfTests

    % Separate the test-class and test-method names.
    fullTestName = string(testResults(testIndex).Name);
    nameParts = split(fullTestName,"/");

    testClass(testIndex) = nameParts(1);
    testName(testIndex) = nameParts(end);

    % Determine the test status.
    if testResults(testIndex).Passed
        testStatus(testIndex) = "Passed";
    elseif testResults(testIndex).Failed && testResults(testIndex).Incomplete
        testStatus(testIndex) = "Failed and incomplete";
    elseif testResults(testIndex).Failed
        testStatus(testIndex) = "Failed";
    elseif testResults(testIndex).Incomplete
        testStatus(testIndex) = "Incomplete";
    else
        testStatus(testIndex) = "Not completed";
    end

end

% Convert the text columns to categorical arrays
testClass = categorical(testClass);
testName = categorical(testName);

testStatus = categorical( ...
    testStatus, ...
    ["Passed", ...
    "Failed", ...
    "Incomplete", ...
    "Failed and incomplete", ...
    "Not completed"], ...
    'Ordinal', false);

% Assemble the summary table.
testSummary = table( ...
    testClass, ...
    testName, ...
    testStatus, ...
    'VariableNames', { ...
    'TestClass', ...
    'TestName', ...
    'Status'});

% Calculate the overall totals.
numberPassed = ...
    nnz([testResults.Passed]);

numberFailed = ...
    nnz([testResults.Failed]);

numberIncomplete = ...
    nnz([testResults.Incomplete]);

numberNotPassed = ...
    nnz(~[testResults.Passed]);

% Display the summary table.
fprintf('\n');
fprintf('OpenSTREAM automated test summary\n');
fprintf('=================================\n\n');

disp(testSummary)

% Display the overall totals.
fprintf( ...
    ['Summary: %d passed, %d failed, and %d incomplete ' ...
    'out of %d tests.\n'], ...
    numberPassed, ...
    numberFailed, ...
    numberIncomplete, ...
    numberOfTests);

end