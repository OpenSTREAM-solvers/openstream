classdef Liquid < Solvers.AbstractPhase
    %LIQUID Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private, GetAccess=private)
        film
        drop
        NZ
        inputSet
    end
    
    methods
        function liquids = Liquid(films, drops)
        %LIQUID Construct an instance of this class
        %   Detailed explanation goes here
            % arguments
            %     films Solvers.ThreeField.Film
            %     drops Solvers.ThreeField.Drop
            % end
            
            if nargin > 0
                liquids(1:length(films)) = Solvers.ThreeField.Liquid();
                for i = 1:length(films)
                    liquids(i).film = films(i);
                    liquids(i).drop = drops(i);
                    liquids(i).NZ = films(i).NZ;
                    liquids(i).inputSet = films(i).inputSet;
                end
            end
        end

        function updatePhases(liquid, film, drop)
            arguments
                liquid
                film Solvers.ThreeField.Film
                drop Solvers.ThreeField.Drop
            end

            liquid.film = film;
            liquid.drop = drop;
            liquid.NZ = film.NZ;
            liquid.inputSet = film.inputSet;
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
            z = liquid.film.Z(zIdx);
        end
        
        function x = X(liquid, zIdx)
        %X Mass fraction [-]
        %
            warning('ThreeFieldSolver.Liquid.X is not a properly implemented method');
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            x = 1-liquid.mix.X(zIdx);
        end
        
        function vf = VF(liquid, zIdx)
        %VF Void fraction [-]
        %
            warning('ThreeFieldSolver.Liquid.VF is not a properly implemented method; old implementation used');
            vf = liquid.film.mix.mixSolver_mix.liquid.VF(zIdx);
            return;

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            vf = 1-liquid.mix.VF(zIdx);
        end

        function w = W(liquid, zIdx)
        %W Mass flow rate [kg/s]
        %
            % TODO: needs testing
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            % While initializing ThreeFieldSolver, length of film.W may be
            % 1. Use value from mixsolver_mix
            % TODO: find better way of doing this in TFsolver init.
            if length(liquid.film.W) == 1
                w = liquid.film.mix.mixSolver_mix.W(zIdx);
            else
                w = liquid.film.W(zIdx) + liquid.drop.W(zIdx);
            end
        end

        function u = U(liquid, zIdx)
        %U Velocity [m/s]
        %
            warning('ThreeFieldSolver.Liquid.U is not a properly implemented method; old implementation used');
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            u = liquid.film.mix.mixSolver_mix.liquid.U(zIdx);
            return;

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
            warning('ThreeFieldSolver.Liquid.H is not a properly implemented method; old implementation used');
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            h = liquid.film.mix.mixSolver_mix.liquid.H(zIdx);
            return;

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
%              X = max(liquid.mix.X(zIdx),liquid.mix.XEQ(zIdx));              % Account for potential subcooled liquid
%             h = (liquid.mix.H(zIdx)-X.*liquid.mix.fluid.HG)./(1-X);
%             %h = min(h,liquid.mix.fluid.HF);                                % No superheated liquid
%             %h = max(h,liquid.mix.H(1));
            
            X = liquid.mix.X(zIdx);  
            h = (liquid.mix.H(zIdx)-X.*liquid.mix.vapor.H(zIdx))./(1-X);
            
            %mix = liquid.mix;
            %h = (mix.W(zIdx).*mix.H(zIdx)-mix.TRELAX.WV(zIdx,:).*mix.TRELAX.HV(zIdx,:))./liquid.W(zIdx);
            
            h(isnan(h)) = liquid.mix.fluid.HF;
            h(isinf(h)) = liquid.mix.fluid.HF;
            %h = max(h,liquid.mix.H(1));
            h = max(h,1E5);
        end

        function mflux = MFLUX(liquid, zIdx)
        %MFLUX Mass flux [kg/m^2/s]
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            mflux = liquid.W(zIdx)./liquid.film.inputSet.geometry.AREA;
        end

        function re = RE(liquid, zIdx)
        %RE Reynolds number [-]
        %TODO: Check definition
        %
            error('ThreeFieldSolver.Liquid.RE is not a properly implemented method');
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            re = 4.*liquid.W(zIdx)./liquid.mix.fluid.MUL(liquid.H(zIdx))...
                    ./sum(liquid.mix.inputSet.geometry.PERIM);
        end
        
        function hfluxwalheat = HFLUX(liquid, zIdx)
        %HFLUX Wall field heat flux [W/m^2]
        %
            error('ThreeFieldSolver.Liquid.HFLUX is not a properly implemented method');
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            hfluxwalheat = liquid.mix.HFLUX(zIdx,:)-liquid.mix.vapor.HFLUX(zIdx)-liquid.mix.vapor.HFLUXWALEVAP(zIdx);
        end
        
        function t = T(liquid, zIdx)
        %T Temperature [K]
        %
            error('ThreeFieldSolver.Liquid.T is not a properly implemented method');
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            t = liquid.mix.fluid.T(liquid.H(zIdx));
        end   

    end
end

