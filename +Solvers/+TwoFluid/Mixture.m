classdef Mixture < Solvers.AbstractPhase
    %MIXTURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private, GetAccess=private)
        mixture
        liquid         
        vapor          
        inputSet       {isa(inputSet,'Inputs.InputSet')}
        fluid          {isa(fluid,'Inputs.FluidProperties')}
        NZ
    end
    
    methods
        function mix = Mixture(mixture,liquid,vapor)
        %MIXTURE Construct an instance of this class
        %   Detailed explanation goes here
            arguments
                mixture {mustBeA(mixture,'Solvers.Mixture.Mixture')}
                liquid  {mustBeA(liquid ,'Solvers.TwoFluid.Liquid')}
                vapor   {mustBeA(vapor  ,'Solvers.TwoFluid.Vapor') }
            end

            mix(1:length(liquid)) = mix;
            for i = 1:length(mix)
                mix(i).mixture  = mixture(i);
                mix(i).liquid   = liquid(i);
                mix(i).vapor    = vapor(i);
                mix(i).fluid    = liquid(i).fluid;
                mix(i).inputSet = liquid(i).inputSet;
                mix(i).NZ       = liquid(i).NZ;
            end
        end
        
        function time = TIME(mix)
        %TIME Time series [s]
        %   Detailed explanation goes here
            time = mix.mixture.TIME;
        end

        function z = Z(mix, zIdx)
        %Z Axial nodes [m]
        %   Detailed explanation goes here
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            z = mix.mixture.Z(zIdx);
        end
        
        function hflux = HFLUX(mix,zIdx)
        %HFLUX Wall heat flux [W/m^2]
        %TODO: Maybe different from mixture HFLUX once a heater model is implemented
        
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            hflux = mix.mixture.HFLUX(zIdx,:);                             % [W/m^2]
        end
        
        function lhgr = LHGR(mix,zIdx)
        %LHGR Linear heat generation rate [W/m]
        
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            geom = mix.inputSet.geometry;
            lhgr = mix.HFLUX(zIdx).*geom.PERIM;                            % [W/m]
        end
        
        function walevapratio = WALEVAPRATIO(mix, zIdx)
        %WALEVAPRATIO Wall mass evaporation ratio [-]    
        %TODO: Results should be updated based on mixture inputs from two-fluid simulation
        
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            walevapratio = mix.mixture.WALEVAPRATIO(zIdx);                 % [-]
        end
        
        function w = W(mix, zIdx)
        %W Mass flow rate [kg/s]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            w = mix.liquid.W(zIdx) + mix.vapor.W(zIdx);                    % [kg/s]
        end
        
        function mflux = MFLUX(mix, zIdx)
        %MFLUX Mass flux [kg/s/m^2]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            geom = mix.inputSet.geometry;
            mflux = mix.W(zIdx)./geom.AREA;                                % [kg/s/m^2]
        end
        
        function rho = RHO(mix,zIdx)
        %RHO Density [kg/m^3]
        
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            RHOV = mix.fluid.RHOV(mix.vapor.H(zIdx));                      % [kg/m^3] vapor density
            RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));                     % [kg/m^3] liquid density
            VF   = mix.vapor.VF(mix.liquid,zIdx);
            
            rho = (1-VF).*RHOL + VF.*RHOV;                                 % [kg/m^3]
        end
        
        function u = U(mix,zIdx)
        %U Velocity [m/s]
        
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            RHOV = mix.fluid.RHOV(mix.vapor.H(zIdx));                      % [kg/m^3] vapor density
            RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));                     % [kg/m^3] liquid density
            VF   = mix.vapor.VF(mix.liquid,zIdx);

            u = ((1-VF).*RHOL.*mix.liquid.U(zIdx) + VF.*RHOV.*mix.vapor.U(zIdx))./((1-VF).*RHOL+ VF.*RHOV); % [m/s]
            %u = (mix.liquid.W(zIdx).*mix.liquid.U(zIdx)+mix.vapor.W(zIdx).*mix.vapor.U(zIdx))./mix.W(zIdx); % [m/s]
        end
        
        function dpdz = DPDZ(mix, zIdx)
        %DPDZ Pressure gradient [Pa/m]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            dpdz = mix.mixture.DP.Tot(zIdx)/mix.mixture.DZ;                % [Pa/m]
        end
        
        function h = H(mix,zIdx)
        %H Enthalpy [J/kg]
        
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
        
            h = (mix.liquid.W(zIdx).*mix.liquid.H(zIdx)+mix.vapor.W(zIdx).*mix.vapor.H(zIdx))./mix.W(zIdx); % [J/kg]
            %[mix.liquid.W(zIdx) mix.vapor.W(zIdx) mix.W(zIdx)]
        end
        
        function xeq = XEQ(mix,zIdx)
        %XEQ Equilibrium thermodynamic quality [-]
        %TODO: Results should be updated based on mixture inputs from two-fluid simulation
        
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            xeq = mix.mixture.XEQ(zIdx);                                   % [-]
            
            %h = mix.H(zIdx);
            %xeq = (h-mix.fluid.HF)./(mix.fluid.HG-mix.fluid.HF); % [-]
        end
        
        function chf = CHF(mix, zIdx)
        %CHF Critical Heat Flux [W/m^2], wall dependant
        %TODO: Results should be updated based on mixture inputs from two-fluid simulation
        
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            chf = mix.mixture.CHF(zIdx);                                   % [-]
        end
        
        function cbt = CBT(mix, zIdx)
        %CBT Critical Boiling Transition flag [-], wall dependant
        %TODO: Results should be updated based on mixture inputs from two-fluid simulation
        
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            cbt = mix.mixture.CBT(zIdx);                                   % [-]
        end
        
        function t = RELAXTCOND(mix, zIdx)
        %RELAXTCOND Time relaxation for interfacial evaporation [s]
        %TODO: Results should be updated based on mixture inputs from two-fluid simulation
        
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            t = mix.mixture.RELAXTCOND(zIdx);                              % [-]
        end
        
        function t = RELAXTEVAP(mix, zIdx)
        %RELAXTEVAP Time relaxation for interfacial condensation [s]
        %TODO: Results should be updated based on mixture inputs from two-fluid simulation
        
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            t = mix.mixture.RELAXTEVAP(zIdx);                              % [-]
        end
        
    end
    
end