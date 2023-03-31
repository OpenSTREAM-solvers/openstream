classdef (Abstract,HandleCompatible)  IndexableInput
    %INDEXABLEINPUT Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function varargout = subsref(obj,s)
           switch s(1).type
              case '.'
                 [varargout{1:nargout}] = builtin('subsref',obj,s);
              case '()'
                 out = obj.obj2struct(s(1).subs{1});
                 if length(s) == 1
                    % Implement obj(indices)
                    varargout{1} = out;
                 elseif length(s) == 2 && strcmp(s(2).type,'.')
                    % Implement obj(ind).PropertyName
                    if ismethod(obj, s(2).subs)
                        out = obj.(s(2).subs);
                        [varargout{1:nargout}] = builtin('subsref',out,s(1));
                    % Implement obj(indices).PropertyName(indices)
                    else
                        [varargout{1:nargout}] = out.(s(2).subs);
                    end
                 elseif length(s) == 3 && strcmp(s(2).type,'.') && strcmp(s(3).type,'()')
                    % Implement obj(indices).MethodName(parameters)
                    if ismethod(obj, s(2).subs)
                        out = obj.(s(2).subs)(s(3).subs{:});
                        [varargout{1:nargout}] = builtin('subsref',out,s(1));
                    
                    % Implement obj(indices).PropertyName(indices)
                    else
                        [varargout{1:nargout}] = out.(s(2).subs)(s(3).subs{:});
                    end
                    ...
                 else
                    % Use built-in for any other expression
                    [varargout{1:nargout}] = builtin('subsref',obj,s);
                 end
              otherwise
                 error('Not a valid indexing expression')
           end
        end

        function n = numArgumentsFromSubscript(obj,s,indexingContext)
           if indexingContext == matlab.mixin.util.IndexingContext.Expression
              n = 1;
           else
              n = length(s(1).subs);
           end
        end
   
    end

    methods (Access=private)

        function out = obj2struct(obj, idx, fieldNames)
            arguments
                obj
                idx (:,1) {isinteger} = 1:size(obj)
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
                    fieldValue = fieldValue(idx,:);
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

