classdef Entity < matlab.mixin.Copyable
    %    properties (SetAccess = private)
    properties
        name = ''
        pattern = ''
        mandatory = false
        directory = ''
        map_func = '';
        dtype = ''
        %files = struct('file', {}, 'value', {}, 'hash', {})
        %files %= struct('file', [], 'value', {})
        files = {}
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
            %             obj.files.file = {};
            %             obj.files.value = {};
            %obj.files = cell(
        end
        
        function val = match_file(obj, f)
            val = [];
            if isempty(obj.map_func)
                tokens = regexp(f.fpath, obj.regex, 'tokens');
                
                if ~isempty(tokens)
                    % take the first token
                    val = tokens{1}{1};
                end
            else
                val = obj.map_func(f);
            end
            %val = obj.astype(val);
        end
        
        
        %         function add_file(obj, bfile, value)
        %             %cellfun(@(x) x.fpath, obj.files.file, 'uni', false);
        %
        %             idx = find(ismember(cellfun(@(x) x.fpath, obj.files.file, 'uni', false), bfile.fpath));
        %
        %             if ~any(idx)
        %                 idx = length(obj.files.file)+1;
        %             end
        %
        %             obj.files.file{idx} = bfile;
        %             obj.files.value{idx} = value;
        %         end
        
        
        function add_file(obj, bfile, value)
            
            %disp(['--- ' , obj.name, '---------------------------'])
            % Not very good, a new
            
            if isempty(obj.files)
                obj.files = {bfile, value};
            else
                %idx = (cellfun(@(x) x.fpath, obj.files.file, 'uni', false), bfile.fpath));
                
                idx = cellfun(@(x) strcmp(x.fpath, bfile.fpath), obj.files(:,1));
                
                % idx = arrayfun(@(x) strcmp(x.fpath, bfile.fpath), obj.files(:,1));
                
                
                %                idx = arrayfun(@(x) isequal(x, bfile), obj.files(:,1));
                if ~any(idx)
                    obj.files(end+1, :) = {bfile, value};
                else
                    obj.files{idx, 2} = value;
                end
            end
        end
        
        
        
        function add_file__(obj, bfile, value)
            
            %disp(['--- ' , obj.name, '---------------------------'])
            % Not very good, a new

            if isempty(obj.files)
                obj.files = {bfile, value};
            else
               idx = arrayfun(@(x) isequal(x, bfile), obj.files(:,1));
                if ~any(idx)
                    obj.files(end+1, :) = {bfile, value};
                else
                    obj.files{idx, 2} = value;
                end
            end
        end
        
        %         function add_file(obj, bfile, value)
        %
        %             idx = arrayfun(@(x) x == bfile, [obj.files.file]);
        %
        %             if ~any(idx)
        %                 idx = length(obj.files)+1;
        %             end
        %
        %             obj.files(idx).file = bfile;
        %             obj.files(idx).value = value;
        %         end
        
        
        %         function add_file(obj, filename, value)
        %             %idx = find(strcmp({obj.files.file}, filename));
        %             idx = find(ismember({obj.files.file}, filename));
        %
        %             % fastest but will be deprecated
        %             %idx = (strmatch({obj.files.file}, filename, 'exact'));
        %
        %             if isempty(idx)
        %                 idx = length(obj.files)+1;
        %             end
        %
        %             obj.files(idx).file = filename;
        %             obj.files(idx).value = value;
        %             % obj.files(idx).hash = string2hash(filename);
        %         end
        %
        %
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