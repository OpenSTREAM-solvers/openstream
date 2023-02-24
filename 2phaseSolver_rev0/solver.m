%close all;
clear variables;

addpath(genpath('scripts'));

g = 9.81;                                                                  % [m/s^2] Gravitational constant

fprintf('\n---------------------- Two-phase flow solver run initiated ----------------------\n')

geomf   = 'inputs/geom.inp';
modelf  = 'inputs/models.inp';
optionf = 'inputs/options.inp';

bcf      = 'inputs/bc_test.inp';
geomID   = 'TEST';
modelID  = 'WATERS';
optionID = 'DEFAULT';

%bcf      = 'inputs/bc_mfval.inp';
%geomID   = 'MFVAL';
%modelID  = 'MFVALS';
%optionID = 'STEADY';

tic

%% Initialize
geom    = geometry(geomf,geomID);
model   = models(modelf,modelID);
option  = options(optionf,optionID);
bc      = boundaryConditions(bcf);

N = model.NNODES+1;                                                        % Total number of axial nodes (add one for inlet conditions)
DT = option.TSTEP;                                                         % [s] Time interval
TIME = bc(1).TIME:DT:bc(end).TIME;                                         % [s] Computational time array

% Interpolate scalar boundary conditions on computational time
param = {'TIME','PRESSURE','HIN','MFLOW','POWER'};
for k=1:length(param)
    bcond.(param{k}) = interp1([bc.TIME],[bc.(param{k})],TIME,option.TIMEINTERP);
end

% Generate input wall heat flux distribution(s) on computational time and mesh
DZ = geom.LENGTH/model.NNODES;                                             % [m] Uniform node length
bcond.Z = (0:DZ:geom.LENGTH)';                                             % [m] Node elevations
WPOWERZ = arrayfun(@(x) interp1(cumsum(x.WMESH)',reshape(x.WPOWER,geom.NWALL,[])',bcond.Z,option.AXIALINTERP,'extrap'),bc,'uni',0);        % [-] Interpolation on computational mesh
WPOWERT = arrayfun(@(n) interp1([bc.TIME]',cell2mat(cellfun(@(x) x(:,n),WPOWERZ,'uni',0))',TIME,option.TIMEINTERP)',1:geom.NWALL,'uni',0); % [-] Interpolation on computational time
bcond.WPOWER = arrayfun(@(n) cell2mat(cellfun(@(x) x(:,n),WPOWERT,'uni',0)),1:length(TIME),'uni',0);                     % [-] Rearrange by time step
bcond.HFLUX = cellfun(@(x,y) x./sum(repmat(geom.PERIM.*DZ,N,1).*y,'all').*y,num2cell(bcond.POWER),bcond.WPOWER,'uni',0); % [W/m^2] Corresponding heat flux distributions

% Initialize properties and mixture object arrays
prop = fluidProperties(bcond.PRESSURE,model);
mix  = mixture(bcond);
liq  = liquid(mix);
vap  = vapor(mix);


%% Solver
fprintf('\nRun solver ...\n')

% Time loop
for i = 2:length(TIME)                                                     % Loop over time steps
    
    fprintf('Time %5.2f [s]',TIME(i))
    
    % Axial sweep
    for k = 2:N                                                            % Loop over axial nodes
        
        % Inner (point) iterations
        for itr = 1:option.MAXITER
            
            % Save parameters from previous point iteration
            Witer = mix(i).W(k);                                           % [kg/s] Mixture mass flow rate
            Piter = mix(i).P(k);                                           % [Pa] Pressure
            Hiter = mix(i).H(k);                                           % [J/kg] Enthalpy
            
            % Update secondary parameters
            VEL   = mix(i).U(prop(i),model,geom,[k-1 k]);                  % [m/s] Calculate velocity array for speed
            U     = VEL(2); Uups = VEL(1);                                 % [m/s] Mixture velocities at node k and k-1
            Uold  = mix(i-1).U(prop(i),model,geom,k);                      % [m/s] Mixture velocity at previous time step
            RHO   = mix(i).RHO(prop(i),model,geom,k);                      % [kg/m^3] Mixture density
            TAUW  = mix(i).TAUW(prop(i),model,geom,k);                     % [Pa] Wall shear stress
            HFLUX = mix(i).HFLUX(k,:);                                     % [W/m^2] Wall heat flux
            
            % Mass conservation
            Wnew = (mix(i).W(k-1)+mix(i-1).W(k)/Uold*DZ/DT)/(1+DZ/U/DT);   % [kg/s] Update mixture mass flow rate
            mix(i).W(k) = (1-option.RELAXWM)*Witer+option.RELAXWM*Wnew;    % [kg/s] Apply relaxation
            
            % Momentum conservation
            dpGrav  = -g*RHO*DZ;                                           % [Pa] Gravitational pressure drop
            dpWall  = -sum(geom.PERIM)*TAUW/geom.AREA*DZ;                  % [Pa] Wall friction pressure drop
            dpAcc_z = -mix(i).W(k)/geom.AREA*(U-Uups);                     % [Pa] Spatial acceleration pressure drop
            dpAcc_t = -mix(i).W(k)/geom.AREA*(1-Uold/U)*DZ/DT;             % [pa] Temporal acceleration pressure drop
            dpK     = -mix(i).DPK(prop(i),model,geom,k);                   % [Pa] Local pressure drop
            Pnew    = mix(i).P(k-1)+dpGrav+dpWall+dpAcc_z+dpAcc_t+dpK;     % [Pa] Update pressure
            mix(i).P(k) = (1-option.RELAXPM)*Piter+option.RELAXPM*Pnew;    % [Pa] Apply relaxation
            
            % Energy conservation
            Hnew = (mix(i).H(k-1)+DZ/mix(i).W(k)*sum(geom.PERIM.*HFLUX)+ ...
                   mix(i-1).H(k)/U*DZ/DT)/(1+DZ/U/DT);                     % [J/kg] Update mixture enthalpy
            mix(i).H(k) = (1-option.RELAXHM)*Hiter+option.RELAXHM*Hnew;    % [J/kg] Apply relaxation
            
            % Check convergence
            dW = abs((mix(i).W(k)-Witer));                                 % [kg/s] Mass flow rate error between inner iterations
            dP = abs((mix(i).P(k)-Piter));                                 % [Pa]   Pressure error between inner iterations
            dH = abs((mix(i).H(k)-Hiter));                                 % [J/kg] Enthalpy error between inner iterations
            if all([dW < option.ERRORW, dP < option.ERRORP, dH < option.ERRORH])   
                break;
            end
            
        end
        
        % Save pressure drop components
        mix(i).DP.Grav(k)  = -dpGrav;                                      % [Pa] Gravitational pressure drop
        mix(i).DP.Wall(k)  = -dpWall;                                      % [Pa] Wall friction pressure drop
        mix(i).DP.Acc_z(k) = -dpAcc_z;                                     % [pa] Spatial acceleration pressure drop
        mix(i).DP.Acc_t(k) = -dpAcc_t;                                     % [Pa] Temporal acceleration pressure drop
        mix(i).DP.K(k)     = -dpK;                                         % [Pa] Local pressure drop
        mix(i).DP.Tot(k)   = -(mix(i).P(k)-mix(i).P(k-1));                 % [Pa] Total pressure drop
        
        mix(i).ITR.N(k)  = itr;
        mix(i).ITR.DW(k) = dW;
        mix(i).ITR.DP(k) = dP;
        mix(i).ITR.DH(k) = dH;
    end
    
    fprintf('   (Max iter = %d, Max errors W = %f [kg/s], %.2f [Pa], %.3f [J/kg])\r',max(mix(i).ITR.N),max(mix(i).ITR.DW),max(mix(i).ITR.DP),max(mix(i).ITR.DH))
    
end

fprintf('\n---------------------- Two-phase flow solver run completed ----------------------\n\n')


toc

