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
            %   NOTE: need to be verified
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            u = liquid.MFLUX(zIdx) ./ liquid.VF(zIdx) ./ liquid.mix.fluid.RHOL(liquid.mix.H(zIdx));
            
            % set to the mixture velocity in the single-phase vapor region
            singlePhaseIdx = isnan(u);
            mixU = liquid.mix.U(zIdx);
            u(singlePhaseIdx) = mixU(singlePhaseIdx);
        end

        function h = H(liquid, zIdx)
            %H Enthalpy [J/kg]
            %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            h = max(liquid.mix.H(zIdx), liquid.mix.fluid.HF.');
        end

        function mflux = MFLUX(liquid, zIdx)
            %MFLUX Mass flux [kg/m^2-s]
            %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            mflux = liquid.W(zIdx)./liquid.mix.inputSet.geometry.AREA;
        end

        function re = RE(liquid, zIdx)
            %RE Reynolds number [-]
            %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            re = 4.*liquid.W(zIdx)./liquid.mix.fluid.MUL(liquid.mix.H(zIdx))...
                    ./sum(liquid.mix.inputSet.geometry.PERIM);
        end

    end
end

