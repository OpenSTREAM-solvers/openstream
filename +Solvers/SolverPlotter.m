classdef SolverPlotter < handle
    %SOLVERPLOTTER Framework for generating solver plots
    %
    % This class provides a flexible plotting interface for visualizing solver results.
    % It supports tiled layouts, animated series, and customizable plot styles.
    % It also includes UI controls for animation playback and export.

    properties

        FontSize                    {mustBePositive, isnumeric}               = 13            % Font size of text in plots
        Title                       {isstring}                                = ""            % Title of the figure
        WallIdx                     {mustBePositive, mustBeInteger}           = 1             % Wall index for multi-wall simulations
        Zs                   (:,1)  {isnumeric}                               = []            % Axial positions [m]
        Ts                   (:,1)  {isnumeric}                               = []            % Time series [s]
        Grid                        {mustBeMember(Grid,{'on','off','minor'})} = 'on'          % Grid display option
        currentAhIdx         (1,1)  {isnumeric}                               = NaN           % Index of current active axes

    end

    properties (Access=protected)

        fh                   (1,1)  matlab.ui.Figure                                          % Figure handle
        th                   (1,1)  matlab.graphics.layout.TiledChartLayout                   % Tiled layout handle
        ahs                         matlab.graphics.axis.Axes                                 % Array of axes handles
        isAnimation          (1,1)  logical                                   = false         % Flag indicating if animation is enabled
        animationTitleFormat (1,1)  string                                    = ""            % Format string for animation title
        animationSeries      (:,1)  {isnumeric}                               = 1             % Series of time steps or frames for animation

    end

    methods

        function plotters = SolverPlotter(titles, WallIdxs, opts)
            %SOLVERPLOTTER Constructor method to initialize plotter objects and layout

            arguments
                titles                  = ""
                WallIdxs                = 1
                opts.arrangement        = 'flow'
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

                plotters(idx).WallIdx = WallIdxs(idx);

                % Check if is an animated series
                if opts.isAnimation
                    plotters(idx).isAnimation = true;
                    plotters(idx).animationSeries = opts.animationSeries;
                    plotters(idx).animationTitleFormat = sprintf('%s - Wall %u', titles(idx), plotters(idx).WallIdx);
                    titles(idx) = sprintf(titles(idx), opts.animationSeries(1));
                end

                plotters(idx).Title = sprintf('%s - Wall %u', titles(idx), plotters(idx).WallIdx);
                plotters(idx).fh = figure("Name", plotters(idx).Title, SizeChangedFcn=@figureSizeChangeCallback);

                plotters(idx).th = tiledlayout(plotters(idx).fh, opts.arrangement,"TileSpacing","loose","Padding","loose");
                plotters(idx).th.Title.String = plotters(idx).Title;
                plotters(idx).th.Title.FontSize = 15;

                % Store animation title data in fh
                if opts.isAnimation
                    plotters(idx).fh.UserData = struct("NameFormat", plotters(idx).animationTitleFormat, ...
                        "NameSeries", plotters(idx).animationSeries, ...
                        "isPlaying", false);
                end

                % Add UI if is an animated series
                if opts.isAnimation
                    rewindButton = uicontrol(plotters(idx).fh, ...
                        Style="pushbutton", ...
                        String="<", ...
                        Units="pixels", ...
                        Position=[20,20,30,20], ...
                        Callback=@animationCallback);

                    advanceButton = uicontrol(plotters(idx).fh, ...
                        Style="pushbutton", ...
                        String=">", ...
                        Units="pixels", ...
                        Position=[110,20,30,20], ...
                        Callback=@animationCallback);

                    counter = uicontrol(plotters(idx).fh, ...
                        Style="edit", ...
                        Tag='animationCounter', ...
                        Units="pixels", ...
                        Position=[60,20,40,20], ...
                        Callback= @animationCallback, ...
                        String = 1);

                    playButton = uicontrol(plotters(idx).fh, ...
                        Style="togglebutton", ...
                        String=char(9658), ...   % play; pause: char([124 32 124])
                        UserData=struct('originalSymbol', char(9658)), ...
                        Position=[150,20,30,20], ...
                        Callback={@playAnimationCallback, false});

                    loopButton = uicontrol(plotters(idx).fh, ...
                        Style="togglebutton", ...
                        String=char(11156), ...
                        UserData=struct('originalSymbol', char(11156)), ...
                        Position=[190,20,30,20], ...
                        Callback={@playAnimationCallback, true});

                    fpsEdit = uicontrol(plotters(idx).fh, ...
                        Style="edit", ...
                        Tag='fpsEdit', ...
                        String=num2str(1/diff(opts.animationSeries(1:2))), ...
                        Position=[230, 20, 30, 20] ...
                        );

                    fpsText = uicontrol(plotters(idx).fh, ...
                        Style="text", ...
                        String="fps", ...
                        Position=[265, 20, 30, 20], ...
                        HorizontalAlignment="left", ...
                        FontSize = 10 ...
                        );

                    animationMenu = uimenu(plotters(idx).fh, 'Text', 'Animation');
                    animationMenu_save = uimenu(animationMenu, 'Text', 'Save', 'MenuSelectedFcn', @animationSaveCallback);
                    animationMenu_showUIControls = uimenu(animationMenu, 'Text', 'Show UI Controls in Video', 'MenuSelectedFcn', @(src,~) set(src,'Checked', ~src.Checked));

                end
            end

            function figureSizeChangeCallback(src, ~)

                % Find legends
                lhs = src.findobj("Type", "legend");

                % Set Location to best
                for i=1:length(lhs)
                    lhs(i).Location = "best";
                end

                % Update
                drawnow limitrate;

                % Set back to none
                for i=1:length(lhs)
                    lhs(i).Location = "none";
                end

                % Update
                drawnow limitrate;
            end

            function animationCallback(src, ~)
                % ANIMATIONCALLBACK Method to handle animation control callbacks (rewind, advance, edit)

                % retrieve figure and axes handles
                fh = src.Parent;
                tlh = findobj(fh, 'type', 'tiledlayout');
                ahs = findobj(tlh, 'type', 'axes');

                % Loop through each ahs
                for ah_idx=1:length(ahs)

                    % Retrieve ah
                    ah = ahs(ah_idx);

                    % Line handles
                    lhs = findall(ah, 'type', 'line');

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
                        if isnan(currentIndex)
                            if src.Style == "edit"
                                src.String = string(lastIndex);
                            end
                            continue;
                        elseif currentIndex > length(lh.UserData.Data)
                            if src.Style == "edit"
                                src.String = string(1);
                            end
                            currentIndex = 1;
                        elseif  currentIndex < 1
                            if src.Style == "edit"
                                src.String = string(length(lh.UserData.Data));
                            end
                            currentIndex = length(lh.UserData.Data);
                        end

                        % Retrieve new YData
                        currentYData = lh.UserData.Data(currentIndex).yData;
                        % Retrieve XData if exists
                        currentXData = [];
                        if isfield(lh.UserData.Data(currentIndex), "xData")
                            currentXData = lh.UserData.Data(currentIndex).xData;
                        end

                        % update lh.YData
                        if isempty(currentXData)
                            set(lh, "YData", currentYData);
                        else
                            set(lh, "XData", currentXData, "YData", currentYData);
                        end

                        % TODO: update yData range for lines called OAF as
                        % ylim of axes changes

                        % update userdata struct
                        lh.UserData.currentIndex = currentIndex;

                        % Update counter UI if available
                        counter = findobj(fh, 'Tag', 'animationCounter');
                        if ~isempty(counter)
                            counter.String = string(currentIndex);
                        end

                        % update figure name
                        fh.Name = sprintf(fh.UserData.NameFormat, fh.UserData.NameSeries(currentIndex));
                        tlh.Title.String = fh.Name;
                        tlh.Title.FontSize = 15;
                    end
                end
            end

            function playAnimationCallback(src, ~, loop)
                %PLAYANIMATIONCALLBACK Method to handle play/pause animation loop with optional looping

                % Get figure and layout
                fh = src.Parent;
                tlh = findobj(fh, 'type', 'tiledlayout');
                ahs = findobj(tlh, 'type', 'axes');

                % Toggle play/pause state
                if isfield(fh.UserData, 'isPlaying') && fh.UserData.isPlaying
                    fh.UserData.isPlaying = false;
                    src.String = char(11156);  % Play symbol
                    return;
                else
                    fh.UserData.isPlaying = true;
                    src.String = char([124 32 124]);  % Pause symbol
                end

                % Animation loop
                while isvalid(fh) && fh.UserData.isPlaying

                    startTime = tic();

                    % Loop through all axes and lines
                    for ah_idx = 1:length(ahs)
                        ah = ahs(ah_idx);
                        lhs = findall(ah, 'type', 'line');

                        for lh_idx = 1:length(lhs)
                            lh = lhs(lh_idx);

                            % Skip if no animation data
                            if ~isfield(lh.UserData, 'Data') || isempty(lh.UserData.Data)
                                continue;
                            end

                            % Get current index
                            lastIndex = lh.UserData.currentIndex;
                            currentIndex = lastIndex + 1;

                            % Loop or stop
                            if currentIndex > length(lh.UserData.Data)
                                if loop
                                    currentIndex = 1;
                                else
                                    currentIndex = lastIndex;
                                    fh.UserData.isPlaying = false;
                                    break;
                                end
                            end

                            % Update line data
                            currentYData = lh.UserData.Data(currentIndex).yData;
                            if isfield(lh.UserData.Data(currentIndex), "xData")
                                currentXData = lh.UserData.Data(currentIndex).xData;
                                set(lh, "XData", currentXData, "YData", currentYData);
                            else
                                set(lh, "YData", currentYData);
                            end

                            % Update index
                            lh.UserData.currentIndex = currentIndex;
                        end
                    end

                    % Update figure title and counter if available
                    if isfield(fh.UserData, 'NameFormat') && isfield(fh.UserData, 'NameSeries')
                        fh.Name = sprintf(fh.UserData.NameFormat, fh.UserData.NameSeries(currentIndex));
                        tlh.Title.String = fh.Name;
                        tlh.Title.FontSize = 15;
                    end

                    % Update counter UI if available
                    counter = findobj(fh, 'Tag', 'animationCounter');
                    if ~isempty(counter)
                        counter.String = string(currentIndex);
                    end

                    drawnow limitrate;

                    % Frame rate control
                    fpsEdit = findobj(fh, 'Tag', 'fpsEdit');
                    if ~isempty(fpsEdit)
                        period = 1 / str2double(fpsEdit.String);
                    else
                        period = 0.1;  % default fallback
                    end

                    elapsedTime = toc(startTime);
                    pause(max(0, period - elapsedTime));
                end

                % Reset toggle
                if isvalid(src)
                    src.Value = false;
                    if isfield(src.UserData, 'originalSymbol')
                        src.String = src.UserData.originalSymbol;
                    else
                        src.String = char(9658);  % Default fallback
                    end
                end
            end

            function animationSaveCallback(src, ~)
                %ANIMATIONSAVECALLBACK Method to save animation as video file with UI toggle and frame rate control

                fh = src.Parent.Parent;
                idx = find(arrayfun(@(p) isequal(p.fh, fh), plotters));

                % Check if fps is positive
                fpsEdit = findobj(plotters(idx).fh, 'Tag', 'fpsEdit');
                assert(str2double(fpsEdit.String) > 0 , "Desired fps must be positive.");

                % Pick file to save
                if ispc || ismac
                    profile     = 'MPEG-4';
                    defaultExt  = '*.mp4';
                    defaultName = 'animation.mp4';
                else
                    profile     = 'Motion JPEG AVI';
                    defaultExt  = '*.avi';
                    defaultName = 'animation.avi';
                end

                [filename, pathname] = uiputfile({defaultExt, 'Video Files'}, 'Save animation as ...', fullfile(pwd, defaultName));
                filepath = fullfile(pathname, filename);

                % Add correction file extension if missing
                [~, ~, ext] = fileparts(filename);
                if isempty(ext)
                    [~, ~, extDefault] = fileparts(defaultName);
                    filename = [filename, extDefault];
                    filepath = fullfile(pathname, filename);
                end

                % Create videowriter object
                vid = VideoWriter(filepath, profile);

                %
                % Set video properties
                %
                % Limit FPS for MPEG-4 on Windows
                fps = str2double(fpsEdit.String);
                if ispc && strcmp(vid.VideoCompressionMethod, 'MPEG-4') && fps > 172
                    warning('Frame rate exceeds 172 fps limit for MPEG-4 on Windows. Setting to 172.');
                    fps = 172;
                end
                vid.FrameRate = fps;

                % TODO: use best quality for now
                vid.Quality = 100;

                % Number of frames
                numFrames = length(plotters(idx).ahs(1).Children(end).UserData.Data);

                % Collection of uicontrols
                fh_uicontrols = findall(plotters(idx).fh, 'type', 'uicontrol');
                % Hide uicontrols
                uimenu_showUIControls = findobj(src.Parent, 'text', 'Show UI Controls in Video');
                if ~uimenu_showUIControls.Checked
                    for uiControl_idx = 1:length(fh_uicontrols)
                        fh_uicontrols(uiControl_idx).Visible = false;
                    end
                end

                % Open video
                open(vid);
                counter = findobj(plotters(idx).fh, 'Tag', 'animationCounter');

                try
                    % Loop through frames
                    for frameIdx = 1:numFrames

                        % Set frame to frameIdx
                        % TODO: this can be a function
                        counter.String = string(frameIdx);
                        counter.Callback(counter, []);

                        drawnow;
                        
                        % capture frame for video
                        writeVideo(vid, getframe(plotters(idx).fh));

                    end
                catch ME
                    close(vid);
                    rethrow(ME);
                end

                % Close file
                close(vid);

                % Show uicontrols
                for uiControl_idx = 1:length(fh_uicontrols)
                    fh_uicontrols(uiControl_idx).Visible = true;
                end
            end
        end

        function add_ah = addTile(plotters, opts)
            %ADDTILE Method to add a new tile to the layout or retrieve existing one by title

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
            %NEWTILE Method to create a new tile with labels and formatting

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

                % Keep track of axes xLim and yLim
                new_ah(idx).UserData = struct('xlim', [], 'ylim', [], 'vertLineHandles', []);

                % Create listener for ylim change on axes
                addlistener(new_ah(idx), "YLim", "PostSet", @YLimChangedCallback);

            end

            % Event listener callback for when the ylim of an axes is set.
            % When set, lines with HandleVisibility set to off (i.e. simple
            % vertical lines) will have their YData updated to match the
            % new ylim range.
            function YLimChangedCallback(src, event)
                
                %fprintf("ylim callback triggered\n");

                % Retrieve new ylim of axes
                new_ylim = ylim(event.AffectedObject);

                % Find all simple vertical lines
                %hidden_lhs = findall(event.AffectedObject,'type', 'line','HandleVisibility','off');
                hidden_lhs = event.AffectedObject.UserData.vertLineHandles;

                % Adjust each line
                for i=1:length(hidden_lhs)
                    
                    % If the YData for the line is truly a simple value
                    % pair, adjust the YData as well as the time series in
                    % LineHandle.UserData.Data(j).yData, at time step j.
                    if numel(hidden_lhs(i).YData) == 2
                        hidden_lhs(i).YData = new_ylim;
                        for j=1:length(hidden_lhs(i).UserData.Data)
                            hidden_lhs(i).UserData.Data(j).yData = new_ylim;
                        end

                    % If the simple lines are plotted with NaN delimiters,
                    % the YData will be updated at the approp. indices.
                    % This is kept for now if we continue to use this
                    % method of defining the lines.
                    % TODO: decide if this is still needed
                    elseif numel(hidden_lhs(i).YData) == 6
                        hidden_lhs(i).YData(1:2) = new_ylim;
                        hidden_lhs(i).YData(4:5) = new_ylim;
                    end
                end
            end

        end

        function plotz(plotters, YData, fieldName, opts)
            %PLOTZ Method to plot spatial or temporal data (YData) on the current axes

            arguments
                plotters
                YData
                fieldName           = 'WAVE'
                opts.DisplayName    = fieldName
                opts.subset         = 1:length(plotters(1).Zs)
                opts.plotOptions    = {}
                opts.XData          = []
                opts.yyaxis
                opts.axisHandle     = plotters.gca()
            end

            % Check if Zs are set
            isZSet = all(not(cellfun(@isempty,{plotters.Zs})));
            if ~isZSet, error('Not all Z arrays are set'); end

            % Determine plot style and color from fieldName
            plotStyles = Solvers.SolverPlotter.fieldName2plotStyle(fieldName);

            % Save input YData
            YData0 = YData;

            % Loop through plotters
            for idx = 1:length(plotters)

                % Current plotter
                plotter = plotters(idx);

                % Current axes
                ah = opts.axisHandle(idx);

                % Restore Ydata
                YData = YData0;

                % Custom and standard XData
                % Provided non-empty XData, set xlim if non is already set
                % in axes userdata.
                % Otherwise, use plotter Zs as XData, and set xlim to the
                % range of Zs.
                if isfield(opts, 'XData') && ~isempty(opts.XData)
                    XData = opts.XData;
                    % Determine xlim
                    if isempty(ah.UserData.xlim)
                        xlim(ah, 'auto');
                    else
                        xlim(ah, [min(ah.UserData.xlim(1), min(XData)) max(ah.UserData.xlim(2), max(XData))]);
                    end
                else
                    XData = plotter.Zs(opts.subset);
                    xlim(ah, XData([1 end]));
                end

                % Save ah.UserData.xlim
                ah.UserData.xlim = xlim(ah);

                % Dual axis
                if isfield(opts, 'yyaxis')
                    yyaxis(ah, opts.yyaxis)
                end

                % Initialize flag: matching line exists
                matchingLineExists = false;

                % Check if the plotter is an animation
                if plotter.isAnimation

                    % Check if lh with DisplayName that match
                    % opts.DisplayName exists
                    
                    % Existing Line handles (OAF, plotK can be hidden, so findall)
                    if opts.DisplayName == "OBSTRUCTION"
                        lh = findall(ah, 'type', 'line', 'DisplayName', opts.DisplayName, 'XData', XData);
                    else
                        lh = findall(ah, 'type', 'line', 'DisplayName', opts.DisplayName);
                    end


                    % Check if there are any lines at all
                    if ~isempty(lh)

                        % Set flag
                        matchingLineExists = true;

                        % Update YData
                        % 
                        % If YData is a literal "ylim" string, the line is
                        % vertical and assumes ylim for the y-coordinates
                        % 
                        % If YData is a vector, there is only one wall
                        % Otherwise, the vector is for the current WallIdx.
                        %
                        if (isstring(YData) || ischar(YData)) && strcmpi(YData, "ylim")
                            YData = ylim(ah);
                            %YData = [NaN NaN];
                        elseif isvector(YData)
                            YData = YData(opts.subset);
                        else
                            YData = YData(opts.subset, plotter.WallIdx);
                        end
            
                        % Then concatenate XData (as needed) and 
                        % YData to lh.UserData
                        if isfield(lh.UserData.Data, "xData")
                            lh.UserData.Data = [lh.UserData.Data, struct('index', length(lh.UserData.Data), 'yData', YData, 'xData', XData)];
                        else
                            lh.UserData.Data = [lh.UserData.Data, struct('index', length(lh.UserData.Data), 'yData', YData)];
                        end

                    end

                end


                % If no matching lines exists, plot it and set up necessary
                % userdata structs
                if ~matchingLineExists

                    % Restore YData as previously set
                    YData = YData0;

                    % Custom plot by YData
                    if  (isstring(YData) || ischar(YData)) && strcmpi(YData, "ylim")
                        drawnow limitrate;
                        YData= ylim(ah);
                        lh = plot(ah, XData, YData, 'DisplayName', opts.DisplayName, opts.plotOptions{:});
                        ah.UserData.vertLineHandles = [ah.UserData.vertLineHandles lh];

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
                        % Store XData and YData
                        if isempty(opts.XData)
                            lh.UserData = struct('currentIndex', 1, 'Data', struct('index', 1, 'yData', lh.YData));
                        else
                            lh.UserData = struct('currentIndex', 1, 'Data', struct('index', 1, 'yData', lh.YData, 'xData', lh.XData));
                        end
                    else
                        % Initialize for single-step mode
                        lh.UserData = struct('Data', []);
                    end

                end

                % Determine ylim
                if isempty(ah.UserData.ylim)
                    ylim(ah, 'auto');
                    drawnow limitrate;
                    new_ylim = ylim(ah);
                else
                    % Select YData for current plotter.WallIdx
                    if size(YData,2) > 1
                        YData = YData(:,plotter.WallIdx); 
                    end
                    new_ylim = [min(ah.UserData.ylim(1), min(YData)) max(ah.UserData.ylim(2), max(YData))];
                    
                    % TODO: this ylim call seems necessary, but takes a
                    % long time. Consider finding alternative way of
                    % setting ylim, perhaps only at end of plotting.
                    ylim(ah, new_ylim);
                end

                % Save widest ylim
                ah.UserData.ylim = new_ylim;
            end
        end

        function plotOAF(plotters, oafZ)
            %PLOTOAF Method to plot onset of annular flow boundary indicator

            if isscalar(oafZ)
                oafZ = repmat(oafZ, 1, 2);
            end
            plotters.plotz('ylim', 'OAF', ...
                'XData',oafZ, ...
                'plotOptions', {'handleVisibility','off'});
        end

        function plotK(plotters, klocZ, ah)
            % PLOTK Method to plot obstruction elevation indicators

            if nargin < 3, ah = plotters.gca(); end

            % Ensure klocZ is a row vector
            klocZ = klocZ(:)';

            % Get current Y-axis limits
            yl = plotters.ylim;

            % Prepare X and Y data for vertical lines with NaN separators
            xdata = reshape([klocZ; klocZ; nan(size(klocZ))], 1, [])';
            ydata = repmat([yl, nan(length(plotters),1)], 1, numel(klocZ))';
            ydata='ylim';

            for i=1:length(klocZ)

                xdata = [klocZ(i) klocZ(i)];
               
                % Plot vertical lines
                plotters.plotz(ydata, 'OBSTRUCTION', 'axisHandle', ah, ...
                    'XData', xdata, 'subset', 1:numel(xdata), ...
                    'plotOptions', {'handleVisibility', 'off'});
            end
        end

        function ahs = gca(plotters)
            %GCA Get Method to retrieve current axes handle

            % Loop through plotters
            for idx = 1:length(plotters)
                plotter = plotters(idx);
                ahs(idx) = plotter.ahs(plotter.currentAhIdx);
            end
        end

        function fh = gcf(plotters)
            %GCF Method to retrieve current plotter handle

            fh = plotters.fh;
        end

        function out = xlim(plotters, newLim)
            %xlim Method to get or set x-axis limits for current axes

            % Loop through plotters
            for idx = 1:length(plotters)
                plotter = plotters(idx);
                if nargin < 2
                    out(idx,:) = xlim(plotter.ahs(plotter.currentAhIdx));
                else
                    xlim(plotter.ahs(plotter.currentAhIdx), newLim);
                    plotter.gca.UserData.xlim = newLim;
                end
            end
        end

        function out = ylim(plotters, newLim)
            %YLIM Method to get or set y-axis limits for current axes

            % Loop through plotters
            for idx = 1:length(plotters)
                plotter = plotters(idx);
                if nargin < 2
                    out(idx,:) = ylim(plotter.ahs(plotter.currentAhIdx));
                else
                    ylim(plotter.ahs(plotter.currentAhIdx), newLim);
                    plotter.gca.UserData.ylim = newLim;
                end
            end
        end

        function ylabels(plotters, labels)
            %YLABEL Method to set y-axis tick labels

            % Loop through plotters
            for idx = 1:length(plotters)
                plotter = plotters(idx);
                yticks(plotter.ahs(plotter.currentAhIdx),1:length(labels));
                yticklabels(plotter.ahs(plotter.currentAhIdx),labels);
            end
        end

        function setZs(plotters, Zs)
            %SETZS Method to assign the parameter(space or time) on the plotter x-axis

            % Loop through plotters
            for idx = 1:length(plotters)
                plotter = plotters(idx);
                plotter.Zs = Zs;
            end
        end

        function lhs = legend(plotters, varargin)
            %legend Method to add legend to current axes

            % Loop through plotters
            for idx = 1:length(plotters)
                plotter = plotters(idx);
                
                % Update graphics
                if isempty(plotter.gca().Legend)
                    lhs(idx) = legend(plotter.gca(), varargin{:});
                    drawnow limitrate;
                end

                % Set legend location to "none"
                lhs(idx).Location = "none";
                

            end
        end

        function resizeFigure(plotters, scaleFactor)
            % resizeFigure Resizes the figure based on tiledlayout rows/columns
            % Keeps top-left fixed and goes full-screen if size exceeds screen resolution.
            %
            % Usage:
            %
            % - plotters.resizeFigure()    — Default scaleFactor = 1
            % - plotters.resizeFigure(1.2) — Tiles 20% larger
            % - plotters.resizeFigure(0.8) — Tiles 20% smaller

            if nargin < 2
                scaleFactor = 1; % default
            end

            for k = 1:length(plotters)

                % Get current figure from plotter
                fig = plotters(k).fh;

                % Find tiledlayout object
                layouts = findall(fig, 'Type', 'tiledlayout');
                if isempty(layouts)
                    error('No tiledlayout found in the current figure.');
                end
                t = layouts(1);

                % Get rows and columns
                nRows = t.GridSize(1);
                nCols = t.GridSize(2);

                % Base size per tile
                tileWidth = 600 * scaleFactor;
                tileHeight = 450 * scaleFactor;

                % Compute new size
                newWidth = tileWidth * nCols;
                newHeight = tileHeight * nRows;

                % Get screen size
                screenSize = get(0, 'ScreenSize'); % [left bottom width height]
                screenWidth = screenSize(3);
                screenHeight = screenSize(4);

                % Current position
                pos = fig.Position;
                top = pos(2) + pos(4); % current top

                if newWidth > screenWidth || newHeight > screenHeight
                    % Full-screen mode
                    fig.Units = 'normalized';
                    fig.OuterPosition = [0 0 1 1];
                else
                    % Keep top-left fixed
                    newBottom = top - newHeight;
                    fig.Position = [pos(1), newBottom, newWidth, newHeight];
                end

            end
        end

    end

    methods (Static)

        function plotStyle = fieldName2plotStyle(fieldName)
            %FIELDNAME2PLOTSTYLE Static method to map field names to plot styles (color, line, marker)

            % Default colors
            colors = ["#0072BD","#D95319","#EDB120","#7E2F8E","#77AC30","#4DBEEE","#A2142F","#808080"];

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
                case {'OBSTRUCTION'}
                    plotStyle = {colors(8), '--', '.'};

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
                    plotStyle = {colors(5), '-', '.'};
                case {'NEARWALL'}
                    plotStyle = {colors(3), '--', '+'};
                case {'BULK'}
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
                    plotStyle = {colors(1), '-', '.'};
                case {'INTERFACIALCOND'}
                    plotStyle = {colors(2), '-', '.'};

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

