classdef Liquid < Solvers.AbstractField
    %LIQUID Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess={?Solvers.AbstractField,?Solvers.AbstractSolver})
        
        % Solver properties
        NZ                                                                 = 0                    % [-] Number of axial steps
        NTIME                                                              = 0                    % [-] Number of time steps
        TIME                                                               = 0                    % [s] Time series
        DT                                                                 = 0                    % [s] Time step size
        TIDX                                                               = 1                    % [-] Time step index
        Z                                                                  = 1.                   % [m] Elevation
        
        % Flow properties
        W            (:,1) double  {mustBeNumeric}                         = 1.                   % [kg/s] Mass flow rate
        U            (:,1) double  {mustBeNumeric}                         = 1.                   % [m/s] Velocity
        H            (:,1) double  {mustBeNumeric}                         = 1E6                  % [J/kg] Enthalpy

        % Iteration properties
        ITR

        % Mixture
        mix          (1,1)        {isa(mix, 'Solvers.Mixture.Mixture')}   = NaN

     end

     properties (Access={?Solvers.AbstractSolver,?Solvers.AbstractPhase, ?Solvers.AbstractField})
        
        DZ           (1,1) double  {mustBeNumeric}                         = 0                    % [m] Axial step size
        inputSet                   {isa(inputSet,'Inputs.InputSet')}
        fluid                      {isa(fluid,'Inputs.FluidProperties')}
     end
    
     
    
    methods
        function liquid = Liquid(inputSet, fluid)
            %liquid Construct an instance of this class
            %   Detailed explanation goes here
            
            if nargin > 0
                % Store inputSet as object property
                liquid.inputSet = inputSet;
                liquid.fluid  = fluid;
            end

            % Overload copyable properties
            %liquid.flowProperties = {'W','U','H'};
        end
        
        function x = X(liquid,zIdx)
        %X Liquid mass fraction
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            x = liquid.W(zIdx)./liquid.mix.W(zIdx);                          % [-]
        end
        
        function t = T(liquid,zIdx)
        %T Liquid temperature
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            t = liquid.fluid.T(liquid.H(zIdx));                            % [K]
        end
        
        function vf = VF(liquid,zIdx)
        %VF Volumetric fraction
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            AREA = liquid.inputSet.geometry.AREA;
            RHOL = liquid.fluid.RHOL(liquid.H(zIdx));
            
            vf = liquid.W(zIdx)./liquid.U(zIdx)./RHOL./AREA;               % [-]
        end
        
        function ai = AI(liquid,zIdx)
        %AI Volumetric interfacial area
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            XEQ = liquid.mix.XEQ;
            VF  = liquid.VF;
            
            aig = 6*(1-VF(zIdx))./liquid.L(zIdx);                          % [m] Dispersed gas
            ail = 6*VF(zIdx)./liquid.L(zIdx);                              % [m] Dispersed liquid
            
            % Transition from dispersed gas to dispersed liquid at XEQ = XTR;
            XTR = 0.2;
            ai = aig;
            ai(XEQ(zIdx)>XTR) = ail(XEQ(zIdx)>XTR);                        % [m^2/m^3]
            ai = max(0,ai);
        end
        
        function l = L(liquid,zIdx)
        %L Interfacial length scale (e.g. bubble of drop diameter)
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            % Make it constant for now
            l = 1E-3.*ones(size(zIdx));                                    % [m]
        end
        
        function inu = INU(liquid,zIdx)
        %INU Interfacial Nusselt number
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            % Make it constant for now
            inu = 2.*ones(size(zIdx));                                     % [-]
            % Other models: Ranz-Marshall?
        end
        
        
        function hflux = HFLUX(liquid,zIdx)
        %HFLUX Wall heat flux to liquid phase
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            XEQ   = liquid.mix.XEQ;
            HFLUX = liquid.mix.HFLUX;
            
            % Heat flux to liquid phase up to XEQ = XCBT
            XCBT = 0.8;                                                    % XCBT set to XEQ = 0.8 for now
            k = [1; diff(min(XCBT,XEQ))./diff(XEQ)];                       % [-] Pre-CBT ratio
            hflux = k(zIdx).*HFLUX(zIdx,:);                                % [W/m^2] 
        end
        
        function inthflux = INTHFLUX(liquid,vapor,zIdx)
        %INTHFLUX Interfacial heat flux to liquid phase
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            L    = liquid.L(zIdx);
            INU  = liquid.INU(zIdx);
            
            KL = liquid.fluid.KL(liquid.H(zIdx));
            h = INU.*KL./L; h(L <= 1E-6) = 0;                              % [W/m^2/K]

            inthflux = h.*(vapor.T(zIdx)-liquid.T(zIdx));                  % [W/m^2]
        end
        
        
        function Mwevap = MWEVAP(liquid,zIdx)
        %MWEVAP Wall evaporation mass flux
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            XEQ = liquid.mix.XEQ;
            HG  = liquid.fluid.HG;
            %HF  = liquid.fluid.HF;
            
            % Mass evaporation starts from XEQ = XOSV
            XOSV = -0.1;                                                   % XOSV set to XEQ = -0.1 for now
            k = [0; diff(max(XOSV,XEQ))./diff(XEQ)];                       % [-] Post-OSV ratio
            %Mwevap = -k(zIdx).*liquid.HFLUX(zIdx)./(HG-HF);                % [kg/s/m^2] Heat flux is only used for evaporation (probably wrong)
            Mwevap = -k(zIdx).*liquid.HFLUX(zIdx)./(HG-liquid.H(zIdx));    % [kg/s/m^2] Heat flux warms up liquid first (if subcooled) before evaporation
        end
        
        function Miexch = MIEXCH(liquid,vapor,zIdx)
        %MIEXCH interfacial mass flux
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            HG  = liquid.fluid.HG;
            HF  = liquid.fluid.HF;
            
            %liquid.H<HF
            %Miexch =  liquid.INTHFLUX(vapor,zIdx)./(HG-liquid.H(zIdx));    % [kg/s/m^2] Condensation
            Miexch1 =  liquid.INTHFLUX(vapor,zIdx)./(vapor.H(zIdx)-liquid.H(zIdx)); % [kg/s/m^2] Condensation
            
            %vapor.H>HG
            %Miexch = -liquid.INTHFLUX(vapor,zIdx)./(vapor.H(zIdx)-HF);     % [kg/s/m^2] Evaporation
            %Miexch = -liquid.INTHFLUX(vapor,zIdx)./(HF-liquid.H(zIdx));    % [kg/s/m^2] Evaporation
            Miexch2 =  liquid.INTHFLUX(vapor,zIdx)./(liquid.H(zIdx)-vapor.H(zIdx)); % [kg/s/m^2] Evaporation
            
            Miexch = Miexch1;
            Miexch(vapor.H(zIdx)>HG+1) = Miexch2(vapor.H(zIdx)>HG+1);
        end
        
        
        function Mwall = MWALL(liquid,zIdx)
        %MWALL Wall evaporation mass transfer
        %No condensation considered at the wall
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            PERIM = liquid.inputSet.geometry.PERIM;
            
            Mwall = sum(PERIM.*liquid.MWEVAP(zIdx),2);                     % [kg/s/m]
        end
        
        function Mevap = MEVAP(liquid,vapor,zIdx)
        %MEVAP Interfacial evaporation mass transfer
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            AREA = liquid.inputSet.geometry.AREA;
            
            Mevap = min(0,AREA.*liquid.AI(zIdx).*liquid.MIEXCH(vapor,zIdx)); % [kg/s/m]
        end
        
        function Mcond = MCOND(liquid,vapor,zIdx)
        %MCOND Interfacial condensation mass transfer
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            AREA = liquid.inputSet.geometry.AREA;
            
            Mcond = max(0,AREA.*liquid.AI(zIdx).*liquid.MIEXCH(vapor,zIdx)); % [kg/s/m]
        end

        function Mtot = MTOT(liquid,vapor,zIdx)
        %MTOT Total mass transfer
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            Mtot  = liquid.MWALL(zIdx);                                    % [kg/s/m]
            %Mtot  = liquid.MWALL(zIdx) + liquid.MEVAP(vapor,zIdx) + liquid.MCOND(vapor,zIdx); % [kg/s/m]
        end
        
        
        
        function Hwhf = HWHF(liquid,zIdx)
        %HWHF wall energy transfer from wall heat flux

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            PERIM = liquid.inputSet.geometry.PERIM;

            Hwhf = sum(PERIM.*liquid.HFLUX(zIdx),2);                       % [W/s/m]
        end
        
        function Hwall = HWALL(liquid,zIdx)
        %HWALL wall energy transfer from mass transfer

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            HG = liquid.fluid.HG;

            Hwall = liquid.MWALL(zIdx).*(HG-liquid.H(zIdx));               % [W/s/m]
        end
        
%         function Hevap = HEVAP(liquid,vapor,zIdx)
%         %HEVAP Interfacial energy transfer from evaporation
% 
%             if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
%             
%             HF = liquid.fluid.HF;
% 
%             Hevap = liquid.MEVAP(vapor,zIdx).*(HF-liquid.H(zIdx));         % [W/s/m]
%         end
        
        function Hcond = HCOND(liquid,vapor,zIdx)
        %HCOND Interfacial energy transfer from condensation

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            HG = liquid.fluid.HG;

            %Hcond = liquid.MCOND(vapor,zIdx).*(HG-liquid.H(zIdx));        % [W/s/m]
            Hcond = liquid.MCOND(vapor,zIdx).*(vapor.H(zIdx)-liquid.H(zIdx)); % [W/s/m]
        end
        
        function Htot = HTOT(liquid,vapor,zIdx)
        %HTOT Total energy transfer
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            Htot  = liquid.HWHF(zIdx) + liquid.HWALL(zIdx);                % [W/s/m]
            %Htot  = liquid.HWHF(zIdx) + liquid.HWALL(zIdx) + liquid.HCOND(vapor,zIdx); % [W/m]
        end
        
    end
end

