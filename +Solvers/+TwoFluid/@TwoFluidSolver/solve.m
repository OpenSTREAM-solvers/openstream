function solve(twfSolver)
%SOLVE Executes the two-fluid solver for steady-state and transient simulations.
%
% Runs the full solution process for the :class:`Solvers.TwoFluid.TwoFluidSolver`
% object. It manages initialization, time stepping, axial sweeps, inner
% iterations, convergence checks, and logging.
%
% Workflow:
%
% - Enables logging and opens persistent log file
% - Validates solver state before execution
% - Runs steady-state initialization (solveINIT = true)
% - If initial step converges, proceeds with transient simulation
% - Handles exceptions and ensures proper log closure
%
% Notes:
%
% - Uses internal `solver` function to handle both steady-state and transient modes
% - Applies relaxation factors for phase flows, velocities, and enthalpies
% - Supports thermal non-equilibrium modeling
% - Logs progress and outputs to session directory

arguments
    twfSolver
end

import Solvers.SolverState

% Enable diary
twfSolver.inputSet.session.log.diaryOn();

% Open log in persistent mode
twfSolver.inputSet.session.log.openLog('keepLogOpen', true);

if twfSolver.STATE ~= SolverState.UNSOLVED
    error('This solver needs to be reinitialized before solving.');
else
    twfSolver.log('\n\n-------------------------------------------- Two-fluid solver run initiated --------------------------------------------\n')

    try
        % Solve init
        solver(true);

        % Continue solving if init converged
        if twfSolver.STATE == SolverState.INITIALSTEPCONVERGED
            solver(false);
        else
            if length(twfSolver.liquid) > 1
                twfSolver.log('\t\tSkipping transient solver ...\n');
            end
        end

    catch ME
        twfSolver.inputSet.session.log.closeLog();
        twfSolver.inputSet.session.log.diaryOff();
        rethrow(ME)
    end

    twfSolver.log('\n-------------------------------------------- Two-fluid solver run completed --------------------------------------------\n\n')
end

twfSolver.inputSet.session.log.closeLog();
twfSolver.inputSet.session.log.diaryOff();
twfSolver.log('Output directory: %s\n\n',twfSolver.inputSet.session.directory);

function solver(solveINIT)
    % Internal solver routine for steady-state and transient modes
    % Handles time stepping, axial sweeps, and inner iterations
    % Applies relaxation and convergence checks
    % Updates mixture properties and logs progress

    % check if solving liquidInit and vaporInit
    if solveINIT
        twfSolver.log('\nSolve steady-state ...\n');
        liquid = twfSolver.liquidInit;
        vapor  = twfSolver.vaporInit;
        fluid  = repmat(twfSolver.fluid(1),1,length(liquid));
        mix    = copy(repmat(twfSolver.mixSolver.mixture(1),1,twfSolver.inputSet.options.SSMAXITER));
    else
        if length(twfSolver.liquid) < 2
            return
        end
        twfSolver.log('\nSolve transient ...\n');
        liquid = twfSolver.liquid;
        vapor  = twfSolver.vapor;
        fluid  = twfSolver.fluid;
        mix    = twfSolver.mixSolver.mixture;
    end

    % set SOLVED flag to SOLVECONVERGED
    twfSolver.STATE = SolverState.SOLVEDCONVERGED;
    
    % Shortcut to inputSet objects
    model   = twfSolver.inputSet.model;
    options = twfSolver.inputSet.options;
    %geom    = twfSolver.inputSet.geometry;
    
    % Uniform mesh size
    DZ = twfSolver.DZ;    
    
    % Start timer
    startTime = tic();
    
    % Time loop
    for tIdx = 2:length(liquid)                                            % Loop over time steps
        
        twfSolver.log('Time %5.2f [s]',liquid(tIdx).TIME)

        DT = liquid(tIdx).DT;                                              % [s] Current time step size
        %RHOF = fluid(tIdx).RHOF;                                           % [kg/m^3] Saturated liquid density
        
        % Update two-field property guesses from previous time step
        liquid(tIdx-1).copyFlowProperties(liquid(tIdx));
        vapor(tIdx-1).copyFlowProperties(vapor(tIdx));

        
        % Axial sweep
        for zIdx = 2:twfSolver.NZ                                          % Loop over axial nodes
            
            Wlold = liquid(tIdx-1).W(zIdx);                                % [kg/s] Liquid mass flow rate at previous time step
            Ulold = liquid(tIdx-1).U(zIdx);                                % [m/s]  Liquid velocity at previous time step
            Hlold = liquid(tIdx-1).H(zIdx);                                % [J/kg] Liquid enthalpy at previous time step
            Wlups = liquid(tIdx).W(zIdx-1);                                % [kg/s] Liquid mass flow rate upstream
            Ulups = liquid(tIdx).U(zIdx-1);                                % [m/s]  Liquid velocity upstream
            Hlups = liquid(tIdx).H(zIdx-1);                                % [J/kg] Liquid enthalpy upstream
            Wvold = vapor(tIdx-1).W(zIdx);                                 % [kg/s] Vapor mass flow rate at previous time step
            Uvold = vapor(tIdx-1).U(zIdx);                                 % [m/s]  Vapor velocity at previous time step
            Hvold = vapor(tIdx-1).H(zIdx);                                 % [J/kg] Vapor enthalpy at previous time step
            Wvups = vapor(tIdx).W(zIdx-1);                                 % [kg/s] Vapor mass flow rate upstream
            Uvups = vapor(tIdx).U(zIdx-1);                                 % [m/s]  Vapor velocity upstream
            Hvups = vapor(tIdx).H(zIdx-1);                                 % [J/kg] Vapor enthalpy upstream

            % Inner (point) iterations
            for itr = 1:options.MAXITER
    
                % Save parameters from previous point iteration
                Wliter = liquid(tIdx).W(zIdx);                             % [kg/s] Liquid mass flow rate
                Uliter = liquid(tIdx).U(zIdx);                             % [m/s] Liquid velocity
                Hliter = liquid(tIdx).H(zIdx);                             % [J/kg] Liquid enthalpy
                Wviter = vapor(tIdx).W(zIdx);                              % [kg/s] Vapor mass flow rate
                Uviter = vapor(tIdx).U(zIdx);                              % [m/s] Vapor velocity
                Hviter = vapor(tIdx).H(zIdx);                              % [J/kg] Vapor enthalpy
                
                % Liquid mass conservation
                Mtot = liquid(tIdx).MTOT(vapor(tIdx),zIdx);                              % [kg/s/m] Mass exchange terms with liquid
                Mtot = sum(Mtot,2);                                                      % [kg/s/m] Lumped approach
                Wlnew = Uliter*(Wlups+Wlold/Ulold*DZ/DT+Mtot*DZ)/(Uliter+DZ/DT);         % [kg/s] Update liquid mass flow rate
                liquid(tIdx).W(zIdx) = (1-options.RELAXWL)*Wliter+options.RELAXWL*Wlnew; % [kg/s] Apply relaxation
                
                % Vapor mass conservation
                Mtot = vapor(tIdx).MTOT(liquid(tIdx),zIdx);                              % [kg/s/m] Mass exchange terms with vapor
                Mtot = sum(Mtot,2);
                Wvnew = Uviter*(Wvups+Wvold/Uvold*DZ/DT+Mtot*DZ)/(Uviter+DZ/DT);         % [kg/s] Update vapor mass flow rate
                vapor(tIdx).W(zIdx) = (1-options.RELAXWV)*Wviter+options.RELAXWV*Wvnew;  % [kg/s] Apply relaxation
                
                % Liquid momentum conservation
                %TODO: Add equilibrium and simplified equilibrium options
                switch model.MOMENTLIQUID
                    case InputEnums.MOMENTLIQUID.MIXTURE
                    % Already initialized to mixture solution
                        Ulnew = Uliter;
                    
                    case InputEnums.MOMENTLIQUID.SLIP
                    % Phase slip model
                        Ulnew = liquid(tIdx).USLIP(vapor(tIdx),zIdx);      % [m/s]
                    
                    case InputEnums.MOMENTLIQUID.FULL
                    % Full liquid momentum conservation
                        
                        Ftot = liquid(tIdx).FTOT(vapor(tIdx),zIdx);                    % [N/m]
                        Ftot = Ftot/(Wliter/Uliter); Ftot(Wliter <= 1E-3) = 0;         % [m/s^2] Avoid division by 0
                        Ulnew = (Uliter*Ulups + Ulold*DZ/DT + Ftot*DZ)/(Uliter+DZ/DT); % [m/s] Update liquid velocity
                        Ulnew = min(max(Ulnew,0),1.5*mix(tIdx).liquid.U(zIdx));          % [m/s] Keep within realistic bounds to help convergence
                        %Ulnew(Wliter <= 1E-3) = liquid(tIdx).USLIP(vapor(tIdx),zIdx);
                        Ulnew(Wliter <= 1E-3) = Uliter;
                end
                liquid(tIdx).U(zIdx) = (1-options.RELAXUL)*Uliter+options.RELAXUL*Ulnew;   % [m/s] Apply relaxation
                
                % Vapor momentum conservation
                %TODO: Add equilibrium and simplified equilibrium options
                switch model.MOMENTGAS
                    case InputEnums.MOMENTGAS.MIXTURE
                    % Already initialized to mixture solution   
                        Uvnew = Uviter;
                    case InputEnums.MOMENTGAS.SLIP
                    % Phase slip model
                        Uvnew = vapor(tIdx).USLIP(liquid(tIdx),zIdx);      % [m/s]
                        
                    case InputEnums.MOMENTGAS.FULL
                    % Full gas momentum conservation
                    
                        Ftot = vapor(tIdx).FTOT(liquid(tIdx),zIdx);                    % [N/m]
                        Ftot = Ftot/(Wviter/Uviter); Ftot(Wviter <= 1E-3) = 0;         % [m/s^2] Avoid division by 0
                        Uvnew = (Uviter*Uvups + Uvold*DZ/DT + Ftot*DZ)/(Uviter+DZ/DT); % [m/s] Update vapor velocity
                        Uvnew = min(max(Uvnew,0),1.5*mix(tIdx).vapor.U(zIdx));           % [m/s] Keep within realistic bounds to help convergence
                        %Uvnew(Wviter <= 1E-3) = vapor(tIdx).USLIP(liquid(tIdx),zIdx);
                        Uvnew(Wviter <= 1E-3) = Uviter;
                end
                vapor(tIdx).U(zIdx) = (1-options.RELAXUV)*Uviter+options.RELAXUV*Uvnew;    % [m/s] Apply relaxation
                
                % Liquid energy conservation
                Htot = liquid(tIdx).HTOT(vapor(tIdx),zIdx);                                % [W/m] Linear energy exchange terms with liquid
                Htot = sum(Htot,2);
                Htot = Htot/(Wliter/Uliter); Htot(Wliter <= 1E-3) = 0;                     % [W/kg] Avoid division by 0
                Hlnew = (Hlups*Uliter+Hlold*DZ/DT+Htot*DZ)/(Uliter+DZ/DT);                 % [J/kg] Update liquid enthalpy
                liquid(tIdx).H(zIdx) = (1-options.RELAXHL)*Hliter+options.RELAXHL*Hlnew;   % [J/kg] Apply relaxation
                
                % Vapor energy conservation
                Htot = vapor(tIdx).HTOT(liquid(tIdx),zIdx);                                % [W/m] Linear energy exchange terms with vapor
                Htot = sum(Htot,2);
                Htot = Htot/(Wviter/Uviter); Htot(Wviter <= 1E-3) = 0;                     % [W/kg] Avoid division by 0
                Hvnew = (Hvups*Uviter+Hvold*DZ/DT+Htot*DZ)/(Uviter+DZ/DT);                 % [J/kg] Update vapor enthalpy
                vapor(tIdx).H(zIdx) = (1-options.RELAXHV)*Hviter+options.RELAXHV*Hvnew;    % [J/kg] Apply relaxation
                
                
                % Check convergence
                dWl = abs((liquid(tIdx).W(zIdx)-Wliter));                  % [kg/s] Liquid mass flow rate error between inner iterations
                dWv = abs((vapor(tIdx).W(zIdx)-Wviter));                   % [kg/s] Vapor mass flow rate error between inner iterations
                dUl = abs((liquid(tIdx).U(zIdx)-Uliter));                  % [m/s]  Liquid velocity error between inner iterations
                dUv = abs((vapor(tIdx).U(zIdx)-Uviter));                   % [m/s]  Vapor velocity error between inner iterations
                dHl = abs((liquid(tIdx).H(zIdx)-Hliter));                  % [J/kg] Enthalpy error between inner iterations
                dHv = abs((vapor(tIdx).H(zIdx)-Hviter));                   % [J/kg] Enthalpy error between inner iterations
                if all([dWl < options.ERRORW, dWv < options.ERRORW, dUl < options.ERRORU, dUv < options.ERRORU, dHl < options.ERRORH, dHv < options.ERRORH])   
                    break;
                    
                elseif itr == options.MAXITER
                    % set SOLVED flag to SOLVEDNOTCONVERGED
                    twfSolver.STATE = SolverState.SOLVEDNOTCONVERGED;
                    break;
                end
    
            end
                        
            % Iteration parameters
            liquid(tIdx).ITR.N(zIdx)  = itr;
            liquid(tIdx).ITR.DW(zIdx) = dWl;
            liquid(tIdx).ITR.DU(zIdx) = dUl;
            liquid(tIdx).ITR.DH(zIdx) = dHl;
            vapor(tIdx).ITR.N(zIdx)   = itr;
            vapor(tIdx).ITR.DW(zIdx)  = dWv;
            vapor(tIdx).ITR.DU(zIdx)  = dUv;
            vapor(tIdx).ITR.DH(zIdx)  = dHv;
    
        end
        
        [maxN,maxzIdx] = max(liquid(tIdx).ITR.N);
        maxDWl = max(liquid(tIdx).ITR.DW);
        maxDUl = max(liquid(tIdx).ITR.DU);
        maxDHl = max(liquid(tIdx).ITR.DH);
        maxDWv = max(vapor(tIdx).ITR.DW);
        maxDUv = max(vapor(tIdx).ITR.DU);
        maxDHv = max(vapor(tIdx).ITR.DH);
        twfSolver.log('\tmax point iter = %3d in node %3d, max errors: Wl = %.7f [kg/s], Wv = %.7f [kg/s], Ul = %.7f [m/s], Uv = %.7f [m/s], Hl = %.5f [J/kg], Hv = %.5f [J/kg]                    \r',maxN,maxzIdx,maxDWl,maxDWv,maxDUl,maxDUv,maxDHl,maxDHv)
        
        % Temporal deviations in W, U, and H
        timeDWl = max(abs(liquid(tIdx).W - liquid(tIdx-1).W));
        timeDUl = max(abs(liquid(tIdx).U - liquid(tIdx-1).U));
        timeDHl = max(abs(liquid(tIdx).H - liquid(tIdx-1).H));
        timeDWv = max(abs(vapor(tIdx).W - vapor(tIdx-1).W));
        timeDUv = max(abs(vapor(tIdx).U - vapor(tIdx-1).U));
        timeDHv = max(abs(vapor(tIdx).H - vapor(tIdx-1).H));
        
        if solveINIT
            % Finish steady state solver when SS convergence criteria are met
            if all([timeDWl < options.SSCONVW, timeDWv < options.SSCONVW,timeDUl < options.SSCONVU, timeDUv < options.SSCONVU, timeDHl < options.SSCONVH, timeDHv < options.SSCONVH]) % [,timeDU < options.SSCONVU]
                
                % Indicate init converged
                twfSolver.STATE = SolverState.INITIALSTEPCONVERGED;
                
                twfSolver.log('\n\t\tSTEADY-STATE CONVERGED            max errors: Wl = %.7f [kg/s], Wv = %.7f [kg/s], Ul = %.7f [m/s], Uv = %.7f [m/s], Hl = %.5f [J/kg], Hv = %.5f [J/kg]\r',timeDWl,timeDWv,timeDUl,timeDUv,timeDHl,timeDHv)
    
                % Replace mixtureInit with subset up to this tIdx
                twfSolver.liquidInit = twfSolver.liquidInit(1:tIdx);
                twfSolver.vaporInit = twfSolver.vaporInit(1:tIdx);
    
                % Replace first transient time step flow data with this tIdx
                twfSolver.liquidInit(end).copyFlowProperties(twfSolver.liquid(1));
                twfSolver.vaporInit(end).copyFlowProperties(twfSolver.vapor(1));
        
                break;
            
            % otherwise, update next timestep with current flow properties
            elseif tIdx < length(liquid)
                twfSolver.liquidInit(tIdx).copyFlowProperties(twfSolver.liquidInit(tIdx+1));
                twfSolver.vaporInit(tIdx).copyFlowProperties(twfSolver.vaporInit(tIdx+1));
                
            % otherwise, not converged
            else
                twfSolver.STATE = "INITIALSTEPNOTCONVERGED";
                twfSolver.log('\n\t\tSTEADY-STATE FAILED TO CONVERGE   max errors: Wl = %.7f [kg/s], Wv = %.7f [kg/s], Ul = %.7f [m/s], Uv = %.7f [m/s], Hl = %.5f [J/kg], Hv = %.5f [J/kg]\r',timeDWl,timeDWv,timeDUl,timeDUv,timeDHl,timeDHv)
                
                % Replace first transient time step flow data with steady-state solver solution, regardless of convergence
                twfSolver.liquidInit(end).copyFlowProperties(twfSolver.liquid(1));
                twfSolver.vaporInit(end).copyFlowProperties(twfSolver.vapor(1));
            end
        end
    
    end
    
    twfSolver.log('\n')
    
    % End timer
    twfSolver.log('Elapsed time: %0.2f sec\n', toc(startTime))
end

end