classdef Entity < matlab.mixin.Copyable
    properties (SetAccess = private)
        name = ''
        pattern = ''
        mandatory = false
        directory = ''
        map_func = '';
        dtype = ''
        files = struct('file', {}, 'value', {})
        regex = ''
    end
    
    methods
        
        function disp(obj)
            fprintf('Class: Entity | Name: %s | Directory: %s | Pattern: %s | Files: %d', obj.name, obj.directory, obj.pattern, numel(obj.files));
            if ~isempty(obj.dtype)
                fprintf(' | Type: %s\n', obj.dtype);
            else
                fprintf('\n');
            end
        end
        
        % Constructor
        function obj = Entity(input_struct)
            % input_struct with at least 'name' as field
            
            p = inputParser;
            p.StructExpand = true;
            
            dtypes = {'int', 'single', 'double', 'logical', 'char'};
            addParameter(p, 'name', '', @(x)validateattributes(x,{'char'},{'nonempty'}));
            addParameter(p, 'pattern', '', @(x)validateattributes(x,{'char'},{'nonempty'}));
            addParameter(p, 'mandatory', false, @(x)validateattributes(x,{'logical', 'numeric'},{'nonempty'}));
            addParameter(p, 'directory', '', @(x)validateattributes(x,{'char'},{'nonempty'}));
            addParameter(p, 'map_func', '', @(x)validateattributes(x,{'function_handle'},{'nonempty'}));
            addParameter(p, 'dtype', '', @(x) any(validatestring(x,dtypes)));
            addParameter(p, 'missing_value', ''); %, @(x)validateattributes(x,{},{'nonempty'}));
            parse(p, input_struct);
            
            if isempty(p.Results.name)
                error('Name must be provided');
            end
            
            obj.name = p.Results.name;
            obj.pattern = p.Results.pattern;
            obj.mandatory = logical(p.Results.mandatory);
            obj.directory = p.Results.directory;
            obj.map_func = p.Results.map_func;
            obj.dtype = p.Results.dtype;
            obj.regex = obj.pattern; % same name as in pybids
        end
        
        function val = match_file(obj, f)
            val = [];
            if ~isempty(obj.map_func)
                val = obj.map_func(f);
            else
                tokens = regexp(f.fpath, obj.regex, 'tokens');

                if ~isempty(tokens)
                    % take the first token
                    val = tokens{1}{1};
                end
            end
            val = obj.astype(val);
        end
        
        function add_file(obj, filename, value)
            idx = find(strcmp({obj.files.file}, filename));
            if isempty(idx)
                idx = length(obj.files)+1;
            end
            obj.files(idx).file = filename;
            obj.files(idx).value = value;
        end            
            
        function values = unique(obj)
            values = unique_mixed({obj.files.value});
        end
        
        function cnt = count(obj, varargin)
            p = inputParser;
            addOptional(p, 'files', false, @(x)validateattributes(x,{'logical', 'numeric'},{'nonempty'}));
            parse(p, varargin{:});
            obj.files = p.Results.files;
            
            if obj.files
                cnt = numel(obj.files);
            else
                cnt = numel(obj.unique());
            end
        end
        
    %end
    %methods (Access=private)
        
        function val = astype(obj, val)
            if ~isempty(val) && ~isempty(obj.dtype)
                val = castto(val, obj.dtype);
            end
        end
    end
end