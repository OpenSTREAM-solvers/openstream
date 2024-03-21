function solve(twfSolver)
%SOLVE  
% 
arguments
    twfSolver
end

import Solvers.SolverState

% Enable diary
twfSolver.inputSet.session.log.diaryOn();

% Open log in presistent mode
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
            twfSolver.log('\t\tSkipping transient solver ...\n');
        end
    catch ME
        twfSolver.inputSet.session.log.closeLog();
        twfSolver.inputSet.session.log.diaryOff();
        rethrow(ME)
    end
    
    twfSolver.log('\n---------------------------------------------- Two-fluid solver run completed ----------------------------------------------\n\n')
end

twfSolver.inputSet.session.log.closeLog();
twfSolver.inputSet.session.log.diaryOff();
twfSolver.log('Output directory: %s\n',twfSolver.inputSet.session.directory);


function solver(solveINIT)

    % check if solving liquidInit and vaporInit
    if solveINIT
        twfSolver.log('\nRun steady-state ...\n');
        liquid = twfSolver.liquidInit;
        vapor = twfSolver.vaporInit;
        fluid = twfSolver.fluidInit;
        mix = copy(repmat(twfSolver.mixSolver.mixture(1),1,twfSolver.inputSet.options.SSMAXITER));
        solveMODE = 'INITIAL';
    else
        twfSolver.log('\nRun transient ...\n');
        liquid = twfSolver.liquid;
        vapor = twfSolver.vapor;
        fluid = twfSolver.fluid;
        mix = twfSolver.mixSolver.mixture;
        solveMODE = 'SPECIFIED';
    end

    % set SOLVED flag to SOLVECONVERGED
    twfSolver.STATE = SolverState.SOLVEDCONVERGED;
    
    % Shortcut to inputSet objects
    model = twfSolver.inputSet.model;
    options = twfSolver.inputSet.options;
    geom = twfSolver.inputSet.geometry;
    
    % Uniform mesh size
    DZ = twfSolver.DZ;    
    
    % Start timer
    startTime = tic();
    
    % Time loop
    for tIdx = 2:length(liquid)                                            % Loop over time steps
        
        twfSolver.log('Time %5.2f [s]',liquid(tIdx).TIME)

        DT = liquid(tIdx).DT;                                              % Current time step size
        RHOF = fluid(tIdx).RHOF;                                           % [kg/m^3] Saturated liquid density
        
        % Update two-field property guesses from previous time step
        liquid(tIdx-1).copyFlowProperties(liquid(tIdx));
        vapor(tIdx-1).copyFlowProperties(vapor(tIdx));

        
        % Axial sweep
        for zIdx = 2:twfSolver.NZ                                                        % Loop over axial nodes
            
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
                
                % Update secondary parameters
                %VEL   = mix(tIdx).U([zIdx-1 zIdx]);                                     % [m/s] Calculate velocity array for speed
                %U     = VEL(2); Uups = VEL(1);                                          % [m/s] Mixture velocities at node k and k-1
                %Uold  = mix(tIdx-1).U(zIdx);                                            % [m/s] Mixture velocity at previous time step
                %RHO   = mix(tIdx).RHO(zIdx);                                            % [kg/m^3] Mixture density
                %TAUW  = mix(tIdx).TAUW(zIdx);                                           % [Pa] Wall shear stress
                %HFLUX = mix(tIdx).HFLUX(zIdx,:);                                        % [W/m^2] Wall heat flux
                
                % Liquid mass conservation
                Mtot = liquid(tIdx).MTOT(zIdx);                                              % [kg/s/m] Mass exchange terms with liquid
                Wlnew = Uliter.*(Wlups+Wlold./Ulold.*DZ./DT+Mtot.*DZ)./(Uliter+DZ./DT);      % [kg/s] Update liquid mass flow rate
                liquid(tIdx).W(zIdx,:) = (1-options.RELAXWL).*Wliter+options.RELAXWL.*Wlnew; % [kg/s] Apply relaxation
                
                % Vapor mass conservation
                Mtot = vapor(tIdx).MTOT(zIdx);                                               % [kg/s/m] Mass exchange terms with vapor
                Wvnew = Uviter.*(Wvups+Wvold./Uvold.*DZ./DT+Mtot.*DZ)./(Uviter+DZ./DT);      % [kg/s] Update vapor mass flow rate
                vapor(tIdx).W(zIdx,:) = (1-options.RELAXWV).*Wviter+options.RELAXWV.*Wvnew;  % [kg/s] Apply relaxation

                % Momentum conservation
                %%%% get pressure from mixture model
                % DPparts = mix(tIdx).DPPARTS(Uold, zIdx);                            % [Pa] Pressure drop components
                % Pnew = mix(tIdx).P(zIdx-1) + DPparts.TOT;                           % [Pa] New pressure
                % mix(tIdx).P(zIdx) = (1-options.RELAXPM)*Piter+options.RELAXPM*Pnew; % [Pa] Apply relaxation
                
                % Liquid energy conservation
                Htot = liquid(tIdx).HTOT(zIdx);                                                   % [W/m] Linear energy exchange terms with liquid
                Hlnew = (Hlups.*Uliter+Hlold.*DZ./DT+Htot./(Wliter/Uliter).*DZ)./(Uliter+DZ./DT); % [J/kg] Update liquid enthalpy
                liquid(tIdx).H(zIdx,:) = (1-options.RELAXHL).*Hliter+options.RELAXHL.*Hlnew;      % [J/kg] Apply relaxation
                
                % Vapor energy conservation
                % TODO: Fix issue when Wv = 0
                Htot = vapor(tIdx).HTOT(zIdx);                                                    % [W/m] Linear energy exchange terms with vapor
                Hvnew = (Hvups.*Uviter+Hvold.*DZ./DT+0)./(Uviter+DZ./DT);                         % [J/kg] Update vapor enthalpy
                %Hvnew = (Hvups.*Uviter+Hvold.*DZ./DT+Htot./(Wviter/Uviter).*DZ)./(Uviter+DZ./DT); % [J/kg] Update vapor enthalpy
                vapor(tIdx).H(zIdx,:) = (1-options.RELAXHV).*Hviter+options.RELAXHV.*Hvnew;       % [J/kg] Apply relaxation
                
                
                % Check convergence
                dWl = abs((liquid(tIdx).W(zIdx)-Wliter));                  % [kg/s] Liquid mass flow rate error between inner iterations
                dWv = abs((vapor(tIdx).W(zIdx)-Wviter));                   % [kg/s] Vapor mass flow rate error between inner iterations

                dHl = abs((liquid(tIdx).H(zIdx)-Hliter));                  % [J/kg] Enthalpy error between inner iterations
                dHv = abs((vapor(tIdx).H(zIdx)-Hviter));                   % [J/kg] Enthalpy error between inner iterations
                if all([dWl < options.ERRORW, dWv < options.ERRORW, dHl < options.ERRORH, dHv < options.ERRORH])   
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
            %liquid(tIdx).ITR.DU(zIdx)  = dUl;
            liquid(tIdx).ITR.DH(zIdx) = dHl;
            vapor(tIdx).ITR.N(zIdx)  = itr;
            vapor(tIdx).ITR.DW(zIdx) = dWv;
            vapor(tIdx).ITR.DH(zIdx) = dHv;

            % Stop running if solver did not converge
            %if twfSolver.STATE == SolverState.SOLVEDNOTCONVERGED
            %    break;
            %end
    
        end
        
        [maxN,maxzIdx] = max(liquid(tIdx).ITR.N);
        maxDWl = max(liquid(tIdx).ITR.DW);
        %maxDUl = max(liquid(tIdx).ITR.DU);
        maxDHl = max(liquid(tIdx).ITR.DH);
        maxDWv = max(vapor(tIdx).ITR.DW);
        maxDHv = max(vapor(tIdx).ITR.DH);
        twfSolver.log('\tmax point iter = %3d in node %3d, max errors: Wl = %.7f [kg/s], Wv = %.7f [kg/s], Hl = %.5f [J/kg], Hv = %.5f [J/kg]\r',maxN,maxzIdx,maxDWl,maxDWv,maxDHl,maxDHv)
        
        % Temporal deviations in W, U, and H
        timeDWl = max(abs(liquid(tIdx).W - liquid(tIdx-1).W));
        %timeDUl = max(abs(liquid(tIdx).U - liquid(tIdx-1).U));
        timeDHl = max(abs(liquid(tIdx).H - liquid(tIdx-1).H));
        timeDWv = max(abs(vapor(tIdx).W - vapor(tIdx-1).W));
        timeDHv = max(abs(vapor(tIdx).H - vapor(tIdx-1).H));
        
        if solveINIT
            % Finish steady state solver when SS convergence criterions are met
            if all([timeDWl < options.SSCONVW, timeDWv < options.SSCONVW, timeDHl < options.SSCONVH, timeDHv < options.SSCONVH]) % [,timeDU < options.SSCONVU]
                
                % Indicate init converged
                twfSolver.STATE = SolverState.INITIALSTEPCONVERGED;
                
                twfSolver.log('\n\t\tSTEADY-STATE CONVERGED            max errors: Wl = %.7f [kg/s], Wv = %.7f [kg/s], Hl = %.5f [J/kg], Hv = %.5f [J/kg]\r',timeDWl,timeDWv,timeDHl,timeDHv)
    
                % Replace mixtureInit with subset up to this tIdx
                twfSolver.liquidInit = twfSolver.liquidInit(1:tIdx);
                twfSolver.vaporInit = twfSolver.vaporInit(1:tIdx);
    
                % Replace first transient time step flow data with this tIdx
                twfSolver.liquidInit(end).copyFlowProperties(twfSolver.liquid(1));
                twfSolver.vaporInit(end).copyFlowProperties(twfSolver.vapor(1));
        
                break;
            
            % otherwise, update next timestep with current flow properties
            elseif tIdx < length(liquid)-1
                % unless non-convergence occurred
                if twfSolver.STATE == SolverState.SOLVEDNOTCONVERGED
                    twfSolver.log('\t\tSTEADY-STATE FAILED TO CONVERGE     max errors: Wl = %.7f [kg/s], Wv = %.7f [kg/s], Hl = %.5f [J/kg], Hv = %.5f [J/kg]\r',timeDWl,timeDWv,timeDHl,timeDHv) %,timeDUf,timeDUd , Uf = %.5f [m/s]), Ud = %.5f [m/s]
                    break;
                end

                twfSolver.liquidInit(tIdx).copyFlowProperties(twfSolver.liquidInit(tIdx+1));
                twfSolver.vaporInit(tIdx).copyFlowProperties(twfSolver.vaporInit(tIdx+1));
            % otherwise, not converged
            else
                twfSolver.STATE = "INITIALSTEPNOTCONVERGED";
                twfSolver.log('\t\tSTEADY-STATE FAILED TO CONVERGE     max errors: Wl = %.7f [kg/s], Wv = %.7f [kg/s], Hl = %.5f [J/kg], Hv = %.5f [J/kg]\r',timeDWl,timeDWv,timeDHl,timeDHv) % ,timeDP,timeDH , P = %.5f [Pa], H = %.5f [J/kg]
                break;
            end
        end
    
    end
    
    %twfSolver.log('\n---------------------- %s solver run completed ----------------------\n\n', solveMODE)
    twfSolver.log('\n')
    
    % End timer
    twfSolver.log('Elapsed time: %0.2f sec\n', toc(startTime))
end

end