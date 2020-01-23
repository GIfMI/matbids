classdef MetadataIndex < handle
    % A simple dict-based index for key/value pairs in JSON metadata.
    %
    % Args:
    %     layout (BIDSLayout): The BIDSLayout instance to index.
    
    properties (SetAccess = private)
        layout
        key_index = struct
        file_index = []
    end
    
    methods
        function disp(obj)
            
        end
        
        % Constructor
        function obj = MetadataIndex(layout)
            p = inputParser;
            addRequired(p, 'layout', @(x)validateattributes(x,{'BIDSLayout'},{'nonempty'}));
            parse(p, layout);
            
            obj.layout = p.Results.layout;
            %obj.key_index = struct;
            %obj.file_index = [];
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
         
            if ischar(f)
                f = obj.layout.get_file(f);
            end
           
            % with cell
            %file_index_fnames = cellfun(@(x) x.bfile.fpath,  obj.file_index, 'uni', false);
            
            % with vector
            % file_index_fnames = arrayfun(@(x) x.bfile.fpath,  obj.file_index, 'uni', false);
            
            % with extra fpath caching in file_index
            if ~isempty(obj.file_index)
                file_index_fnames = {obj.file_index.fpath};
            else
                file_index_fnames = {};
            end
            
            [fileidx, ib] = ismember(file_index_fnames, {f.fpath});
            
            if any(fileidx) && ~ overwrite
                return
            end
            
            % Skip files without suffixes
            if ~isfield(f.entities, 'suffix')
                return
            end

            md = obj.get_metadata_(f.fpath);
            fns = fieldnames(md);
            
            for fnidx = 1:numel(fns)
                md_key = fns{fnidx};
                md_val = md.(md_key);
                
                if ~isfield(obj.key_index, md_key)
                    obj.key_index.(md_key) = {};
                end
                
                obj.key_index.(md_key){end+1}.bfile =  f;
                obj.key_index.(md_key){end}.md_val =  md_val;
                obj.key_index.(md_key);
                
                 % without internal caching
%                  updated_file_index_fnames = cellfun(@(x) x.bfile.fpath,  obj.file_index, 'uni', false);
%                  [idx_, ib] = ismember(updated_file_index_fnames, {f.fpath});

                 % without internal caching
                 %file_index_fnames = cellfun(@(x) x.bfile.fpath,  obj.file_index, 'uni', false);
                 [idx_, ib] = ismember(file_index_fnames, {f.fpath});

                  % with internal caching
                  if ~isempty(obj.file_index)
                      file_index_fnames = {obj.file_index.fpath};
                  else
                      file_index_fnames = {};
                  end
                 %file_index_fnames = {obj.file_index.fpath};
                 [idx_, ib] = ismember(file_index_fnames, {f.fpath});
                 
                 
                if ~any(idx_)
                    % not in file index
                    str.bfile = f;
                    str.md.(md_key) = md_val;
                    % for faster lookup
                    str.fpath =  f.fpath;
                    
                    obj.file_index =  [obj.file_index str];
                    
%                     obj.file_index{end+1}.bfile = f;
%                     obj.file_index{end}.md.(md_key) = md_val;
                    % for internal caching
                    
                    
                    %file_index_fnames{end+1} = f.fpath;
                else
                    % found in file index, update md_key
                    %obj.file_index{idx_}.md.(md_key) = md_val;
                    obj.file_index(idx_).md.(md_key) = md_val;
                end
            end
         end
         
%          function index_file(obj, f, varargin)
%         %function index_file(obj, f, overwrite)
%             % Index metadata for the specified file.
%             %
%             % Args:
%             % 	f (BIDSFile, str): A BIDSFile or path to an indexed file.
%             %   	overwrite (bool): If True, forces reindexing of the file even if
%             %       an entry already exists.
%             p = inputParser;
%             addRequired(p, 'f',@(x)validateattributes(x,{'BIDSFile', 'char'},{'nonempty'}));
%             addParameter(p, 'overwrite', false, @(x)validateattributes(x,{'logical', 'double'},{}));
%             
%             parse(p, f, varargin{:});
%             
%             f = p.Results.f;
%             overwrite = p.Results.overwrite;
%          
% %             if ~isempty(varargin)
% %                 overwrite = logical(varargin{1});
% %             end
%             
%             %disp('=============================================================================================')
%             if ischar(f)
%                 f = obj.layout.get_file(f);
%             end
%            
%            % f_hash = string2hash(f.fpath);
%            %    hash_array = cellfun(@(x) x.bfile.hash, obj.file_index);
%            %    idx_ = find(hash_array==f_hash, 1);
%                
%            % idx_ = find(cellfun(@(x) strcmp(f.fpath, x.bfile.fpath) , obj.file_index));
% 
%            % fastest
%             file_index_fnames = cellfun(@(x) x.bfile.fpath,  obj.file_index, 'uni', false);
%             [fileidx, ib] = ismember(file_index_fnames, {f.fpath});
% 
%             if any(fileidx) && ~ overwrite
% %            if ~isempty(idx_) && ~ overwrite
%                %             if obj.file_index.isKey(f.fpath) && ~overwrite
%                 return
%             end
%             
%             % Skip files without suffixes
%             if ~isfield(f.entities, 'suffix')
%                 return
%             end
% 
%             md = obj.get_metadata_(f.fpath);
%             fns = fieldnames(md);
%             
% %             for fn_ = {fns{:}}
% %                 md_key = fn_{1};
%             for idx = 1:numel(fns)
%                 md_key = fns{idx};
%                 md_val = md.(md_key);
%                 
%                 if ~isfield(obj.key_index, md_key)
%                     obj.key_index.(md_key) = {};
%                 end
%                 
%                 obj.key_index.(md_key){end+1}.bfile =  f;
%                 %obj.key_index.(md_key){end}.fpath =  f.fpath;
%                 obj.key_index.(md_key){end}.md_val =  md_val;
% 
%                 obj.key_index.(md_key);
%                 % hash_array = cellfun(@(x) x.bfile.hash,obj.file_index);
%                 % idx_ = find(hash_array == f.hash);
%                 %idx_ = find(cellfun(@(x) strcmp(f.fpath, x.bfile.fpath) , obj.file_index));
%                 
%                  updated_file_index_fnames = cellfun(@(x) x.bfile.fpath,  obj.file_index, 'uni', false);
%                  [idx_, ib] = ismember(updated_file_index_fnames, {f.fpath});
% 
%                 if ~any(idx_)
%                 %if isempty(idx_)
%                     obj.file_index{end+1}.bfile = f;
%                     %obj.file_index{end}.fpath = f.fpath;
%                     obj.file_index{end}.md.(md_key) = md_val;
%                 else
%                     obj.file_index{idx_}.md.(md_key) = md_val;
%                 end
%             end
%         end
        
        
%  
        
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
                'extension', 'json');
            results = struct;
            if isempty(potential_jsons)
                return;
            end
            
            % The calling function must take care of absolute paths
            
            for json_file_path_= potential_jsons(end:-1:1)
                json_file_path = json_file_path_{1};
                
                if exist(json_file_path, 'file') == 2
                    param_struct = jsonread(json_file_path);
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
                files = cellfun(@(x) x.fname  , obj.layout.files, 'uni', false);
            end
            
            % Index metadata for any previously unseen files
%             times = zeros(1, numel(files))
%             i=1;

%             for f_=files
%                 f = f_{1};
            for idx=1:numel(files)
                f = files{idx};
                %fprintf('Indexing metadata of %s \n', f);
                obj.index_file(f);
            end
%             %  Make it a row vector to index, stupid Matlab behavior
%             if numel(all_keys) >1
%                 all_keys = {all_keys{:}};
%             end
            
            % Get file intersection of all kwargs keys--this is fast
            filesets = {};
%             for key_=all_keys
%                 key = key_{1};
            for idx = 1:numel(all_keys)
                key = all_keys{idx};
                %cellfun(@(x) x.fpath obj.key_index.(key), 'uni', false);
                if isempty(filesets)
                    obj.key_index
                    filesets = cellfun(@(x) x.bfile.fpath, obj.key_index.(key), 'uni', false);
                    %filesets = cellfun(@(x) x.fpath, obj.key_index.(key), 'uni', false);
                else
                    filesets = intersect(filesets, cellfun(@(x) x.fpath, obj.key_index.(key), 'uni', false));
                end
            end
            matches = filesets; % same as pybids
            
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
%                idx_ = find(cellfun(@(x) strcmp(f, x.fpath) , obj.file_index));

                % with vector
                idx_ = find(arrayfun(@(x) strcmp(f, x.bfile.fpath) , obj.file_index));
                f_val = obj.file_index(idx_).md.(key);
                
                % with cell
                %idx_ = find(cellfun(@(x) strcmp(f, x.bfile.fpath) , obj.file_index));
                %f_val = obj.file_index{idx_}.md.(key);

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
                fprintf(' File: %s | key: %s | val: %s | fileval: %s', ff, key, mat2str(val), mat2str(f_val))

                if m
                    fprintf(' | ++++');
                end
                fprintf('\n')
            end
            
            % Serially check matches against each pattern, with early termination
            fns = fieldnames(kwargs);
%             for fn_={fns{:}}
%                 k = fn_{1};
            for idx=1:numel(fns)
                k = fns{idx};
                val = kwargs.(k);
                fprintf('Checking %s = %s\n', k, mat2str(val))
                idx_ = cellfun(@(x) check_matches(x, k, val), matches);
                matches = matches(idx_);
                if isempty(matches)
                     return;
                end
            end
            
            cellfun(@ disp, matches)
        end
    end
end