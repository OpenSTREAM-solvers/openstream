classdef Vapor < Solvers.AbstractPhase
    %VAPOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Dependent, SetAccess=private)
        TIME          double  {mustBeNumeric}
        Z             double  {mustBeNumeric}
        X
        VF
        W
        U
        H
        MFLUX
        RE
    end

    properties (SetAccess=private, GetAccess=private)
        mix 
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
            end
        end
        
        function time = get.TIME(vapor)
            %TIME Time series [s]
            %   Detailed explanation goes here
            time = vapor.mix.TIME;
        end

        function z = get.Z(vapor)
            %Z Axial nodes [m]
            %   Detailed explanation goes here
            z = vapor.mix.Z;
        end
        
        function x = get.X(vapor)
            %X Mass fraction [-]
            %
            x = vapor.mix.X();
        end
        
        function vf = get.VF(vapor)
            %VF Void fraction [-]
            %
            vf = vapor.mix.VF();
        end

        function w = get.W(vapor)
            %W Mass flow rate [kg/s]
            %
            w = vapor.X .* vapor.mix.W;
        end

        function u = get.U(vapor)
            %U Velocity [m/a]
            %   NOTE: need to be verified
            u = vapor.MFLUX ./ vapor.VF ./ vapor.mix.fluid.RHOV(vapor.mix.H);
            
            % set to the mixture velocity in the single-phase liquid region
            %singlePhaseIdx = 1:(vapor.mix.OAFIDX-1);
            singlePhaseIdx = isnan(u);
            u(singlePhaseIdx) = vapor.mix.U(singlePhaseIdx);
            
        end

        function h = get.H(vapor)
            %H Enthalpy [J/kg]
            %
            h = min(vapor.mix.H, vapor.mix.fluid.HG.');
        end

        function mflux = get.MFLUX(vapor)
            %MFLUX Mass flux [kg/m^2-s]
            %
            mflux = vapor.W./vapor.mix.inputSet.geometry.AREA;
        end

        function re = get.RE(vapor)
            %RE Reynolds number [-]
            %
            re = 4.*vapor.W./vapor.mix.fluid.MUV(vapor.mix.H)...
                    ./sum(vapor.mix.inputSet.geometry.PERIM);
        end

    end
end

