classdef MetadataIndex < handle
    % A simple struct and list based index for key/value pairs in JSON metadata.
    %
    % Args:
    %     layout (BIDSLayout): The BIDSLayout instance to index.
    
    properties (SetAccess = private)
        layout
        key_index = struct
        file_index = {};
        file_index_fnames = {}; %internal caching of fnames
        json_index = {};
        json_index_fnames = {}; %internal caching of jsons
    end
    
    methods
        function disp(obj)
            fprintf('Class: MetadataIndex | Files: %d | Entities: %d\n', ...
                numel(obj.file_index), numel(obj.key_index));
        end
        
        % Constructor
        function obj = MetadataIndex(layout)
            p = inputParser;
            addRequired(p, 'layout', @(x)validateattributes(x,{'BIDSLayout'},{'nonempty'}));
            parse(p, layout);
            
            obj.layout = p.Results.layout;
        end
        function index_file(obj, f, varargin)
            %function index_file(obj, f, overwrite)
            % Index metadata for the specified file.
            %
            % Args:
            % 	f (BIDSFile, str): A BIDSFile or path to an indexed file.
            %   	overwrite (bool): If True, forces reindexing of the file even if
            %       an entry already exists.
            p = inputParser;
            addRequired(p, 'f',@(x)validateattributes(x,{'BIDSFile', 'char'},{'nonempty'}));
            addParameter(p, 'overwrite', false, @(x)validateattributes(x,{'logical', 'double'},{}));
            
            parse(p, f, varargin{:});
            
            f = p.Results.f;
            overwrite = p.Results.overwrite;
            
            % Get the BIDSFile object
            if ischar(f)
                f = obj.layout.get_file(f);
            end
            
            % check if already indexed

            [fileidx_, ~] = ismember(obj.file_index_fnames, f.fpath);
            
            if any(fileidx_) && ~ overwrite
                 disp('already indexed')
                return
            end
            
            % Skip files without suffixes
            if ~isfield(f.entities, 'suffix')
                return
            end
            
            % This should be a unique index
            fileidx = find(fileidx_);
            
            md = obj.get_metadata_(f.fpath);
            fns = fieldnames(md);
            
            for fnidx = 1:numel(fns)
                md_key = fns{fnidx};
                md_val = md.(md_key);
  
                %{
                if ~isfield(obj.key_index, md_key)
                    obj.key_index.(md_key) = struct;
                    idx = 1;
                else
                    idx = numel(obj.key_index.(md_key)) + 1;
                end
                
                obj.key_index.(md_key)(idx).bfile =  f;
                obj.key_index.(md_key)(idx).fpath =  f.fpath;
                obj.key_index.(md_key)(idx).md_val =  md_val;
                
                %}
                
                % a little bit faster
                %
                if ~isfield(obj.key_index, md_key)
                    obj.key_index.(md_key) = [];
                end
                
                % create a seperate variable as the struct function expands
                % input cells to create an array
                addstruct.fpath = f.fpath;
                addstruct.bfile = f;
                addstruct.md_val = md_val;

                obj.key_index.(md_key) =  [obj.key_index.(md_key), addstruct];
                %}
                if isempty(fileidx)
                    fileidx = numel(obj.file_index)+1;
                    str.bfile = f;
                    str.md.(md_key) = md_val;
                    
                    obj.file_index{fileidx} =  str;
                    obj.file_index_fnames{fileidx} = f.fpath;
                    
                else
                    % found in file index, update md_key
                    obj.file_index{fileidx}.md.(md_key) = md_val;
                end
            end
        end
        
      
        
        function results = get_metadata_(obj, fpath, varargin)
            p = inputParser;
            %p.KeepUnmatched = true;
            addRequired(p, 'fpath',@(x)validateattributes(x,{'char'},{'nonempty'}));
            
            addParameter(p, 'return_type', 'file', @(x)ischar(validatestring(x,valid_types)));
            addParameter(p, 'strict', true, @(x)validateattributes(x,{'logical', 'double'},{}));
            addParameter(p, 'all_', false, @(x)validateattributes(x,{'logical', 'double'},{}));
            addParameter(p, 'ignore_strict_entities', {}, @(x)validateattributes(x,{'char', 'cell'},{}));
            addParameter(p, 'full_search', false, @(x)validateattributes(x,{'logical', 'double'},{}));
            
            parse(p, fpath, varargin{:});
            %kwargs = p.Unmatched;
            %kwargs = namedargs2cell(p.Unmatched);
            %             kwargs = reshape([fieldnames(kwargs) struct2cell(kwargs)]',2*numel(fieldnames(kwargs)), []);
            %             kwargs = {kwargs{:}};
            
            potential_jsons = obj.layout.get_nearest(fpath, ...
                'return', 'file', ...
                'all_', true, ...
                'ignore_strict_entities', {'suffix'}, ...
                'extension', 'json', ...
                'absolute_paths', true);
            results = struct;
            
            if isempty(potential_jsons)
                return;
            end
            

            for json_file_path_= potential_jsons(end:-1:1)
                json_file_path = json_file_path_{1};

                % Make path absolute to be able to load (deal with
                % absolute_paths = false
                % Adds a bit of overhead but is crucial
                % json_file_path = path_join(obj.layout.root, json_file_path);
                
                 json_file_path_full = json_file_path;
                 
% % % %                 if ~isabs(json_file_path)
% % % %                     json_file_path_full = fullfile(obj.layout.root, json_file_path);
% % % %                 else
% % % %                     json_file_path_full = json_file_path;
% % % %                 end
                
                if exist(json_file_path_full, 'file') == 2
                    % ADDED: caching of json data to avoid multiple
                    % jsonread call
                    % Seems that for a limited amount of json files the
                    % overhead of the caching is equal to the repeated
                    % loading of json files
                    
                    % check if already indexed
                    % fastest with internal and logical indexing
                    [fileidx, ~] = ismember(obj.json_index_fnames, json_file_path);
                    if ~any(fileidx)
                        fileidx = [fileidx true];
                        obj.json_index{fileidx}.fpath = json_file_path;
                        obj.json_index{fileidx}.json = jsonread(json_file_path_full);
                        obj.json_index_fnames{fileidx} = json_file_path;
                    end
                    
                    param_struct = obj.json_index{fileidx}.json;
                    results = update_struct(param_struct, results);
                end
            end
        end
        
        function matches = search(obj, varargin)
            % Search files in the layout by metadata fields.
            %
            % Args:
            % 	files (list): Optional list of names of files to search. If None,
            %   	all files in the layout are scanned.
            %   defined_fields (list): Optional list of names of fields that must
            %       be defined in the JSON sidecar in order to consider the file a
            %       match, but which don't need to match any particular value.
            %   kwargs: Optional keyword arguments defining search constraints;
            %       keys are names of metadata fields, and values are the values
            %       to match those fields against (e.g., SliceTiming=0.017) would
            %       return all files that have a SliceTiming value of 0.071 in
            %       metadata.
            %
            % Returns: A list of filenames that match all constraints.

            p = inputParser;
            p.KeepUnmatched = true;
            addParameter(p, 'files', {}, @(x)validateattributes(x,{'cell', 'char'},{}));
            addParameter(p, 'defined_fields', {}, @(x)validateattributes(x,{'cell', 'char'},{}));
            
            parse(p, varargin{:});
            kwargs = p.Unmatched;
            
            defined_fields = cellify(p.Results.defined_fields);
            
            all_keys = union(defined_fields, fieldnames(kwargs));
            
            if isempty(all_keys)
                error('At least one field to search on must be passed.');
            end
            
            files = cellify(p.Results.files);
            
            
            % If no list of files is passed, use all files in layout
            if isempty(files)
                files = cellfun(@(x) x.fpath  , obj.layout.files, 'uni', false);
            end

            
            % Index metadata for any previously unseen files
            
            t= [];
            
            for idx=1:numel(files)
                f = files{idx};
                tic
                %fprintf('Indexing metadata of %s \n', f);
                disp('index_file SEARCH');
                obj.index_file(f);
                t(end+1) = toc;
                %disp(t(end));
            end
            disp(fprintf('total = %f | mean = %f | std = %f | min = %f | std = %f', sum(t), mean(t), std(t), min(t), max(t)));
            
            % Get file intersection of all kwargs keys--this is fast
            filesets = {};
            
            for idx = 1:numel(all_keys)
                key = all_keys{idx};
                if isempty(filesets)
                    filesets = {obj.key_index.(key).fpath};
                else
                    filesets = intersect(filesets, {obj.key_index.(key).fpath});
                end
            end
            
            matches = filesets; % same as pybids
            
%             if ~obj.layout.absolute_paths
%                 files = cellfun(@(x) relativepath(x, obj.layout.root), files, 'uni', false);
%             end
%             

            if ~isempty(files)
                matches = intersect(matches, files);
            end
            
            if isempty(matches)
                matches = {};
                return;
            end
            
            % Deep comparison: comparing integers and strings results in
            % internal conversion
            function m = check_matches(f, key, val)
                [fileidx, ~] = ismember(obj.file_index_fnames, f);
                f_val = obj.file_index{fileidx}.md.(key);
                
                [~, ff] = fileparts(f);
                if ischar(val) && ~isempty(strfind(val, '*'))
                    % regular expression
                    val = strrep(sprintf('^%s$',val), '*', '.*');
                    m = regexp(mat2str(f_val), val, 'match');
                    m = ~isempty(m);
                elseif isnumeric(val)
                    %key_val = num2str(mat2str(val));
                    if ischar(f_val)
                        f_val = str2double(f_val);
                    end
                    
                    m = isequal(f_val, val);
                elseif ischar(val)
                    if isnumeric(f_val)
                        f_val = mat2str(f_val);
                    end
                    m = strcmp(val, f_val);
                else
                    error('combination does not fit');
                end
%                 fprintf(' File: %s | key: %s | val: %s | fileval: %s', ff, key, mat2str(val), mat2str(f_val))
%                 
%                 if m
%                     fprintf(' | ++++');
%                 end
%                 fprintf('\n')
            end
            
            % Serially check matches against each pattern, with early termination
            fns = fieldnames(kwargs);
            
            for idx=1:numel(fns)
                
                k = fns{idx};
                val = kwargs.(k);
                idx_ = cellfun(@(x) check_matches(x, k, val), matches);
                matches = matches(idx_);
                if isempty(matches)
                    return;
                end
            end
        end
    end
end