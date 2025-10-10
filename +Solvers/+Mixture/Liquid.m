classdef Liquid < Solvers.AbstractPhase
    %LIQUID Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private, GetAccess=private)
        mix
        NZ
    end
    
    methods
        function liquid = Liquid(mix)
        %LIQUID Construct an instance of this class
        %   Detailed explanation goes here
            arguments
                mix {mustBeA(mix, 'Solvers.Mixture.Mixture')}
            end
            
            liquid(1:length(mix)) = liquid;
            for i = 1:length(mix)
                liquid(i).mix = mix(i);
                liquid(i).NZ = mix(i).NZ;
            end
        end
        
        function time = TIME(liquid)
        %TIME Time series [s]
        %   Detailed explanation goes here
            time = liquid.mix.TIME;
        end

        function z = Z(liquid, zIdx)
        %Z Axial nodes [m]
        %   Detailed explanation goes here
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            z = liquid.mix.Z(zIdx);
        end
        
        function x = X(liquid, zIdx)
        %X Mass fraction [-]
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            x = 1-liquid.mix.X(zIdx);
        end
        
        function vf = VF(liquid, zIdx)
        %VF Void fraction [-]
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            vf = 1-liquid.mix.VF(zIdx);
        end

        function w = W(liquid, zIdx)
        %W Mass flow rate [kg/s]
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            w = liquid.X(zIdx) .* liquid.mix.W(zIdx);
        end

        function u = U(liquid, zIdx)
        %U Velocity [m/s]
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            u = liquid.MFLUX(zIdx)./liquid.VF(zIdx)./liquid.mix.fluid.RHOL(liquid.H(zIdx));
            
            % Set to the mixture velocity in the single-phase vapor region
            mixU           = liquid.mix.U(zIdx);
            singlePhaseIdx = isnan(u);
            u(singlePhaseIdx) = mixU(singlePhaseIdx);
        end

        function h = H(liquid, zIdx)
        %H Enthalpy [J/kg]
        %Calculated based on mixture & vapor enthalpies and vapor quality
        %TODO: Check and clean up
        %TODO: Find a better way to prevent division by small 1-X and negative h
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
%              X = max(liquid.mix.X(zIdx),liquid.mix.XEQ(zIdx));              % Account for potential subcooled liquid
%             h = (liquid.mix.H(zIdx)-X.*liquid.mix.fluid.HG)./(1-X);
%             %h = min(h,liquid.mix.fluid.HF);                                % No superheated liquid
%             %h = max(h,liquid.mix.H(1));
            
            X = liquid.mix.X(zIdx);  
            h = (liquid.mix.H(zIdx)-X.*liquid.mix.vapor.H(zIdx))./(1-X);
            
            h(isnan(h)) = liquid.mix.fluid.HF;
            h(isinf(h)) = liquid.mix.fluid.HF;
            %h = max(h,liquid.mix.H(1));
            %h = max(h,1E5);
        end

        function mflux = MFLUX(liquid, zIdx)
        %MFLUX Mass flux [kg/m^2/s]
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            mflux = liquid.W(zIdx)./liquid.mix.inputSet.geometry.AREA;
        end

        function re = RE(liquid, zIdx)
        %RE Reynolds number [-]
        %TODO: Check definition
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            re = 4.*liquid.W(zIdx)./liquid.mix.fluid.MUL(liquid.H(zIdx))...
                    ./sum(liquid.mix.inputSet.geometry.PERIM);
        end
        
        function hfluxwalheat = HFLUX(liquid, zIdx)
        %HFLUX Wall field heat flux [W/m^2]
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            hfluxwalheat = liquid.mix.HFLUX(zIdx,:)-liquid.mix.vapor.HFLUX(zIdx)-liquid.mix.vapor.HFLUXWALEVAP(zIdx);
        end
        
        function t = T(liquid, zIdx)
        %T Temperature [K]
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            t = liquid.mix.fluid.T(liquid.H(zIdx));
        end   

    end
end

