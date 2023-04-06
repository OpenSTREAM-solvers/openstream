function solve(mix, opts)
%SOLVE  
% 
arguments
    mix
    opts.verbose = true
end

if mix.SOLVED
    error('This solver needs to be reinitialized before solving.');
else
    fprintf('\nRun solver ...\n');
end

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
%     zIdx = 2:mix.NZ;
        
        % Inner (point) iterations
        for itr = 1:options.MAXITER

            % Save parameters from previous point iteration
            Witer = mix.W(zIdx,tIdx);                                       % [kg/s] Mixture mass flow rate
            Piter = mix.P(zIdx,tIdx);                                       % [Pa] Pressure
            Hiter = mix.H(zIdx,tIdx);                                       % [J/kg] Enthalpy
            
            % Update secondary parameters
            VEL   = mix.U([zIdx-1 zIdx],tIdx);                              % [m/s] Calculate velocity array for speed
            U     = VEL(2); Uups = VEL(1);                                  % [m/s] Mixture velocities at node k and k-1
            Uold  = mix.U(zIdx, tIdx-1);                                    % [m/s] Mixture velocity at previous time step
            RHO   = mix.RHO(zIdx, tIdx);                                    % [kg/m^3] Mixture density
            TAUW  = mix.TAUW(zIdx, tIdx);                                   % [Pa] Wall shear stress
            HFLUX = mix.HFLUX(zIdx,tIdx,:);                                 % [W/m^2] Wall heat flux
            
            % Mass conservation
            Wnew = (mix.W(zIdx-1,tIdx)+mix.W(zIdx,tIdx-1)/Uold*mix.DZ/mix.DT)/(1+mix.DZ/U/mix.DT);   % [kg/s] Update mixture mass flow rate
            mix.W(zIdx,tIdx) = (1-options.RELAXWM)*Witer+options.RELAXWM*Wnew;    % [kg/s] Apply relaxation
            
            % Momentum conservation
            dpGrav  = -model.G*RHO*mix.DZ;                                  % [Pa] Gravitational pressure drop
            dpWall  = -sum(geom.PERIM)*TAUW./geom.AREA.*mix.DZ;               % [Pa] Wall friction pressure drop
            dpAcc_z = -mix.W(zIdx,tIdx)./geom.AREA.*(U-Uups);                 % [Pa] Spatial acceleration pressure drop
            dpAcc_t = -mix.W(zIdx,tIdx)./geom.AREA.*(1-Uold/U).*mix.DZ./mix.DT; % [pa] Temporal acceleration pressure drop
            dpK     = -mix.DPK(zIdx,tIdx);                                  % [Pa] Local pressure drop
            Pnew    = mix.P(zIdx-1,tIdx)+dpGrav+dpWall+dpAcc_z+dpAcc_t+dpK; % [Pa] Update pressure
            mix.P(zIdx,tIdx) = (1-options.RELAXPM)*Piter+options.RELAXPM*Pnew; % [Pa] Apply relaxation

            % Energy conservation
            Hnew = (mix.H(zIdx-1,tIdx)+mix.DZ./mix.W(zIdx,tIdx).*sum(geom.PERIM.'.*reshape(HFLUX,length(zIdx),[]).',1)+ ...
                   mix.H(zIdx,tIdx-1)./U.*mix.DZ./mix.DT)/(1+mix.DZ./U./mix.DT); % [J/kg] Update mixture enthalpy
            mix.H(zIdx,tIdx) = (1-options.RELAXHM)*Hiter+options.RELAXHM*Hnew;    % [J/kg] Apply relaxation
            
            % Check convergence
            dW = abs((mix.W(zIdx,tIdx)-Witer));                             % [kg/s] Mass flow rate error between inner iterations
            dP = abs((mix.P(zIdx,tIdx)-Piter));                             % [Pa]   Pressure error between inner iterations
            dH = abs((mix.H(zIdx,tIdx)-Hiter));                             % [J/kg] Enthalpy error between inner iterations
            if all([dW < options.ERRORW, dP < options.ERRORP, dH < options.ERRORH])   
                break;
            end

        end
        
        % Save pressure drop components
        mix.DP.Grav(zIdx,tIdx)  = -dpGrav;                                  % [Pa] Gravitational pressure drop
        mix.DP.Wall(zIdx,tIdx)  = -dpWall;                                  % [Pa] Wall friction pressure drop
        mix.DP.Acc_z(zIdx,tIdx) = -dpAcc_z;                                 % [pa] Spatial acceleration pressure drop
        mix.DP.Acc_t(zIdx,tIdx) = -dpAcc_t;                                 % [Pa] Temporal acceleration pressure drop
        mix.DP.K(zIdx,tIdx)     = -dpK;                                     % [Pa] Local pressure drop
        mix.DP.Tot(zIdx,tIdx)   = -(mix.P(zIdx,tIdx)-mix.P(zIdx-1,tIdx));   % [Pa] Total pressure drop
        
        mix.ITR.N(zIdx,tIdx)  = itr;
        mix.ITR.DW(zIdx,tIdx) = dW;
        mix.ITR.DP(zIdx,tIdx) = dP;
        mix.ITR.DH(zIdx,tIdx) = dH;


    end
    
    fprintf('\t(Max iter = %d, Max errors W = %f [kg/s], %.2f [Pa], %.3f [J/kg])\r',max(mix.ITR.N(:,tIdx)),max(mix.ITR.DW(:,tIdx)),max(mix.ITR.DP(:,tIdx)),max(mix.ITR.DH(:,tIdx)))

end


fprintf('\n---------------------- Two-phase flow solver run completed ----------------------\n\n')

% End timer
toc

% set SOLVED flag to true
mix.SOLVED = true;

function fprintf(varargin)
    if opts.verbose, builtin('fprintf',varargin{:}); end
end

end