classdef Mixture < Solvers.AbstractField
    %MIXTURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=?Solvers.AbstractSolver)
        
        % Solver properties
        NZ                                                                 = 0                    % [-] Number of axial steps
        NTIME                                                              = 0                    % [-] Number of time steps
        TIME                                                               = 0                    % [s] Time series
        DT                                                                 = 0                    % [s] Time step size
        TIDX                                                               = 1                    % [-] Time step index
        Z                                                                  = 1.                   % [m] Elevation
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % [W/m^2] Wall heat flux
        
        % Flow properties
        W            (:,1) double  {mustBeNumeric}                         = 1.                   % [kg/s] Mass flow rate
        P            (:,1) double  {mustBeNumeric}                         = 7E6                  % [Pa] Pressure
        H            (:,1) double  {mustBeNumeric}                         = 1E6                  % [J/kg] Enthalpy
        DP           (1,1) struct                                                                 % [-] Detailed pressure drops

        % Iteration properties
        ITR

        % Phases
        liquid
        vapor
    end

    properties (SetAccess=?Solvers.AbstractSolver, GetAccess={?Solvers.AbstractPhase,?Solvers.AbstractSolver})
        
        DZ           (1,1) double  {mustBeNumeric}                         = 0                    % [m] Axial step size
        inputSet                   {isa(inputSet,'Inputs.InputSet')}
        fluid                      {isa(fluid,'Inputs.FluidProperties')}
        solver
        mixFull
    end

    properties (Access=private)
        mflux        (:,1) double  {mustBeNumeric}                         = 1                  % [kg/m^2-s] Mass flux
        xeq          (:,1) double  {mustBeNumeric}                         = 1                  % [-] Equilibrium quality
        x            (:,1) double  {mustBeNumeric}                         = 1                  % [-] Vapor quality
        oafidx_const       double  {mustBeNumeric}                         = []                 % [-] Solved index for onset of annular flow
        sigm_const   (:,1) double  {mustBeNumeric}                         = []                 % [-] Solved sigmoid fnc value
    end       
    
    methods
        function mix = Mixture(inputSet, fluid)
            %MIXTURE Creates a Mixture, mix
            %   Detailed explanation goes here

            if nargin > 0
                % Store inputSet as object property
                mix.inputSet = inputSet;
                mix.fluid  = fluid;
            end

        end
        
        function set.W(mix, val)
        %SET.W Setter for W, mass flow rate [kg/s]
        %  mix.mflux is calculated upon setting mix.W

            % Set mix.W value
            mix.W = val;

            % Calculate mix.mflux
            mix.MFLUX_CALC();

        end
        
        function set.H(mix, val)
        %SET.H Setter for H, enthalpy [J/kg]
        %  mix.x and mix.xeq are calculated upon setting mix.H
            
            % Set mix.H value
            mix.H = val;

            % Calculate mix.x (mix.x calls mix.xeq internally)
            mix.X_CALC();
    
        end
        
        function mflux = MFLUX(mix, zIdx)
        %MFLUX Mass flux [kg/m^2-s]
        %
            if nargin < 2, mflux = mix.mflux; 
            else, mflux = mix.mflux(zIdx); end
        end

        function xeq = XEQ(mix, zIdx)
        %XEQ Equilibrium quality [-]
        %   This function only retrieves the mix.xeq values pre-calculated
        %   when mix.H is set. This is to eliminate the redundant
        %   calculation as a result of requent function calls. The values
        %   are calculated via mix.XEQ_CALC()
        %
            if nargin < 2, xeq = mix.xeq; 
            else, xeq = mix.xeq(zIdx); end

        end

        function x = X(mix, zIdx)
        %X Vapor quality [-]
        %   This function only retrieves the mix.x values pre-calculated
        %   when mix.H is set. This is to eliminate the redundant
        %   calculation as a result of requent function calls. The values
        %   are calculated via mix.X_CALC()
        %
            if nargin < 2
                x = mix.x; 
            else
                x = mix.x(zIdx); 
            end
        end

        function vf =VF(mix, zIdx)
        %VF Void fraction [-]
        %   
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            geom = mix.inputSet.geometry;
            fluidProp = mix.fluid;

            switch model.VOID
                case InputEnums.VOID.HOMOGENEOUS
                    % [-] Homogeneous void model
                    if nargin < 2, vf = vfslip(mix.X(),1); 
                    else,          vf = vfslip(mix.X(zIdx),1); 
                    end
                    
                case InputEnums.VOID.SLIP
                    % [-] Slip void model
                    if nargin < 2, vf = vfslip(mix.X(),model.SLIP); 
                    else,          vf = vfslip(mix.X(zIdx),model.SLIP); 
                    end

                case InputEnums.VOID.BESTION
                    % [-] Bestion drift flux model
                    C0 = 1.;                                               % [-] Distribution parameter
                    ugj = 0.188.*sqrt(model.G.*geom.HDIAM.*(fluidProp.RHOF-fluidProp.RHOG)./fluidProp.RHOG); % [m/s] Drift velocity
                    vf = vfdrift(C0,ugj);            
            end
            
            
            function vf = vfslip(x,S)
            %VFSLIP Void fraction based on slip model
                vf = x.*fluidProp.RHOF./(x.*fluidProp.RHOF+S.*(1-x).*fluidProp.RHOG);
            end
            
            function vf = vfdrift(C0,ugj)
            %VFDRIFT Void fraction based on drift flux model
            % C0    [-]     Distribution parameter
            % ugj   [m/s]   Drift velocity
                if nargin < 2, vf  = mix.JG./(C0.*(mix.JG+mix.JL)+ugj);
                else,          vf  = mix.JG(zIdx)./(C0.*(mix.JG(zIdx)+mix.JL(zIdx))+ugj);
                end
            end
            
        end

        function rho = RHO(mix, zIdx)
        %RHO Density [kg/m^3]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            vf = mix.VF(zIdx);
            rho = vf.*mix.fluid.RHOV(mix.H(zIdx))+ ...
                    (1-vf).*mix.fluid.RHOL(mix.H(zIdx));
        end

        function mu = MU(mix, zIdx)
        %MU Dynamic viscosity [Pa-s]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            mu = mix.X(zIdx).*mix.fluid.MUV(mix.H(zIdx)) + ...
                    (1-mix.X(zIdx)).*mix.fluid.MUL(mix.H(zIdx));
        end

        function u = U(mix, zIdx)
        %U Velocity [m/s]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            u = mix.W(zIdx)./mix.RHO(zIdx)./mix.inputSet.geometry.AREA; 
        end

        function jl = JL(mix, zIdx)
        %JL Superfacial liquid velocity [m/s]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            jl = (1-mix.X(zIdx)).*mix.MFLUX(zIdx)./mix.fluid.RHOL(mix.H(zIdx));
        end

        function jg = JG(mix, zIdx)
        %JG Superfacial vapor velocity [m/s]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            jg = mix.X(zIdx).*mix.MFLUX(zIdx)./mix.fluid.RHOV(mix.H(zIdx));
        end

        function re = RE(mix, zIdx)
        %RE Reynolds number [-]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            re = 4.*mix.W(zIdx)./mix.MU(zIdx)./sum(mix.inputSet.geometry.PERIM);
        end

        function rel = REL(mix, zIdx)
        %REL Liquid-equivalent Reynolds number [-]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            rel = 4.*mix.W(zIdx)./mix.MUL(zIdx)./sum(mix.inputSet.geometry.PERIM);
        end

        function fw = FW(mix, zIdx)
        %FW Wall friction factor [-]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            fw = model.FRICTION(1).*mix.RE(zIdx).^model.FRICTION(2)+model.FRICTION(3);
        end

        function tauw = TAUW(mix, zIdx)
        %TAUW wall shear stress [Pa]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            tauw = 0.5.*(mix.FW(zIdx)./4)./mix.RHO(zIdx).*(mix.W(zIdx)./mix.inputSet.geometry.AREA).^2;
        end

        function kloss = KLOSS(mix, zIdx)
        %KLOSS Local pressure loss coefficient [-]
        % TODO: NEED TO BE VERIFIED
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;

            kloss = zeros(length(mix.Z),1);                                 % [-] Initialize local loss coefficient array to 0
            [~,ind]=min(abs(mix.Z-model.KLOC));                             % Find local loss elevation indexes (closest node)
            kloss(ind)=model.KLOSS;                                         % [-] Apply loss
            kloss = kloss(zIdx).';                                          % [-] Restrict to selected nodes
            
        end
        
        function dpGrav = DPGRAV(mix, zIdx)
        %DPK Gravitational pressure loss [Pa]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            dpGrav  = -mix.inputSet.model.G*cos(mix.inputSet.model.ANGLE*pi/180)*mix.RHO(zIdx)*mix.DZ;
        end

        function dpWall = DPWALL(mix, zIdx)
        %DPWALL Wall friction pressure drop [Pa]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            dpWall  = -sum(mix.inputSet.geometry.PERIM)*mix.TAUW(zIdx)./mix.inputSet.geometry.AREA.*mix.DZ;                
        end

        function dpAcc_z = DPACCZ(mix, zIdx)
        %DPACCZ Spatial acceleration pressure drop [Pa]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            VEL   = mix.U([zIdx-1 zIdx]);                                     % [m/s] Calculate velocity array
            U     = VEL(2); 
            Uups  = VEL(1);

            dpAcc_z = -mix.W(zIdx)./mix.inputSet.geometry.AREA.*(U-Uups);
        end

        function dpAcc_t = DPACCT(mix, Uold, zIdx)
        %DPACCT Temporal acceleration pressure drop [Pa]
        %
            if nargin < 3, zIdx = (1:mix(1).NZ).'; end
            
            VEL   = mix.U([zIdx-1 zIdx]);                                     % [m/s] Calculate velocity array
            U     = VEL(2);

            dpAcc_t = -mix.W(zIdx)./mix.inputSet.geometry.AREA.*(1-Uold/U).*mix.DZ./mix.DT;
        end

        function dpk = DPK(mix, zIdx)
        %DPK Local pressure loss [Pa]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            dpk = 0.5.*mix.KLOSS(zIdx)./mix.RHO(zIdx).*(mix.W(zIdx)./mix.inputSet.geometry.AREA).^2;
        end

        function dptot = DPTOT(mix, Uold, zIdx)
        %DPTOT Total pressure loss [Pa]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            dptot = mix.DPGRAV(zIdx) + mix.DPWALL(zIdx) + mix.DPACCZ(zIdx) + mix.DPACCT(Uold, zIdx) + mix.DPK(zIdx);
        end

        function dpparts = DPPARTS(mix, Uold, zIdx)
        %DPPARTS Pressure loss components[Pa]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            dpparts.GRAV = mix.DPGRAV(zIdx);
            dpparts.WALL = mix.DPWALL(zIdx);
            dpparts.ACCZ = mix.DPACCZ(zIdx);
            dpparts.ACCT = mix.DPACCT(Uold, zIdx);
            dpparts.K    = mix.DPK(zIdx);
            dpparts.TOT  = dpparts.GRAV + dpparts.WALL + dpparts.ACCZ + dpparts.ACCT + dpparts.K;
            
        end

        function t = T(mix, zIdx)
        %T Temperature [K]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            t = mix.fluid.T(mix.H(zIdx));
        end      
        
        function oafIdx = OAFIDX(mix)
            %OAFIDX Onset of annular flow node
            %
            
            % See if a full mixture is provided
            if ~isempty(mix.mixFull)
                % Use the mixFull version
                oafIdx = mix.mixFull.OAFIDX();
            
                % If oafIdx > mix.NZ
                %   return NZ
                % TODO: this needs to be verfied to work well in obs.
                if oafIdx > mix.NZ
                    oafIdx = mix.NZ;
                end

            % Otherwise, calculate it for this mixture
            else
                % Use saved value if it has been calculated already
                if ~isempty(mix.oafidx_const)
                    oafIdx = mix.oafidx_const;
                    return
                end
                
                model = mix.inputSet.model;
                HDIAM  = mix.inputSet.geometry.HDIAM;
                MFLUX  = mix.MFLUX;
                
                % Densities
                RHOF = mix.fluid.RHOF;
                RHOG = mix.fluid.RHOG;
                DELTARHO = RHOF-RHOG;
                
                switch model.OAF
                    case InputEnums.OAF.WALLIS
                        % Wallis model
                        xoaf = (0.6+0.4.*sqrt(model.G*HDIAM*(DELTARHO)*RHOF)./MFLUX)./(0.6+sqrt(RHOF/RHOG)); % [-] Quality at onset of annular flow
                    case InputEnums.OAF.WALLIS_SIMP
                        % Simplified Wallis model
                        xoaf = sqrt(model.G*HDIAM*(DELTARHO)*RHOG)./MFLUX;
                end
                oafIdx = find(mix.X>=xoaf, 1, 'first');                        % Find node corresponding to the onset of annular flow
                if isempty(oafIdx), oafIdx = mix.NZ; end                       % Most donstream node (NZ) when annular flow region is not found
    
                % Save value
                mix.oafidx_const = oafIdx;
            end
        end
        
        function oafz = OAFZ(mix)
        %OAFZ Onset of annular flow elevation
        %
            % See if a full mixture is provided
            if ~isempty(mix.mixFull)
                % Use the mixFull version
                oafz = mix.mixFull.OAFZ();

            % Otherwise, calculate it for this mixture
            else
                oafz = mix.Z(mix.OAFIDX);                                   % [m] Elevation at onset of annular flow
            end

        end
        
        function oafwl = OAFWL(mix)
        %OAFWL Liquid mass flow rate at onset of annular flow
        %
            % See if a full mixture is provided
            if ~isempty(mix.mixFull)
                % Use the mixFull version
                oafwl = mix.mixFull.OAFWL();

            % Otherwise, calculate it for this mixture
            else
                oafwl = mix.liquid.W(mix.OAFIDX);                           % [kg/s] Mixture liquid mass flow rate
            end
        end
        
        function afFnc = AFFNC(mix, zIdx)
        %AFFNC Annular flow function
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            % See if a full mixture is provided
            if ~isempty(mix.mixFull)
                
                % offset zIdx
                zIdx = zIdx + mix.solver.zIdx_offset;

                % Use the mixFull version
                afFnc = mix.mixFull.AFFNC(zIdx);

            % Otherwise, calculate it for this mixture
            else

                model = mix.inputSet.model;
                geom  = mix.inputSet.geometry;
    
                p = model.OAFTRANSITION;                                       % Sigmoid function parameters 
                p = p.*(model.NNODES/geom.LENGTH);                             % ... in node length
                afFnc = mix.sigm(zIdx,[p(1), mix.OAFIDX()+p(2)]);
            end
        end
        
        function afDistr = AFDISTR(mix,param1,param2,zIdx)
        %AFDISTR Annular flow distribution function
        %
            if nargin < 4, zIdx = (1:mix(1).NZ).'; end

            % See if a full mixture is provided
            if ~isempty(mix.mixFull)
                
                % offset zIdx
                zIdx = zIdx + mix.solver.zIdx_offset -1;

                % Use the mixFull version
                afDistr = mix.mixFull.AFDISTR(param1,param2,zIdx);

            % Otherwise, calculate it for this mixture
            else
                affnc = mix.AFFNC(zIdx);
                afDistr = (1-affnc).*param1 + affnc.*param2;
            end
        end
        
        function out = struct(obj)
        %STRUCT Converter to struct
        %
            for i = length(obj):-1:1
                out(i) = struct('TIME', obj(i).TIME, ...
                                'W',   obj(i).W, ...
                                'P',   obj(i).P, ...
                                'H',   obj(i).H, ...
                                'DP',  obj(i).DP, ...
                                'ITR', obj(i).ITR);
            end
        end

        function copyFlowProperties(srcObj, targetObj, opts)
        %COPYFLOWPROPERTIES
        %
            arguments
                srcObj
                targetObj (1,:) Solvers.Mixture.Mixture
                opts.copyMode  (1,1) string {mustBeMember(opts.copyMode,{'full','first','rest','continue'})} = "full"
            end

            for i = 1:length(targetObj)
                
                
                
                % Copy properties
                propNames = {'W','P','H','DP'};
                for j = 1:length(propNames)
                    % Full copy
                    if opts.copyMode == "full"

                        % Make sure obj meshes match
                        if srcObj(1).Z ~= targetObj(1).Z
                            throw( ...
                                MException( ...
                                    'MixtureError:copyFlowPropertiesError', ...
                                    'Source and target objects have mismatched spatial meshes' ...
                                    ) ...
                                );
                        end

                        targetObj(i).(propNames{j}) = srcObj(i).(propNames{j});

                    % Partial copy to preserve inlet conditions
                    elseif opts.copyMode == "rest"
                        
                        % Make sure obj meshes match
                        if srcObj(1).Z ~= targetObj(1).Z
                            throw( ...
                                MException( ...
                                    'MixtureError:copyFlowPropertiesError', ...
                                    'Source and target objects have mismatched spatial meshes' ...
                                    ) ...
                                );
                        end

                        % Scalar structs are copied per field
                        if isstruct(targetObj(i).(propNames{j})) && isscalar(targetObj(i).(propNames{j}))
                            structFields = fieldnames(targetObj(i).(propNames{j}));
                            for ii = 1:length(structFields)
                                targetObj(i).(propNames{j}).(structFields{ii})(2:end) = ...
                                    srcObj(i).(propNames{j}).(structFields{ii})(2:end);
                            end
                        % Non-scalar properties are copied as a vector
                        else
                            targetObj(i).(propNames{j})(2:end) = srcObj(i).(propNames{j})(2:end);
                        end

                    % Partial copy of only first element in space
                    elseif opts.copyMode == "first"
                        % Scalar structs are copied per field
                        if isstruct(targetObj(i).(propNames{j})) && isscalar(targetObj(i).(propNames{j}))
                            structFields = fieldnames(targetObj(i).(propNames{j}));
                            for ii = 1:length(structFields)
                                targetObj(i).(propNames{j}).(structFields{ii})(1) = ...
                                    srcObj(i).(propNames{j}).(structFields{ii})(1);
                            end
                        % Non-scalar properties are copied as a vector
                        else
                            targetObj(i).(propNames{j})(1) = srcObj(i).(propNames{j})(1);
                        end
                    
                    % Partial copy of only last element in space in src to
                    % first element in space in target
                    elseif opts.copyMode == "continue"

                        % Scalar structs are copied per field
                        if isstruct(targetObj(i).(propNames{j})) && isscalar(targetObj(i).(propNames{j}))
                            structFields = fieldnames(targetObj(i).(propNames{j}));
                            for ii = 1:length(structFields)
                                if propNames{j} == "DP"
                                    srcVal = sum(srcObj(i).(propNames{j}).(structFields{ii}));
                                else
                                    srcVal = srcObj(i).(propNames{j}).(structFields{ii})(end);
                                end
                                targetObj(i).(propNames{j}).(structFields{ii})(1) = srcVal;
                            end
                        % Non-scalar properties are copied as a vector
                        else
                            % If property size shows different num. of walls, 
                            % look at inputset.obs for hints, FOR NOW
                            % TODO: if there are more than 1 obstruction,
                            %       major changes will be needed.
                            if size(targetObj(i).(propNames{j}), 2) ~= size(srcObj(i).(propNames{j}), 2)
                                
                                % Determine obstruction wall id
                                wallID = srcObj.inputSet.obs(1).WALL;

                                % source value
                                srcVal = srcObj(i).(propNames{j})(end,:);

                                % Split srcVal at wallID to 2
                                % ex. if wallID ==1 , targetVal(:,[1,2])
                                % will correspond to srcVal(:,1)
                                targetVal = [srcVal(:,1:wallID), repmat(srcVal(:,wallID),1,2), srcVal(:,wallID+1:end)];

                                % Assign targetVal
                                targetObj(i).(propNames{j})(1,:) = targetVal;                                

                                
                            else
                                % simply copy if same size
                                targetObj(i).(propNames{j})(1,:) = srcObj(i).(propNames{j})(end,:);
                            end
                        end
                       
                    end
                end


            end

        end
    
    end

    methods(Access = protected)
    

        function cpObj = copyElement(obj)
        %COPYELEMENT Override copyElement method to create correct references
        % with properties liquid and vapor 
            
            import Solvers.Mixture.*

            % Make a shallow copy of all four properties
            cpObj = copyElement@matlab.mixin.Copyable(obj);
            
            % Update liquid and vapor 'mix' property
            cpObj.liquid = Liquid(cpObj);
            cpObj.vapor = Vapor(cpObj);
        end


        function interpOut = timeInterpolate(mix, y)
        %TIMEINTERPOLATE Interpolate vector y in TIME
        %
            interpOut = interp1([mix.inputSet.bc.TIME], ...
                                y, ...
                                mix.TIME, ...
                                mix.inputSet.options.TIMEINTERP);
        end

        function interpOut = axialInterpolate(mix, x, y)
        %AXIALINTERPOLATE Interpolate vector y in x
        %
            interpOut = interp1(x, ...
                                y, ...
                                mix.Z, ...
                                mix.inputSet.options.AXIALINTERP, ...
                                "extrap");
        end

        function MFLUX_CALC(mix)
        %MFLUX_CALC Helper function to calculate Mass flux [kg/m^2-s]
            mix.mflux = mix.W./mix.inputSet.geometry.AREA;
        end

        function XEQ_CALC(mix)
        %XEQ_CALC Helper function to calculate Equilibrium quality [-]
        %  
            mix.xeq =(mix.H-mix.fluid.HF) ./ mix.fluid.HFG;
        end

        function X_CALC(mix)
        %X_CALC Helper function to calculate Equilibrium quality [-]
        %  
            
            % Call XEQ first
            mix.XEQ_CALC();
            
            % Use mix.xeq to calculate x
            switch mix.inputSet.model.SCBOIL
                case 'NONE'
                    mix.x=min(max(mix.xeq,0),1);
            end
        end

    end

    methods (Access=private)
        function s = sigm(mix, zIdx, pCoefs)
            
            % Calculate sigmoid function once
            % NOTE: changing pCoefs after first call will not result in
            % update of this function values.
            if isempty(mix.sigm_const)
                zIdxs = (1:mix(1).NZ).';
                mix.sigm_const = 1./(1+exp(-pCoefs(1).*(zIdxs-pCoefs(2)))); % Define sigmoid function
            end
            s = mix.sigm_const(zIdx);
        end
    end

end

