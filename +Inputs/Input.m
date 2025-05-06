classdef (HandleCompatible) Input < dynamicprops & matlab.mixin.Copyable
    %INPUT Su
    %   Detailed explanation goes here

    properties (SetAccess=protected)
        extra       = struct.empty()
        warnings    = struct.empty()
    end
    
    methods
        function obj = Input(inputFilePath, key, val)
            %INPUT Parse inputFile to construct this class
            %   Detailed explanation goes here
            arguments
                inputFilePath {mustBeText}                                  = ""
                key {mustBeText}                                            = ""
                val {mustBeA(val,["string","char","double"])}               = ""
            end
            
            % Return if empty inputFilePath
            if strlength(inputFilePath) == 0
                return
            end

            % Add temporary property inputStruct
            obj.addprop('inputStruct');

            % Parse and store the input file
            obj.inputStruct = obj.readInputFile(inputFilePath);

            % 

            % limit input struct to entry specified by {key, val} pair
            if strlength(key) > 1
                
                % Find 1st matching entry with key having val
                if isnumeric(val)
                    entryIdx = find([obj.inputStruct.(key)] == val, 1);
                else
                    entryIdx = find(string({obj.inputStruct.(key)}) == val, 1);
                end

                % Throw error if none was found
                if isempty(entryIdx)
                    throw( ...
                        MException( ...
                            sprintf('INPUT:entryNotFoundError'), ...
                            'Entry with key %s=%s was not found', key, num2str(val)) ...
                    );
                else
                    obj.inputStruct = obj.inputStruct(entryIdx);
                end
            end
        end

        function [isSpecifiedEntry, defaultUsed, defaultValue] = validateInputEntry(obj, objPropname, opts)
            % VALIDATEINPUTENTRY 
            %   Description
            arguments
                obj
                objPropname
                opts.id = ''
            end
            
            % Warning setup
            previousWarnStruct = warning('query');
            warning('off','backtrace')
            objClassName = strrep(upper(class(obj)),'.','_');

            % Default false isValidEntry and defaultUsed
            isSpecifiedEntry = false;
            defaultUsed = false;
            defaultValue = [];

            % List of properties set in inputStruct 
            inputStructFieldnames = fieldnames(obj.inputStruct);

            % objProp is a required property if it doesn't have a default
            % value, or if default value is empty
            propProps = findprop(obj,objPropname);
            propIsRequired = ~propProps.HasDefault || isempty(propProps.DefaultValue);
            
            % Find propname in inputStructFieldnames
            if find(strcmp(inputStructFieldnames, objPropname))
                
                % Variable is specified
                isSpecifiedEntry = true;

                % assign field entry as inputField
                inputField = obj.inputStruct.(objPropname);

                % Is inputField value empty
                inputFieldIsEmpty = isempty(inputField) || (isstring(inputField) && strlength(inputField)==0);

                % Check requirements
                if propIsRequired && inputFieldIsEmpty
                % Throw exception if property is required, yet a
                % value was not specified
                    throwAsCaller( ...
                        MException( ...
                            sprintf('%s:missingRequiredValueError',objClassName), ...
                            'Required entry with key %s for %s is empty', objPropname, opts.id) ...
                    );
                elseif ~propIsRequired && inputFieldIsEmpty
                % Provide warning if property is optional and a
                % value was not specified. Use default instead.
                    % warning('%s: Value for entry %s was not set. Default value used: %s', ...
                    %     objClassName, objPropname, Inputs.Input.defaultValueString(propProps.DefaultValue));
                    defaultUsed = true;
                    defaultValue = propProps.DefaultValue;
                else
                    % Assign specified non-empty value to property
                    % Let MATLAB throw errors from parameter validation
                end
            else
                if propIsRequired
                % A required property was not specified
                throwAsCaller( ...
                        MException( ...
                            sprintf('%s:missingRequiredValueError',objClassName), ...
                            'Required entry with key %s for %s is missing', objPropname, opts.id) ...
                    );
                else
                % An optional property was not specified
                    
                    % warning('%s: Value for optional property %s was not set. Default value used: %s', ...
                    %     objClassName, objPropname, Inputs.Input.defaultValueString(propProps.DefaultValue));
                    defaultUsed = true;
                    defaultValue = propProps.DefaultValue;
                end
            end

            % Reset warning state
            warning(previousWarnStruct);
        end
        
        function objPropnames = listInputProperties(obj, opts)
            %LISTINPUTPROPERTIES 
            % List of protected obj property names
            arguments
                obj
                opts.exclude = {}   % Cell array of properties to exclude from the list
            end
            objPropnames = string({metaclass(obj).PropertyList.Name}.');
            objPropnames = objPropnames( ...
                cellfun(@(setaccess) isa(setaccess, 'meta.class'), [metaclass(obj).PropertyList.SetAccess]) ...
                & ~strcmp(string({metaclass(obj).PropertyList.Name}),'SOLVERDEPENDENTPROPS')...
                & ~strcmp(string({metaclass(obj).PropertyList.Name}),'extra')...
                & ~strcmp(string({metaclass(obj).PropertyList.Name}),'warnings'));

            % Exclude properties specified in opts.exclude
            for idx = 1:length(opts.exclude)
                objPropnames = objPropnames( ...
                    ~strcmpi(objPropnames,opts.exclude{idx}));
            end

        end

        function [varargout] = defaultValueUsedReport(obj, propNames, propValues)
        %DEFAULTVALUEUSEDREPORT Report of properties in which the default
        %values were used.
        %
        %
        arguments
            obj
            propNames   string
            propValues  cell
        end

            % TODO: Check propNames and propValues size matches
    
            % Init. string array
            rep = "";
    
            % Title line
            rep(end+1) = sprintf("Default values were used for the following variables in %s:", upper(class(obj)));

            % Max propname length
            propName_max = max(arrayfun(@(n) strlength(n),propNames));
    
            % For each propName, add entry to rep
            for i = 1:length(propNames)
                
                % Get propname, propvalue
                propName = propNames(i);
                propValue = propValues{i};
    
                % Identify propValue type format
                if isstring(propValue) || ischar(propValue)
                    %propValue = propValue;
                elseif isnumeric(propValue)
                    % Check if is scalar
                    if isscalar(propValue)
                        addBrackets = false;
                    else
                        addBrackets = true;
                    end
                    % Convert to string and add brackets
                    % NOTE: 2D+ arrays will be reshaped...
                    propValue = sprintf('%f ', propValue);
                    if addBrackets
                        propValue = sprintf('[%s]', propValue);
                    end
                elseif isa(propValue, "function_handle")
                    % Convert to string
                    propValue = sprintf('%s ', func2str(propValue));

                else
                    % TODO: Throw error or handle it somehow
                end
    
                % Create string
                rep(end+1) = sprintf(sprintf('%%-%ds: %%s ',propName_max+2), propName, propValue);
    
            end
    
            
            if nargout == 1
                % return if nargout == 1
                varargout(1) = {rep};
            elseif nargout == 0
                % print if no outputs requested
                fprintf('%s\n', rep)
            else
                % TODO: Throw error for requesting too many outputs
            end

        end

        function out = applySolverDependentProperties(obj, solverName)
            
            % Make copy of obj to avoid overwriting the dependency
            % specification
            out = copy(obj);

            % Convert solvername to upper
            solverName = upper(solverName);

            % Check if SOLVERDEPENDENTPROPS is a property
            %   simply exit if not
            if ~isprop(out, 'SOLVERDEPENDENTPROPS')
                return;
            end

            % Iterate through each field in SOLVERDEPENDENTPROPS
            depPropNames = fields(out.SOLVERDEPENDENTPROPS);
            for i = length(depPropNames)
                % Name of property
                depPropName = depPropNames{i};
                
                % Details of the solver dependency
                depProp = out.SOLVERDEPENDENTPROPS.(depPropName);
                
                % Retrieve flag that shows property is solver dependent
                dep_flag = depProp.DEP_FLAG;
                
                % See if property is set to be dependent
                if out.(depPropName) == dep_flag
                    
                    % Find solver in depProp details
                    if isfield(depProp, solverName)
                        % Identify detail type
                        if isenum(depProp.(solverName)) || out.(depPropName)
                            % Simply replace an enum or numeric value
                            out.(depPropName) = depProp.(solverName);
                        elseif isstruct(depProp.(solverName))
                            % Expect a field called value
                             out.(depPropName) = depProp.(solverName).value;
                             % TODO: Handle further instructions. For
                             % example, models that require different
                             % coefficients can be specified and applied
                             % here. This case is not tested.
                        end
                    % Apply default if
                    elseif isfield(depProp, 'DEFAULT')
                        out.(depPropName) = depProp.DEFAULT;
                    end
                end
            end
    
        end

    end
    
    methods(Static, Access=protected)
        
        function inputStruct = readInputFile(filePath)
            %READINPUTFILE input file parser
            % This function accepts the uniform input file format and 
            % converts it to a struct array for each entry. 
            arguments
                filePath {mustBeFile}
            end
            
            % Try to open and read the file
            try
                fileContent = readlines(filePath);
                [~,fileName,fileExt] = fileparts(filePath);
            catch ME
                % TODO: decide whether to just set the output to -1 or
                % throw an error. The error message needs improvement.
                % inputStruct = -1;
                ME_local = MException( ...
                             sprintf('INPUT:openFileError'), ...
                             'Reading file at %s resulted in an error.', filePath ...
                             );
                rethrow(addCause(ME, ME_local));
            end
            
            % Choose parser depending on file extenstion
            switch lower(fileExt)
                case '.json'
                    % Read the json file
                    inputStructJson = jsondecode(strjoin(fileContent));
                    
                    % jsondecode outputs a cell array of structs when extra
                    % or missing fields are present
                    if iscell(inputStructJson)
                        
                        % Compile the full array of fieldnames
                        fullFieldnames = {};
                        
                        % 
                        for i = 1:length(inputStructJson)
                            fullFieldnames = unique([fullFieldnames; fieldnames(inputStructJson{i})]);
                        end

                        % Convert each cell to a struct with the
                        % fullFieldNames
                        inputStruct(length(inputStructJson),1) = ...
                            cell2struct(cell(length(fullFieldnames),1),fullFieldnames,1);
                        for i = 1:length(inputStructJson)
                            for j = 1:length(fullFieldnames)
                                fullFieldname = fullFieldnames{j};
                                if isfield(inputStructJson{i},fullFieldname)
                                    inputStruct(i).(fullFieldname) = inputStructJson{i}.(fullFieldname);
                                end
                            end
                        end
                        
                    else
                        inputStruct = inputStructJson;
                    end

                case '.inp'

                    % Regex expression for parsing the input file.
                    entryExpr = {};
                    %   Capture the "END" tag
                    entryExpr{1} = '(?<PARAMETER>(end|END))';
                    %   Capture comments, indicated by '#' symbol
                    entryExpr{2} = '(?<PARAMETER>(#|\/\/|%).*)';
                    %   Capture PARAMETER ! DESCRIPTION > VALUE
                    entryExpr{3} = '(?<PARAMETER>[\w]+)?\s*\!\s*(?<DESC>.*?)>\s*(?<VALUE>[@><=&|()\*\[\],\w\s\+\-\.]*)?';
                    %   Join parts together and remove spaces (use \s instead).
                    entryExpr = strrep(strjoin(entryExpr,'|'),' ','');
                    
                    % Parse file using regex
                    fileStruct = regexpi(fileContent, sprintf('%s',entryExpr),"names");

                    % Initalize output struct
                    inputStruct = struct();
                    inputStructEntriesCount = 0;
                    inputStructEntryFields = string().empty();
        
                    % Loops through each row of fileStruct
                    for fileLineIdx = 1:length(fileStruct)
        
                        % Index into fileStruct
                        fileRow = fileStruct{fileLineIdx};
                        
                        % Skip if fileRow is empty
                        if isempty(fileRow)
                            continue;
                        end
        
                        % Process fileRow depending on PARAMETER value
                        switch fileRow.PARAMETER
                            case "END"
                                % Increment inputStructEntries
                                inputStructEntriesCount = inputStructEntriesCount + 1;
                                % Reset EntryFields
                                inputStructEntryFields = inputStructEntryFields.empty();
        
                            case {"COMMENT", '#' ,'//', '%'}
                                % Ignore comments for now
        
                            otherwise
                                % if parameter was already specified, throw
                                % error
                                if ~isempty(inputStructEntryFields) && ismember(fileRow.PARAMETER,inputStructEntryFields)
                                    throw( ...
                                        MException( ...
                                            sprintf('INPUT:duplicateEntryError'), ...
                                            'A duplicate of parameter %s was detected on line %d in file %s%s', ...
                                                fileRow.PARAMETER, fileLineIdx, fileName, fileExt) ...
                                    ); 
                                else
                                    inputStructEntryFields(end+1) = fileRow.PARAMETER;
                                end
                                % Throw warning if field value is empty
                                valueToSave = '';
                                if strlength(fileRow.VALUE) == 0
                                    % TODO throw warning for empty field value
                                    valueToSave = '';
                                else
                                    % Look for numeric values
                                    numericValues = textscan(fileRow.VALUE, '%f');
                                    numericValues = numericValues{1};
                                    if isempty(numericValues)
                                        valueToSave = fileRow.VALUE;
                                    else
                                        valueToSave = numericValues;
                                    end
                                end
                                % Save entry values
                                inputStruct(inputStructEntriesCount+1).(fileRow.PARAMETER) = valueToSave;
                        end
        
                    end
                otherwise
                    % Unknown or unspecified file extensions are not
                    % supported.
                    throw( ...
                        MException( ...
                            sprintf('INPUT:fileTypeError'), ...
                            'Input file with extension %s is not supported.', fileExt) ...
                    );
            end

            

        end
        
        

        function defVal = defaultValueString(defVal)
        %DEFAULTVALUESTRING Convert numeric default value to string
            if isnumeric(defVal)
                defVal = num2str(defVal);
            elseif islogical(defVal)
                defVal = string(defVal);
            end
        end

        
    end

    methods(Static)
        function writeInputFile(filePathName, fidMode, varargin)
            
            if mod(length(varargin),2) == 1
                error('An even number of inputs after filePath is required.');
            end

            % Gather calling class property names
            callStack = dbstack();
            [~,callClass] = fileparts(callStack(2).file);
            callClass = ['Inputs.' callClass];
            callClass = eval(['?' callClass]);
            descriptionDict = containers.Map( ...
                                {callClass.PropertyList.Name}, ...
                                {callClass.PropertyList.Description});

            % Create file to write
            fid = fopen(filePathName,fidMode);
            if fid == -1
                error('An error occurred while creating %s', filePathName);
            end

            for idx = 1:length(varargin)/2
                
                % Odd idx refer to the names
                varIdx = 2*idx-1;

                % Force name to be upper case
                varName = upper(string(varargin{varIdx}));
                
                % Force value to be a string
                varValue = varargin{varIdx+1};
                if isnumeric(varValue)
                    varValue = num2str(reshape(varValue,1,[]),'%.11f ');
                elseif islogical(varValue)
                    varValue = string(varValue);
                else
                    varValue = upper(varValue);
                end
                
                % Determine action given varName
                switch varName

                    % NOTE: Other options can be specified here

                    otherwise
                        
                        % Find varName in descriptionDict
                        if descriptionDict.isKey(varName)
                            description = descriptionDict(varName);
                        else
                            description = '';
                        end

                        % Print line in file
                        fprintf(fid, '%-11s! %-63s> %s\n', varName, description, varValue);
                end
            end

            % Print
            fprintf(fid,'END\n\n');

            % Close file
            fclose(fid);

        end

        function validateFunctionHandleInput(handleString)
            arguments
                handleString    {mustBeTextScalar}
            end

            restrictedKeywords = ["eval", "feval", "system", "fopen", "delete", "!", ...
                                     "load", "save", "assignin", "clear", "global", "import", ...
                                     "java", "py\.", "web", "dir", "cd", "run", "builtin", ...
                                     "uigetfile", "input", "persistent", "classdef", "meta\."];
            
            for restrictedKeyword = restrictedKeywords
                if ~isempty(regexp(handleString, restrictedKeyword, 'once', 'ignorecase'))
                    error("Unsafe content detected: '%s' in function handle: %s", restrictedKeyword, handleString);
                end
            end

        end

        function jsonText = convert2JSON(inputFilePath)
            
            % Read inputFilePath
            inputStruct = Inputs.Input.readInputFile(inputFilePath);
            
            % convert inputObj.inputStruct to json format
            jsonText = jsonencode(inputStruct,"PrettyPrint",true);
        end
        
    end

end

