function solve(tfSolver)
%SOLVE  
% 
arguments
    tfSolver
end

import Solvers.SolverState

% Enable diary
tfSolver.inputSet.session.log.diaryOn();

% Open log in presistent mode
tfSolver.inputSet.session.log.openLog('keepLogOpen', true);

if tfSolver.STATE ~= SolverState.UNSOLVED
    error('This solver needs to be reinitialized before solving.');
else
    tfSolver.log('\n\n------------------------------------------- Three-field solver run initiated -------------------------------------------\n')

    try
        % Solve init
        solver(true);
        
        % Continue solving if init converged
        if tfSolver.STATE == SolverState.INITIALSTEPCONVERGED
            solver(false);
        else
            tfSolver.log('\t\tSkipping transient solver ...\n');
        end
    catch ME
        tfSolver.inputSet.session.log.closeLog();
        tfSolver.inputSet.session.log.diaryOff();
        rethrow(ME)
    end
    
    tfSolver.log('\n------------------------------------------- Three-field solver run completed -------------------------------------------\n\n')
end

tfSolver.inputSet.session.log.closeLog();
tfSolver.inputSet.session.log.diaryOff();
tfSolver.log('Output directory: %s\n',tfSolver.inputSet.session.directory);


function solver(solveINIT)
    
    
    nwall = tfSolver.inputSet.geometry.NWALL;

    % check if solving filmInit and dropInit
    if solveINIT
        tfSolver.log('\nSolve steady-state ...\n');
        film = tfSolver.filmInit;
        drop = tfSolver.dropInit;
        fluid = tfSolver.fluidInit;
        mix = copy(repmat(tfSolver.mixSolver.mixture(1),1,tfSolver.inputSet.options.SSMAXITER));
        solveMODE = 'INITIAL';
    else
        tfSolver.log('\nSolve transient ...\n');
        film = tfSolver.film;
        drop = tfSolver.drop;
        fluid = tfSolver.fluid;
        mix = tfSolver.mixSolver.mixture;
        solveMODE = 'SPECIFIED';
    end
    
    % set SOLVED flag to SOLVECONVERGED
    tfSolver.STATE = SolverState.SOLVEDCONVERGED;
    
    % Shortcut to inputSet objects
    model   = tfSolver.inputSet.model;
    options = tfSolver.inputSet.options;
    geom    = tfSolver.inputSet.geometry;
    
    % Uniform mesh size
    DZ = tfSolver.DZ;    
    
    % Start timer
    startTime = tic();
    
    % Time loop
    for tIdx = 2:length(film)                                              % Loop over time steps
        
        tfSolver.log('Time %5.2f [s]',film(tIdx).TIME)
        
        DT = film(tIdx).DT;                                                % [s] Current time step size
        RHOF = fluid(tIdx).RHOF;                                  % [kg/m^3] Satrurated liquid density

        % Update three-field property guesses from previous time step
        film(tIdx-1).copyFlowProperties(film(tIdx));
        drop(tIdx-1).copyFlowProperties(drop(tIdx));
        
        
        % Axial sweep
        for zIdx = 2:tfSolver.NZ
            
            Wfold = film(tIdx-1).W(zIdx,:);                                % [kg/s] Film mass flow rate at previosu time step
            Ufold = film(tIdx-1).U(zIdx,:);                                % [m/s] Film velocity at previous time step
            Wfups = film(tIdx).W(zIdx-1,:);                                % [kg/s] Film mass flow rate at previosu time step
            Ufups = film(tIdx).U(zIdx-1,:);                                % [m/s] Film velocity at previous time step
            Udold = drop(tIdx-1).U(zIdx);                                  % [m/s] Drop velocity at previous time step
            Udups = drop(tIdx).U(zIdx-1);                                  % [m/s] Drop velocity at previous time step
            
            % Inner (point) iterations
            for itr = 1:options.MAXITER
                
                % Save primary parameters from previous point iteration
                Wfiter = film(tIdx).W(zIdx,:);                             % [kg/s] Film mass flow rate
                WLiter = film(tIdx).WL(zIdx);                              % [kg/s/m] Film mass flow rate per unit perimeter
                Ufiter = film(tIdx).U(zIdx,:);                             % [m/s] Film velocity
                Uditer = drop(tIdx).U(zIdx);                              % [m/s] Drop velocity
                
                % Film mass conservation
                Mtot = film(tIdx).MTOT(mix(tIdx),drop(tIdx),zIdx);                            % [kg/s/m^2] Mass exchange terms with film
                Wfnew = Ufiter.*(Wfups+Wfold./Ufold.*DZ./DT+geom.PERIM.*Mtot.*DZ)./(Ufiter+DZ./DT); % [kg/s] Update film mass flow rate
                film(tIdx).W(zIdx,:) = (1-options.RELAXWF).*Wfiter+options.RELAXWF.*Wfnew;    % [kg/s] Apply relaxation
                
                if model.POSFILM
                    film(tIdx).W(zIdx,:) = max(film(tIdx).W(zIdx,:),0);                       % [kg/s] 
                end
                
                % Film momentum conservation
                switch model.MOMENTFILM
                    case InputEnums.MOMENTFILM.ALGEBRAIC
                    % Simple algebraic model
                        film(tIdx).U(zIdx,:) = film(tIdx).UALGEBR(mix(tIdx),zIdx);                    % [m/s]
                        
                    case InputEnums.MOMENTFILM.EQUILIBRIUMS
                    % Simple equilibrium model (Fwall+ Fvapor = 0)
                        film(tIdx).U(zIdx,:) = film(tIdx).UEQUILS(mix(tIdx),zIdx);                    % [m/s]
                        
                    case InputEnums.MOMENTFILM.EQUILIBRIUM
                    % Complete equilibrium model (Ftot = 0)
                        film(tIdx).U(zIdx,:) = film(tIdx).UEQUIL(mix(tIdx),drop(tIdx),zIdx);          % [m/s]
                        
                    case InputEnums.MOMENTFILM.FULL
                    % Full film momentum conservation
                        %for i = 1:round(1/options.RELAXUF)
                        
                        thick = max(abs(film(tIdx).THICK(zIdx)),model.THINFILMTHICK);                 % [m] Film thickness
                        
                        if thick>model.THINFILMTHICK
                            Fftot = film(tIdx).FTOT(mix(tIdx),drop(tIdx),zIdx);                        % [N/m^2] Momentum exchange terms with film
                            Unew = (Ufups.*Ufiter+Ufold.*DZ./DT+Fftot.*DZ./(RHOF.*thick))./(Ufiter+DZ/DT); % [m/s] Update velocity
                            Unew = min(max(Unew,0),mix(tIdx).liquid.U(zIdx));                         % [m/s] Keep within realistic bounds to help convergence
                            film(tIdx).U(zIdx,:) = (1-options.RELAXUF).*Ufiter+options.RELAXUF.*Unew;  % [m/s] Apply relaxation
                            film(tIdx).U(zIdx,:) = mix(tIdx).AFDISTR(mix(tIdx).liquid.U(zIdx),film(tIdx).U(zIdx,:),zIdx);
                        else
                            film(tIdx).U(zIdx,:) = film(tIdx).UEQUIL(mix(tIdx),drop(tIdx),zIdx);      % [m/s] Complete equilibrium model for thin film
                        end
                        
                        %Uiter = film(tIdx).U(zIdx,:);
                        %end
                end
                
                % Drop mass conservation
                drop(tIdx).W(zIdx) = mix(tIdx).liquid.W(zIdx)-sum(film(tIdx).W(zIdx,:)); % [kg/s] Drop flowrate
                
                % Drop momentum conservation
                switch model.MOMENTDROP
                    case InputEnums.MOMENTDROP.SLIP
                    % Velocity slip model
                        drop(tIdx).U(zIdx) = drop(tIdx).USLIP(mix(tIdx),zIdx);                    % [m/s] Drop velocity
                    
                    case InputEnums.MOMENTDROP.ALGEBRAIC
                    % Model consistent with mixture model
                        drop(tIdx).U(zIdx) = drop(tIdx).UALGEBR(film(tIdx),mix(tIdx),zIdx);       % [m/s] Drop velocity
                        
                    case InputEnums.MOMENTDROP.EQUILIBRIUMS
                    % Simple equilibrium model (Fdrag + Fgrav + Fbuoy = 0)
                        drop(tIdx).U(zIdx) = drop(tIdx).UEQUIL(mix(tIdx),film(tIdx),zIdx,1);      % [m/s] Drop velocity 
                        
                    case InputEnums.MOMENTDROP.EQUILIBRIUM
                    % Complete equilibrium model (Ftot = 0)
                        drop(tIdx).U(zIdx) = drop(tIdx).UEQUIL(mix(tIdx),film(tIdx),zIdx);        % [m/s] Drop velocity      
                        
                    case InputEnums.MOMENTDROP.FULL
                    % Full drop momentum conservation
                        Fdtot = drop(tIdx).FTOT(mix(tIdx),film(tIdx),zIdx);                       % [N/m^3] Momentum exchange terms with drop
                        Udnew = (Udups.*Uditer+Udold.*DZ./DT+Fdtot.*DZ./RHOF)./(Uditer+DZ/DT);    % [m/s] Update velocity
                        drop(tIdx).U(zIdx) = (1-options.RELAXUD).*Uditer+options.RELAXUD.*Udnew;  % [m/s] Apply relaxation
                        drop(tIdx).U(zIdx) = mix(tIdx).AFDISTR(mix(tIdx).liquid.U(zIdx),drop(tIdx).U(zIdx),zIdx);
                end
                
                % Check convergence
                dWL = abs((film(tIdx).WL(zIdx)-WLiter));                   % [kg/s/m] Film mass flow rate error between inner iterations
                dUf = abs((film(tIdx).U(zIdx,:)-Ufiter));                  % [m/s]    Film velocity error between inner iterations
                dUd = abs((drop(tIdx).U(zIdx)-Uditer));                    % [m/s]    Drop velocity error between inner iterations
                if all([dWL < options.ERRORWF, dUf < options.ERRORUF, dUd < options.ERRORUD])
                    break;                                                 % Exit point iteration when converged
                
                elseif itr == options.MAXITER
                % set SOLVED flag to SOLVEDNOTCONVERGED
                    tfSolver.STATE = SolverState.SOLVEDNOTCONVERGED;
                    break;
                end
                
            end
            
            % Iteration parameters
            film(tIdx).ITR.N(zIdx)  = itr;
            film(tIdx).ITR.DWL(zIdx,1:nwall) = dWL;
            film(tIdx).ITR.DU(zIdx,1:nwall)  = dUf;
            drop(tIdx).ITR.N(zIdx)  = itr;
            drop(tIdx).ITR.DU(zIdx) = dUd;
            
        end
        
        [maxN,maxzIdx] = max(film(tIdx).ITR.N);
        maxDWL = max(film(tIdx).ITR.DWL,[],'all');
        maxDUf = max(film(tIdx).ITR.DU,[],'all');
        maxDUd = max(drop(tIdx).ITR.DU,[],'all');
        tfSolver.log('\tmax point iter = %3d in node %3d, max errors: Wf = %.7f [kg/s/m], Uf = %.5f [m/s], Ud = %.5f [m/s]\r',maxN,maxzIdx,maxDWL,maxDUf,maxDUd)
        
        % Temporal deviations in W and U
        timeDWL = max(abs((film(tIdx).WL - film(tIdx-1).WL)),[],'all');
        timeDUf  = max(abs((film(tIdx).U - film(tIdx-1).U)),[],'all');
        timeDUd = max(abs((drop(tIdx).U - drop(tIdx-1).U)),[],'all');
        
        if solveINIT
            % Finish steady state solver when SS convergence criterions are met
            if all([timeDWL < options.SSCONVWF ,timeDUf < options.SSCONVUF, timeDUd < options.SSCONVUD] )

                % Indicate init converged
                tfSolver.STATE = SolverState.INITIALSTEPCONVERGED;
    
                tfSolver.log('\n\t\tSTEADY-STATE CONVERGED            max errors: Wf = %.7f [kg/s/m], Uf = %.5f [m/s], Ud = %.5f [m/s]\r',timeDWL,timeDUf,timeDUd)
    
                % Replace filmInit and dropInit with subset up to this tIdx
                tfSolver.filmInit = tfSolver.filmInit(1:tIdx);
                tfSolver.dropInit = tfSolver.dropInit(1:tIdx);
                
                % Replace first transient time step flow data with this tIdx
                tfSolver.filmInit(end).copyFlowProperties(tfSolver.film(1));
                tfSolver.dropInit(end).copyFlowProperties(tfSolver.drop(1));
                
                break;
            
            % otherwise, update next timestep with current flow properties
            elseif tIdx < length(film)-1
                % unless non-convergence occurred
                if tfSolver.STATE == SolverState.SOLVEDNOTCONVERGED
                    tfSolver.log('\t\tSTEADY-STATE FAILED TO CONVERGE     max errors: Wf = %.7f [kg/s/m], Uf = %.5f [m/s]), Ud = %.5f [m/s]\r',timeDWL,timeDUf,timeDUd)
                    break;
                end

                tfSolver.filmInit(tIdx).copyFlowProperties(tfSolver.filmInit(tIdx+1));
                tfSolver.dropInit(tIdx).copyFlowProperties(tfSolver.dropInit(tIdx+1));
            % otherwise, not converged
            else
                tfSolver.STATE = SolverState.INITIALSTEPNOTCONVERGED;
                tfSolver.log('\t\tSTEADY-STATE FAILED TO CONVERGE     max errors: Wf = %.7f [kg/s/m], Uf = %.5f [m/s]), Ud = %.5f [m/s]\r',timeDWL,timeDUf,timeDUd)
                break;
            end
        end
    
    end
    
    %tfSolver.log('\n------------------------------ %9s Three-field solver run completed ------------------------------\n\n', solveMODE)
    tfSolver.log('\n')
    
    % End timer
    tfSolver.log('Elapsed time: %0.2f sec\n', toc(startTime))
end

end