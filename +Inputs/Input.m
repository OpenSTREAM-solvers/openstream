classdef (HandleCompatible) Input < dynamicprops
    %INPUT Su
    %   Detailed explanation goes here
    
    properties
        %inputStruct struct                                                  % structure that stores input file contents            
    end
    
    methods
        function obj = Input(inputFilePath, key, val)
            %INPUT Parse inputFile to construct this class
            %   Detailed explanation goes here
            arguments
                inputFilePath {mustBeText}
                key {mustBeText}                                            = ""
                val {mustBeA(val,["string","char","double"])}               = ""
            end
            
            % Add temporary property inputStruct
            obj.addprop('inputStruct');

            % Parse and store the input file
            obj.inputStruct = obj.readInputFile(inputFilePath);

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

        function isValidEntry = validateInputEntry(obj, objPropname, opts)
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

            % Default false isValidEntry
            isValidEntry = false;

            % List of properties set in inputStruct 
            inputStructFieldnames = fieldnames(obj.inputStruct);

            % objProp is a required property if it doesn't have a default
            % value, or if default value is empty
            propProps = findprop(obj,objPropname);
            propIsRequired = ~propProps.HasDefault || isempty(propProps.DefaultValue);
            
            % Find propname in inputStructFieldnames
            if find(strcmp(inputStructFieldnames, objPropname))
                
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
                            sprintf('INPUT:missingRequiredValueError'), ...
                            'Required entry with key %s for %s is empty', objPropname, opts.id) ...
                    );
                elseif ~propIsRequired && inputFieldIsEmpty
                % Provide warning if property is optional and a
                % value was not specified. Use default instead.
                    warning('INPUT: Value for entry %s was not set. Default value used: %s', ...
                        objPropname, num2str(propProps.DefaultValue));
                else
                    % Assign specified non-empty value to property
                    % Let MATLAB throw errors from parameter validation
                    isValidEntry = true;
                end
            else
                if propIsRequired
                % A required property was not specified
                throwAsCaller( ...
                        MException( ...
                            sprintf('INPUT:missingRequiredValueError'), ...
                            'Required entry with key %s for %s is missing', objPropname, opts.id) ...
                    );
                else
                % An optional property was not specified
                    warning('INPUT: Value for optional property %s was not set. Default value used: %s', ...
                        objPropname, num2str(propProps.DefaultValue));
                end
            end

            % Reset warning state
            warning(previousWarnStruct);
        end
        
    end

    methods(Static)
        
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
                [~,~,fileExt] = fileparts(filePath);
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
                    %TODO: Implement JSON parser
                    inputStruct = jsondecode(strjoin(fileContent));

                case '.inp'

                    % Regex expression for parsing the input file.
                    entryExpr = {};
                    %   Capture the "END" tag
                    entryExpr{1} = '(?<PARAMETER>(end|END))';
                    %   Capture comments, indicated by '#' symbol
                    entryExpr{2} = '(?<PARAMETER>(#|\/\/)).*';
                    %   Capture PARAMETER ! DESCRIPTION > VALUE
                    entryExpr{3} = '(?<PARAMETER>[\w]+)?[\s]* \!{1}[\s]*(?<DESC>.*)? >{1}[\s]*(?<VALUE>[\w\f\s\-\.]*)?';
                    %   Join parts together and remove spaces (use \s instead).
                    entryExpr = strrep(strjoin(entryExpr,'|'),' ','');
                    
                    % Parse file using regex
                    fileStruct = regexpi(fileContent, sprintf('%s',entryExpr),"names");

                    % Initalize output struct
                    inputStruct = struct();
                    inputStructEntries = 0;
        
                    % Loops through each row of fileStruct
                    for idx = 1:length(fileStruct)
        
                        % Index into fileStruct
                        fileRow = fileStruct{idx};
                        
                        % Skip if fileRow is empty
                        if isempty(fileRow)
                            continue;
                        end
        
                        % Process fileRow depending on PARAMETER value
                        switch fileRow.PARAMETER
                            case "END"
                                % Increment inputStructEntries
                                inputStructEntries = inputStructEntries + 1;
        
                            case {"COMMENT", '#' ,'//'}
                                % Ignore comments for now
        
                            otherwise
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
                                inputStruct(inputStructEntries+1).(fileRow.PARAMETER) = valueToSave;
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

        function jsonText = convert2JSON(inputFilePath)
            
%             import Input.*
            % Read inputFilePath
            inputStruct = Inputs.Input.readInputFile(inputFilePath);
            
            % convert inputObj.inputStruct to json format
            jsonText = jsonencode(inputStruct,"PrettyPrint",true);
        end
        
    end
end

