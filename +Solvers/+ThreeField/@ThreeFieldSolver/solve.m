function solve(tfSolver)
%SOLVE  
% 
arguments
    tfSolver
end

import Solvers.SolverState

tfSolver.inputSet.session.log.toggleDiary(true);

if tfSolver.STATE ~= SolverState.UNSOLVED
    error('This solver needs to be reinitialized before solving.');
else
    solver(true);
    solver(false);
    
    tfSolver.log('\n---------------------- Three-field solver run completed ----------------------\n\n')
end

tfSolver.inputSet.session.log.toggleDiary();
fprintf('Output directory: %s\n',tfSolver.inputSet.session.directory);
tfSolver.inputSet.session.log.toggleDiary(true);


function solver(solveINIT)
    
    mix = tfSolver.mixture;
    nwall = tfSolver.inputSet.geometry.NWALL;

    % check if solving filmInit and dropInit
    if solveINIT
        tfSolver.log('\nRun three-field steady-state solver ...\n');
        film = tfSolver.filmInit;
        drop = tfSolver.dropInit;
        solveMODE = 'INITIAL';
    else
        tfSolver.log('\nRun three-field transient solver ...\n');
        film = tfSolver.film;
        drop = tfSolver.drop;
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
    tic
    
    % Time loop
    for tIdx = 2:length(film)                                              % Loop over time steps
        
        tfSolver.log('Time %5.2f [s]',film(tIdx).TIME)
        
        DT = film(tIdx).DT;                                                % [s] Current time step size
        RHOF = tfSolver.fluid(tIdx).RHOF;                                  % [kg/m^3] Satrurated liquid density

        % Update three-field property guesses from previous time step
        film(tIdx-1).copyFlowProperties(film(tIdx));
        drop(tIdx-1).copyFlowProperties(drop(tIdx));
        
        
        % Axial sweep
        for zIdx = 2:tfSolver.NZ
            
            Wold = film(tIdx-1).W(zIdx,:);                                 % [kg/s] Film mass flow rate at previosu time step
            Uold = film(tIdx-1).U(zIdx,:);                                 % [m/s] Film velocity at previous time step
            Wups = film(tIdx).W(zIdx-1,:);                                 % [kg/s] Film mass flow rate at previosu time step
            Uups = film(tIdx).U(zIdx-1,:);                                 % [m/s] Film velocity at previous time step
            
            % Inner (point) iterations
            for itr = 1:options.MAXITER
                
                % Save primary parameters from previous point iteration
                Witer = film(tIdx).W(zIdx,:);                              % [kg/s] Film mass flow rate
                Uiter = film(tIdx).U(zIdx,:);                              % [m/s] Film velocity
                
                % Film mass conservation
                Mtot = MTOT(film(tIdx),mix(tIdx),drop(tIdx),zIdx);                            % [kg/s/m^2] Mass exchange terms with film
                Wnew = Uiter.*(Wups+Wold./Uold.*DZ./DT+geom.PERIM.*Mtot.*DZ)./(Uiter+DZ./DT); % [kg/s] Update film mass flow rate
                film(tIdx).W(zIdx,:) = (1-options.RELAXWF).*Witer+options.RELAXWF.*Wnew;      % [kg/s] Apply relaxation
                
                if model.POSFILM
                    film(tIdx).W(zIdx,:) = max(film(tIdx).W(zIdx,:),0);                       % [kg/s] 
                end
                
                % Film momentum conservation
                switch model.MOMENTFILM
                    case 'ALGEBRAIC'
                    % Simple algebraic model
                        film(tIdx).U(zIdx,:) = film(tIdx).UALGEBR(mix(tIdx),zIdx);                    % [m/s]
                        
                    case 'EQUILIBRIUMS'
                    % Simple equilibrium model (Fwall+ Fvapor = 0)
                        film(tIdx).U(zIdx,:) = film(tIdx).UEQUILS(mix(tIdx),zIdx);                    % [m/s]
                        
                    case 'EQUILIBRIUM'
                    % Complete equilibrium model (Ftot = 0)
                        film(tIdx).U(zIdx,:) = film(tIdx).UEQUIL(mix(tIdx),drop(tIdx),zIdx);          % [m/s]
                        
                    case 'FULL'
                    % Full momentum conservation
                        %for i = 1:round(1/options.RELAXUF)
                        
                        thick = max(abs(film(tIdx).THICK(zIdx)),model.THINFILMTHICK);                 % [m] Film thickness
                        
                        if thick>model.THINFILMTHICK
                            Ftot = film(tIdx).FTOT(mix(tIdx),drop(tIdx),zIdx);                        % [N/m^2] Momentum exchange terms with film
                            Unew = (Uups.*Uiter+Uold.*DZ./DT+Ftot.*DZ./(RHOF.*thick))./(Uiter+DZ/DT); % [m/s] Update velocity
                            Unew = min(max(Unew,0),mix(tIdx).liquid.U(zIdx));                         % [m/s] Keep within realistic bounds to help convergence
                            film(tIdx).U(zIdx,:) = (1-options.RELAXUF).*Uiter+options.RELAXUF.*Unew;  % [m/s] Apply relaxation
                            %film(tIdx).U(zIdx,:) = mix(tIdx).AFDISTR(mix(tIdx).liquid.U(zIdx),film(tIdx).U(zIdx,:),zIdx);
                        else
                            film(tIdx).U(zIdx,:) = film(tIdx).UEQUIL(mix(tIdx),drop(tIdx),zIdx);      % [m/s] Complete equilibrium model for thin film
                        end
                        
                        %Uiter = film(tIdx).U(zIdx,:);
                        %end
                end
                
                % Drop mass conservation
                drop(tIdx).W(zIdx,:) = mix(tIdx).liquid.W(zIdx)-sum(film(tIdx).W(zIdx,:)); % [kg/s] Drop flowrate
                
                % Drop momentum conservation
                switch model.MOMENTDROP
                    case 'SLIP'
                        drop(tIdx).U(zIdx,:) = model.DROPSLIP.*mix(tIdx).vapor.U(zIdx); % [m/s] Drop velocity
                end
                
                % Check convergence
                dW = abs((film(tIdx).W(zIdx,:)-Witer));                    % [kg/s] Film mass flow rate error between inner iterations
                dU = abs((film(tIdx).U(zIdx,:)-Uiter));                    % [m/s]  Film velocity error between inner iterations
                if all([dW < options.ERRORWF, dU < options.ERRORUF])
                    break;
                    elseif itr == options.MAXITER
                    % set SOLVED flag to SOLVEDNOTCONVERGED
                        tfSolver.STATE = SolverState.SOLVEDNOTCONVERGED;
                end
                
            end
            
            % Iteration parameters
            film(tIdx).ITR.N(zIdx)  = itr;
            film(tIdx).ITR.DW(zIdx,1:nwall) = dW;
            film(tIdx).ITR.DU(zIdx,1:nwall) = dU;
            
        end
        
        maxN  = max(film(tIdx).ITR.N);
        maxDW = max(film(tIdx).ITR.DW,[],'all');
        maxDU = max(film(tIdx).ITR.DU,[],'all');
        
        % Temporal deviations in W and U
        timeDW = max(abs((film(tIdx).W - film(tIdx-1).W)),[],'all');
        timeDU = max(abs((film(tIdx).U - film(tIdx-1).U)),[],'all');
        tfSolver.log('\t(Max iter = %2d, Max errors W = %.7f [kg/s], U = %.4f [m/s])\r',maxN,maxDW,maxDU)

        
        if solveINIT
            % Finish steady state solver when SS convergence criterions are met
            if all([timeDW < options.SSCONVWF ,timeDU < options.SSCONVUF] )
    
                tfSolver.log('\t\tCONVERGED: Max errors W = %.7f [kg/s], U = %.4f [m/s])\r',timeDW,timeDU)
    
                % Replace filmInit and dropInit with subset up to this tIdx
                tfSolver.filmInit = tfSolver.filmInit(1:tIdx);
                tfSolver.dropInit = tfSolver.dropInit(1:tIdx);
                
                % Replace first transient time step flow data with this tIdx
                tfSolver.filmInit(end).copyFlowProperties(tfSolver.film(1));
                tfSolver.dropInit(end).copyFlowProperties(tfSolver.drop(1));
                
                break;
            
            % otherwise, update next timestep with current flow properties
            elseif tIdx < length(film)-1
                tfSolver.filmInit(tIdx).copyFlowProperties(tfSolver.filmInit(tIdx+1));
                tfSolver.dropInit(tIdx).copyFlowProperties(tfSolver.dropInit(tIdx+1));
            % otherwise, not converged
            else
                tfSolver.STATE = "INITIALSTEPNOTCONVERGED";
                tfSolver.log('\t\tFAILED TO CONVERGE: Max errors W = %.7f [kg/s], U = %.4f [m/s])\r',timeDW,timeDU)
            end
        end
    
    end
    
    
    tfSolver.log('\n---------------------- %s Three-field solver run completed ----------------------\n\n', solveMODE)
    
    % End timer
    toc
end

end