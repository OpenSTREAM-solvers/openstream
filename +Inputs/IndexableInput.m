classdef (Abstract,HandleCompatible) IndexableInput < matlab.mixin.indexing.RedefinesParen 
    %INDEXABLEINPUT Su
    %   Detailed explanation goes here
    
    methods (Abstract)
        size
    end
    methods (Access=public)
        function out = cat(dim,varargin)
            throw( ...
                MException('IndexableInputError:UnsupportedOperation', ...
                           'Concatenating this type is not supported.') ...
                 );
        end
    end

    methods (Access=protected)
        function varargout = parenReference(obj, indexOp)
             
             out = obj.obj2struct(indexOp(1).Indices{1});
             if isscalar(indexOp)
                % All fields
                varargout{1} = out;
                return
            end

            [varargout{1:nargout}] = out.(indexOp(2:end));
        end

        function obj = parenAssign(obj,indexOp,varargin)
            throw( ...
                MException('IndexableInputError:UnsupportedOperation', ...
                           'Assigning values for this type is not supported.') ...
                 );
        end

        function n = parenListLength(obj,indexOp,ctx)
            if numel(indexOp) <= 2
                n = 1;
                return;
            end
            containedObj = obj.(indexOp(1:2));
            n = listLength(containedObj,indexOp(3:end),ctx);
        end

        function obj = parenDelete(obj,indexOp)
            throw( ...
                MException('IndexableInputError:UnsupportedOperation', ...
                           'Assigning values for this type is not supported.') ...
                 );
        end
    end

    methods (Access=private)

        function out = obj2struct(obj, idx, fieldNames)
            arguments
                obj
                idx {isinteger} = 1:size(obj)
                fieldNames {iscell} = {}
            end

            % all fields if fields is empty
            if isempty(fieldNames)
                fieldNames = string({metaclass(obj).PropertyList.Name}.');
                fieldNames = fieldNames( ...
                            strcmp( ...
                                string({metaclass(obj).PropertyList.SetAccess}), ...
                                'immutable' ...
                            ));
        
            end
            out = struct();
            for i=1:length(fieldNames)
                fieldName = fieldNames{i};
                fieldValue = obj.(fieldName);
                if ~isscalar(fieldValue)
                    fieldValue = fieldValue(idx);
                end
                out = setfield(out, fieldName, fieldValue);
            end
        end

    end
    methods (Static, Access=public)
        function obj = empty()
            throw( ...
                MException('IndexableInputError:UnsupportedOperation', ...
                           'Assigning values for this type is not supported.') ...
                 );
        end
    end
end

