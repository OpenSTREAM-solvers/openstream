classdef Liquid < Solvers.AbstractPhase
    %LIQUID Summary of this class goes here
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
        function liquid = Liquid(mix)
            %LIQUID Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                mix {mustBeA(mix, 'Solvers.Mixture.Mixture')}
            end

            liquid.mix = mix;
        end
        
        function time = get.TIME(liquid)
            %TIME Time series [s]
            %   Detailed explanation goes here
            time = liquid.mix.TIME;
        end

        function z = get.Z(liquid)
            %Z Axial nodes [m]
            %   Detailed explanation goes here
            z = liquid.mix.Z;
        end
        
        function x = get.X(liquid)
            %X Mass fraction [-]
            %
            x = 1-liquid.mix.X();
        end
        
        function vf = get.VF(liquid)
            %VF Void fraction [-]
            %
            vf = 1-liquid.mix.VF();
        end

        function w = get.W(liquid)
            %W Mass flow rate [kg/s]
            %
            w = liquid.X .* liquid.mix.W;
        end

        function u = get.U(liquid)
            %U Velocity [m/a]
            %   NOTE: need to be verified
            u = liquid.MFLUX ./ liquid.VF ./ liquid.mix.inputSet.fluid.RHOL(liquid.mix.H);
        end

        function h = get.H(liquid)
            %H Enthalpy [J/kg]
            %
            h = max(liquid.mix.H, liquid.mix.inputSet.fluid.HF.');
        end

        function mflux = get.MFLUX(liquid)
            %MFLUX Mass flux [kg/m^2-s]
            %
            mflux = liquid.W./liquid.mix.inputSet.geometry.AREA;
        end

        function re = get.RE(liquid)
            %RE Reynolds number [-]
            %
            re = 4.*liquid.W./liquid.mix.inputSet.fluid.MUL(liquid.mix.H.').'...
                    ./sum(liquid.mix.inputSet.geometry.PERIM);
        end

    end
end

