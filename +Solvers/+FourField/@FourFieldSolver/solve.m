function solve(ffSolver)
%SOLVE  
% 
arguments
    ffSolver
end

import Solvers.SolverState

% Enable diary
ffSolver.inputSet.session.log.diaryOn();

% Open log in presistent mode
ffSolver.inputSet.session.log.openLog('keepLogOpen', true);

if ffSolver.STATE ~= SolverState.UNSOLVED
    error('This solver needs to be reinitialized before solving.');
else
    ffSolver.log('\n\n------------------------------------------- Four-field solver run initiated -------------------------------------------\n')

    try
        % Solve init
        solver(true);
        
        % Continue solving if init converged
        if ffSolver.STATE == SolverState.INITIALSTEPCONVERGED
            solver(false);
        else
            ffSolver.log('\t\tSkipping transient solver ...\n');
        end
    catch ME
        ffSolver.inputSet.session.log.closeLog();
        ffSolver.inputSet.session.log.diaryOff();
        rethrow(ME)
    end
    
    ffSolver.log('\n------------------------------------------- Four-field solver run completed -------------------------------------------\n\n')
end

ffSolver.inputSet.session.log.closeLog();
ffSolver.inputSet.session.log.diaryOff();
ffSolver.log('Output directory: %s\n',ffSolver.inputSet.session.directory);


function solver(solveINIT)
    
    
    nwall = ffSolver.inputSet.geometry.NWALL;

    % check if solving filmInit and dropInit
    if solveINIT
        ffSolver.log('\nSolve steady-state ...\n');
        film = ffSolver.filmInit;
        base = [film.base];
        wave = [film.wave];
        drop = ffSolver.dropInit;
        fluid = ffSolver.fluidInit;
        mix = copy(repmat(ffSolver.mixSolver.mixture(1),1,ffSolver.inputSet.options.SSMAXITER));
        solveMODE = 'INITIAL';
    else
        ffSolver.log('\nSolve transient ...\n');
        film = ffSolver.film;
        base = [film.base];
        wave = [film.wave];
        drop = ffSolver.drop;
        fluid = ffSolver.fluid;
        mix = ffSolver.mixSolver.mixture;
        solveMODE = 'SPECIFIED';
    end
    
    % set SOLVED flag to SOLVECONVERGED
    ffSolver.STATE = SolverState.SOLVEDCONVERGED;
    
    % Shortcut to inputSet objects
    model   = ffSolver.inputSet.model;
    options = ffSolver.inputSet.options;
    geom    = ffSolver.inputSet.geometry;
    
    % Uniform mesh size
    DZ = ffSolver.DZ;    
    
    % Start timer
    startTime = tic();
    
    % Time loop
    for tIdx = 2:length(film)                                              % Loop over time steps
        
        ffSolver.log('Time %5.2f [s]',film(tIdx).TIME)
        
        DT = film(tIdx).DT;                                                % [s] Current time step size
        RHOF = fluid(tIdx).RHOF;                                  % [kg/m^3] Satrurated liquid density

        % Update four-field property guesses from previous time step
        base(tIdx-1).copyFlowProperties(base(tIdx));
        wave(tIdx-1).copyFlowProperties(wave(tIdx));
        drop(tIdx-1).copyFlowProperties(drop(tIdx));
        
        
        % Axial sweep
        for zIdx = 2:ffSolver.NZ
            
            Wbold = base(tIdx-1).W(zIdx,:);                                % [kg/s] Base mass flow rate at previous time step
            Ubold = base(tIdx-1).U(zIdx,:);                                % [m/s] Base velocity at previous time step
            Wbups = base(tIdx).W(zIdx-1,:);                                % [kg/s] Base mass flow rate at previous node
            Ubups = base(tIdx).U(zIdx-1,:);                                % [m/s] Base velocity at previous node
    
            Wwold = wave(tIdx-1).W(zIdx,:);                                % [kg/s] Wave mass flow rate at previous time step
            Uwold = wave(tIdx-1).U(zIdx,:);                                % [m/s] Wave velocity at previous time step
            Wwups = wave(tIdx).W(zIdx-1,:);                                % [kg/s] Wave mass flow rate at previous node
            Uwups = wave(tIdx).U(zIdx-1,:);                                % [m/s] Wave velocity at previous node

            Udold = drop(tIdx-1).U(zIdx);                                  % [m/s] Drop velocity at previous time step
            Udups = drop(tIdx).U(zIdx-1);                                  % [m/s] Drop velocity at previous node
            
            % Inner (point) iterations
            for itr = 1:options.MAXITER
                
                % Save primary parameters from previous point iteration
                Wbiter = base(tIdx).W(zIdx,:);                             % [kg/s] Base mass flow rate
                WLbiter = base(tIdx).WL(zIdx);                             % [kg/s/m] Base mass flow rate per unit perimeter
                Ubiter = base(tIdx).U(zIdx,:);                             % [m/s] Base velocity

                Wwiter = wave(tIdx).W(zIdx,:);                             % [kg/s] Wave mass flow rate
                WLwiter = wave(tIdx).WL(zIdx);                             % [kg/s/m] Wave mass flow rate per unit perimeter
                Uwiter = wave(tIdx).U(zIdx,:);                             % [m/s] Wave velocity
                
                Uditer = drop(tIdx).U(zIdx);                               % [m/s] Drop velocity
                
                % Base film mass conservation
                Mtot_b = base(tIdx).MTOT(mix(tIdx),drop(tIdx),zIdx);                            % [kg/s/m^2] Mass exchange terms with base
                Wbnew = Ubiter.*(Wbups+Wbold./Ubold.*DZ./DT+geom.PERIM.*Mtot_b.*DZ)./(Ubiter+DZ./DT); % [kg/s] Update film mass flow rate
                base(tIdx).W(zIdx,:) = (1-options.RELAXWB).*Wbiter+options.RELAXWB.*Wbnew;    % [kg/s] Apply relaxation

                % Wave mass conservation
                Mtot_w = wave(tIdx).MTOT(mix(tIdx),drop(tIdx),zIdx);                            % [kg/s/m^2] Mass exchange terms with wave
                Wwnew = Uwiter.*(Wwups+Wwold./Uwold.*DZ./DT+geom.PERIM.*Mtot_w.*DZ)./(Uwiter+DZ./DT); % [kg/s] Update film mass flow rate
                wave(tIdx).W(zIdx,:) = (1-options.RELAXWW).*Wwiter+options.RELAXWW.*Wwnew;    % [kg/s] Apply relaxation

                % DEBUG
                % fprintf('t:%d, z:%d, itr:%03d-> mtot:%0.8u, wbase:%0.8u, wdrop:%0.8u, ment: %0.8u\n', ...
                %     tIdx, zIdx, itr, ...
                %     Mtot, mean(base(tIdx).W(zIdx,:)), drop(tIdx).W(zIdx,:), base(tIdx).MENT(mix(tIdx),zIdx));

                if model.POSFILM
                    base(tIdx).W(zIdx,:) = max(base(tIdx).W(zIdx,:),0);                       % [kg/s] 
                    wave(tIdx).W(zIdx,:) = max(wave(tIdx).W(zIdx,:),0);                       % [kg/s] 
                end
                
                % Base momentum conservation
                switch model.MOMENTFILM
                    case InputEnums.MOMENTFILM.ALGEBRAIC
                    % Simple algebraic model
                        base(tIdx).U(zIdx,:) = base(tIdx).UALGEBR(mix(tIdx),zIdx);                    % [m/s]
                        
                    case InputEnums.MOMENTFILM.EQUILIBRIUMS
                    % Simple equilibrium model (Fwall+ Fvapor = 0)
                        base(tIdx).U(zIdx,:) = base(tIdx).UEQUILS(mix(tIdx),zIdx);                    % [m/s]
                        
                    case InputEnums.MOMENTFILM.EQUILIBRIUM
                    % Complete equilibrium model (Ftot = 0)
                        base(tIdx).U(zIdx,:) = base(tIdx).UEQUIL(mix(tIdx),drop(tIdx),zIdx);          % [m/s]
                        
                    case InputEnums.MOMENTFILM.FULL
                    % Full film momentum conservation
                        %for i = 1:round(1/options.RELAXUF)
                        
                        thick = max(abs(base(tIdx).THICK(zIdx)),model.THINFILMTHICK);                 % [m] Film thickness
                        
                        if thick>model.THINFILMTHICK
                            Fbtot = base(tIdx).FTOT(mix(tIdx),drop(tIdx),zIdx);                        % [N/m^2] Momentum exchange terms with base
                            Unew = (Ubups.*Ubiter+Ubold.*DZ./DT+Fbtot.*DZ./(RHOF.*thick))./(Ubiter+DZ/DT); % [m/s] Update velocity
                            Unew = min(max(Unew,0),mix(tIdx).liquid.U(zIdx));                         % [m/s] Keep within realistic bounds to help convergence
                            base(tIdx).U(zIdx,:) = (1-options.RELAXUB).*Ubiter+options.RELAXUB.*Unew;  % [m/s] Apply relaxation
                            base(tIdx).U(zIdx,:) = mix(tIdx).AFDISTR(mix(tIdx).liquid.U(zIdx),base(tIdx).U(zIdx,:),zIdx);
                        else
                            base(tIdx).U(zIdx,:) = base(tIdx).UEQUIL(mix(tIdx),drop(tIdx),zIdx);      % [m/s] Complete equilibrium model for thin film
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
                dWLb = abs((base(tIdx).WL(zIdx)-WLbiter));                 % [kg/s/m] Base mass flow rate error between inner iterations
                dUb  = abs((base(tIdx).U(zIdx,:)-Ubiter));                 % [m/s]    Base velocity error between inner iterations
                dUd  = abs((drop(tIdx).U(zIdx)-Uditer));                   % [m/s]    Drop velocity error between inner iterations
                if all([dWLb < options.ERRORWF, dUb < options.ERRORUF, dUd < options.ERRORUD])
                    break;                                                 % Exit point iteration when converged
                
                elseif itr == options.MAXITER
                % set SOLVED flag to SOLVEDNOTCONVERGED
                    ffSolver.STATE = SolverState.SOLVEDNOTCONVERGED;
                    break;
                end
                
            end
            
            % Iteration parameters
            base(tIdx).ITR.N(zIdx)  = itr;
            base(tIdx).ITR.DWL(zIdx,1:nwall) = dWLb;
            base(tIdx).ITR.DU(zIdx,1:nwall)  = dUb;
            drop(tIdx).ITR.N(zIdx)  = itr;
            drop(tIdx).ITR.DU(zIdx) = dUd;
            
        end
        
        [maxN,maxzIdx] = max(base(tIdx).ITR.N);
        maxDWLb = max(base(tIdx).ITR.DWL,[],'all');
        maxDUb = max(base(tIdx).ITR.DU,[],'all');
        maxDUd = max(drop(tIdx).ITR.DU,[],'all');
        ffSolver.log('\tmax point iter = %3d in node %3d, max errors: Wb = %.7f [kg/s/m], Ub = %.5f [m/s], Ud = %.5f [m/s]\r',maxN,maxzIdx,maxDWLb,maxDUb,maxDUd)
        
        % Temporal deviations in W and U
        timeDWLb = max(abs((base(tIdx).WL - base(tIdx-1).WL)),[],'all');
        timeDUb  = max(abs((base(tIdx).U - base(tIdx-1).U)),[],'all');
        timeDUd = max(abs((drop(tIdx).U - drop(tIdx-1).U)),[],'all');
        
        if solveINIT
            % Finish steady state solver when SS convergence criterions are met
            if all([timeDWLb < options.SSCONVWF , timeDUb < options.SSCONVUF, timeDUd < options.SSCONVUD] )

                % Indicate init converged
                ffSolver.STATE = SolverState.INITIALSTEPCONVERGED;
    
                ffSolver.log('\n\t\tSTEADY-STATE CONVERGED            max errors: Wb = %.7f [kg/s/m], Ub = %.5f [m/s], Ud = %.5f [m/s]\r',timeDWLb,timeDUb,timeDUd)
    
                % Replace filmInit and dropInit with subset up to this tIdx
                ffSolver.filmInit = ffSolver.filmInit(1:tIdx);
                ffSolver.dropInit = ffSolver.dropInit(1:tIdx);
                
                % Replace first transient time step flow data with this tIdx
                ffSolver.filmInit(end).copyFlowProperties(ffSolver.film(1));
                ffSolver.dropInit(end).copyFlowProperties(ffSolver.drop(1));
                
                break;
            
            % otherwise, update next timestep with current flow properties
            elseif tIdx < length(film)-1
                % unless non-convergence occurred
                if ffSolver.STATE == SolverState.SOLVEDNOTCONVERGED
                    ffSolver.log('\t\tSTEADY-STATE FAILED TO CONVERGE     max errors: Wb = %.7f [kg/s/m], Ub = %.5f [m/s]), Ud = %.5f [m/s]\r',timeDWLb,timeDUb,timeDUd)
                    break;
                end

                ffSolver.filmInit(tIdx).copyFlowProperties(ffSolver.filmInit(tIdx+1));
                ffSolver.dropInit(tIdx).copyFlowProperties(ffSolver.dropInit(tIdx+1));
            % otherwise, not converged
            else
                ffSolver.STATE = SolverState.INITIALSTEPNOTCONVERGED;
                ffSolver.log('\t\tSTEADY-STATE FAILED TO CONVERGE     max errors: Wb = %.7f [kg/s/m], Ub = %.5f [m/s]), Ud = %.5f [m/s]\r',timeDWLb,timeDUb,timeDUd)
                break;
            end
        end
    
    end
    
    %tfSolver.log('\n------------------------------ %9s Four-field solver run completed ------------------------------\n\n', solveMODE)
    ffSolver.log('\n')
    
    % End timer
    ffSolver.log('Elapsed time: %0.2f sec\n', toc(startTime))
end

end