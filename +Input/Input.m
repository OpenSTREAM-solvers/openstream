classdef (Abstract) Input < dynamicprops
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
                key {mustBeText}                      = ""
                val {mustBeA(val,["string","char","double"])}                 = ""
            end
            
            % Add temporary property inputStruct
            inputStructH = obj.addprop('inputStruct');

            % Parse and store the input file
            obj.inputStruct = obj.readInputFile(inputFilePath);

            % limit input struct to entry specified by {key, val} pair
            if strlength(key) > 1
                
                % Find 1st matching entry with key having val
                entryIdx = find([obj.inputStruct.(key)] == val, 1);

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
                    throw( ...
                        MException( ...
                            sprintf('INPUT:fileTypeError'), ...
                            'Input file with extension %s is not supported.', fileExt) ...
                    );

                case '.inp'

                    % Regex expression for parsing the input file.
                    entryExpr = {};
                    %   Capture the "END" tag
                    entryExpr{1} = '(?<PARAMETER>(end|END))';
                    %   Capture comments, indicated by '#' symbol
                    entryExpr{2} = '#(?<PARAMETER>.*)';
                    %   Capture PARAMETER ! DESCRIPTION > VALUE
                    entryExpr{3} = '(?<PARAMETER>[\w]+)?[\s]* \!{1}[\s]*(?<DESC>[\w\s\-\[\]]*)? >{1}[\s]*(?<VALUE>[\w\f\s\-\.]*)?';
                    %   Join parts together and remove spaces (use \s instead).
                    entryExpr = strrep(strjoin(entryExpr,'|'),' ','');
                    
                    % Parse file using regex
                    fileStruct = regexpi(fileContent, sprintf('%s',entryExpr),"names");
                otherwise
                    % Unknown or unspecified file extensions are not
                    % supported.
                    throw( ...
                        MException( ...
                            sprintf('INPUT:fileTypeError'), ...
                            'Input file with extension %s is not supported.', fileExt) ...
                    );
            end

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

                    case "COMMENT"
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

        end


    end
end

