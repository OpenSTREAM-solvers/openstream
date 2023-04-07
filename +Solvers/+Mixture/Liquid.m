classdef Liquid %< Solvers.AbstractPhase
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
    end

    properties (SetAccess=private)
        mix 
    end
    
    methods
        function obj = Liquid(mix)
            %LIQUID Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                mix {mustBeA(mix, 'Solvers.Mixture.Mixture')}
            end
            
            obj.mix = mix;
        end
        
        function time = get.TIME(obj)
            %TIME Time series [s]
            %   Detailed explanation goes here
            time = obj.mix.TIME;
        end

        function z = get.Z(obj)
            %Z Axial nodes [m]
            %   Detailed explanation goes here
            z = obj.mix.Z;
        end
        
        function x = get.X(obj)
            %X Mass fraction [-]
            %
            x = 1-obj.mix.X();
        end
        
        function vf = get.VF(obj)
            %VF Void fraction [-]
            %
            vf = 1-obj.mix.VF();
        end

        function w = get.W(obj)
            %W Mass flow rate [kg/s]
            %
            w = obj.X .* obj.mix.W;
        end

        function u = get.U(obj)
            %U Velocity [m/a]
            %   NOTE: need to be verified
            u = obj.MFLUX ./ obj.VF ./ obj.mix.inputSet.fluid.RHOL(obj.mix.H);
        end

        function h = get.H(obj)
            %H Enthalpy [J/kg]
            %
            h = max(obj.mix.H, obj.mix.inputSet.fluid.HF);
        end

        function mflux = get.MFLUX(obj)
            %MFLUX Mass flux [kg/m^2-s]
            %
            mflux = obj.W./obj.mix.inputSet.geometry.AREA;
        end

    end
end

