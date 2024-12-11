function solve(mixSolver)
%SOLVE  
% 
arguments
    mixSolver
end

import Solvers.SolverState

% Enable diary
mixSolver.inputSet.session.log.diaryOn();

% Open log in presistent mode
mixSolver.inputSet.session.log.openLog('keepLogOpen', true);

if mixSolver.STATE ~= SolverState.UNSOLVED
    error('This solver needs to be reinitialized before solving.');
else
    mixSolver.log('\n\n--------------------------------------------- Mixture solver run initiated ---------------------------------------------\n')

    try
        % Solve init
        solver(true);
    
        % Continue solving if init converged
        if mixSolver.STATE == SolverState.INITIALSTEPCONVERGED
            solver(false);
        else
            mixSolver.log('\t\tSkipping transient solver ...\n');
        end

    catch ME
        mixSolver.inputSet.session.log.closeLog();
        mixSolver.inputSet.session.log.diaryOff();
        rethrow(ME)
    end
    
    mixSolver.log('\n--------------------------------------------- Mixture solver run completed ---------------------------------------------\n\n')
end

mixSolver.inputSet.session.log.closeLog();
mixSolver.inputSet.session.log.diaryOff();
mixSolver.log('Output directory: %s\n',mixSolver.inputSet.session.directory);

function solver(solveINIT)

    % Check if solving mixtureInit
    if solveINIT
        mixSolver.log('\nRun steady-state ...\n');
        mix = mixSolver.mixtureInit;
        solveMODE = 'INITIAL';
        fluid   = repmat(mixSolver.fluid(1),1,length(mix));
    else
        mixSolver.log('\nRun transient ...\n');
        mix = mixSolver.mixture;
        solveMODE = 'SPECIFIED';
        fluid   = mixSolver.fluid;
    end
    
    % Shortcut to inputSet objects
    model   = mixSolver.inputSet.model;
    options = mixSolver.inputSet.options;
    geom    = mixSolver.inputSet.geometry;
    
    % Uniform mesh size
    DZ = mixSolver.DZ;    
    
    % Start timer
    startTime = tic();
    
    % Time loop
    for tIdx = 2:length(mix)                                                            % Loop over time steps
        
        mixSolver.log('Time %5.2f [s]',mix(tIdx).TIME)

        % Current time step size
        DT = mix(tIdx).DT;
        
        % Update flow property guesses from previous time step
        mix(tIdx-1).copyFlowProperties(mix(tIdx))

        % Axial sweep
        for zIdx = 2:mixSolver.NZ                                                       % Loop over axial nodes
            
            LHGR   = geom.PERIM.*mix(tIdx).HFLUX(zIdx,:);                               % [W/m] Linear heat generation rate
            
            % Parameters from previous time step
            Wold    = mix(tIdx-1).W(zIdx);                                              % [kg/s] Mixture mass flow rate at previous time step
            Uold    = mix(tIdx-1).U(zIdx);                                              % [m/s] Mixture velocity at previous time step
            Hold    = mix(tIdx-1).H(zIdx);                                              % [J/kg] Mixture enthalpy at previous time step
            WVold   = mix(tIdx-1).TRELAX.WV(zIdx,:);                                    % [m/s] Relaxed vapor mass flow rate at previous time step
            WVTHold = mix(tIdx-1).TRELAX.WVTH(zIdx,:);                                  % [m/s] Relaxed thermodynamic vapor mass flow rate at previous time step
            
            % Inner (point) iterations
            for itr = 1:options.MAXITER
    
                % Save parameters from previous point iteration
                Witer = mix(tIdx).W(zIdx);                                              % [kg/s] Mixture mass flow rate
                Piter = mix(tIdx).P(zIdx);                                              % [Pa] Pressure
                Hiter = mix(tIdx).H(zIdx);                                              % [J/kg] Enthalpy
                
                % Update secondary parameters
                U     = mix(tIdx).U(zIdx);                                              % [m/s] Mixture velocity
                
                % Mass conservation
                Wnew = (mix(tIdx).W(zIdx-1)+Wold/Uold*DZ/DT)/(1+DZ/U/DT);               % [kg/s] Update mixture mass flow rate
                mix(tIdx).W(zIdx) = (1-options.RELAXWM)*Witer+options.RELAXWM*Wnew;     % [kg/s] Apply relaxation
                
                % Momentum conservation
                DPparts = mix(tIdx).DPPARTS(Uold, zIdx);                                % [Pa] Pressure drop components
                Pnew = mix(tIdx).P(zIdx-1) + DPparts.TOT;                               % [Pa] New pressure
                mix(tIdx).P(zIdx) = (1-options.RELAXPM)*Piter+options.RELAXPM*Pnew;     % [Pa] Apply relaxation
    
                % Energy conservation
                Hnew = (mix(tIdx).H(zIdx-1)+DZ./mix(tIdx).W(zIdx)*sum(LHGR) + ...
                       Hold/U*DZ/DT)/(1+DZ/U/DT);                                       % [J/kg] Update mixture enthalpy
                mix(tIdx).H(zIdx) = (1-options.RELAXHM)*Hiter+options.RELAXHM*Hnew;     % [J/kg] Apply relaxation
                
                % Critical Boiling Transition
                [~,cbt] = mix(tIdx).CHF(zIdx);                                          % [-] Critical Boiling Transition array
                
                % Time relaxation terms (that needs to be updated in point iterations)
                switch model.SCBOIL
                    case 'TRELAX'
                        mix(tIdx).TRELAX.WV(zIdx,:) = mix(tIdx).WV(zIdx,U,WVold,Uold,DT,DZ,LHGR,cbt);     % [kg/s] Relaxed vapor mass flow
                        mix(tIdx).TRELAX.X(zIdx,:)  = mix(tIdx).TRELAX.WV(zIdx,:)./mix(tIdx).WWALL(zIdx); % [-] Relaxed vapor quality
                end
                
                % Check convergence
                dW = abs((mix(tIdx).W(zIdx)-Witer));                                    % [kg/s] Mass flow rate error between inner iterations
                dP = abs((mix(tIdx).P(zIdx)-Piter));                                    % [Pa]   Pressure error between inner iterations
                dH = abs((mix(tIdx).H(zIdx)-Hiter));                                    % [J/kg] Enthalpy error between inner iterations
                if all([dW < options.ERRORW, dP < options.ERRORP, dH < options.ERRORH])   
                    break;
                elseif itr == options.MAXITER
                    % set SOLVED flag to SOLVEDNOTCONVERGED
                    mixSolver.STATE = SolverState.SOLVEDNOTCONVERGED;
                    break;
                end
    
            end
            
            % Save time relaxation terms
            mix(tIdx).TRELAX.TIME(zIdx,:) = mix(tIdx).RELAXTIME(zIdx,cbt);                            % [s] Time relaxation
            mix(tIdx).TRELAX.WV(zIdx,:)   = mix(tIdx).WV(zIdx,U,WVold,Uold,DT,DZ,LHGR,cbt);           % [kg/s] Relaxed vapor mass flow
            mix(tIdx).TRELAX.X(zIdx,:)    = mix(tIdx).TRELAX.WV(zIdx,:)./mix(tIdx).WWALL(zIdx);       % [-] Relaxed vapor quality
            mix(tIdx).TRELAX.WVTH(zIdx,:) = mix(tIdx).WVTH(zIdx,U,WVTHold,Uold,DT,DZ,LHGR,cbt);       % [kg/s] Relaxed thermodynamic vapor mass flow
            mix(tIdx).TRELAX.XTH(zIdx,:)  = mix(tIdx).TRELAX.WVTH(zIdx,:)./mix(tIdx).WNEARWALL(zIdx); % [-] Relaxed thermodynamic vapor quality
            
            % Save pressure drop components
            mix(tIdx).DP.Grav(zIdx)  = -DPparts.GRAV;                                  % [Pa] Gravitational pressure drop
            mix(tIdx).DP.Wall(zIdx)  = -DPparts.WALL;                                  % [Pa] Wall friction pressure drop
            mix(tIdx).DP.Acc_z(zIdx) = -DPparts.ACCZ;                                  % [pa] Spatial acceleration pressure drop
            mix(tIdx).DP.Acc_t(zIdx) = -DPparts.ACCT;                                  % [Pa] Temporal acceleration pressure drop
            mix(tIdx).DP.K(zIdx)     = -DPparts.K;                                     % [Pa] Local pressure drop
            mix(tIdx).DP.Tot(zIdx)   = -DPparts.TOT;                                   % [Pa] Total pressure drop
            
            % Save acceleration terms
            mix(tIdx).ACC.U_z(zIdx) = mix(tIdx).U(zIdx).*(mix(tIdx).U(zIdx)-mix(tIdx).U(zIdx-1))./DZ; % [m/s^2]  Spatial  hydrodynamic acceleration
            mix(tIdx).ACC.U_t(zIdx) = (mix(tIdx).U(zIdx)-Uold)./DT;                                   % [m/s^2]  Temporal hydrodynamic acceleration
            mix(tIdx).ACC.U(zIdx)   = mix(tIdx).ACC.U_z(zIdx)+mix(tIdx).ACC.U_t(zIdx);                % [m/s^2]  Total    hydrodynamic acceleration
            mix(tIdx).ACC.H_z(zIdx) = mix(tIdx).U(zIdx).*(mix(tIdx).H(zIdx)-mix(tIdx).H(zIdx-1))./DZ; % [J/kg/s] Spatial  thermal acceleration
            mix(tIdx).ACC.H_t(zIdx) = (mix(tIdx).H(zIdx)-Hold)./DT;                                   % [J/kg/s] Temporal thermal acceleration
            mix(tIdx).ACC.H(zIdx)   = mix(tIdx).ACC.H_z(zIdx)+mix(tIdx).ACC.H_t(zIdx);                % [J/kg/s] Total    thermal acceleration
            
            % Iteration parameters
            mix(tIdx).ITR.N(zIdx)  = itr;
            mix(tIdx).ITR.DW(zIdx) = dW;
            mix(tIdx).ITR.DP(zIdx) = dP;
            mix(tIdx).ITR.DH(zIdx) = dH;

            % Stop running if solver did not converge
            if mixSolver.STATE == SolverState.SOLVEDNOTCONVERGED
                break;
            end
    
        end
        
        [maxN,maxzIdx] = max(mix(tIdx).ITR.N);
        maxDW = max(mix(tIdx).ITR.DW);
        maxDP = max(mix(tIdx).ITR.DP);
        maxDH = max(mix(tIdx).ITR.DH);
        
        % Temporal deviations in W, P, and H
        timeDW = max(abs((mix(tIdx).W - mix(tIdx-1).W)));
        timeDP = max(abs((mix(tIdx).P - mix(tIdx-1).P)));
        timeDH = max(abs((mix(tIdx).H - mix(tIdx-1).H)));
        mixSolver.log('\tmax point iter = %3d in node %3d, max errors: W = %.7f [kg/s], P = %.5f [Pa], H = %.5f [J/kg]\r',maxN,maxzIdx,maxDW,maxDP,maxDH)
    
        
        if solveINIT
            % Finish steady state solver when SS convergence criterions are met
            if all([timeDW < options.SSCONVW ,timeDP < options.SSCONVP ,timeDH < options.SSCONVH] )
                
                % Indicate init converged
                mixSolver.STATE = SolverState.INITIALSTEPCONVERGED;
                
                mixSolver.log('\n\t\tSTEADY-STATE CONVERGED            max errors: W = %.7f [kg/s], P = %.5f [Pa], H = %.5f [J/kg]\r',timeDW,timeDP,timeDH)
    
                % Replace mixtureInit with subset up to this tIdx
                mixSolver.mixtureInit = mixSolver.mixtureInit(1:tIdx);
    
                % Replace first transient time step flow data with this tIdx
                mixSolver.mixtureInit(end).copyFlowProperties(mixSolver.mixture(1));
        
                break;
            
            % otherwise, update next timestep with current flow properties
            elseif tIdx < length(mix)-1
                mixSolver.mixtureInit(tIdx).copyFlowProperties(mixSolver.mixtureInit(tIdx+1));
            % otherwise, not converged
            else
                mixSolver.STATE = "INITIALSTEPNOTCONVERGED";
                mixSolver.log('\t\tSTEADY-STATE FAILED TO CONVERGE     max errors: W = %.7f [kg/s], P = %.5f [Pa], H = %.5f [J/kg]\r',timeDW,timeDP,timeDH)
            end
        end
    
    end
    
    %mixSolver.log('\n---------------------- %s solver run completed ----------------------\n\n', solveMODE)
    mixSolver.log('\n')
    
    % End timer
    mixSolver.log('Elapsed time: %0.2f sec\n', toc(startTime))
end

end