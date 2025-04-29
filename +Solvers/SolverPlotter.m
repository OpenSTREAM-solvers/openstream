classdef SolverPlotter < handle
    %SOLVERPLOTTER Framework for generating solver plots
    %   Detailed explanation goes here
    
    properties
        FontSize            {mustBePositive, isnumeric}             = 14            % Font size of text in plots
        Title               {isstring}                              = ""            % Figure title
        WallIdx             {mustBePositive, mustBeInteger}         = 1             % Wall index
        Zs          (:,1)   {isnumeric}                             = []
        Ts          (:,1)   {isnumeric}                             = []
    
        Grid                {mustBeMember(Grid,{'on','off','minor'})} = 'on'        % Grid option


        currentAhIdx (1,1)  {isnumeric}                             = NaN
    end

    properties (Access=protected)
        fh          (1,1) matlab.ui.Figure       
        th          (1,1) matlab.graphics.layout.TiledChartLayout
        ahs               matlab.graphics.axis.Axes
    end
    
    methods
        function plotters = SolverPlotter(Titles, WallIdxs)
            %SOLVERPLOTTER Construct an instance of this class
            %   Detailed explanation goes here

            if nargin == 0, return; end
            if ischar(Titles)
                Titles = string(Titles);
            end
            if isscalar(Titles) && ~isscalar(WallIdxs)
                Titles = repmat(Titles,1,length(WallIdxs));
            end

            % Create plotter objects
            plotters(length(WallIdxs)) = Solvers.SolverPlotter();
            for idx = 1:length(plotters)
                plotters(idx).WallIdx = WallIdxs(idx);
                plotters(idx).Title = sprintf('%s - Wall %u', Titles(idx), plotters(idx).WallIdx);
                plotters(idx).fh = figure("Name", plotters(idx).Title);
                plotters(idx).th = tiledlayout(plotters(idx).fh, "flow","TileSpacing","loose","Padding","loose");
            end
        end

        function new_ah = newTile(plotters, opts)
            arguments
                plotters
                opts.tileTitle = ""
                opts.xlabel = ""
                opts.ylabel = ""
            end

            % Create new tile for each plotters
            for idx = 1:length(plotters)

                plotter = plotters(idx);
                new_ah(idx) = nexttile(plotters(idx).th);
                plotter.ahs(end+1) = new_ah(idx);
                plotter.currentAhIdx = length(plotter.ahs);

                % Set tile title
                title(new_ah(idx), opts.tileTitle);

                % Set x-y label
                xlabel(new_ah(idx), opts.xlabel);
                if iscell(opts.ylabel) && length(opts.ylabel) == 2
                    yyaxis(new_ah(idx), 'left');
                    ylabel(new_ah(idx), opts.ylabel{1});
                    yyaxis(new_ah(idx), 'right');
                    ylabel(new_ah(idx), opts.ylabel{2});
                else
                    ylabel(new_ah(idx), opts.ylabel);
                end

                % Set font size
                new_ah(idx).FontSize = plotter.FontSize;

                % Turn hold on for axes
                hold(new_ah(idx), "on");

                % Set grid option
                grid(new_ah(idx), plotter.Grid);

            end
        end
        
        function plotz(plotters,YData, fieldName, opts)
            %PLOTZ Summary of this method goes here
            %   Detailed explanation goes here
            arguments
                plotters
                YData
                fieldName           = 'WAVE'
                opts.DisplayName    = fieldName
                opts.subset         = 1:length(plotters(1).Zs)
                opts.plotOptions    = {}
                opts.XData          = []
                opts.yyaxis
            end
            
            % Check if Zs are set
            isZSet = all(not(cellfun(@isempty,{plotters.Zs})));
            if ~isZSet, error('Not all Z arrays are set'); end

            % Determine plot style and color from fieldName
            plotStyles = Solvers.SolverPlotter.fieldName2plotStyle(fieldName);

            % Loop through plotters
            for idx = 1:length(plotters)
                
                % Current plotter
                plotter = plotters(idx);

                % Current axes
                ah = plotter.gca();

                % Custom and standard XData
                if isfield(opts, 'XData') && ~isempty(opts.XData)
                    XData = opts.XData;
                else
                    XData = plotter.Zs(opts.subset);
                    xlim(ah, XData([1 end]));
                end

                % Dual axis
                if isfield(opts, 'yyaxis')
                    yyaxis(ah, opts.yyaxis)
                end

                % Custom plot by YData
                if  (isstring(YData) || ischar(YData)) && strcmpi(YData, "ylim")
                    lh = plot(ah, XData, ylim(ah), 'DisplayName', opts.DisplayName, opts.plotOptions{:});
                elseif isvector(YData)
                    lh = plot(ah, XData, YData(opts.subset), 'DisplayName', opts.DisplayName, opts.plotOptions{:});
                else
                    lh = plot(ah, XData, YData(opts.subset, plotter.WallIdx), 'DisplayName', opts.DisplayName, opts.plotOptions{:});
                end

                lh.Color = plotStyles.Color;
                lh.LineStyle = plotStyles.LineStyle;
                lh.Marker = plotStyles.Marker;

            end
            
        end

        function plotOAF(plotters, oafIdx)

            if isscalar(oafIdx)
                oafIdx = repmat(oafIdx, 1, 2);
            end
            plotters.plotz('ylim', 'OAF', ...
                           'XData',oafIdx, ...
                           'plotOptions', {'handleVisibility','off'});
        end

        function ahs = gca(plotters)

            % Loop through plotters
            for idx = 1:length(plotters)
                plotter = plotters(idx);
                ahs(idx) = plotter.ahs(plotter.currentAhIdx);
            end
        end

        function fh = gcf(plotters)

            fh = plotters.fh;
        end

        function out = ylim(plotters, newLim)

            % Loop through plotters
            for idx = 1:length(plotters)
                plotter = plotters(idx);
                if nargin < 2
                    out(idx) = ylim(plotter.ahs(plotter.currentAhIdx));
                else
                    ylim(plotter.ahs(plotter.currentAhIdx), newLim);
                end
            end
        end

        function setZs(plotters, Zs)

            % Loop through plotters
            for idx = 1:length(plotters)
                plotter = plotters(idx);
                plotter.Zs = Zs;
            end
        end

        function legend(plotters, varargin)
            
            % Loop through plotters
            for idx = 1:length(plotters)
                plotter = plotters(idx);
                legend(plotter.gca, varargin{:});
            end
        end

    end

    methods (Static)

        function plotStyle = fieldName2plotStyle(fieldName)
            
            % Default colors
            colors = ["#0072BD","#D95319","#EDB120","#7E2F8E","#77AC30","#4DBEEE","#A2142F"];
            
            switch upper(fieldName)
                
                case {'Z'}
                    plotStyle = {colors(2), '-', '.'};
                case {'TIME', 'T'}
                    plotStyle = {colors(3), '-', '+'};
                case {'SATURATION'}
                    plotStyle = {colors(1), '--', 'none'};    
                case {'SATLIQ'}
                    plotStyle = {colors(2), '--', 'none'};    
                case {'SATVAP'}
                    plotStyle = {colors(1), '--', 'none' };    
                    
                % Mixture solver
                case {'MIX', 'MIXTURE'}
                    plotStyle = {colors(7), '-', 's'};
                case {'LIQUID+VAPOR', 'VAPOR+LIQUID'}
                    plotStyle = {colors(7), '--', '+'};   
                case {'MIXLIQ', 'MIXTURELIQUID', 'LIQUID'}
                    plotStyle = {colors(2), '-', '.'};
                case {'VAP', 'VAPOR'}
                    plotStyle = {colors(1), '-', '.' };
                case {'RELAXVAPOR','WALLVAPOR','VAPORDRAG'}
                    plotStyle = {colors(1), '--', 'o' };
                case {'EQ', 'EQUILIBRIUM', 'EQUIL'}
                    plotStyle = {colors(5), '-', 'o'};
                case {'RELAXEQUIL'}
                    plotStyle = {colors(5), '--', '+'};
                case {'NONEQ', 'NONEQUILIBRIUM', 'NON-EQ', 'NON-EQUILIBRIUM'}
                    plotStyle = {colors(6), '-', '.'};
                case {'EQQUAL', 'EQUILIBRIUMQUAL', 'EQUILQ'}
                    plotStyle = {colors(5), '-', 'o'};
                case {'VF','VOIDFRACTION'}
                    plotStyle = {colors(6), '-', '.'};
                case {'EVAPORATION'}
                    plotStyle = {colors(3), '--', '.'};
                case {'EXCHANGE'}
                    plotStyle = {colors(4), '-', '.'};
                case {'TOTAL'}
                    plotStyle = {'black', '-', 'x'};
                case {'WALL'}
                    plotStyle = {colors(5), '-', '.'};
                case {'BUOYANCY'}
                    plotStyle = {colors(6), '-', '.'};
                case {'GRAVITY', 'GRAVITATIONAL', 'GRAV'}
                    plotStyle = {colors(7), '-', '.'};
                case {'LOCAL'}
                    plotStyle = {'black', '--', '.'};
                case {'CHF', 'CBT'}
                    plotStyle = {colors(7), '--', '+'};       
                    
                % Two-fluid solver
                case {'INTERFACIAL'}
                    plotStyle = {colors(1), '-', 'O'};
                case {'INTERFACIALEVAP'}
                    plotStyle = {colors(1), '-', '+'};
                case {'INTERFACIALCOND'}
                    plotStyle = {colors(1), '-', '.'};  
                
                % Three-field solver
                case {'OAF'}
                    plotStyle = {'red', '--', '.'};
                case {'FILM'}
                    plotStyle = {colors(2), '--', '.'};
                case {'DROP'}
                    plotStyle = {colors(5), '--', 'o'};
                case {'DROP+FILM', 'FILM+DROP'}
                    plotStyle = {colors(2), '--', '+'};
                case {'DEPOSITION'}
                    plotStyle = {colors(5), '--', 'o'};
                case {'ENTRAINMENT'}
                    plotStyle = {colors(2), '--', 'o'};
                    
                % Four-field solver
                case {'EQFILM'}
                    plotStyle = {colors(2), '--', '^'};
                case {'BASE'}
                    plotStyle = {colors(3), '--', '.'};
                case {'BASE MIN','BASEMIN','BASEMASS'}
                    plotStyle = {colors(3), '--', 'none'};    
                case {'EQBASE', 'BASEEQ', 'BASE EQ'}
                    plotStyle = {colors(3), '--', '^'};
                case {'WAVE'}
                    plotStyle = {colors(4), '--', '.'};
                case {'WAVEMASS'}
                    plotStyle = {colors(4), '--', 'none'};    
                case {'EQWAVE', 'WAVEEQ', 'WAVE EQ'}
                    plotStyle = {colors(4), '--', '^'};
                case {'WAVEAMP', 'WAVE AMP'}
                    plotStyle = {colors(4), '--', 'x'};
                case {'WAVEFREQ', 'WAVE FREQ'}
                    plotStyle = {colors(4), '--', 'd'};
                case {'WAVEEQFREQ', 'WAVE EQ FREQ'}
                    plotStyle = {colors(4), '--', '+'};
                case {'WAVEWIDTH', 'WAVE WIDTH', 'WIDTH'}
                    plotStyle = {colors(4), '--', '.'};
                case {'WAVESPACING', 'WAVE SPACING', 'SPACING'}
                    plotStyle = {colors(4), '--', 'o'};
                    
                otherwise
                    plotStyle = {'black', '--', '.'};
            end

            % Convert cell to struct
            plotStyle = cell2struct(plotStyle, {'Color', 'LineStyle', 'Marker'},2);

        end


        end
end

