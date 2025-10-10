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
        %
            time = liquid.film.TIME;
        end

        function z = Z(liquid, zIdx)
        %Z Axial nodes [m]
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            z = liquid.film.Z(zIdx);
        end
        
        function x = X(liquid, zIdx)
        %X Mass fraction [-]
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            x = liquid.W(zIdx)./liquid.film.mix.W(zIdx);
        end
        
        function vf = VF(liquid, zIdx)
        %VF Void fraction [-]
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            geom = liquid.inputSet.geometry;
            fluid = liquid.film.mix.fluid;

            Af = sum(liquid.film.THICK(zIdx).*geom.PERIM,2);               % [m^2]
            Ad = liquid.drop.W(zIdx)./liquid.drop.U(zIdx)./fluid.RHOL(liquid.H(zIdx)); % [m^2]
            vf = (Af+Ad)./geom.AREA;
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
                w = liquid.film.mix.mixSolver_mix.liquid.W(zIdx);
            else
                w = sum(liquid.film.W(zIdx,:),2) + liquid.drop.W(zIdx);
            end
        end

        function u = U(liquid, zIdx)
        %U Velocity [m/s]
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            if length(liquid.film.W) == 1
                u = liquid.film.mix.mixSolver_mix.liquid.U(zIdx);
            else
                u = liquid.W(zIdx)./(liquid.drop.W(zIdx)./liquid.drop.U(zIdx)+sum(liquid.film.W(zIdx,:)./liquid.film.U(zIdx,:),2));
            end
        end

        function h = H(liquid, zIdx)
        %H Enthalpy [J/kg]
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            if length(liquid.film.W) == 1
                h = liquid.film.mix.mixSolver_mix.liquid.H(zIdx);
            else
                h = (sum(liquid.film.W(zIdx,:).*liquid.film.H(zIdx,:),2) + liquid.drop.W(zIdx).*liquid.drop.H(zIdx))./liquid.W(zIdx);
            end
        end

        function mflux = MFLUX(liquid, zIdx)
        %MFLUX Mass flux [kg/m^2/s]
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            mflux = liquid.W(zIdx)./liquid.film.inputSet.geometry.AREA;
        end

        function re = RE(liquid, zIdx)
        %RE Reynolds number [-]
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            geom = liquid.inputSet.geometry;
            fluid = liquid.film.mix.fluid;

            re = 4.*liquid.W(zIdx)./fluid.MUL(liquid.H(zIdx))./sum(geom.PERIM);
        end
        
        function hflux = HFLUX(liquid, zIdx)
        %HFLUX Wall field heat flux [W/m^2]
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            hflux = liquid.film.mix.HFLUX(zIdx,:);
        end
        
        function t = T(liquid, zIdx)
        %T Temperature [K]
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            fluid = liquid.film.mix.fluid;

            t = fluid.T(liquid.H(zIdx));
        end   

    end
end

