function solve(ffSolver)
%SOLVE Executes the four-field solver for steady-state and transient simulations.
%
% Runs the full solution process for the :class:`Solvers.FourField.FourFieldSolver`
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
    ffSolver
end

import Solvers.SolverState

% Enable diary
ffSolver.inputSet.session.log.diaryOn();

% Open log in persistent mode
ffSolver.inputSet.session.log.openLog('keepLogOpen', true);

if ffSolver.STATE ~= SolverState.UNSOLVED
    error('This solver needs to be reinitialized before solving.');
else
    ffSolver.log('\n\n------------------------------------------- Four-field solver run initiated --------------------------------------------\n')

    try
        % Solve init
        solver(true);

        % Continue solving if init converged
        if ffSolver.STATE == SolverState.INITIALSTEPCONVERGED
            solver(false);
        else
            if length(ffSolver.film) > 1
                ffSolver.log('\t\tSkipping transient solver ...\n');
            end
        end

    catch ME
        ffSolver.inputSet.session.log.closeLog();
        ffSolver.inputSet.session.log.diaryOff();
        rethrow(ME)
    end

    ffSolver.log('\n------------------------------------------- Four-field solver run completed --------------------------------------------\n\n')
end

ffSolver.inputSet.session.log.closeLog();
ffSolver.inputSet.session.log.diaryOff();
ffSolver.log('Output directory: %s\n',ffSolver.inputSet.session.directory);


function solver(solveINIT)
    % Internal solver routine for steady-state and transient modes
    % Handles time stepping, axial sweeps, and inner iterations
    % Applies relaxation and convergence checks
    % Updates mixture properties and logs progress

    nwall = ffSolver.inputSet.geometry.NWALL;

    % check if solving filmInit and dropInit
    if solveINIT
        ffSolver.log('\nSolve steady-state ...\n');
        film = ffSolver.filmInit;
        base = [film.base];
        wave = [film.wave];
        drop = ffSolver.dropInit;
        fluid = repmat(ffSolver.fluid(1),1,length(film));
        mix = copy(repmat(ffSolver.mixSolver.mixture(1),1,ffSolver.inputSet.options.SSMAXITER));
    else
        if length(ffSolver.film) < 2
            return
        end
        ffSolver.log('\nSolve transient ...\n');
        film = ffSolver.film;
        base = [film.base];
        wave = [film.wave];
        drop = ffSolver.drop;
        fluid = ffSolver.fluid;
        mix = ffSolver.mixSolver.mixture;
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
        if solveINIT
            RHOF = fluid.RHOF;                                             % [kg/m^3] Saturated liquid density
        else
            RHOF = fluid(tIdx).RHOF;                                       % [kg/m^3] Saturated liquid density
        end
        
        % Update four-field property guesses from previous time step
        base(tIdx-1).copyFlowProperties(base(tIdx));
        wave(tIdx-1).copyFlowProperties(wave(tIdx));
        drop(tIdx-1).copyFlowProperties(drop(tIdx));
        
        % Redistribute wave and base mass flow in pre-annular flow region based on updated field parameters
        eb = film(tIdx).distributeOAFW(film(tIdx).W(mix(tIdx).OAFIDX,:),mix(tIdx).OAFIDX);
        filmW = film(tIdx).W(1:mix(tIdx).OAFIDX,:);                        % [kg/s] Save total film flow rate
        base(tIdx).W(1:mix(tIdx).OAFIDX,:) = repmat(eb.*film(tIdx).W(mix(tIdx).OAFIDX,:),mix(tIdx).OAFIDX,1); % [kg/s] Set constant base film flow rate                         
        wave(tIdx).W(1:mix(tIdx).OAFIDX,:) = max(0,filmW-base(tIdx).W(1:mix(tIdx).OAFIDX,:));  % [kg/s] Adjust wave flow rate   
        
        % Axial sweep
        for zIdx = 2:ffSolver.NZ
            
            Wbold = base(tIdx-1).W(zIdx,:);                                % [kg/s] Base mass flow rate at previous time step
            Ubold = base(tIdx-1).U(zIdx,:);                                % [m/s] Base velocity at previous time step
            Wbups = base(tIdx).W(zIdx-1,:);                                % [kg/s] Base mass flow rate at previous node
            Ubups = base(tIdx).U(zIdx-1,:);                                % [m/s] Base velocity at previous node
    
            Wwold = wave(tIdx-1).W(zIdx,:);                                % [kg/s] Wave mass flow rate at previous time step
            Uwold = wave(tIdx-1).U(zIdx,:);                                % [m/s] Wave velocity at previous time step
            Fwold = wave(tIdx-1).FREQUENCY(zIdx,:);                        % [Hz] Wave frequency at previous time step
            Wwups = wave(tIdx).W(zIdx-1,:);                                % [kg/s] Wave mass flow rate at previous node
            Uwups = wave(tIdx).U(zIdx-1,:);                                % [m/s] Wave velocity at previous node
            Fwups = wave(tIdx).FREQUENCY(zIdx-1,:);                        % [Hz] Wave frequency at previous node
            
            Udold = drop(tIdx-1).U(zIdx);                                  % [m/s] Drop velocity at previous time step
            Udups = drop(tIdx).U(zIdx-1);                                  % [m/s] Drop velocity at previous node
            
            % Inner (point) iterations
            for itr = 1:options.MAXITER
                
                % Save primary parameters from previous point iteration
                Wbiter  = base(tIdx).W(zIdx,:);                            % [kg/s] Base mass flow rate
                WLbiter = base(tIdx).WL(zIdx);                             % [kg/s/m] Base mass flow rate per unit perimeter
                Ubiter  = base(tIdx).U(zIdx,:);                            % [m/s] Base velocity

                Wwiter  = wave(tIdx).W(zIdx,:);                            % [kg/s] Wave mass flow rate
                WLwiter = wave(tIdx).WL(zIdx);                             % [kg/s/m] Wave mass flow rate per unit perimeter
                Uwiter  = wave(tIdx).U(zIdx,:);                            % [m/s] Wave velocity
                Fwiter  = wave(tIdx).FREQUENCY(zIdx,:);                    % [Hz] Wave frequency
                
                Uditer  = drop(tIdx).U(zIdx);                              % [m/s] Drop velocity
                
                % Film mass conservation
                % Base film mass conservation
                Mtot_b = base(tIdx).MTOT(drop(tIdx),zIdx);                                              % [kg/s/m^2] Mass exchange terms with base
                Wbnew = Ubiter.*(Wbups+Wbold./Ubold.*DZ./DT+geom.PERIM.*Mtot_b.*DZ)./(Ubiter+DZ./DT);   % [kg/s] Update film mass flow rate
                base(tIdx).W(zIdx,:) = (1-options.RELAXWB).*Wbiter+options.RELAXWB.*Wbnew;              % [kg/s] Apply relaxation

                % Wave mass conservation
                Mtot_w = wave(tIdx).MTOT(drop(tIdx),zIdx);                                              % [kg/s/m^2] Mass exchange terms with wave
                Wwnew = Uwiter.*(Wwups+Wwold./Uwold.*DZ./DT+geom.PERIM.*Mtot_w.*DZ)./(Uwiter+DZ./DT);   % [kg/s] Update film mass flow rate
                wave(tIdx).W(zIdx,:) = (1-options.RELAXWW).*Wwiter+options.RELAXWW.*Wwnew;              % [kg/s] Apply relaxation

                % Enforce non-negative film (POSFILM)
                % TODO: requires further investigation
                if model.POSFILM
                    filmW = film(tIdx).W(zIdx,:);                             % [kg/s] Save film flow
                    wave(tIdx).W(zIdx,:) = max(wave(tIdx).W(zIdx,:),0);       % [kg/s] Wave flow is limited by 0
                    base(tIdx).W(zIdx,:) = max(filmW-wave(tIdx).W(zIdx,:),0); % [kg/s] Base flow compensate for wave mass source/sink when needed and is limited by 0
                    % base(tIdx).W(zIdx,:) = max(base(tIdx).W(zIdx,:),0);       % [kg/s] Base flow compensate for wave mass source/sink when needed and is limited by 0
                end

                % Drop mass conservation
                drop(tIdx).W(zIdx) = mix(tIdx).liquid.W(zIdx)-sum(film(tIdx).W(zIdx,:)); % [kg/s] Drop flowrate
                
                % Wave number conservation
                %TODO: consider using wave number density as option
                switch model.WAVEFREQUENCY
                    case InputEnums.WAVEFREQUENCY.EQUILIBRIUM
                    % Equilibrium model
                        wave(tIdx).FREQUENCY(zIdx,:) = wave(tIdx).EQFREQUENCY(zIdx); % [Hz]
                        
                    case InputEnums.WAVEFREQUENCY.RELAXATION
                    % Wave number conservation based on relaxation time approximation    
                        deltafreq = wave(tIdx).DELTAFREQ(zIdx);            % [Hz/m] Wave frequency exchange terms
                        Fwnew = Uwiter.*(Fwups+Fwold./Uwold.*DZ./DT+deltafreq.*DZ)./(Uwiter+DZ./DT);       % [Hz] Update wave frequency
                        wave(tIdx).FREQUENCY(zIdx,:) = (1-options.RELAXFW).*Fwiter+options.RELAXFW.*Fwnew; % [Hz] Apply relaxation
                end

                % Base momentum conservation
                switch model.MOMENTBASE
                    case InputEnums.MOMENTBASE.ALGEBRAIC
                    % Simple algebraic model
                        base(tIdx).U(zIdx,:) = base(tIdx).UALGEBR(zIdx);           % [m/s]
                        
                    case InputEnums.MOMENTBASE.EQUILIBRIUMS
                    % Simple equilibrium model (Fwall+ Fvapor = 0)
                        base(tIdx).U(zIdx,:) = base(tIdx).UEQUILS(zIdx);           % [m/s]
                        
                    case InputEnums.MOMENTBASE.EQUILIBRIUM
                    % Complete equilibrium model (Ftot = 0)
                        base(tIdx).U(zIdx,:) = base(tIdx).UEQUIL(drop(tIdx),zIdx); % [m/s]
                        
                    case {InputEnums.MOMENTBASE.FULL,InputEnums.MOMENTBASE.FULLNOP}
                    % Full film momentum conservation
                    % Switch to simplified momentum equation for thin base film to avoid division by 0
                        
                        %thick = max(abs(base(tIdx).THICK(zIdx)),model.THINFILMTHICK); % [m] Base film thickness
                        thick = abs(base(tIdx).THICK(zIdx));               % [m] Base film thickness
                        
                        if thick>model.THINFILMTHICK
                            Fbtot = base(tIdx).FTOT(drop(tIdx),zIdx);                                      % [N/m^2] Momentum exchange terms with base
                            Unew = (Ubups.*Ubiter+Ubold.*DZ./DT+Fbtot.*DZ./(RHOF.*thick))./(Ubiter+DZ/DT); % [m/s] Update velocity
                            Unew = min(max(Unew,0),mix(tIdx).liquid.U(zIdx));                              % [m/s] Keep within realistic bounds to help convergence
                            base(tIdx).U(zIdx,:) = (1-options.RELAXUB).*Ubiter+options.RELAXUB.*Unew;      % [m/s] Apply relaxation
                            base(tIdx).U(zIdx,:) = mix(tIdx).AFDISTR(mix(tIdx).liquid.U(zIdx),base(tIdx).U(zIdx,:),zIdx);
                        else
                            base(tIdx).U(zIdx,:) = base(tIdx).UEQUIL(drop(tIdx),zIdx);                     % [m/s] Complete equilibrium model for thin film
                            %base(tIdx).U(zIdx,:) = base(tIdx).UEQUILS(zIdx);                               % [m/s] Simplified equilibrium model for thin film
                            %base(tIdx).U(zIdx,:) = base(tIdx).UALGEBR(zIdx);                               % [m/s] Algebraic model for thin film
                        end
                end

                % Wave momentum conservation
                switch model.MOMENTWAVE
                    case InputEnums.MOMENTWAVE.ALGEBRAIC
                    % Simple algebraic model
                        wave(tIdx).U(zIdx,:) = wave(tIdx).UALGEBR(zIdx);           % [m/s]

                    case InputEnums.MOMENTWAVE.EQUILIBRIUM
                    % Complete equilibrium model (Ftot = 0)
                        wave(tIdx).U(zIdx,:) = wave(tIdx).UEQUIL(drop(tIdx),zIdx); % [m/s]

                    case InputEnums.MOMENTWAVE.FULL
                    % Full film momentum conservation
                    % Keep wave thickness above a small, negligible, value to avoid division by 0

                        thick = max(abs(wave(tIdx).THICK(zIdx)),model.THINWAVETHICK);                      % [m] Wave equivalent thickness
                        
                        %if thick>model.THINFILMTHICK
                            Fwtot = wave(tIdx).FTOT(drop(tIdx),zIdx);                                      % [N/m^2] Momentum exchange terms with wave
                            Unew = (Uwups.*Uwiter+Uwold.*DZ./DT+Fwtot.*DZ./(RHOF.*thick))./(Uwiter+DZ/DT); % [m/s] Update velocity
                            Unew = min(max(Unew,0),mix(tIdx).vapor.U(zIdx));                               % [m/s] Keep within realistic bounds to help convergence
                            wave(tIdx).U(zIdx,:) = (1-options.RELAXUW).*Uwiter+options.RELAXUW.*Unew;      % [m/s] Apply relaxation
                            wave(tIdx).U(zIdx,:) = mix(tIdx).AFDISTR(mix(tIdx).liquid.U(zIdx),wave(tIdx).U(zIdx,:),zIdx);
                        %else
                            %wave(tIdx).U(zIdx,:) = wave(tIdx).UEQUIL(drop(tIdx),zIdx);                     % [m/s] Complete equilibrium model for thin film
                            %wave(tIdx).U(zIdx,:) = wave(tIdx).UALGEBR(zIdx);                               % [m/s] Algebraic model for thin film
                        %end
                end

                % Drop momentum conservation
                switch model.MOMENTDROP
                    case InputEnums.MOMENTDROP.SLIP
                    % Velocity slip model
                        drop(tIdx).U(zIdx) = drop(tIdx).USLIP(zIdx);               % [m/s] Drop velocity
                    
                    case InputEnums.MOMENTDROP.ALGEBRAIC
                    % Model consistent with mixture model
                        drop(tIdx).U(zIdx) = drop(tIdx).UALGEBR(film(tIdx),zIdx);  % [m/s] Drop velocity
                        
                    case InputEnums.MOMENTDROP.EQUILIBRIUMS
                    % Simple equilibrium model (Fdrag + Fgrav + Fbuoy = 0)
                        drop(tIdx).U(zIdx) = drop(tIdx).UEQUIL(film(tIdx),zIdx,1); % [m/s] Drop velocity 
                        
                    case InputEnums.MOMENTDROP.EQUILIBRIUM
                    % Complete equilibrium model (Ftot = 0)
                        drop(tIdx).U(zIdx) = drop(tIdx).UEQUIL(film(tIdx),zIdx);   % [m/s] Drop velocity      
                        
                    case InputEnums.MOMENTDROP.FULL
                    % Full drop momentum conservation
                        Fdtot = drop(tIdx).FTOT(film(tIdx),zIdx);                                 % [N/m^3] Momentum exchange terms with drop
                        Udnew = (Udups.*Uditer+Udold.*DZ./DT+Fdtot.*DZ./RHOF)./(Uditer+DZ/DT);    % [m/s] Update velocity
                        drop(tIdx).U(zIdx) = (1-options.RELAXUD).*Uditer+options.RELAXUD.*Udnew;  % [m/s] Apply relaxation
                        drop(tIdx).U(zIdx) = mix(tIdx).AFDISTR(mix(tIdx).liquid.U(zIdx),drop(tIdx).U(zIdx),zIdx);
                end

                % Check convergence
                dWLb = abs((base(tIdx).WL(zIdx)-WLbiter));                 % [kg/s/m] Base mass flow rate error between inner iterations
                dUb  = abs((base(tIdx).U(zIdx,:)-Ubiter));                 % [m/s]    Base velocity error between inner iterations
                dWLw = abs((wave(tIdx).WL(zIdx)-WLwiter));                 % [kg/s/m] Wave mass flow rate error between inner iterations
                dUw  = abs((wave(tIdx).U(zIdx,:)-Uwiter));                 % [m/s]    Wave velocity error between inner iterations
                dFw  = abs((wave(tIdx).FREQUENCY(zIdx,:)-Fwiter));         % [Hz]     Wave frequency error between inner iterations
                dUd  = abs((drop(tIdx).U(zIdx)-Uditer));                   % [m/s]    Drop velocity error between inner iterations
                if all([dWLb < options.ERRORWF, dUb < options.ERRORUF, dWLw < options.ERRORWF, dUw < options.ERRORUF, dFw < options.ERRORFW, dUd < options.ERRORUD])
                    break;                                                 % Exit point iteration when converged
                
                elseif itr == options.MAXITER
                % set SOLVED flag to SOLVEDNOTCONVERGED
                    ffSolver.STATE = SolverState.SOLVEDNOTCONVERGED;
                    break;
                end
                
            end
            
            % Iteration parameters
            base(tIdx).ITR.N(zIdx)           = itr;
            base(tIdx).ITR.DWL(zIdx,1:nwall) = dWLb;
            base(tIdx).ITR.DU(zIdx,1:nwall)  = dUb;

            wave(tIdx).ITR.N(zIdx)           = itr;
            wave(tIdx).ITR.DWL(zIdx,1:nwall) = dWLw;
            wave(tIdx).ITR.DU(zIdx,1:nwall)  = dUw;
            wave(tIdx).ITR.DF(zIdx,1:nwall)  = dFw;

            drop(tIdx).ITR.N(zIdx)           = itr;
            drop(tIdx).ITR.DU(zIdx)          = dUd;
            
        end
        
        [maxNb,maxzIdxb] = max([base(tIdx).ITR.N]);
        maxDWLb = max(base(tIdx).ITR.DWL,[],'all');
        maxDUb  = max(base(tIdx).ITR.DU,[],'all');

        [maxNw,maxzIdxw] = max([wave(tIdx).ITR.N]);
        maxDWLw = max(wave(tIdx).ITR.DWL,[],'all');
        maxDUw  = max(wave(tIdx).ITR.DU,[],'all');
        maxDFw  = max(wave(tIdx).ITR.DF,[],'all');

        maxDUd = max(drop(tIdx).ITR.DU,[],'all');
        
        maxzIdxs = [maxzIdxb, maxzIdxw];
        [maxN, maxzIdx] = max([maxNb, maxNw]);
        maxzIdx = maxzIdxs(maxzIdx);
        ffSolver.log('\tmax point iter = %3d in node %3d, max errors: Wb = %.7f [kg/s/m], Ub = %.5f [m/s], Ww = %.7f [kg/s/m], Uw = %.5f [m/s], Fw = %.5f [Hz], Ud = %.5f [m/s]                    \r',maxN,maxzIdx,maxDWLb,maxDUb,maxDWLw,maxDUw,maxDFw,maxDUd)
        
        % Temporal deviations in W and U
        timeDWLb = max(abs((base(tIdx).WL - base(tIdx-1).WL)),[],'all');
        timeDUb  = max(abs((base(tIdx).U  - base(tIdx-1).U)),[],'all');
        timeDWLw = max(abs((wave(tIdx).WL - wave(tIdx-1).WL)),[],'all');
        timeDUw  = max(abs((wave(tIdx).U  - wave(tIdx-1).U)),[],'all');
        timeDFw  = max(abs((wave(tIdx).FREQUENCY  - wave(tIdx-1).FREQUENCY)),[],'all');
        timeDUd  = max(abs((drop(tIdx).U  - drop(tIdx-1).U)),[],'all');
        
        if solveINIT
            % Finish steady state solver when SS convergence criteria are met
            if all([timeDWLb < options.SSCONVWF , timeDUb < options.SSCONVUF,timeDWLw < options.SSCONVWF , timeDUw < options.SSCONVUF, timeDUd < options.SSCONVUD] )

                % Indicate init converged
                ffSolver.STATE = SolverState.INITIALSTEPCONVERGED;
    
                ffSolver.log('\n\t\tSTEADY-STATE CONVERGED            max errors: Wb = %.7f [kg/s/m], Ub = %.5f [m/s], Ww = %.7f [kg/s/m], Uw = %.5f [m/s], Fw = %.5f [Hz], Ud = %.5f [m/s]\r',timeDWLb,timeDUb,timeDWLw,timeDUw,timeDFw,timeDUd)
    
                % Replace filmInit and dropInit with subset up to this tIdx
                ffSolver.filmInit  = ffSolver.filmInit(1:tIdx);
                ffSolver.dropInit = ffSolver.dropInit(1:tIdx);
               
                % Replace first transient time step flow data with this tIdx
                ffSolver.filmInit(end).copyFlowProperties(ffSolver.film(1));
                ffSolver.dropInit(end).copyFlowProperties(ffSolver.drop(1));
                
                break;
            
            % otherwise, update next timestep with current flow properties
            elseif tIdx < length(film)

                ffSolver.filmInit(tIdx).copyFlowProperties(ffSolver.filmInit(tIdx+1));
                ffSolver.dropInit(tIdx).copyFlowProperties(ffSolver.dropInit(tIdx+1));
                
            % otherwise, not converged
            else
                ffSolver.STATE = SolverState.INITIALSTEPNOTCONVERGED;
                ffSolver.log('\n\t\tSTEADY-STATE FAILED TO CONVERGE   max errors: Wb = %.7f [kg/s/m], Ub = %.5f [m/s], Ww = %.7f [kg/s/m], Uw = %.5f [m/s], Fw = %.5f [Hz], Ud = %.5f [m/s]\r',timeDWLb,timeDUb,timeDWLw,timeDUw,timeDFw,timeDUd)
                ffSolver.log('\n\t\tIncreasing steady state iterations (options.SSMAXITER) may help.');
                
                % Replace first transient time step flow data with steady-state solver solution, regardless of convergence
                ffSolver.filmInit(end).copyFlowProperties(ffSolver.film(1));
                ffSolver.dropInit(end).copyFlowProperties(ffSolver.drop(1));
            end
        end
    
    end
    
    ffSolver.log('\n')
    
    % End timer
    ffSolver.log('Elapsed time: %0.2f sec\n', toc(startTime))
end

end