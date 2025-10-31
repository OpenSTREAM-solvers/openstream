Run sample script
=================

At this point, you are ready to run the sample script. You will see some of the basic usages of  OpenSTREAM. 

.. code-block:: matlab

    % Clear existing variables from workspace
    clearvars

    % Import the necessary classes for inputs and solvers
    import Inputs.*
    import Solvers.*
    import Solvers.Mixture.*

    % Turn off warnings during input setup
    warning off
    % Create the input set using paths to model, options, geometry, and boundary condition files
    inputSet = InputSet( ...
                modelFilePath         = './inputs/models.inp',  modelID    = 'TUTORIAL1', ...
                optionsFilePath       = './inputs/options.inp', optionsID  = 'DEFAULT', ...
                geometryFilePath      = './inputs/geom.inp',    geometryID = 'TUTORIAL1', ...
                bcFilePath            = './inputs/tutorial1.inp', ...
                sessionParentDir      = fullfile(pwd,'outputs'), ...
                overwriteSessionFiles = true, ...
                LOGMODE               = 'BOTH');        

    % Create a mixture solver object
    mixSolver = MixtureSolver(inputSet);

    % mixSolver is initialized at construction. Here, it is explicitly initialized for clarity.
    mixSolver.initializeSolver(); 

    % Solve (does not accept any argument)
    mixSolver.solve();

    % Axial plots
    mixSolver.plotz();

    % Save results
    mixSolver.save();


.. figure:: sample_mix_plotz.png

   Sample figure of axial distributions of mixture parameters.