classdef InputSet
    %INPUTSET Creates set of input objects
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        model
        options
        geometry
        bc
        obs

        session                   (1,1) Session.Session
    end
    
    methods
        function obj = InputSet(opts)
            %INPUTSET Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                opts.modelFilePath      {isfile}            = ''        % Model input file (inp/json)
                opts.modelID            {mustBeTextScalar}  = ''        % Model ID
                
                opts.optionsFilePath    {isfile}            = ''        % Options input file (inp/json)
                opts.optionsID          {mustBeTextScalar}  = ''        % Options ID
                
                opts.geometryFilePath   {isfile}            = ''        % Geometry input file (inp/json)
                opts.geometryID         {mustBeTextScalar}  = ''        % Geometry ID
                
                opts.bcFilePath         {isfile}            = ''        % Boundary condition input file (inp/json)

                opts.obsFilePath        {isfile}            = ''        % Obstruction input file (inp/json)
                opts.obsIDs             {mustBeText}        = ''        % Obstruction IDs, multiple allowed

                opts.LOGMODE (1,1)      Session.LogMode         = Session.LogMode.LOGTOCONSOLEONLY
                opts.sessionName        {isStringScalar}    = ""        % Session name
                opts.sessionDirName     {isStringScalar}    = ""        % Session directory name
                opts.sessionParentDir   {isfolder}          = userpath  % Session parent directory
                opts.overwriteSessionFiles ...
                                        {islogical}         = false     % Flag to overwrite existing session files
            end

            % Import packages
            import Inputs.*

            % Return if no inputs were given
            if ~isfield(opts, 'modelFilePath')
                return;
            end
            
            %
            % Setup Log mechanism
            % Build sessionName as needed
            if opts.sessionName == ""
                [~,sessionName] = fileparts(opts.bcFilePath);
            else
                sessionName = opts.sessionName;
            end

            % Build sessionDirName as needed
            if opts.sessionDirName == ""
                sessionDirName = strcat( ...
                                    opts.geometryID,'-', ...
                                    opts.modelID,'-', ...
                                    opts.optionsID);
            else
                sessionDirName = opts.sessionDirName;
            end

            % Create Log
            sessionParentDir = opts.sessionParentDir;
            obj.session = Session.Session( ...
                                "name",sessionName, ...
                                "dirName",sessionDirName, ...
                                "parentDir",sessionParentDir, ...
                                "overwriteFiles", opts.overwriteSessionFiles);
            obj.session.setupLog(opts.LOGMODE);
            
            
            % Create input objects
            obj.session.log.diaryOn();
            try
                obj.model = Model(opts.modelFilePath,opts.modelID);
                obj.options = Options(opts.optionsFilePath,opts.optionsID);
                obj.geometry = Geometry(opts.geometryFilePath, opts.geometryID);
                obj.bc = BoundaryConditions(opts.bcFilePath, obj.geometry);

                % If obstructions are specified, add them to obs
                if ~isempty(opts.obsIDs) && ~isempty(opts.obsFilePath)
                    for idx = 1:length(opts.obsIDs)
                        obsID = opts.obsIDs{idx};
                        obs(idx) = Obstruction(opts.obsFilePath, obsID);
                    end
                    obj.obs = obs;
                end
            catch ME
                getReport(ME);
                obj.session.log.diaryOn();
                rethrow(ME)
            end
            obj.session.log.diaryOff();

        end

        function inputSets = SplitByAxialPosition(obj, axialPositions)
            % SPLITBYAXIALPOSITION Splits an inputSet by axialPositions
            %
            %   This function allows a simulation to be split up into
            %   multiple segments. The motivation for this function is the
            %   development of the Obstruction Solver, where a flow
            %   obstruction divides a flow into three segments:
            %       1) Pre-obstruction, 
            %       2) Along-obstruction, and
            %       3) Post-obstruction (wake)
            %
            %   Currently, this function assumes uniform axial node
            %   distribution. This assumption can pose an issue later on,
            %   if/when non-uniform node distributions are implemented.

            % (0) Checks
            % TODO: If first position ~= 1, error
            % TODO: If last position ~= totalLength, error


            % (1) Determine the split location node indicies
            
            % Total length of the geometry
            totalLength = obj.geometry.LENGTH;

            % Total number of walls;
            totalNumWalls = obj.geometry.NWALL;
            
            % Total number of nodes (NNODES)
            totalNumNodes = obj.model.NNODES;

            % Total number of segments
            totalNumSegments = length(axialPositions)-1;

            % Determine node indicies that correspond to axialPositions
            % Remember, 1-based indexing
            axialNodeIndicies = round(totalNumNodes/totalLength.*axialPositions)+1;

            % If two consecutive indicies are the same, increment the
            % latter one
            for i=1:totalNumSegments
                if( axialNodeIndicies(i) == axialNodeIndicies(i+1) )
                    % Increment latter if not last node
                    if axialNodeIndicies(i+1) < totalNumNodes
                        axialNodeIndicies(i+1) = axialNodeIndicies(i+1) + 1;
                    end
                end
            end


            % (2) Build pairs of start/end indicies for each segment
            segmentBoundIndicies = [axialNodeIndicies(1:end-1); axialNodeIndicies(2:end-1), axialNodeIndicies(end)];

            % number of nodes in eaech segment
            segmentNumNodes = diff(segmentBoundIndicies(:,:))+1;

            % (3) Determine interpolated boundary conditions using
            % MixtureSolver
            % NOTE: This might not be a great idea, but for now we assume
            % all solvers use the implementation of BC in the Mixture
            % solver.

            % Create and implicitly initialize Mixture solver instance
            mix = Solvers.Mixture.MixtureSolver(obj);

            % Determine segment lengths
            nodeLength = mix.DZ;
            segmentLengths = nodeLength .* (segmentNumNodes-1);

            % mix BCs
            mixBC = mix.boundaryConditions;

            % Segment boundary conditions to segments
            mixBCFields = fieldnames(mixBC);
            
            % For each segment
            for i=1:totalNumSegments
                
                % Make direct copy
                segmentBC = mixBC;

                % Split WPOWER and HFLUX by node id
                fns = {'WPOWER', 'HFLUX'};
                for j=1:numel(fns)
                    
                    % fieldname
                    fn = fns{j};
                
                    % Retrieve field value
                    mixBCFieldValue = mixBC.(fn);
                    % Subset of field value
                    mixBCFieldValue = mixBCFieldValue( ...
                                        linspace(segmentBoundIndicies(1,i),segmentBoundIndicies(2,i),segmentNumNodes(i)),:,:);
                    % Store subset
                    segmentBC.(fn) = mixBCFieldValue;
                    
                end

                % Field POWER should be updated to reflect total 
                % power in segment. 
                segmentBC.POWER = segmentBC.POWER.*0+sum(segmentBC.HFLUX(:,:,10).*nodeLength.*mix.inputSet.geometry.PERIM, 'all');

                % Convert boundary conditions to Inputs.BoundaryConditions
                % format
                for tIdx = 1:length(segmentBC.TIME)
                    bcStep(tIdx) = Inputs.BoundaryConditions();
                    bcStep(tIdx).setProperty("TIME", segmentBC.TIME(tIdx,1));
                    bcStep(tIdx).setProperty("PRESSURE", segmentBC.PRESSURE(tIdx,1));
                    bcStep(tIdx).setProperty("HIN", segmentBC.HIN(tIdx,1));
                    bcStep(tIdx).setProperty("MFLOW", segmentBC.MFLOW(tIdx,1));
                    bcStep(tIdx).setProperty("POWER", segmentBC.POWER(tIdx,1));
                    bcStep(tIdx).setProperty("WMESH",  nodeLength.*ones(1,segmentNumNodes(i)));
                    % if all elements of WPOWER is 0, set to 1.
                    if all(segmentBC.WPOWER(:,:,tIdx) == 0, 'all')
                        segmentBC.WPOWER(:,:,tIdx) = 1;
                    end
                    bcStep(tIdx).setProperty("WPOWER",  segmentBC.WPOWER(:,:,tIdx));
                end

                % Save bcSteps
                bcSteps{i} = bcStep;

                % Save segmentBC (Unneeded?)
                segmentBCs(i) = segmentBC;

            end
            

            % (4) Create copy of inputSet and modify contents for each
            % segment
            for i=1:totalNumSegments

                % Copy inputSet
                inputSet = obj.copy();

                % Modify number of nodes
                inputSet.model.setProperty('NNODES', diff(segmentBoundIndicies(:,i))+1);

                % Modify geometry length
                % NOTE: Geometry.LENGTH was set to be mustBeNonnegative to
                % accomodate the potential for 0-length nodes. This may
                % cause issues with secondary property calculations. An
                % alternative solution may be needed for segments with no
                % lengths
                inputSet.geometry.setProperty("LENGTH", segmentLengths(i));

                % Modify boundary conditions
                % TODO: Translate segmentBC back to inputset format
                inputSet.bc = bcSteps{i};

                % Save inputSet
                inputSets(i) = inputSet;

            end

        end

        function obj = SplitBySpanPosition(obj, wallIdx, spanPositions)
        % SPLITBYSPANPOSITION Splits an inputSet by axialPositions
        %
        %   This function allows a simulation to be split up into
        %   multiple tracks.
        % Assume one obstruction which simply splits single segment to two
        % solution tracks: 
        %
        %   1) Non-wake region
        %   2) Wake region

            % TODO: Check spanPosition vector size
    
            % (1) Determine split widths
            
            % Total perim of specified wall
            totalPerim = obj.geometry.PERIM(wallIdx);
    
            % Wake track perim
            wakeTrackPerim = spanPositions(3)-spanPositions(2);
            
            % Non-wake perim 
            nonWakeTrackPerim = spanPositions(4)-wakeTrackPerim;
    
            % non-track:total perim ratio
            perimRatio = nonWakeTrackPerim./totalPerim;
    
            % TODO: check if total track width == totalWidth
    
            % (2) Modify original inputset
            
            % Update geom perims
            trackPerims = [nonWakeTrackPerim, wakeTrackPerim];
            originalPerims = obj.geometry.PERIM;
            obj.geometry.setProperty("PERIM", [originalPerims(1:wallIdx-1) trackPerims originalPerims(wallIdx+1:end)]);
    
            % Update boundary conditions (WPOWER)

            
            % All BC time steps
            BCs = obj.bc;
    
            % For each BC step in time
            for tIdx = 1:length(BCs)
                
                % Retreive WPOWER, and make into NWMESHxNWALL
                currWPOWERs = reshape(BCs(tIdx).WPOWER, length(BCs(tIdx).WPOWER), []);
    
                % Copy of wall to be modified
                targetWallWPOWER = currWPOWERs(:,wallIdx);
    
                % duplicate targetWallWPOWER
                targetWallWPOWERs = repmat(targetWallWPOWER,1,2);
    
                % Apply perim ratio
                targetWallWPOWERs = targetWallWPOWERs.*[perimRatio 1-perimRatio];
    
                % Insert new WPOWERs
                newWPOWERs = [currWPOWERs(:,1:wallIdx-1) targetWallWPOWERs currWPOWERs(:,wallIdx+1:end)];
                
                % setWPOWER in BC
                obj.bc(tIdx).setProperty('WPOWER', newWPOWERs);
    
            end

        end

        function objCopy = copy(obj)
            
            objCopy = Inputs.InputSet();
            objCopy.model = copy(obj.model);
            objCopy.options = copy(obj.options);
            objCopy.geometry = copy(obj.geometry);
            objCopy.bc = copy(obj.bc);
            objCopy.obs = copy(obj.obs);

            % Use the same session handle
            objCopy.session = obj.session;

        end
    end

    
end

