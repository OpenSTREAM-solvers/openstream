classdef SolverPlotter < handle
    %SOLVERPLOTTER Framework for generating solver plots
    %
    %   TODO: Detailed explanations
    
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

        isAnimation             (1,1) logical                                   = false
        animationTitleFormat    (1,1) string                                = ""
        animationSeries         (:,1) {isnumeric}                           = 1
    end
    
    methods
        function plotters = SolverPlotter(titles, WallIdxs, opts)
        %SOLVERPLOTTER Creates a solver plotter
        %

        arguments
            titles                  = ""
            WallIdxs                = 1
            opts.isAnimation        = false;
            opts.animationSeries    = 1;
        end

            if nargin == 0, return; end
            if ischar(titles)
                titles = string(titles);
            end
            if isscalar(titles) && ~isscalar(WallIdxs)
                titles = repmat(titles,1,length(WallIdxs));
            end

            % Create plotter objects
            plotters(length(WallIdxs)) = Solvers.SolverPlotter();
            for idx = 1:length(plotters)
                
                % Check if is an animated series
                if opts.isAnimation
                    plotters(idx).isAnimation = true;
                    plotters(idx).animationSeries = opts.animationSeries;
                    plotters(idx).animationTitleFormat = titles(idx);
                    titles(idx) = sprintf(titles(idx), opts.animationSeries(1));
                end

                plotters(idx).WallIdx = WallIdxs(idx);
                plotters(idx).Title = sprintf('%s - Wall %u', titles(idx), plotters(idx).WallIdx);
                plotters(idx).fh = figure("Name", plotters(idx).Title);
                plotters(idx).th = tiledlayout(plotters(idx).fh, "flow","TileSpacing","loose","Padding","loose");

                % Store animation title data in fh
                if opts.isAnimation
                    plotters(idx).fh.UserData = struct("NameFormat", plotters(idx).animationTitleFormat, "NameSeries", plotters(idx).animationSeries);
                end

                % Add UI if is an animated series
                if opts.isAnimation
                    rewindButton = uicontrol(Style="pushbutton", String="<");
                    rewindButton.Units = 'pixels';
                    rewindButton.Position = [20,20,30,20];
                    rewindButton.Callback = @animationCallback;

                    advanceButton = uicontrol(Style="pushbutton", String=">");
                    advanceButton.Units = "pixels";
                    advanceButton.Position = [110,20,30,20];
                    advanceButton.Callback = @animationCallback;

                    % TODO: counter? Update figure title?
                    animationCounter = uicontrol(Style="edit");
                    animationCounter.Units = 'pixels';
                    animationCounter.Position = [60,20,40,20];
                    animationCounter.Callback = @animationCallback;
                    animationCounter.String = 1;
                end

                    
            end

            function animationCallback(src, event)

                % retrieve figure and axes handles
                fh = event.Source(1).Parent;
                tlh = findobj(fh, 'type', 'tiledlayout');
                ahs = findobj(tlh, 'type', 'axes');

                % Loop through each ahs
                for ah_idx=1:length(ahs)
                    
                    % Retrieve ah
                    ah = ahs(ah_idx);

                    % Line handles
                    lhs = findobj(ah, 'type', 'line');

                    % Loop through each lhs
                    for lh_idx = 1:length(lhs)
                    
                        % Retrieve lh
                        lh = lhs(lh_idx);

                        % TODO: check struct in lhuserdata
                        
                        % Save index of what is last displayed
                        lastIndex = lh.UserData.currentIndex;

                        % Rewind/Advance
                        if string(src.String) == "<"
                            currentIndex = lastIndex-1;
                        elseif string(src.String) == ">"
                            currentIndex = lastIndex+1;
                        elseif (src.Style == "edit") 
                            currentIndex = str2double(src.String);
                        end

                        % Continue to next lh if at last YData
                        if isnan(currentIndex) || currentIndex > length(lh.UserData.YData) || currentIndex < 1
                            if src.Style == "edit"
                                src.String = string(lastIndex);
                            end
                            continue;
                        end

                        % Retrieve new YData
                        currentYData = lh.UserData.YData(currentIndex).data;
                        
                        % update lh.YData
                        lh.YData = currentYData;
                        
                        % update userdata struct
                        lh.UserData.currentIndex = currentIndex;

                        % update counter
                        if src.Style == "pushbutton"
                            animationCounter.String = string(currentIndex);
                        end

                        % update figure name
                        fh.Name = sprintf(fh.UserData.NameFormat, fh.UserData.NameSeries(currentIndex));


                    end

                end
            end
        end

        function add_ah = addTile(plotters, opts)
        %ADDTILE Finds existing tile by tileTitle, or create new one if non
        %is found.
            arguments
                plotters
                opts.tileTitle = ""
                opts.xlabel = ""
                opts.ylabel = ""
            end

            % Loop through each plotter
            for plotterIdx = 1:length(plotters)

                % Current plotter
                plotter = plotters(plotterIdx);

                % Axes handles in plotter
                plotter_ahs = plotter.ahs;

                % opts in cell format
                opts_cell = namedargs2cell(opts);

                % Check if tilelayout is empty
                if isempty(plotter_ahs)
                    
                    % Simply create new tile if empty
                    add_ah(plotterIdx) = plotter.newTile(opts_cell{:});
                else

                    % Get title strings
                    titles = [plotter_ahs.Title];
                    titleStrings = string({titles.String});
    
                    % Find index of opts.tileTitle in titleStrings
                    tileIdx = find(titleStrings == opts.tileTitle);
                    % If none found, make new tile
                    if isempty(tileIdx)
                        add_ah(plotterIdx) = plotter.newTile(opts_cell{:});
                    
                    % Otherwise, use existing
                    else
                        add_ah(plotterIdx) = plotter_ahs(tileIdx);
                        plotter.currentAhIdx = tileIdx;
                    end
                end
            end


        end

        function new_ah = newTile(plotters, opts)
        %newTile Creates a new tile
        %
            arguments
                plotters
                opts.tileTitle = ""
                opts.xlabel = ""
                opts.ylabel = ""
            end

            % Create new tile for each plotter
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
        
        function plotz(plotters, YData, fieldName, opts)
        %PLOTZ Plot input (YData) distributions (in space or time)
        %
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

                matchingLineExists = false;

                % Check if isAnimation
                if plotter.isAnimation

                    % Check if lh with DisplayName that match
                    % opts.DisplayName exists
                    
                    % Existing Line handles
                    lhs = findobj(ah, 'type', 'Line');

                    % Check if there are any lines at all
                    if ~isempty(lhs)
                        
                        % lh DisplayNames
                        dispNames = string({lhs.DisplayName});

                        % Find matching lh index
                        lh_idx = find(dispNames == opts.DisplayName);

                        % if not empty, set flag to true
                        if ~isempty(lh_idx)
                            matchingLineExists = true;
                            
                            % Then store YData to lh.userData
                            lh = lhs(lh_idx);
                            if  (isstring(YData) || ischar(YData)) && strcmpi(YData, "ylim")
                                YData= ylim(ah);
                            elseif isvector(YData)
                                YData = YData(opts.subset);
                            else
                                YData = YData(opts.subset, plotter.WallIdx);
                            end
                            lh.UserData.YData = [lh.UserData.YData, struct('index', length(lh.UserData.YData), 'data', YData)];
                        end
                    end


                end

                if ~matchingLineExists
                    % Custom plot by YData
                    if  (isstring(YData) || ischar(YData)) && strcmpi(YData, "ylim")
                        lh = plot(ah, XData, ylim(ah), 'DisplayName', opts.DisplayName, opts.plotOptions{:});
                    elseif isvector(YData)
                        lh = plot(ah, XData, YData(opts.subset), 'DisplayName', opts.DisplayName, opts.plotOptions{:});
                    else
                        lh = plot(ah, XData, YData(opts.subset, plotter.WallIdx), 'DisplayName', opts.DisplayName, opts.plotOptions{:});
                    end

                    % Set line styles
                    lh.Color = plotStyles.Color;
                    lh.LineStyle = plotStyles.LineStyle;
                    lh.Marker = plotStyles.Marker;

                    % Store YData if isAnimation
                    if plotter.isAnimation
                        % Store YData
                        lh.UserData = struct('currentIndex', 1, 'YData', struct('index', 1, 'data', lh.YData));
                    end

                end

                

            end
        end

        function plotOAF(plotters, oafIdx)
        %plotOAF Plot onset of annular flow boundary
        %
            if isscalar(oafIdx)
                oafIdx = repmat(oafIdx, 1, 2);
            end
            plotters.plotz('ylim', 'OAF', ...
                           'XData',oafIdx, ...
                           'plotOptions', {'handleVisibility','off'});
        end

        function ahs = gca(plotters)
        %gca Get current plotter axes properties
        %
            % Loop through plotters
            for idx = 1:length(plotters)
                plotter = plotters(idx);
                ahs(idx) = plotter.ahs(plotter.currentAhIdx);
            end
        end

        function fh = gcf(plotters)
        %gcf Get current plotter handle properties
        %
            fh = plotters.fh;
        end
        
        function out = xlim(plotters, newLim)
        %xlim Set or query plotter x-axis limits
        %
            % Loop through plotters
            for idx = 1:length(plotters)
                plotter = plotters(idx);
                if nargin < 2
                    out(idx) = xlim(plotter.ahs(plotter.currentAhIdx));
                else
                    xlim(plotter.ahs(plotter.currentAhIdx), newLim);
                end
            end
        end

        function out = ylim(plotters, newLim)
        %ylim Set or query plotter y-axis limits
        %
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
        
        function ylabels(plotters, labels)
        %ylabel Label the plotter y-axis
        %
            % Loop through plotters
            for idx = 1:length(plotters)
                plotter = plotters(idx);
                yticks(plotter.ahs(plotter.currentAhIdx),1:length(labels));
                yticklabels(plotter.ahs(plotter.currentAhIdx),labels);
            end
        end

        function setZs(plotters, Zs)
        %setZs Set the parameter on the plotter x-axis (space or time)
        %
            % Loop through plotters
            for idx = 1:length(plotters)
                plotter = plotters(idx);
                plotter.Zs = Zs;
            end
        end

        function legend(plotters, varargin)
        %legend Create a plotter legend.
        %
            % Loop through plotters
            for idx = 1:length(plotters)
                plotter = plotters(idx);
                legend(plotter.gca, varargin{:});
            end
        end

    end

    methods (Static)

        function plotStyle = fieldName2plotStyle(fieldName)
        %plotStyle Indicate the plot style (color, marker, etc) for each
        %fieldName
            
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
                    plotStyle = {colors(2), '--', 'o'};
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

