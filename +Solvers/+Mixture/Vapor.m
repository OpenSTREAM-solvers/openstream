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

    properties (SetAccess=private)
        mix 
    end
    
    methods
        function vapor = Vapor(mix)
            %VAPOR Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                mix {mustBeA(mix, 'Solvers.Mixture.Mixture')}
            end

            vapor.mix = mix;
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
            x = 1-vapor.mix.X();
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
            u = vapor.MFLUX ./ vapor.VF ./ vapor.mix.inputSet.fluid.RHOV(vapor.mix.H.').';
        end

        function h = get.H(vapor)
            %H Enthalpy [J/kg]
            %
            h = min(vapor.mix.H, vapor.mix.inputSet.fluid.HG.');
        end

        function mflux = get.MFLUX(vapor)
            %MFLUX Mass flux [kg/m^2-s]
            %
            mflux = vapor.W./vapor.mix.inputSet.geometry.AREA;
        end

        function re = get.RE(vapor)
            %RE Reynolds number [-]
            %
            re = 4.*vapor.W./vapor.mix.inputSet.fluid.MUG(vapor.mix.H.').'...
                    ./sum(vapor.mix.inputSet.geometry.PERIM);
        end

    end
end

