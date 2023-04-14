function solve(mixSolver,  opts)
%SOLVE  
% 
arguments
    mixSolver
    opts.verbose = true
end

if mixSolver.SOLVED
    error('This solver needs to be reinitialized before solving.');
else
    solver('STEADY');
    solver('TRANSIENT');
    
    fprintf('\n---------------------- Two-phase flow solver run completed ----------------------\n\n')
end


function solver(solveMode)

    switch upper(solveMode)
        case 'TRANSIENT'
            fprintf('\nRun transient solver ...\n');
            mix = mixSolver.mixtureTransient;
    
        case 'STEADY'
            fprintf('\nRun steady-state solver ...\n');
            mix = mixSolver.mixtureSteady;
    end    
    
    % set SOLVED flag to true
    mixSolver.SOLVED = true;
    
    % Shortcut to inputSet objects
    model = mixSolver.inputSet.model;
    options = mixSolver.inputSet.options;
    geom = mixSolver.inputSet.geometry;
    
    
    % Uniform mesh and time step
    DZ = mixSolver.DZ;
    DT = mixSolver.DT;
    
    % Start timer
    tic
    
    % Time loop
    for tIdx = 2:length(mix)                                                     % Loop over time steps
        
        fprintf('Time %5.2f [s]',mix(tIdx).TIME)
        
        % Axial sweep
        for zIdx = 2:mixSolver.NZ                                                        % Loop over axial nodes
            
            % Inner (point) iterations
            for itr = 1:options.MAXITER
    
                % Save parameters from previous point iteration
                Witer = mix(tIdx).W(zIdx);                                              % [kg/s] Mixture mass flow rate
                Piter = mix(tIdx).P(zIdx);                                              % [Pa] Pressure
                Hiter = mix(tIdx).H(zIdx);                                              % [J/kg] Enthalpy
                
                % Update secondary parameters
                VEL   = mix(tIdx).U([zIdx-1 zIdx]);                                     % [m/s] Calculate velocity array for speed
                U     = VEL(2); Uups = VEL(1);                                          % [m/s] Mixture velocities at node k and k-1
                Uold  = mix(tIdx-1).U(zIdx);                                            % [m/s] Mixture velocity at previous time step
                RHO   = mix(tIdx).RHO(zIdx);                                            % [kg/m^3] Mixture density
                TAUW  = mix(tIdx).TAUW(zIdx);                                           % [Pa] Wall shear stress
                HFLUX = mix(tIdx).HFLUX(zIdx,:);                                        % [W/m^2] Wall heat flux
                
                % Mass conservation
                Wnew = (mix(tIdx).W(zIdx-1)+mix(tIdx-1).W(zIdx)/Uold*DZ/DT) ...
                                                            ./(1+DZ/U/DT);              % [kg/s] Update mixture mass flow rate
                mix(tIdx).W(zIdx) = (1-options.RELAXWM)*Witer+options.RELAXWM*Wnew;     % [kg/s] Apply relaxation
                
                % Momentum conservation
                dpGrav  = -model.G*RHO*DZ;                                      % [Pa] Gravitational pressure drop
                dpWall  = -sum(geom.PERIM)*TAUW./geom.AREA.*DZ;                 % [Pa] Wall friction pressure drop
                dpAcc_z = -mix(tIdx).W(zIdx)./geom.AREA.*(U-Uups);              % [Pa] Spatial acceleration pressure drop
                dpAcc_t = -mix(tIdx).W(zIdx)./geom.AREA.*(1-Uold/U).*DZ./DT;    % [Pa] Temporal acceleration pressure drop
                dpK     = -mix(tIdx).DPK(zIdx);                                 % [Pa] Local pressure drop
                Pnew    = mix(tIdx).P(zIdx-1)+dpGrav+dpWall+dpAcc_z+dpAcc_t+dpK;    % [Pa] Update pressure
                mix(tIdx).P(zIdx) = (1-options.RELAXPM)*Piter+options.RELAXPM*Pnew; % [Pa] Apply relaxation
    
                % Energy conservation
                Hnew = (mix(tIdx).H(zIdx-1)+DZ./mix(tIdx).W(zIdx).*sum(geom.PERIM.'.*reshape(HFLUX,length(zIdx),[]).',1)+ ...
                       mix(tIdx-1).H(zIdx)./U.*DZ./DT)/(1+DZ./U./DT);               % [J/kg] Update mixture enthalpy
                mix(tIdx).H(zIdx) = (1-options.RELAXHM)*Hiter+options.RELAXHM*Hnew; % [J/kg] Apply relaxation
                
                % Check convergence
                dW = abs((mix(tIdx).W(zIdx)-Witer));                             % [kg/s] Mass flow rate error between inner iterations
                dP = abs((mix(tIdx).P(zIdx)-Piter));                             % [Pa]   Pressure error between inner iterations
                dH = abs((mix(tIdx).H(zIdx)-Hiter));                             % [J/kg] Enthalpy error between inner iterations
                if all([dW < options.ERRORW, dP < options.ERRORP, dH < options.ERRORH])   
                    break;
                end
    
            end
            
            % Save pressure drop components
            mix(tIdx).DP.Grav(zIdx)  = -dpGrav;                                  % [Pa] Gravitational pressure drop
            mix(tIdx).DP.Wall(zIdx)  = -dpWall;                                  % [Pa] Wall friction pressure drop
            mix(tIdx).DP.Acc_z(zIdx) = -dpAcc_z;                                 % [pa] Spatial acceleration pressure drop
            mix(tIdx).DP.Acc_t(zIdx) = -dpAcc_t;                                 % [Pa] Temporal acceleration pressure drop
            mix(tIdx).DP.K(zIdx)     = -dpK;                                     % [Pa] Local pressure drop
            mix(tIdx).DP.Tot(zIdx)   = -(mix(tIdx).P(zIdx)-mix(tIdx).P(zIdx-1)); % [Pa] Total pressure drop
            
            % Iteration parameters
            mix(tIdx).ITR.N(zIdx)  = itr;
            mix(tIdx).ITR.DW(zIdx) = dW;
            mix(tIdx).ITR.DP(zIdx) = dP;
            mix(tIdx).ITR.DH(zIdx) = dH;
    
    
        end
        
        maxN = max(mix(tIdx).ITR.N);
        maxDW = max(mix(tIdx).ITR.DW);
        maxDP = max(mix(tIdx).ITR.DP);
        maxDH = max(mix(tIdx).ITR.DH);
        
        % Temporal deviations in W, P, and H
        timeDW = max(abs((mix(tIdx).W - mix(tIdx-1).W)));
        timeDP = max(abs((mix(tIdx).P - mix(tIdx-1).P)));
        timeDH = max(abs((mix(tIdx).H - mix(tIdx-1).H)));
        fprintf('\t(Max iter = %d, Max errors W = %f [kg/s], %.2f [Pa], %.3f [J/kg])\r',maxN,maxDW,maxDP,maxDH)
    
        % Finish steady state solver when SS convergence criterions are met
        if strcmp(solveMode, 'STEADY') && ...
                all([timeDW < options.SSCONVW ,timeDP < options.SSCONVP ,timeDH < options.SSCONVH] )
    
            fprintf('\t\tMax errors W = %f [kg/s], %.6f [Pa], %.6f [J/kg])\r',timeDW,timeDP,timeDH)

            % Replace mixtureSteady with subset up to this tIdx
            mixSolver.mixtureSteady = mixSolver.mixtureSteady(1:tIdx);
    
            % Replace first transient time step with this tIdx
            mixSolver.mixtureTransient(1) = copy(mixSolver.mixtureSteady(tIdx));
            mixSolver.mixtureTransient(1).TIME = mixSolver.mixtureSteady(1).TIME;
            mixSolver.mixtureTransient(1).TIDX = mixSolver.mixtureSteady(1).TIDX;        
    
            break;
        end
    
        
    
    end
    
    
    fprintf('\n---------------------- %s solver run completed ----------------------\n\n', solveMode)
    
    % End timer
    toc
end

function fprintf(varargin)
    if opts.verbose, builtin('fprintf',varargin{:}); end
end

end