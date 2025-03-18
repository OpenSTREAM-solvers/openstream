classdef Vapor < Solvers.AbstractPhase
    %VAPOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private, GetAccess=private)
        mix
        NZ
    end
    
    methods
        function vapor = Vapor(mix)
            %VAPOR Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                mix {mustBeA(mix, 'Solvers.Mixture.Mixture')}
            end

            vapor(1:length(mix)) = vapor;
            for i = 1:length(mix)
                vapor(i).mix = mix(i);
                vapor(i).NZ = mix(i).NZ;
            end
        end
        
        function time = TIME(vapor)
            %TIME Time series [s]
            %   Detailed explanation goes here
            time = vapor.mix.TIME;
        end

        function z = Z(vapor, zIdx)
            %Z Axial nodes [m]
            %   Detailed explanation goes here
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            z = vapor.mix.Z(zIdx);
        end
        
        function x = X(vapor, zIdx)
            %X Mass fraction [-]
            %
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            x = vapor.mix.X(zIdx);
        end
        
        function vf = VF(vapor, zIdx)
            %VF Void fraction [-]
            %
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            vf = vapor.mix.VF(zIdx);
        end

        function w = W(vapor, zIdx)
            %W Mass flow rate [kg/s]
            %
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            w = vapor.X(zIdx) .* vapor.mix.W(zIdx);
        end

        function u = U(vapor, zIdx)
            %U Velocity [m/s]
            %NOTE: need to be verified
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            u = vapor.MFLUX(zIdx) ./ vapor.VF(zIdx) ./ vapor.mix.fluid.RHOV(vapor.H(zIdx));
            
            % set to the mixture velocity in the single-phase liquid region
            %singlePhaseIdx = 1:(vapor.mix.OAFIDX-1);
            singlePhaseIdx = isnan(u);
            mixU = vapor.mix.U(zIdx);
            u(singlePhaseIdx) = mixU(singlePhaseIdx);
        end

        function h = H(vapor, zIdx)
            %H Enthalpy [J/kg]
            %Calculation dpends on non equilibrium model
            %TODO: Check and clean up
            %
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            model = vapor.mix.inputSet.model;
            
            switch model.THERMALNONEQ
                
                case 'TRELAX'
                    WV = vapor.mix.TRELAX.WV(zIdx,:);
                    h = sum(vapor.mix.TRELAX.HV(zIdx,:).*WV,2)./sum(WV,2);
                    h(isnan(h)) = vapor.mix.fluid.HG;
                    % sum(WV,2) is the same as vapor.W
                    
                otherwise
                    X = min(vapor.mix.X(zIdx),vapor.mix.XEQ(zIdx));        % Account for potential superheated vapor
                    h = (vapor.mix.H(zIdx)-(1-X).*vapor.mix.fluid.HF)./X;  % Division by 0?
                    %h = max(h,vapor.mix.fluid.HG);                         % No subcooled vapor
                    %h = min(h,5E6);
            end
        end

        function mflux = MFLUX(vapor, zIdx)
            %MFLUX Mass flux [kg/m^2-s]
            %
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            mflux = vapor.W(zIdx)./vapor.mix.inputSet.geometry.AREA;
        end

        function re = RE(vapor, zIdx)
            %RE Reynolds number [-]
            %
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            %re = 4.*vapor.W(zIdx)./vapor.mix.fluid.MUV(vapor.H(zIdx))...
            %        ./sum(vapor.mix.inputSet.geometry.PERIM);
            
            geom  = vapor.mix.inputSet.geometry;
            fluid = vapor.mix.fluid;
            re = fluid.RHOV(vapor.H(zIdx)).*vapor.U(zIdx).*geom.HDIAM./fluid.MUV(vapor.H(zIdx));
        end
        
        function t = T(vapor, zIdx)
            %T Temperature [K]
            %
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            t = vapor.mix.fluid.T(vapor.H(zIdx));
        end   

    end
end

