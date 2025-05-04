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
            if length(mixSolver.mixture) > 1
                mixSolver.log('\t\tSkipping transient solver ...\n');
            end
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
    
    nwall = mixSolver.inputSet.geometry.NWALL;

    % Check if solving mixtureInit
    if solveINIT
        mixSolver.log('\nSolve steady-state ...\n');
        mix = mixSolver.mixtureInit;
        %solveMODE = 'INITIAL';
        fluid   = repmat(mixSolver.fluid(1),1,length(mix));
    else
        if length(mixSolver.mixture) < 2
            return
        end
        mixSolver.log('\nSolve transient ...\n');
        mix = mixSolver.mixture;
        %solveMODE = 'SPECIFIED';
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
    
    % Initialize
    dWv = 0; dHv = 0;
    
    % Time loop
    for tIdx = 2:length(mix)                                               % Loop over time steps
        
        mixSolver.log('Time %5.2f [s]',mix(tIdx).TIME)

        % Current time step size
        DT = mix(tIdx).DT;                                                 % [s] Current time step size
        
        % Update flow property guesses from previous time step
        mix(tIdx-1).copyFlowProperties(mix(tIdx))

        % Axial sweep
        for zIdx = 2:mixSolver.NZ                                          % Loop over axial nodes
            
            LHGR   = mix(tIdx).LHGR(zIdx);                                 % [W/m] Linear heat generation rate
            
            % Parameters from previous time step
            Wold    = mix(tIdx-1).W(zIdx);                                 % [kg/s] Mixture mass flow rate at previous time step
            Uold    = mix(tIdx-1).U(zIdx);                                 % [m/s] Mixture velocity at previous time step
            Hold    = mix(tIdx-1).H(zIdx);                                 % [J/kg] Mixture enthalpy at previous time step
            Uvold   = mix(tIdx-1).vapor.U(zIdx);                           % [m/s] Vapor velocity at previous time step
            Wvold   = mix(tIdx-1).TRELAX.WV(zIdx,:);                       % [m/s] Relaxed vapor mass flow rate at previous time step
            WvTHold = mix(tIdx-1).TRELAX.WVTH(zIdx,:);                     % [m/s] Relaxed thermodynamic vapor mass flow rate at previous time step
            Hvold   = mix(tIdx-1).TRELAX.HV(zIdx,:);                       % [J/kg] Relaxed vapor enthalpy at previous time step
            
            % Inner (point) iterations
            for itr = 1:options.MAXITER
    
                % Save parameters from previous point iteration
                Witer = mix(tIdx).W(zIdx);                                              % [kg/s] Mixture mass flow rate
                Piter = mix(tIdx).P(zIdx);                                              % [Pa] Pressure
                Hiter = mix(tIdx).H(zIdx);                                              % [J/kg] Mixture enthalpy
                
                % Update secondary parameters
                U     = mix(tIdx).U(zIdx);                                              % [m/s] Mixture velocity
                
                % Mixture mass conservation
                Wnew = (mix(tIdx).W(zIdx-1)+Wold/Uold*DZ/DT)/(1+DZ/U/DT);               % [kg/s] Update mixture mass flow rate
                mix(tIdx).W(zIdx) = (1-options.RELAXWM)*Witer+options.RELAXWM*Wnew;     % [kg/s] Apply relaxation
                
                % Mixture momentum conservation
                Pnew = mix(tIdx).P(zIdx-1) + mix(tIdx).DPTOT(Uold, zIdx);               % [Pa] New pressure
                mix(tIdx).P(zIdx) = (1-options.RELAXPM)*Piter+options.RELAXPM*Pnew;     % [Pa] Apply relaxation
    
                % Mixture energy conservation
                Hnew = (mix(tIdx).H(zIdx-1)+DZ./mix(tIdx).W(zIdx)*sum(LHGR) + ...
                       Hold/U*DZ/DT)/(1+DZ/U/DT);                                       % [J/kg] Update mixture enthalpy
                mix(tIdx).H(zIdx) = (1-options.RELAXHM)*Hiter+options.RELAXHM*Hnew;     % [J/kg] Apply relaxation
                
                switch model.THERMALNONEQ
                    case 'RELAXATION'
                        % Five-equation thermal non-equilibrium model based on time-relaxed vapor mass and energy conservations
                        
                        % Save parameters from previous point iteration
                        Wviter = mix(tIdx).TRELAX.WV(zIdx,:);                           % [J/kg] Vapor mass flow rate
                        Hviter = mix(tIdx).TRELAX.HV(zIdx,:);                           % [J/kg] Vapor enthalpy
                        
                        % Update secondary parameters
                        Uv     = mix(tIdx).vapor.U(zIdx);                               % [m/s] Vapor velocity
                        
                        % Vapor mass conservation
                        Mvtot = mix(tIdx).MTOT(zIdx);                                                      % [kg/s/m] Linear vapor mass transfer rate
                        Wvnew = Uv.*(mix(tIdx).TRELAX.WV(zIdx-1,:)+(Wvold./Uvold./DT+Mvtot).*DZ)./(Uv+DZ/DT);
                        Wvnew = max(0,Wvnew);
                        mix(tIdx).TRELAX.WV(zIdx,:) = (1-options.RELAXWV).*Wviter+options.RELAXWV.*Wvnew;  % [kg/s] Apply relaxation

                        mix(tIdx).TRELAX.X(zIdx,:)  = mix(tIdx).TRELAX.WV(zIdx,:)./mix(tIdx).WWALL(zIdx);  % [-] Relaxed vapor quality
                        
                        % Vapor energy conservation
                        Hvtot = mix(tIdx).HVTOT(zIdx);                                                   % [J/kg/m] Linear vapor enthalpy transfer
                        Htot  = Hvtot.*Uv;                                                               % [W/kg]
                        Hvnew = (Uv.*mix(tIdx).TRELAX.HV(zIdx-1,:)+(Hvold./DT+Htot).*DZ)./(Uv+DZ/DT);    % [J/kg] Update vapor enthalpy
                        Hvnew = max(fluid(tIdx).HG,Hvnew);
                        mix(tIdx).TRELAX.HV(zIdx,:) = (1-options.RELAXHV).*Hviter+options.RELAXHV.*Hvnew;  % [J/kg] Apply relaxation
                        
                        % Check convergence
                        dWv = abs((mix(tIdx).TRELAX.WV(zIdx,:)-Wviter));                                   % [kg/s] Vapor mass flow rate error between inner iterations
                        dHv = abs((mix(tIdx).TRELAX.HV(zIdx,:)-Hviter));                                   % [J/kg] Vapor enthalpy error between inner iterations
                end
                
                % Check convergence
                dW = abs((mix(tIdx).W(zIdx)-Witer));                                    % [kg/s] Mass flow rate error between inner iterations
                dP = abs((mix(tIdx).P(zIdx)-Piter));                                    % [Pa]   Pressure error between inner iterations
                dH = abs((mix(tIdx).H(zIdx)-Hiter));                                    % [J/kg] Enthalpy error between inner iterations
                if all([dW < options.ERRORW, dP < options.ERRORP, dH < options.ERRORH, dWv < options.ERRORW, dHv < options.ERRORH])
                    break;
                elseif itr == options.MAXITER
                    % set SOLVED flag to SOLVEDNOTCONVERGED
                    mixSolver.STATE = SolverState.SOLVEDNOTCONVERGED;
                    break;
                end
    
            end
            
            % Save time relaxation terms (including near-wall terms)
            mix(tIdx).TRELAX.TIME(zIdx,:) = mix(tIdx).RELAXTCOND(zIdx);                               % [s] Time relaxation
            mix(tIdx).TRELAX.TV(zIdx,:)   = fluid(tIdx).T(mix(tIdx).TRELAX.HV(zIdx,:))';              % [J/kg] Relaxed vapor temperature
            mix(tIdx).TRELAX.WVTH(zIdx,:) = mix(tIdx).WVTH(zIdx,WvTHold,Uold);                        % [kg/s] Relaxed thermodynamic vapor mass flow
            mix(tIdx).TRELAX.XTH(zIdx,:)  = mix(tIdx).TRELAX.WVTH(zIdx,:)./mix(tIdx).WNEARWALL(zIdx); % [-] Relaxed thermodynamic vapor quality
            
            % Save pressure drop components
            DPparts = mix(tIdx).DPPARTS(Uold, zIdx);                       % [Pa] Pressure drop components
            mix(tIdx).DP.Grav(zIdx)  = -DPparts.GRAV;                      % [Pa] Gravitational pressure drop
            mix(tIdx).DP.Wall(zIdx)  = -DPparts.WALL;                      % [Pa] Wall friction pressure drop
            mix(tIdx).DP.Acc_z(zIdx) = -DPparts.ACCZ;                      % [pa] Spatial acceleration pressure drop
            mix(tIdx).DP.Acc_t(zIdx) = -DPparts.ACCT;                      % [Pa] Temporal acceleration pressure drop
            mix(tIdx).DP.K(zIdx)     = -DPparts.K;                         % [Pa] Local pressure drop
            mix(tIdx).DP.Tot(zIdx)   = -DPparts.TOT;                       % [Pa] Total pressure drop
            
            % Save acceleration terms
            mix(tIdx).ACC.U_z(zIdx) = mix(tIdx).U(zIdx).*(mix(tIdx).U(zIdx)-mix(tIdx).U(zIdx-1))./DZ; % [m/s^2]  Spatial  hydrodynamic acceleration
            mix(tIdx).ACC.U_t(zIdx) = (mix(tIdx).U(zIdx)-Uold)./DT;                                   % [m/s^2]  Temporal hydrodynamic acceleration
            mix(tIdx).ACC.U(zIdx)   = mix(tIdx).ACC.U_z(zIdx)+mix(tIdx).ACC.U_t(zIdx);                % [m/s^2]  Total    hydrodynamic acceleration
            mix(tIdx).ACC.H_z(zIdx) = mix(tIdx).U(zIdx).*(mix(tIdx).H(zIdx)-mix(tIdx).H(zIdx-1))./DZ; % [J/kg/s] Spatial  thermal acceleration
            mix(tIdx).ACC.H_t(zIdx) = (mix(tIdx).H(zIdx)-Hold)./DT;                                   % [J/kg/s] Temporal thermal acceleration
            mix(tIdx).ACC.H(zIdx)   = mix(tIdx).ACC.H_z(zIdx)+mix(tIdx).ACC.H_t(zIdx);                % [J/kg/s] Total    thermal acceleration
            
            % Iteration parameters
            mix(tIdx).ITR.N(zIdx)           = itr;
            mix(tIdx).ITR.DW(zIdx)          = dW;
            mix(tIdx).ITR.DP(zIdx)          = dP;
            mix(tIdx).ITR.DH(zIdx)          = dH;
            mix(tIdx).ITR.DWV(zIdx,1:nwall) = dWv;
            mix(tIdx).ITR.DHV(zIdx,1:nwall) = dHv;

        end
        
        % Save cumulative pressure drop components
        mix(tIdx).DPSUM.Grav  = cumsum(mix(tIdx).DP.Grav);                 % [Pa] Gravitational pressure drop
        mix(tIdx).DPSUM.Wall  = cumsum(mix(tIdx).DP.Wall);                 % [Pa] Wall friction pressure drop
        mix(tIdx).DPSUM.Acc_z = cumsum(mix(tIdx).DP.Acc_z);                % [pa] Spatial acceleration pressure drop
        mix(tIdx).DPSUM.Acc_t = cumsum(mix(tIdx).DP.Acc_t);                % [Pa] Temporal acceleration pressure drop
        mix(tIdx).DPSUM.K     = cumsum(mix(tIdx).DP.K);                    % [Pa] Local pressure drop
        mix(tIdx).DPSUM.Tot   = cumsum(mix(tIdx).DP.Tot);                  % [Pa] Total pressure drop
        
        [maxN,maxzIdx] = max(mix(tIdx).ITR.N);
        maxDW  = max(mix(tIdx).ITR.DW);
        maxDP  = max(mix(tIdx).ITR.DP);
        maxDH  = max(mix(tIdx).ITR.DH);
        maxDWv = max(mix(tIdx).ITR.DWV,[],'all');
        maxDHv = max(mix(tIdx).ITR.DHV,[],'all');
        switch model.THERMALNONEQ
            case 'RELAXATION'
                mixSolver.log('\tmax point iter = %3d in node %3d, max errors: W = %.7f [kg/s], Wv = %.7f [kg/s], P = %.5f [Pa], H = %.5f [J/kg], Hv = %.5f [J/kg]                    \r',maxN,maxzIdx,maxDW,maxDWv,maxDP,maxDH,maxDHv)
            otherwise
                mixSolver.log('\tmax point iter = %3d in node %3d, max errors: W = %.7f [kg/s], P = %.5f [Pa], H = %.5f [J/kg]                    \r',maxN,maxzIdx,maxDW,maxDP,maxDH)
        end
        
        % Temporal deviations in W, P, and H
        timeDW  = max(abs((mix(tIdx).W - mix(tIdx-1).W)));
        timeDP  = max(abs((mix(tIdx).P - mix(tIdx-1).P)));
        timeDH  = max(abs((mix(tIdx).H - mix(tIdx-1).H)));
        timeDWv = max(abs((mix(tIdx).TRELAX.WV - mix(tIdx-1).TRELAX.WV)),[],'all');
        timeDHv = max(abs((mix(tIdx).TRELAX.HV - mix(tIdx-1).TRELAX.HV)),[],'all');
        
        if solveINIT
            % Finish steady state solver when SS convergence criterions are met
            if all([timeDW < options.SSCONVW, timeDP < options.SSCONVP ,timeDH < options.SSCONVH, timeDWv < options.SSCONVW, timeDHv < options.SSCONVH])
                
                % Indicate init converged
                mixSolver.STATE = SolverState.INITIALSTEPCONVERGED;
                
                switch model.THERMALNONEQ
                    case 'RELAXATION'
                        mixSolver.log('\n\t\tSTEADY-STATE CONVERGED            max errors: W = %.7f [kg/s], Wv = %.7f [kg/s], P = %.5f [Pa], H = %.5f [J/kg], Hv = %.5f [J/kg]\r',timeDW,timeDWv,timeDP,timeDH,timeDHv)
                    otherwise
                        mixSolver.log('\n\t\tSTEADY-STATE CONVERGED            max errors: W = %.7f [kg/s], P = %.5f [Pa], H = %.5f [J/kg]\r',timeDW,timeDP,timeDH)
                end
                
                % Replace mixtureInit with subset up to this tIdx
                mixSolver.mixtureInit = mixSolver.mixtureInit(1:tIdx);
    
                % Replace first transient time step flow data with steady-state solver solution
                mixSolver.mixtureInit(end).copyFlowProperties(mixSolver.mixture(1));
        
                break;
            
            % otherwise, update next timestep with current flow properties
            elseif tIdx < length(mix)
                mixSolver.mixtureInit(tIdx).copyFlowProperties(mixSolver.mixtureInit(tIdx+1));
            
            % otherwise, not converged
            else
                mixSolver.STATE = "INITIALSTEPNOTCONVERGED";
                
                switch model.THERMALNONEQ
                    case 'RELAXATION'
                        mixSolver.log('\n\t\tSTEADY-STATE FAILED TO CONVERGE   max errors: W = %.7f [kg/s], Wv = %.7f [kg/s], P = %.5f [Pa], H = %.5f [J/kg], Hv = %.5f [J/kg]\r',timeDW,timeDWv,timeDP,timeDH,timeDHv)
                    otherwise
                        mixSolver.log('\n\t\tSTEADY-STATE FAILED TO CONVERGE   max errors: W = %.7f [kg/s], P = %.5f [Pa], H = %.5f [J/kg]\r',timeDW,timeDP,timeDH)
                end
                
                % Replace first transient time step flow data with steady-state solver solution, regardless of convergence
                mixSolver.mixtureInit(end).copyFlowProperties(mixSolver.mixture(1));
            end
        end
    
    end
    
    mixSolver.log('\n')
    
    % End timer
    mixSolver.log('Elapsed time: %0.2f sec\n', toc(startTime))
end

end