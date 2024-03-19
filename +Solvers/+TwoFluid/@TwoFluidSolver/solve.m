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
    twfSolver.log('\n\n--------------------------------------------- Two-fluid solver run initiated ---------------------------------------------\n')

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
    
    twfSolver.log('\n--------------------------------------------- Two-fluid solver run completed ---------------------------------------------\n\n')
end

twfSolver.inputSet.session.log.closeLog();
twfSolver.inputSet.session.log.diaryOff();
twfSolver.log('Output directory: %s\n',twfSolver.inputSet.session.directory);

function solver(solveINIT)

    % check if solving mixtureInit
    if solveINIT
        twfSolver.log('\nRun steady-state ...\n');
        mix = twfSolver.mixtureInit;
        solveMODE = 'INITIAL';
    else
        twfSolver.log('\nRun transient ...\n');
        mix = twfSolver.mixture;
        solveMODE = 'SPECIFIED';
    end

    % set SOLVED flag to SOLVECONVERGED
    twfSolver.STATE = SolverState.SOLVEDCONVERGED;
    
    % Shortcut to inputSet objects
    %model = twfSolver.inputSet.model;
    options = twfSolver.inputSet.options;
    %geom = twfSolver.inputSet.geometry;
    
    
    % Uniform mesh size
    DZ = twfSolver.DZ;    
    
    % Start timer
    startTime = tic();
    
    % Time loop
    for tIdx = 2:length(mix)                                                     % Loop over time steps
        
        twfSolver.log('Time %5.2f [s]',liquid(tIdx).TIME)

        % Current time step size
        DT = liquid(tIdx).DT;
        
        % Update two-field property guesses from previous time step
        liquid(tIdx-1).copyFlowProperties(liquid(tIdx));
        vapor(tIdx-1).copyFlowProperties(vapor(tIdx));

        % Axial sweep
        for zIdx = 2:twfSolver.NZ                                                        % Loop over axial nodes
            
            Wlold = liquid(tIdx-1).W(zIdx,:);                                % [kg/s] Liquid mass flow rate at previous time step
            Ulold = liquid(tIdx-1).U(zIdx,:);                                % [m/s]  Liquid velocity at previous time step
            Hlold = liquid(tIdx-1).H(zIdx,:);                                % [J/kg] Liquid enthalpy at previous time step
            Wlups = liquid(tIdx).W(zIdx-1,:);                                % [kg/s] Liquid mass flow rate upstream
            Ulups = liquid(tIdx).U(zIdx-1,:);                                % [m/s]  Liquid velocity upstream
            Hlups = liquid(tIdx).H(zIdx-1,:);                                % [J/kg] Liquid enthalpy upstream
            Wvold = vapor(tIdx-1).W(zIdx,:);                                % [kg/s] Vapor mass flow rate at previous time step
            Uvold = vapor(tIdx-1).U(zIdx,:);                                % [m/s]  Vapor velocity at previous time step
            Hvold = vapor(tIdx-1).H(zIdx,:);                                % [J/kg] Vapor enthalpy at previous time step
            Wvups = vapor(tIdx).W(zIdx-1,:);                                % [kg/s] Vapor mass flow rate upstream
            Uvups = vapor(tIdx).U(zIdx-1,:);                                % [m/s]  Vapor velocity upstream
            Hvups = vapor(tIdx).H(zIdx-1,:);                                % [J/kg] Vapor enthalpy upstream

            % Inner (point) iterations
            for itr = 1:options.MAXITER
    
                % Save parameters from previous point iteration
                Wliter = liquid(tIdx).W(zIdx,:);                             % [kg/s] Liquid mass flow rate
                Wviter = vapor(tIdx).W(zIdx);                               % [kg/s] Vapor mass flow rate 
                Uliter = liquid(tIdx).U(zIdx,:);                             % [m/s] Liquid velocity
                Uviter = vapor(tIdx).U(zIdx);                               % [m/s] Vapor velocity                              
                
                % Update secondary parameters
                %VEL   = mix(tIdx).U([zIdx-1 zIdx]);                                     % [m/s] Calculate velocity array for speed
                %U     = VEL(2); Uups = VEL(1);                                          % [m/s] Mixture velocities at node k and k-1
                %Uold  = mix(tIdx-1).U(zIdx);                                            % [m/s] Mixture velocity at previous time step
                %RHO   = mix(tIdx).RHO(zIdx);                                            % [kg/m^3] Mixture density
                %TAUW  = mix(tIdx).TAUW(zIdx);                                           % [Pa] Wall shear stress
                %HFLUX = mix(tIdx).HFLUX(zIdx,:);                                        % [W/m^2] Wall heat flux
                
                % Mass conservation %%%% include mass transfer later
                Wlnew = Uliter.*(Wlups+DZ./DT.*Wlold./Ulold)./(Uliter+DZ./DT) ; % [kg/s] Update liquid mass flow rate
                Wvnew = Uviter.*(Wvups+DZ./DT.*Wvold./Uvold)./(Uviter+DZ./DT) ; % [kg/s] Update vapor mass flow rate
                liquid(tIdx).W(zIdx) = Wlnew;     % [kg/s] Assign new value
                vapor(tIdx).W(zIdx) = Wvnew;     % [kg/s] Assign new value

                % Momentum conservation
                %%%% get pressure from mixture model
                % DPparts = mix(tIdx).DPPARTS(Uold, zIdx);                            % [Pa] Pressure drop components
                % Pnew = mix(tIdx).P(zIdx-1) + DPparts.TOT;                           % [Pa] New pressure
                % mix(tIdx).P(zIdx) = (1-options.RELAXPM)*Piter+options.RELAXPM*Pnew; % [Pa] Apply relaxation
                
                % Energy conservation
                %Hnew = (mix(tIdx).H(zIdx-1)+DZ./mix(tIdx).W(zIdx).*sum(geom.PERIM.'.*reshape(HFLUX,length(zIdx),[]).',1)+ ...
                %       mix(tIdx-1).H(zIdx)./U.*DZ./DT)/(1+DZ./U./DT);               % [J/kg] Update mixture enthalpy
                %mix(tIdx).H(zIdx) = (1-options.RELAXHM)*Hiter+options.RELAXHM*Hnew; % [J/kg] Apply relaxation
                
                % Check convergence
                dWl = abs((liquid(tIdx).W(zIdx)-Wliter)); % [kg/s] Mass flow rate error between inner iterations
                dWv = abs((vapor(tIdx).W(zIdx)-Wviter)); % [kg/s] Mass flow rate error between inner iterations
                %dP = abs((mix(tIdx).P(zIdx)-Piter));                             % [Pa]   Pressure error between inner iterations
                %dH = abs((mix(tIdx).H(zIdx)-Hiter));                             % [J/kg] Enthalpy error between inner iterations
                if all([dW < options.ERRORW, dP < options.ERRORP, dH < options.ERRORH])   
                    break;
                elseif itr == options.MAXITER
                    % set SOLVED flag to SOLVEDNOTCONVERGED
                    twfSolver.STATE = SolverState.SOLVEDNOTCONVERGED;
                    break;
                end
    
            end
                        
            % Iteration parameters
            liquid(tIdx).ITR.N(zIdx)  = itr;
            liquid(tIdx).ITR.DWL(zIdx,1:nwall) = dWl;
            %liquid(tIdx).ITR.DUL(zIdx,1:nwall)  = dUl;
            vapor(tIdx).ITR.N(zIdx)  = itr;
            vapor(tIdx).ITR.DWV(zIdx) = dWv;

            % Stop running if solver did not converge
            if twfSolver.STATE == SolverState.SOLVEDNOTCONVERGED
                break;
            end
    
    
        end
        
        [maxN,maxzIdx] = max(liquid(tIdx).ITR.N);
        maxDWL = max(liquid(tIdx).ITR.DWL);
        %maxDP = max(mix(tIdx).ITR.DP);
        %maxDH = max(mix(tIdx).ITR.DH);
        
        % Temporal deviations in W, P, and H
        timeDWL = max(abs((liquid(tIdx).W - liquid(tIdx-1).W)),[],'all');
        %timeDP = max(abs((mix(tIdx).P - mix(tIdx-1).P)));
        %timeDH = max(abs((mix(tIdx).H - mix(tIdx-1).H)));
        twfSolver.log('\tmax point iter = %3d in node %3d, max errors: W = %.7f [kg/s]\r',maxN,maxzIdx,maxDWL)%,maxDP,maxDH) , P = %.5f [Pa], H = %.5f [J/kg]
    
        
        if solveINIT
            % Finish steady state solver when SS convergence criterions are met
            if all(timeDWL < options.SSCONVW ) % [,timeDP < options.SSCONVP ,timeDH < options.SSCONVH]
                
                % Indicate init converged
                twfSolver.STATE = SolverState.INITIALSTEPCONVERGED;
                
                twfSolver.log('\n\t\tSTEADY-STATE CONVERGED            max errors: W = %.7f [kg/s], P = %.5f [Pa], H = %.5f [J/kg]\r',timeDW,timeDP,timeDH)
    
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
                    twfSolver.log('\t\tSTEADY-STATE FAILED TO CONVERGE     max errors: Wf = %.7f [kg/s/m]\r',timeDWL) %,timeDUf,timeDUd , Uf = %.5f [m/s]), Ud = %.5f [m/s]
                    break;
                end

                twfSolver.liquidInit(tIdx).copyFlowProperties(twfSolver.liquidInit(tIdx+1));
                twfSolver.vaporInit(tIdx).copyFlowProperties(twfSolver.vaporInit(tIdx+1));            % otherwise, not converged
            else
                twfSolver.STATE = "INITIALSTEPNOTCONVERGED";
                twfSolver.log('\t\tSTEADY-STATE FAILED TO CONVERGE     max errors: W = %.7f [kg/s]\r',timeDWL) % ,timeDP,timeDH , P = %.5f [Pa], H = %.5f [J/kg]
            end
        end
    
        
    
    end
    
    %twfSolver.log('\n---------------------- %s solver run completed ----------------------\n\n', solveMODE)
    twfSolver.log('\n')
    
    % End timer
    twfSolver.log('Elapsed time: %0.2f sec\n', toc(startTime))
end

end