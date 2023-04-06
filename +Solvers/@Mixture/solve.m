function solve(mix, opts)
%SOLVE  
%
arguments
    mix
    opts.verbose = true
end

fprintf('\nRun solver ...\n');

% Shortcut to inputSet objects
model = mix.inputSet.model;
options = mix.inputSet.options;
geom = mix.inputSet.geometry;

% Start timer
tic

% Time loop
for tIdx = 2:length(mix.TIME)                                                  % Loop over time steps
    
    fprintf('Time %5.2f [s]',mix.TIME(tIdx))
    
    % Axial sweep
    for zIdx = 2:mix.NZ                                                        % Loop over axial nodes
        
        % Inner (point) iterations
        for itr = 1:options.MAXITER

            % Save parameters from previous point iteration
            Witer = mix.W(tIdx,zIdx);                                       % [kg/s] Mixture mass flow rate
            Piter = mix.P(tIdx,zIdx);                                       % [Pa] Pressure
            Hiter = mix.H(tIdx,zIdx);                                       % [J/kg] Enthalpy
            
            % Update secondary parameters
            VEL   = mix.U(tIdx,[zIdx-1 zIdx]);                              % [m/s] Calculate velocity array for speed
            U     = VEL(2); Uups = VEL(1);                                  % [m/s] Mixture velocities at node k and k-1
            Uold  = mix.U(tIdx-1, zIdx);                                    % [m/s] Mixture velocity at previous time step
            RHO   = mix.RHO(tIdx, zIdx);                                    % [kg/m^3] Mixture density
            TAUW  = mix.TAUW(tIdx, zIdx);                                   % [Pa] Wall shear stress
            HFLUX = mix.HFLUX(tIdx,zIdx,:);                                 % [W/m^2] Wall heat flux
            
            % Mass conservation
            Wnew = (mix.W(tIdx,zIdx-1)+mix.W(tIdx-1,zIdx)/Uold*mix.DZ/mix.DT)/(1+mix.DZ/U/mix.DT);   % [kg/s] Update mixture mass flow rate
            mix.W(tIdx,zIdx) = (1-options.RELAXWM)*Witer+options.RELAXWM*Wnew;    % [kg/s] Apply relaxation
            
            % Momentum conservation
            dpGrav  = -model.G*RHO*mix.DZ;                                  % [Pa] Gravitational pressure drop
            dpWall  = -sum(geom.PERIM)*TAUW/geom.AREA*mix.DZ;               % [Pa] Wall friction pressure drop
            dpAcc_z = -mix.W(tIdx,zIdx)/geom.AREA*(U-Uups);                 % [Pa] Spatial acceleration pressure drop
            dpAcc_t = -mix.W(tIdx,zIdx)/geom.AREA*(1-Uold/U)*mix.DZ/mix.DT; % [pa] Temporal acceleration pressure drop
            dpK     = -mix.DPK(tIdx,zIdx);                                  % [Pa] Local pressure drop
            Pnew    = mix.P(tIdx,zIdx-1)+dpGrav+dpWall+dpAcc_z+dpAcc_t+dpK; % [Pa] Update pressure
            mix.P(tIdx,zIdx) = (1-options.RELAXPM)*Piter+options.RELAXPM*Pnew; % [Pa] Apply relaxation

            % Energy conservation
            Hnew = (mix.H(tIdx,zIdx-1)+mix.DZ/mix.W(tIdx,zIdx)*sum(geom.PERIM.*HFLUX,'all')+ ...
                   mix.H(tIdx-1,zIdx)/U*mix.DZ/mix.DT)/(1+mix.DZ/U/mix.DT); % [J/kg] Update mixture enthalpy
            mix.H(tIdx,zIdx) = (1-options.RELAXHM)*Hiter+options.RELAXHM*Hnew;    % [J/kg] Apply relaxation
            
            % Check convergence
            dW = abs((mix.W(tIdx,zIdx)-Witer));                             % [kg/s] Mass flow rate error between inner iterations
            dP = abs((mix.P(tIdx,zIdx)-Piter));                             % [Pa]   Pressure error between inner iterations
            dH = abs((mix.H(tIdx,zIdx)-Hiter));                             % [J/kg] Enthalpy error between inner iterations
            if all([dW < options.ERRORW, dP < options.ERRORP, dH < options.ERRORH])   
                break;
            end

        end
        
        % Save pressure drop components
        mix.DP.Grav(tIdx,zIdx)  = -dpGrav;                                  % [Pa] Gravitational pressure drop
        mix.DP.Wall(tIdx,zIdx)  = -dpWall;                                  % [Pa] Wall friction pressure drop
        mix.DP.Acc_z(tIdx,zIdx) = -dpAcc_z;                                 % [pa] Spatial acceleration pressure drop
        mix.DP.Acc_t(tIdx,zIdx) = -dpAcc_t;                                 % [Pa] Temporal acceleration pressure drop
        mix.DP.K(tIdx,zIdx)     = -dpK;                                     % [Pa] Local pressure drop
        mix.DP.Tot(tIdx,zIdx)   = -(mix.P(tIdx,zIdx)-mix.P(tIdx,zIdx-1));   % [Pa] Total pressure drop
        
        mix.ITR.N(tIdx,zIdx)  = itr;
        mix.ITR.DW(tIdx,zIdx) = dW;
        mix.ITR.DP(tIdx,zIdx) = dP;
        mix.ITR.DH(tIdx,zIdx) = dH;


    end
    
    fprintf('\t(Max iter = %d, Max errors W = %f [kg/s], %.2f [Pa], %.3f [J/kg])\r',max(mix.ITR.N(tIdx,:)),max(mix.ITR.DW(tIdx,:)),max(mix.ITR.DP(tIdx,:)),max(mix.ITR.DH(tIdx,:)))

end


fprintf('\n---------------------- Two-phase flow solver run completed ----------------------\n\n')

% End timer
toc

function fprintf(varargin)
    if opts.verbose, builtin('fprintf',varargin{:}); end
end

end