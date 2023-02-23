classdef Input
    %INPUT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods
        function obj = Input()
            %MODEL Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj;
        end
    end

    methods(Static)
        
        function inputStruct = readInputFile(filePath)
            %READINPUTFILE input file parser
            % This function accepts the uniform input file format of this
            % class and converts it to a struct array for each entry. 
            arguments
                filePath {isfile}
            end
            
            % Try to open and read the file
            try
                fileContent = readlines(filePath);
            catch ME
                % TODO: decide whether to just set the output to -1 or
                % throw and error. The error message needs improvement.
                % inputStruct = -1;
                error('Reading file at %s resulted in an error.', filepath);
            end
            
            % Regex expression for parsing the input file.
            entryExpr = {};
            %   Capture the "END" tag
            entryExpr{1} = '(?<PARAMETER>(end|END))';
            %   Capture comments, indicated by '#' symbol
            entryExpr{2} = '#(?<PARAMETER>.*)';
            %   Capture PARAMETER ! DESCRIPTION > VALUE
            entryExpr{3} = '(?<PARAMETER>[A-Z0-9]+)?[\s]*\!{1}[\s]*(?<DESC>[\w\s\-\[\]]*)?>{1}[\s]*(?<VALUE>[\w\f\s\-\.]*)?';
            entryExpr = strjoin(entryExpr,'|');
            
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


            % 
        end

    end
end

