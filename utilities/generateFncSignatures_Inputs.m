function jsonSignature = generateFncSignatures_Inputs(metaInputClass)
% GENERATEFNCSIGNATURES_INPUTS A utility function for generating the code
% suggestion json file (i.e. resourece/functionSignature.json) for the
% `writeInputFile` function in Inputs.Input subclasses. 
%
% There are two ways to use GENERATEFNCSIGNATURES_INPUTS. The first way is
% to simply provide a metaclass object of a class that inherits
% Inputs.Input, such as ?Inputs.Model. `?` is the metaclass operator. The
% output is the jsonencoded string of the provided Inputs.Input class
%
% The other way of using GENERATEFNCSIGNATURES_INPUTS is to provide a list
% of metaclass objects that inherit Inputs.Input. 
%
%   jsonStr = ...
%       generateFncSignatures_Inputs( ...
%           [?Inputs.Model, ?Inputs.Options, ?Inputs.BoundaryConditions, ?Inputs.Geometry]);
%
% This creates the full content of the functionSignatures.json file, and
% can be copied to the clipboard using:
%
%   clipboard('copy',jsonStr)
%
% And then pasted and overwrite the contents of
% resources/functionSignatures.json .
%

%   TODO: If more function signatures need to be created in the future,
%   this function should be incorporated into a class.

    % if metaInputClass is not a scalar, recursively call each inputClass,
    % then compile the results together.
    if ~isscalar(metaInputClass)
        
        results = "";

        % Add schema
        schema_json = jsonencode(struct('schemaVersion','1.0.0'));
        schema_json = strrep(schema_json, '{"schemaVersion', '"_schemaVersion');
        schema_json = strrep(schema_json, '"}', sprintf('",\n\n'));
        results = results + schema_json;

        % Call each class
        for idx = 1:numel(metaInputClass)
            inputClass=metaInputClass(idx);
            results = results + generateFncSignatures_Inputs(inputClass);
            if idx < numel(metaInputClass)
                results = results + "," + newline;
            else
                results = results + newline;
            end
            
        end

        % Add curly brackets
        results = sprintf("{\n") + results + sprintf("}");
        
        % Assign resulting json string to `jsonSignature`
        jsonSignature = results;
        
        % End here.
        return
    end

    
    % Get list of properties
    propList = metaInputClass.PropertyList;
    
    % Get list of user-facing properties
    propNames = eval(metaInputClass.Name).listInputProperties();
    propStructs = struct('name', {}, 'kind', {}, 'type', {}, 'purpose', {});

    % Add `filePathName`
    % {"name":"filePathName",  "kind":"required", "type":[["string","scalar"],["char"]],"purpose":"File pathname"}
    propStruct.name = 'filePathName';
    propStruct.kind = 'required';
    propStruct.type = {["string", "scalar"], ["char"]};
    propStruct.purpose = "File pathname";
    propStructs(end+1) = propStruct;
    
    % Iterate through each propName
    for idx = 1:numel(propNames)
    
        % Index
        propName = propNames(idx);
    
        % Find propName in propList.Name
        propIdx = find(string({propList.Name}) == propName);
    
        % TODO: make sure 1 is found
    
        % Get property validation and description
        prop = struct('list',{propList(propIdx)});
        prop.name = propName;
        prop.purpose = prop.list.Description;
        prop.hasDefault = prop.list.HasDefault;
        prop.class = prop.list.Validation.Class;
        % List types, ie validations
        %   All entries can be scalar strings or chars
        prop.type = {["string", "scalar"], ["char"]};
    
        %   ID can be a positive integer
        if prop.name == "ID"
            prop.type{end+1} = ["integer", "positive", "scalar"];
        
        %   InputEnums enumerators
        elseif ~isempty(prop.class.ContainingPackage) ...
            && prop.class.ContainingPackage.Name == "InputEnums"
            prop.type{end+1} = [sprintf("choices=string(enumeration('%s'))", prop.class.Name)];
    
        %   Logicals
        elseif prop.class.Name == "logical"
            prop.type{end+1} = ["logical", "choices={'TRUE','FALSE'}","scalar"];
        %   Doubles
        elseif prop.class.Name == "double"
            numericType = string.empty();
            % Integer vs numeric
            if isInCellArray("mustBeInteger", prop.list.Validation.ValidatorFunctions)
                numericType(end+1) = "integer";
            else
                numericType(end+1) = "numeric";
            end
            
            % Positive only
            if isInCellArray("mustBePositive", prop.list.Validation.ValidatorFunctions)
                numericType(end+1) = "positive";
            end

            % Scalar/empty, or specified size
            if isInCellArray("mustBeScalarOrEmpty", prop.list.Validation.ValidatorFunctions)
                numericType(end+1) = "scalar";

            elseif ~isempty(prop.list.Validation.Size)
                size_type_str = "size=";
                for size_idx = 1:numel(prop.list.Validation.Size)
                    dim_size = prop.list.Validation.Size(size_idx);
                    if isa(dim_size, 'meta.FixedDimension')
                        size_type_str = size_type_str + dim_size.Length;
                    elseif isa(dim_size, 'meta.UnrestrictedDimension')
                        size_type_str = size_type_str + ":";
                    end
                    if size_idx < numel(prop.list.Validation.Size)
                        size_type_str = size_type_str + ",";
                    end
                end
                numericType(end+1) = size_type_str;
            end
    
            % Addd numericType to type
            prop.type{end+1} = numericType;       
            
        end
        
        % Assemble propStruct
        propStruct.name = propName;
        if ismember(propName, ["filePathName", "ID"])
            propStruct.kind = "required";
        else
            propStruct.kind = "namevalue";
        end
        propStruct.type = prop.type;
        propStruct.purpose = prop.purpose;
        
        % Add propstruct to propStructs
        propStructs(end+1) = propStruct;
    
    end
    
    % Package the propStructs
    jsonSignature = sprintf('"%s":%s', sprintf('%s.writeInputFile', metaInputClass.Name),jsonencode(struct('inputs', propStructs),PrettyPrint=true));

    function res = isInCellArray(A,B)      
        res = cellfun(@(b) string(A)==func2str(b), B);
    end
    
end