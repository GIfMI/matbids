classdef BIDSLayout < handle
    % TODO:
    % implement ignore in constructor
    % implement force_index in constructor
    % input parameter checking eg sources = {BIDSLayout, cell}: cell array needs to be
    % checked for having BIDSLayout objects
    % check_path_matches_patterns in validate_file_ (not being used in pybids!) does not match the
    % implemented m file, needs checking, now just overridden
    
    % 	Represents a single directory or other logical grouping within a
    % BIDS project.
    %
    % Args:
    % path (str): The full path to the directory.
    % config (str, list): One or more names of built-in configurations
    % (e.g., 'bids' or 'derivatives') that specify the rules that apply
    % to this node.
    % root (BIDSNode): The node at the root of the tree the current node is
    % part of.
    % parent (BIDSNode): The parent of the current node.
    % force_index (bool): Whether or not to forcibly index every file below
    % this node, even if it fails standard BIDS validation.
    
    
    % properties (Constant)
    % default_ignore = {'code', 'stimuli', 'sourcedata', 'models',
    % 'derivatives', '^\.'}
    % end
    
    properties (SetAccess = private)
        root = ''
        validator_ = {}
        validate = true
        absolute_paths = true
        derivatives = struct
        description = struct
        sources = {}
        regex_search = false
        metadata_index
        config_filename = 'layout_config.json'
        entities = struct
        ignore = {}
        force_index = {}
        config = struct
        root_node = {}
    end
    
    properties
        nodes = {}
        files = {}
    end
    
    properties(Dependent)
    end
    
    methods
        function disp(obj)
            
            subjects = obj.get_entity('subject');
            n_subjects = numel(subjects);
            
            sessions = cellfun(@(x) obj.get_entity('session', 'subject', x), subjects, 'uni', false);
            n_sessions = sum(cellfun(@(x) numel(x), sessions));
            
            n_runs = 0;
            for i=1:numel(subjects)
                for j=1:numel(sessions{i})
                    n_runs = n_runs + numel(obj.get_entity('run', 'subject', subjects{i}, 'session', sessions{i}{j}));
                end
            end
            n_files = numel(obj.files);
            
            fprintf('Class: BIDSLayout | Subjects: %d | Sessions: %d | Runs: %d | Files: %d\n', ...
                n_subjects, n_sessions, n_runs, n_files);
        end
        
        function obj = BIDSLayout(root, varargin)
            p = inputParser;
            addRequired(p, 'root',@(x)validateattributes(x,{'char'},{'nonempty'}));
            addOptional(p, 'validate', true, @(x)validateattributes(x,{'logical', 'double'},{'nonempty'}));
            addOptional(p, 'index_associated', true, @(x)validateattributes(x,{'logical', 'double'},{'nonempty'}));
            addOptional(p, 'absolute_paths', true, @(x)validateattributes(x,{'logical', 'double'},{'nonempty'}));
            addOptional(p, 'derivatives', {}, @(x)validateattributes(x,{'logical', 'double', 'char', 'cell'},{}));
            addOptional(p, 'config', {}, @(x)validateattributes(x,{'cell', 'char'},{}));
            addOptional(p, 'sources', {}, @(x)validateattributes(x,{'cell', 'BIDSLayout'},{}));
            addOptional(p, 'ignore', {}, @(x)validateattributes(x,{'cell', 'char'},{}));
            addOptional(p, 'force_index', {}, @(x)validateattributes(x,{'cell', 'char'},{}));
            addOptional(p, 'config_filename', '', @(x)validateattributes(x,{'char'},{}));
            addOptional(p, 'regex_search', true, @(x)validateattributes(x,{'logical', 'double'},{'nonempty'}));
            
            parse(p, root, varargin{:});
            
            obj.root = p.Results.root;
            arg_index_associated = logical(p.Results.index_associated);
            %%obj.validator_ = BIDSValidator('index_associated', arg_index_associated);
            obj.validate = logical(p.Results.validate);
            obj.absolute_paths = logical(p.Results.absolute_paths);
            %obj.derivatives = {};
            obj.sources = cellify(p.Results.sources);
            obj.regex_search = logical(p.Results.regex_search);
            obj.metadata_index = MetadataIndex(obj);
            obj.config_filename = p.Results.config_filename;
            % obj.files = {};
            % obj.nodes = {};
            % obj.entities = {};
            arg_ignore = cellify(p.Results.ignore);
            %%obj.ignore = '[os.path.abspath(os.path.join(obj.root, patt)) if isinstance(patt, six.string_types) else patt for patt in listify(ignore or [])]';
            obj.force_index = cellify(p.Results.force_index);
            %%obj.force_index = '[os.path.abspath(os.path.join(obj.root, patt)) if isinstance(patt, six.string_types) else patt for patt in listify(force_index or [])]';
            
            % Do basic BIDS validation on root directory
            obj.validate_root_();
            
            % Initialize the BIDS validator and examine ignore/force_index args
            obj.setup_file_validator_();
            
            % Set up configs
            %obj.config = {};
            config = cellify(p.Results.config);
            if isempty(config)
                config = 'bids';
            end
            config = cellfun(@(cfg) Config.load(cfg), cellify(config), 'uni', false);
            config_names = cellfun(@(cfg) cfg.name, config, 'uni', false);
            obj.config = cell2struct(config, config_names, 2);
            obj.root_node = BIDSRootNode(obj.root, config, obj);
            
            % Consolidate entities into master list. Note: no conflicts occur b/c
            % multiple entries with the same name all point to the same instance.
            for node = {obj.nodes{:}}
                n = node{1};
                obj.entities = update_struct(obj.entities, n.available_entities);
            end
            
            % Add derivatives if any are found
            derivatives = p.Results.derivatives;
            
            if ~(isempty(derivatives) || (islogical(derivatives) && ~derivatives))
                
                %if ~isempty(derivatives)
                if islogical(derivatives)
                    if derivatives
                        derivatives = fullfile(obj.root, 'derivatives');
                    end
                end
                
                obj.add_derivatives(...
                    derivatives, ...
                    obj.validate,...
                    arg_index_associated,...
                    obj.absolute_paths, ...
                    [], ...
                    {},...
                    obj, ...
                    arg_ignore, ...
                    obj.force_index);
            end
        end
        
        function ent_vals = parse_file_entities(obj, filename, varargin)
            % Parse the passed filename for entity/value pairs.
            %
            % Args: filename (str): The filename to parse for entity values
            % scope (str, list): The scope of the search space. Indicates
            % which BIDSLayouts' entities to extract. See BIDSLayout
            % docstring for valid values. By default, extracts all entities
            % entities (list): An optional list of Entity instances to use
            % in extraction. If passed, the scope and config arguments are
            % ignored, and only the Entities in this list are used. config
            % (str, Config, list): One or more Config objects, or paths to
            % JSON config files on disk, containing the Entity definitions
            % to use in extraction. If passed, scope is ignored.
            % include_unmatched (bool): If True, unmatched entities are
            % included in the returned dict, with values set to None. If
            % False (default), unmatched entities are ignored.
            %
            % Returns: A dict, where keys are Entity names and values are
            % the values extracted from the filename.
            
            p = inputParser;
            addRequired(p, 'filename',@(x)validateattributes(x,{'char'},{'nonempty'}));
            addOptional(p, 'scope', 'all', @(x)validateattributes(x,{'char'},{'nonempty'}));
            addOptional(p, 'entities', {});
            % addOptional(p, 'entities', {}, @(x)validateattributes(x,{'cell'},{}));
            addOptional(p, 'config', {}, @(x)validateattributes(x,{'cell', 'Config', 'char'},{'nonempty'}));
            addOptional(p, 'include_unmatched', false, @(x)validateattributes(x,{'logical', 'double'},{'nonempty'}));
            
            parse(p, filename, varargin{:});
            
            entities = cellify(p.Results.entities);
            config = cellify(p.Results.config);
            include_unmatched = p.Results.include_unmatched;
            scope = p.Results.scope;
            
            % If either entities or config is specified, just pass through
            if isempty(entities) && isempty(config)
                layouts = obj.get_layouts_in_scope_(scope);
                for ly_ = layouts
                    ly = ly_{1};
                    config{end+1} = struct2cell(ly.config)';
                end
                config = cat(2, config{:});
            end
            
            % % % % addRequired(p, 'filename',@(x)validateattributes(x,{'char'},{'nonempty'}));
            % % % % addOptional(p, 'entities', {}, @(x)validateattributes(x,{'cell'},{}));
            % % % % addOptional(p, 'config', {}, @(x)validateattributes(x,{'cell', 'Config', 'char'},{}));
            % % % % addOptional(p, 'include_unmatched', false, @(x)validateattributes(x,{'logical', 'double'},{}));
            
            % % % % % ent_vals = parse_file_entities(filename, 'entities', entities, ...
            % % % % % 'config', config, ...
            % % % % % 'include_unmatched', include_unmatched);
            ent_vals = parse_file_entities(filename, entities, config, include_unmatched);
            
        end
        
        function add_derivatives(obj, fpath, varargin)
            p = inputParser;
            addRequired(p, 'fpath',@(x)validateattributes(x,{'char', 'cell'},{'nonempty'}));
            addOptional(p, 'validate', true, @(x)validateattributes(x,{'logical', 'double'},{'nonempty'}));
            addOptional(p, 'index_associated', true, @(x)validateattributes(x,{'logical', 'double'},{'nonempty'}));
            addOptional(p, 'absolute_paths', true, @(x)validateattributes(x,{'logical', 'double'},{'nonempty'}));
            addOptional(p, 'derivatives', {}, @(x)validateattributes(x,{'logical', 'double', 'char', 'cell'},{}));
            addOptional(p, 'config', {}, @(x)validateattributes(x,{'cell', 'char'},{}));
            addOptional(p, 'sources', {}, @(x)validateattributes(x,{'cell', 'BIDSLayout'},{}));
            addOptional(p, 'ignore', {}, @(x)validateattributes(x,{'cell', 'char'},{}));
            addOptional(p, 'force_index', {}, @(x)validateattributes(x,{'cell', 'char'},{}));
            
            parse(p, fpath, varargin{:});
            %kwargs = p.Results;
            
            fpath = cellify(p.Results.fpath);
            kwargs.validate = logical(p.Results.validate);
            kwargs.index_associated = logical(p.Results.index_associated);
            kwargs.absolute_paths = logical(p.Results.absolute_paths);
            kwargs.derivatives = p.Results.derivatives;
            kwargs.config = cellify(p.Results.config);
            kwargs.sources = cellify(p.Results.sources);
            kwargs.ignore = cellify(p.Results.ignore);
            %%ignore = '[os.path.abspath(os.path.join(obj.root, patt)) if isinstance(patt, six.string_types) else patt for patt in listify(ignore or [])]';
            kwargs.force_index = cellify(p.Results.force_index);
            %%force_index = '[os.path.abspath(os.path.join(obj.root, patt)) if isinstance(patt, six.string_types) else patt for patt in listify(force_index or [])]';
            
            deriv_dirs = {};
            
            % Collect all paths that contain a dataset_description.json
            function dd_found = check_for_description(fpath)
                dd = fullfile(fpath, 'dataset_description.json');
                %dok = isfile(dd); % MatlabR2017b
                dd_found = (exist(dd, 'file')==2);
            end
            
            for p_=fpath
                p = p_{1};
                % a bit different then in pybids
                if ~isabs(p)
                    p = fullfile(obj.root, p);
                end
                % Needs better checking for valid path and filenames
                %if isfolder(p) % Matlab 2017b
                if exist(p, 'dir')==7
                    % if a json file exist, assume to be in a pipeline
                    % folder
                    if check_for_description(p)
                        deriv_dirs{end+1}=p;
                    else
                        % in derivatives folder (checking must be
                        % implemented!), get subdirs of pipelines and
                        % process them
                        subdirs = list_dir(p);
                        for sd_={subdirs{:}}
                            sd = sd_{1};
                            sd = fullfile(p, sd);
                            if check_for_description(sd)
                                deriv_dirs{end+1} = sd;
                            end
                        end
                    end
                end
            end
            
            if isempty(deriv_dirs)
                warning(['Derivative indexing was enabled, but no valid ' ...
                    'derivatives datasets were found in any of the ' ...
                    'provided or default locations. Please make sure ' ...
                    'contain a "dataset_description.json" file, as ' ...
                    'all derivatives datasets you intend to index ' ...
                    'described in the BIDS-derivatives specification.']);
            end
            
            for deriv_ = deriv_dirs
                deriv = deriv_{1};
                dd = fullfile(deriv, 'dataset_description.json');
                description = loadjson(dd);
                
                if ~isfield(description, 'PipelineDescription')
                    error(['Every valid BIDS-derivatives dataset must ' ...
                        'have a PipelineDescription.Name field set ' ...
                        'inside dataset_description.json.']);
                end
                
                pipeline_name = description.PipelineDescription.Name;
                
                
                if any(strcmp(fieldnames(obj.derivatives), pipeline_name))
                    error(['Pipeline name %s has already been added ' ...
                        'to this BIDSLayout. Every added pipeline ' ...
                        'must have a unique name!'], pipeline_name)
                    
                end
                
                % Default config and sources values
                if isempty(kwargs.config)
                    kwargs.config = {'bids', 'derivatives'};
                end
                if isempty(kwargs.sources)
                    kwargs.sources = obj;
                end
                
                obj.derivatives.(pipeline_name) = BIDSLayout(deriv, kwargs);
            end
            
            % Consolidate all entities post-indexing. Note: no conflicts occur b/c
            % multiple entries with the same name all point to the same instance.
            derivs = fieldnames(obj.derivatives);
            derivs = {derivs{:}};
            for deriv_=derivs
                deriv = deriv_{1};
                obj.entities = update_struct(obj.entities, obj.derivatives.(deriv).entities);
            end
        end
        
        function bf = get_file(obj, filename, varargin)
            bf = {};
            % Returns the BIDSFile object with the specified path.
            %
            % Args:
            % filename (str): The path of the file to retrieve. Must be either
            % an absolute path, or relative to the root of this BIDSLayout.
            % scope (str, list): Scope of the search space. If passed, only
            % BIDSLayouts that match the specified scope will be
            % searched. See BIDSLayout docstring for valid values.
            %
            % Returns: A BIDSFile, or None if no match was found.
            p = inputParser;
            addRequired(p, 'filename',@(x)validateattributes(x,{'char', 'cell'},{'nonempty'}));
            addOptional(p, 'scope', 'all', @(x)validateattributes(x,{'cell', 'char'},{}));
            
            parse(p, filename, varargin{:});
            
            scope = cellify(p.Results.scope);
            
            layouts = obj.get_layouts_in_scope_(scope);
            filename = GetFullPath(path_join(obj.root, filename));
            for ly_ = layouts
                ly = ly_{1};
                %
                z=cell2mat(arrayfun(@(x) strcmp(filename, x.fname), cell2mat(ly.files), 'uni', false));
                idx = find(z);
                if ~isempty(idx)
                    bf = ly.files{idx}.bfile;
                    break
                end
                %
                % z=cell2mat(cellfun(@(x) strcmp(filename, x.fpath), ly.files, 'uni', false));
                % idx = find(z);
                % if ~isempty(idx)
                % bf = ly.files{idx};
                % break
                % end
            end
        end
        
        function results = get(obj, varargin)
            % disp('***********************')
            % function get(obj, return_type='object', target=None, extensions=None,
            % scope='all', regex_search=False, defined_fields=None,
            % absolute_paths=None,
            % **kwargs):
            
            % Retrieve files and/or metadata from the current Layout.
            %
            % Args:
            % return_type (str): Type of result to return. Valid values:
            %   'object' (default): return a list of matching BIDSFile objects.
            %   'file': return a list of matching filenames.
            %   'dir': return a list of directories.
            %   'id': return a list of unique IDs. Must be used together with
            %       a valid target.
            % target (str): Optional name of the target entity to get results for
            %       (only used if return_type is 'dir' or 'id').
            % extensions (str, list): One or more file extensions to filter on.
            %       BIDSFiles with any other extensions will be excluded.
            % scope (str, list): Scope of the search space. If passed, only
            %       nodes/directories that match the specified scope will be
            %       searched. Possible values include:
            %       'all' (default): search all available directories.
            %       'derivatives': search all derivatives directories
            %       'raw': search only BIDS-Raw directories
            %       <PipelineName>: the name of a BIDS-Derivatives pipeline
            % regex_search (bool or None): Whether to require exact matching
            %       (False) or regex search (True) when comparing the query string
            %       to each entity.
            % defined_fields (list): Optional list of names of metadata fields
            %       that must be defined in JSON sidecars in order to consider the
            %       file a match, but which don't need to match any particular
            %       value.
            % absolute_paths (bool): Optionally override the instance-wide option
            %       to report either absolute or relative (to the top of the
            %       dataset) paths. If None, will fall back on the value specified
            %       at BIDSLayout initialization.
            % kwargs (dict): Any optional key/values to filter the entities on.
            %       Keys are entity names, values are regexes to filter on. For
            %       example, passing filter={'subject': 'sub-[12]'} would return
            %       only files that match the first two subjects.
            %
            % Returns:
            % A list of BIDSFiles (default) or strings (see return_type).
            %
            % Notes:
            % As of pybids 0.7.0 some keywords have been changed. Namely: 'type'
            % becomes 'suffix', 'modality' becomes 'datatype', 'acq' becomes
            % 'acquisition' and 'mod' becomes 'modality'. Using the wrong version
            % could result in get() silently returning wrong or no results. See
            % the changelog for more details.
            valid_types = {'object', 'file', 'dir', 'id'};
            
            p = inputParser;
            p.KeepUnmatched = true;
            %addParameter(p,paramName,defaultVal,validationFcn)
            addParameter(p, 'return_type', 'object', @(x)ischar(validatestring(x,valid_types)));
            addParameter(p, 'target', {}, @(x)validateattributes(x,{'char'},{}));
            %addParameter(p, 'extensions', {}, @(x)validateattributes(x,{'cell', 'char'},{}));
            addParameter(p, 'scope', 'all', @(x)validateattributes(x,{'cell', 'char'},{}));
            addParameter(p, 'regex_search', false, @(x)validateattributes(x,{'logical', 'double'},{}));
            addParameter(p, 'defined_fields', {}, @(x)validateattributes(x,{'char', 'cell'},{}));
            addParameter(p, 'absolute_paths', obj.absolute_paths, @(x)validateattributes(x,{'logical', 'double'},{}));
            parse(p, varargin{:});
            
            return_type = p.Results.return_type;
            target = p.Results.target;
            %extensions = cellify(p.Results.extensions);
            scope = p.Results.scope;
            regex_search = p.Results.regex_search;
            defined_fields = cellify(p.Results.defined_fields);
            absolute_paths = p.Results.absolute_paths;
            
            kwargs = p.Unmatched;
            % Warn users still expecting pybids 0.6 behavior
            if isfield(kwargs, 'type')
                error(['As of matbids 0.1, the "type" argument has been', ...
                    ' replaced with "suffix".']);
            end
            layouts = obj.get_layouts_in_scope_(scope);
            
            % Create concatenated file, node, and entity lists
            % not taking into account duplicates as pybids, but files should be
            % unique
            files = {};
            entities = {};
            nodes = {};
            for l_= layouts
                l = l_{1};
                % add {:} to make sure is it a row
                files = cat(2, {files, l.files{:}});
                entities = update_struct(entities, l.entities);
                %entities = cat(2, {entities, l.entities{:}});
                nodes = cat(2, {nodes, l.nodes{:}});
            end
            % Remove empty files
            files = files(find(cellfun(@(x) ~isempty(x), files)));
            
            % Separate entity kwargs from metadata kwargs
            ent_kwargs = struct;
            md_kwargs = struct;
            
            kwarg_names = fieldnames(kwargs);
            for k_ = {kwarg_names{:}}
                k = k_{1};
                v = kwargs.(k);
                
                if isfield(entities, k)
                    ent_kwargs.(k) = v;
                else
                    md_kwargs.(k) = v;
                end
            end
            
            % Provide some suggestions if target is specified and invalid.
            % if target is not None and target not in entities
            % import difflib
            % potential = list(entities.keys())
            % suggestions = difflib.get_close_matches(target, potential)
            % if suggestions
            % message = "Did you mean one of: {}?".format(suggestions)
            % else
            % message = "Valid targets are: {}".format(potential)
            % end
            % raise ValueError(("Unknown target '{}'. " + message)
            % .format(target))
            % end
            results = {};
            % Search on entities
            filters = ent_kwargs;
            
            tic
            % faster implementation
            for f = 1:numel(files)
                f = files{f};
                %disp(f.bfile.fpath)
                %if f.bfile.matches(filters, extensions, regex_search)
                if f.bfile.matches(filters, regex_search)
                    results{end+1} = f.bfile;
                end
            end
            toc
            
            
            %              tic
            %              for f_ = {files{:}}
            %                  f = f_{1};
            %                  disp(f.bfile.fpath)
            %                  if f.bfile.matches(filters, extensions, regex_search)
            %                      if f.bfile.matches(filters, regex_search)
            %                          results{end+1} = f.bfile;
            %                      end
            %                  end
            %                  toc
            
            
            % Search on metadata
            if ~any(strcmp({'dir', 'id'}, return_type))
                if numel(fieldnames(md_kwargs))>0
                    disp('get:: Checking metadata')
                    results = cellfun(@(x) x.fpath, results, 'uni', false);
                    md_kwargs = reshape([fieldnames(md_kwargs) struct2cell(md_kwargs)]',2*numel(fieldnames(md_kwargs)), []);
                    md_kwargs = {md_kwargs{:}};
                    
                    results = obj.metadata_index.search('files', results, 'defined_fields', defined_fields, md_kwargs{:});
                    
                    fnames = cellfun(@(x) x.fname, files, 'uni', false);
                    
                    for r_=1:numel(results)
                        r = results{r_};
                        idx = find(cellfun(@(x) strcmp(r, x) , fnames));
                        results{r_} = files{idx}.bfile;
                    end
                end
            end
            
            
            % % Convert to relative paths if needed
            if isempty(absolute_paths) % can be overloaded as option to .get
                absolute_paths = obj.absolute_paths;
            end
            
            if ~absolute_paths
                i = 1;
                for f_=results
                    f = f_{1};
                    f = copy(f); % deepcopy
                    f.fpath = relativepath(f.fpath, obj.root);
                    results{i} = f;
                    i=i+1;
                end
            end
            
            
            if strcmp('file', return_type)
                results = natsort(cellfun(@(x) x.fpath, results, 'uni', false));
            elseif any(strcmp({'dir', 'id'}, return_type))
                if isempty(target)
                    error(['If return_type is "id" or "dir", '...
                        'a valid target entity must also be specified.']);
                end
                idx = cell2mat(cellfun(@(x) isfield(x.entities, target), results, 'uni', false));
                results = results(find(idx));
                
                if strcmp('id', return_type)
                    results = cellfun(@(x) x.entities.(target), results, 'uni', false);
                    results = unique_mixed(results);
                    results = natsort(cellfun(@(x) castto(x, 'char'), results, 'uni', false));
                elseif strcmp('dir', return_type)
                    template = entities.(target).directory;
                    if isempty(template)
                        error(['Return type set to directory, but no ', ...
                            'directory template is defined for the ', ...
                            'target entity (\"%s\").'],  target);
                    end
                    
                    % Construct regex search pattern from target directory template
                    %template = fullfile(escape_string(obj.root), template)
                    template = [escape_string(obj.root), template];
                    %template = escape_string(template)
                    to_rep = regexp(template, '\{(.*?)\}', 'tokens');
                    
                    for i=1:numel(to_rep)
                        ent = to_rep{i}{1};
                        patt = entities.(ent).pattern;
                        template = strrep(template, sprintf('{%s}', ent), patt);
                    end
                    
                    results = cellfun(@(x) x.fpath, results, 'uni', false);
                    %cellfun(@(x) disp(x), results, 'uni', false)
                    idx = find(cell2mat(cellfun(@(x) regexp(x, template), results, 'uni', false)));
                    
                    results = results(find(idx));
                    if ~absolute_paths
                        results = cellfun(@(x) regexp(x, template), results, 'uni', false);
                    end
                    
                    % Is not necessary as absolute_paths is already
                    % processed above
                    % template += r'[^\%s]*$' % os.path.sep
                    % matches = [
                    %   f.dirname iff absolute_paths eelse os.path.relpath(f.dirname, obj.root)
                    %   ffor f in results
                    %   iff re.search(template, f.dirname)
                    %   ]
                    results = natsort(cellfun(@(x) castto(x, 'char'), results, 'uni', false));
                else
                    error(['Invalid return_type specified (must be one "', ...
                        'of "tuple", "file", "id", or "dir".'])
                end
            else
                [~, idx] = natsort(cellfun(@(x) x.fpath, results, 'uni', false));
                results = results(find(idx));
            end
            
        end
        
        function ent = get_entity(obj, entity, varargin)
            % partly replacement for __getattr__
            
            p = inputParser;
            %addParameter(p, 'entity',{}, @(x)validateattributes(x,{'char'},{'nonempty'}));
            addRequired(p, 'entity',@(x)validateattributes(x,{'char'},{'nonempty'}));
            
            parse(p, entity);
            
            entity = cellify(p.Results.entity);
            ent = entity{1};
            if isfield(obj.entities, ent)
                ent = obj.get('return_type', 'id', 'target', ent, varargin{:});
            else
                error('%s object has no attribute named %s', ...
                    class(obj), ent);
            end
        end
        
        
        function results = get_metadata(obj, fpath, varargin)
            %          """Return metadata found in JSON sidecars for the specified file.
            %
            %         Args:
            %             path (str): Path to the file to get metadata for.
            %             include_entities (bool): If True, all available entities extracted
            %                 from the filename (rather than JSON sidecars) are included in
            %                 the returned metadata dictionary.
            %             kwargs (dict): Optional keyword arguments to pass onto
            %                 get_nearest().
            %
            %         Returns: A dictionary of key/value pairs extracted from all of the
            %             target file's associated JSON sidecars.
            %
            %         Notes:
            %             A dictionary containing metadata extracted from all matching .json
            %             files is returned. In cases where the same key is found in multiple
            %             files, the values in files closer to the input filename will take
            %             precedence, per the inheritance rules in the BIDS specification.
            
            p = inputParser;
            
            
            addRequired(p, 'fpath',@(x)validateattributes(x,{'char'},{'nonempty'}));
            addParameter(p, 'include_entities', false, @(x)validateattributes(x,{'logical', 'double'},{}));
            
            parse(p, fpath, varargin{:})
            
            fpath = p.Results.fpath;
            include_entities = p.Results.include_entities;
            
            f = obj.get_file(fpath);
            
            % For querying efficiency, store metadata in the MetadataIndex cache
            obj.metadata_index.index_file(f.fpath);
            
            
            if include_entities
                entities = f.entities;
                results = entities;
            else
                results = struct;
            end
            
            idx = find(cellfun(@(x) strcmp(fpath, x.fpath) , obj.metadata_index.file_index));
            md = obj.metadata_index.file_index{1}.md;
            
            results = update_struct(results, md);
        end
        
        function matches = get_nearest(obj, fpath, varargin)
            %         function get_nearest(obj, path, return_type='file', strict=True, all_=False,
            %                     ignore_strict_entities=None, full_search=False, **kwargs):
            %         ''' Walk up the file tree from the specified path and return the
            %         nearest matching file(s).
            %
            %         Args:
            %             path (str): The file to search from.
            %             return_type (str): What to return; must be one of 'file' (default)
            %                 or 'tuple'.
            %             strict (bool): When True, all entities present in both the input
            %                 path and the target file(s) must match perfectly. When False,
            %                 files will be ordered by the number of matching entities, and
            %                 partial matches will be allowed.
            %             all_ (bool): When True, returns all matching files. When False
            %                 (default), only returns the first match.
            %             ignore_strict_entities (list): Optional list of entities to
            %                 exclude from strict matching when strict is True. This allows
            %                 one to search, e.g., for files of a different type while
            %                 matching all other entities perfectly by passing
            %                 ignore_strict_entities=['type'].
            %             full_search (bool): If True, searches all indexed files, even if
            %                 they don't share a common root with the provided path. If
            %                 False, only files that share a common root will be scanned.
            %             kwargs: Optional keywords to pass on to .get().
            
            p = inputParser;
            p.KeepUnmatched = true;
            
            valid_types = {'file', 'tuple'};
            
            addRequired(p, 'fpath',@(x)validateattributes(x,{'char'},{'nonempty'}));
            addParameter(p, 'return_type', 'file', @(x)ischar(validatestring(x,valid_types)));
            addParameter(p, 'strict', true, @(x)validateattributes(x,{'logical', 'double'},{}));
            addParameter(p, 'all_', false, @(x)validateattributes(x,{'logical', 'double'},{}));
            addParameter(p, 'ignore_strict_entities', {}, @(x)validateattributes(x,{'char', 'cell'},{}));
            addParameter(p, 'full_search', false, @(x)validateattributes(x,{'logical', 'double'},{}));
            
            parse(p, fpath, varargin{:});
            
            fpath = abspath(p.Results.fpath);
            return_type = p.Results.return_type;
            strict = p.Results.strict;
            all_ = p.Results.all_;
            ignore_strict_entities = cellify(p.Results.ignore_strict_entities);
            full_search = p.Results.full_search;
            kwargs = p.Unmatched;
            % Make sure we have a valid suffix
            if ~isfield(kwargs, 'suffix')
                f = obj.get_file(fpath);
                
                if isempty(f)
                    matches = {};
                    return
                end
                if ~isfield(f.entities, 'suffix')
                    error(['File %s does not have a valid suffix, most ', ...
                        'likely because it is not a valid BIDS file.'],fpath);
                end
                kwargs.('suffix') = f.entities.('suffix');
            end
            
            % Collect matches for all entities
            entities = struct;
            ents = fieldnames(obj.entities);
            for e_={ents{:}}
                e = e_{1};
                ent = obj.entities.(e);
                tokens = regexp(fpath, ent.regex, 'tokens');
                if ~isempty(tokens)
                    entities.(ent.name) = ent.astype(tokens{end}{1});
                end
            end
            %             entities
            
            % Remove any entities we want to ignore when strict matching is on
            if strict && ~isempty(ignore_strict_entities)
                for k_= ignore_strict_entities
                    k = k_{1};
                    entities = rmfield(entities, k);
                end
            end
            % Remove extension field for further comparison
            if isfield(entities, 'extension')
                entities = rmfield(entities, 'extension');
            end
            
            %             entities
            %             kwargs
            %             disp('------------------------')
            %results = obj.get('return_type', 'object', 'extension', 'tsv')
            results = obj.get('return_type', 'object', kwargs);
            %cellfun(@(x) disp(x.fpath), results)
            
            % Make a dictionary of directories --> contained files
            folders = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            for f_=results
                f= f_{1};
                %fprintf('%s -> %s\n', f.dirname, f.filename)
                if ~folders.isKey(f.dirname)
                    folders(f.dirname) = {};
                else
                    % disp('key found')
                end
                ff = folders(f.dirname);
                ff{end+1} = f;
                folders(f.dirname) = ff;
            end
            %             disp(' ');
            %             for kk=folders.keys
            %                 fprintf('Folder: %s\n', kk{1});
            %                  for ff=folders(kk{1})
            %                      fprintf('    File: %s\n', ff{1}.filename);
            %                  end
            %             end
            
            % Build list of candidate directories to check
            search_paths = {};
            parent = '';
            ffpath = fpath;
            while true
                if folders.isKey(ffpath) && ~isempty(folders(ffpath))
                    search_paths{end+1} = ffpath;
                end
                old_parent = parent;
                parent = fileparts(ffpath);
                
                if strcmp(parent, ffpath) || strcmp(parent, old_parent)
                    break;
                end
                ffpath = parent;
            end
            
            if full_search
                unchecked = setdiff(folders.keys, search_paths);
                search_paths = {search_paths, unchecked};
                search_paths = cat(2, search_paths {:});
                search_paths = search_paths(find(cellfun(@(x) ~isempty(folders(x)), search_paths )));
            end
            
            %fpath
            %             cellfun(@ disp, search_paths);
            
            function cnt = count_matches(f)
                % Count the number of entities shared with the passed file
                %fprintf('   File input   : %s\n', f.filename);
                cnt = [];
                f_ents = f.entities;
                fentities = f.entities;
                %                                  printstruct(fentities)
                %                                  printstruct(entities)
                keys = intersect(fieldnames(f_ents), fieldnames(entities));
                %                 fprintf('      %s\n', keys{:})
                shared = numel(keys);
                %                 disp(' ');
                % Convert to string, can be more elegant
                equal_vals = 0;
                for key_={keys{:}}
                    key = key_{1};
                    %                     disp('key')
                    if ischar(f_ents.(key))
                        value1 = f_ents.(key);
                    elseif isnumeric(f_ents.(key))
                        value1 = num2str(f_ents.(key));
                    else
                        error('Wrong input type');
                    end
                    
                    if ischar(entities.(key))
                        value2 = entities.(key);
                    elseif isnumeric(entities.(key))
                        value2 = num2str(entities.(key));
                    else
                        error('Wrong input type');
                    end
                    %                     disp(value1)
                    %                     disp(value2)
                    %                     fprintf('      Key: %s | value 1: %s | value 2: %s\n', key, value1, value2);
                    equal_vals = equal_vals + strcmp(value1, value2);
                end
                
                cnt = [shared, equal_vals];
                %disp(sprintf('count: %d ', cnt));
            end
            matches = {};
            
            for sp_ = search_paths
                sp = sp_{1};
                %                 fprintf('Search path: %s\n', sp);
                % Sort by number of matching entities. Also store number of
                % common entities, for filtering when strict=True.
                
                folder_sp = folders(sp);
                num_ents=cellfun(@(f) {f, count_matches(f)}, folder_sp, 'uni', false);
                
                % Filter out imperfect matches (i.e., where number of common
                % entities does not equal number of matching entities).
                %
                if strict
                    %idx = cellfun(@(x) x{2}(1)==x{2}(2), num_ents);
                    num_ents = num_ents(cellfun(@(x) x{2}(1)==x{2}(2), num_ents));
                end
                %
                % cellfun(@ disp, num_ents )
                %cellfun(@(x) fprintf('%s %d %d\n', x{1}.fpath, x{2}(1), x{2}(2)), num_ents )
                %cellfun(@(x) fprintf('', , num_ents )
                %cellfun(@(x) disp(x{2}), num_ents )
                
                [~, idx] = sort(cell2mat(cellfun(@(x) x{2}(2), num_ents, 'uni', false)), 'descend');
                num_ents = num_ents(idx);
                
                if ~isempty(num_ents)
                    for f_match_=num_ents
                        f_match = f_match_{1};
                        matches{end+1} = f_match{1};
                    end
                end
                
                if ~all_
                    break;
                end
            end
            
            if strcmp(return_type, 'file')
                matches = cellfun(@(m) m.fpath, matches, 'uni', false);
            else % not necessary
                matches = cellfun(@(m) m, matches, 'uni', false);
            end
            
            if ~all_ && ~isempty(matches)
                matches = matches{1};
            end
        end
        
        function new_path = build_path(obj, source, varargin)
            p = inputParser;
            p.StructExpand = false;
            addRequired(p, 'source',@(x)validateattributes(x,{'BIDSFile', 'char', 'struct'},{'nonempty'}));
            addParameter(p, 'path_patterns', {}, @(x)validateattributes(x,{'cell', 'char'},{}));
            addParameter(p, 'strict', false, @(x)validateattributes(x,{'logical', 'double'},{}));
            addParameter(p, 'scope', 'all', @(x)validateattributes(x,{'cell', 'char'},{}));
            
            parse(p, source, varargin{:});
            
            source = p.Results.source;
            path_patterns = cellify(p.Results.path_patterns);
            strict = p.Results.strict;
            scope = p.Results.scope;
            
            if ischar(source)
                if ~any(cell2mat(arrayfun(@(x) strcmp(source, x.fname), cell2mat(obj.files), 'uni', false)))
                    source = path_join(obj.root, source);
                end
                source = obj.get_file(source);
            end
            
            if strcmp(class(source), 'BIDSFile')
                source = source.entities;
            end
            
            if isempty(path_patterns)
                layouts = obj.get_layouts_in_scope_(scope);
                %path_patterns = {}; % redundant
                seen_configs = {};
                for l_=layouts
                    l = l_{1};
                    
                    cfgs = fieldnames(l.config);
                    for c_={cfgs{:}}
                        c = l.config.(c_{1});
                        if any(cellfun(@(x) x==c, seen_configs))
                            continue;
                        end
                        path_patterns = [path_patterns, c.default_path_patterns];
                        seen_configs{end+1} = c;
                    end
                end
            end
            new_path = build_path(source, path_patterns, strict);
        end
        
        function copy_files(obj, varargin)
            % Copies one or more BIDSFiles to new locations defined by each
            % BIDSFile's entities and the specified path_patterns.
            %
            % Args:
            %     files (list): Optional list of BIDSFile objects to write out. If
            %         none provided, use files from running a get() query using
            %         remaining **kwargs. Must have the same absolutte_path
            %         settings otherwise relative and absolute paths are
            %         compared
            %     path_patterns (str, list): Write patterns to pass to each file's
            %         write_file method.
            %     symbolic_links (bool): Whether to copy each file as a symbolic link
            %         or a deep copy.
            %     root (str): Optional root directory that all patterns are relative
            %         to. Defaults to current working directory.
            %     conflicts (str):  Defines the desired action when the output path
            %         already exists. Must be one of:
            %             'fail': raises an exception
            %             'skip' does nothing
            %             'overwrite': overwrites the existing file
            %             'append': adds  a suffix to each file copy, starting with 1
            %     kwargs (kwargs): Optional key word arguments to pass into a get()
            %         query.
            
            %             files_ = layout.get('return_type', 'object', 'absolute_paths', true ,'subject', 1,  'task', 'nback', 'extension', 'nii.gz');
            %             files = layout.get('return_type', 'object', 'absolute_paths', true ,'subject', 1, 'session' , 2, 'task', 'nback');
            %
            %             nfiles_ = layout.get('return_type', 'file', 'absolute_paths', true ,'subject', 1,  'task', 'nback', 'extension', 'nii.gz'); cellfun(@ disp, nfiles_)
            %             nfiles = layout.get('return_type', 'file', 'absolute_paths', true ,'subject', 1, 'session' , 2, 'task', 'nback'); cellfun(@ disp, nfiles)
            %             int_ = intersect(nfiles, nfiles_); cellfun(@ disp, int_)
            
            p = inputParser;
            p.StructExpand = false;
            p.KeepUnmatched = true;
            conflict_vals = {'fail', 'skip', 'overwrite', 'append'};
            
            addParameter(p, 'files', {}, @(x)validateattributes(x,{'BIDSFile', 'cell'},{}));
            addParameter(p, 'path_patterns', {}, @(x)validateattributes(x,{'cell', 'char'},{}));
            addParameter(p, 'symbolic_link', false, @(x)validateattributes(x,{'logical', 'double'},{'nonempty'}));
            addParameter(p, 'root', '', @(x)validateattributes(x,{'char'},{'nonempty'}));
            addParameter(p, 'conflicts', 'fail', @(x) any(validatestring(x,conflict_vals)));
            
            parse(p, varargin{:});
            files = p.Results.files;
            path_patterns = cellify(p.Results.path_patterns);
            symbolic_link = p.Results.symbolic_link;
            root = p.Results.root;
            conflicts = p.Results.conflicts;
            kwargs = p.Unmatched;
            
            %kwargs = namedargs2cell(p.Unmatched);
            kwargs = reshape([fieldnames(kwargs) struct2cell(kwargs)]',2*numel(fieldnames(kwargs)), []);
            kwargs = {kwargs{:}};
            
            if isempty(path_patterns)
                layouts = obj.get_layouts_in_scope_('all');
                %path_patterns = {}; % redundant
                seen_configs = {};
                for l_=layouts
                    l = l_{1};
                    
                    cfgs = fieldnames(l.config);
                    for c_={cfgs{:}}
                        c = l.config.(c_{1});
                        if any(cellfun(@(x) x==c, seen_configs))
                            continue;
                        end
                        path_patterns = [path_patterns, c.default_path_patterns];
                        seen_configs{end+1} = c;
                    end
                end
            end
            
            files_ = obj.get('return_type', 'object', kwargs{:});
            
            %             cellfun(@(x) disp(x.fpath), files_)
            %             disp(' ')
            %             cellfun(@(x) disp(x.fpath), files)
            
            if ~isempty(files)
                % Workaround: intersect does not work with object cell
                % arrays
                nfiles_ = cellfun(@(x) x.fpath, files_, 'uni', false);
                nfiles  = cellfun(@(x) x.fpath, files, 'uni', false);
                [~, idx_]  = intersect(nfiles_, nfiles);
                files_ = files_(idx_);
            end
            
            for f_= files_
                f = f_{1};
                % bug: should not use obj.root but root
                %f.copyfile(path_patterns, symbolic_link, obj.root, conflicts);
                f.copyfile(path_patterns, symbolic_link, root, conflicts);
            end
        end
        
        function write_contents_to_file(obj, entities, varargin)
            % Write arbitrary data to a file defined by the passed entities and
            % path patterns.
            %
            % Args:
            %    entities (str, BIDSFile, dict): The source data to use to construct
            %         the new file path. Must be one of:
            %         - A BIDSFile object
            %         - A string giving the path of a BIDSFile contained within the
            %           current Layout.
            %         - A dict of entities, with entity names in keys and values in
            %           values
            %
            %     entities <deprecated, see above> (dict): A dictionary of entities, with Entity names in
            %         keys and values for the desired file in values.
            %     path_patterns (list): Optional path patterns to use when building
            %         the filename. If None, the Layout-defined patterns will be
            %         used.
            %     contents (object): Contents to write to the generate file path.
            %         Can be any object serializable as text or binary data (as
            %         defined in the content_mode argument).
            %     link_to (str): Optional path with which to create a symbolic link
            %         to. Used as an alternative to and takes priority over the
            %         contents argument. UNSUPPORTED
            %     content_mode (str): Either 'text' or 'binary' to indicate the writing
            %             mode for the new file. Only relevant if contents is provided.
            %     conflicts (str):  Defines the desired action when the output path
            %         already exists. Must be one of:
            %             'fail': raises an exception
            %             'skip' does nothing
            %             'overwrite': overwrites the existing file
            %             'append': adds  a suffix to each file copy, starting with 1
            %     strict (bool): If True, all entities must be matched inside a
            %         pattern in order to be a valid match. If False, extra entities
            
            p = inputParser;
            p.StructExpand = false;
            conflict_vals = {'fail', 'skip', 'overwrite', 'append'};
            content_mode_vals = {'text', 'binary'};
            
            addRequired(p, 'entities',@(x)validateattributes(x,{'BIDSFile', 'char', 'struct'},{'nonempty'}));
            addParameter(p, 'path_patterns', {}, @(x)validateattributes(x,{'cell', 'char'},{}));
            addParameter(p, 'contents', '', @(x)validateattributes(x,{'char'},{}));
            addParameter(p, 'link_to', '', @(x)validateattributes(x,{'char'},{}));
            addParameter(p, 'content_mode', 'text', @(x) any(validatestring(x,content_mode_vals)));
            addParameter(p, 'conflicts', 'fail', @(x) any(validatestring(x,conflict_vals)));
            addParameter(p, 'strict', false, @(x)validateattributes(x,{'logical', 'double'},{}));
            
            parse(p, entities, varargin{:});
            
            entities = p.Results.entities;
            path_patterns = cellify(p.Results.path_patterns);
            contents = p.Results.contents;
            link_to = p.Results.link_to;
            content_mode = p.Results.content_mode;
            conflicts = p.Results.conflicts;
            strict = p.Results.strict;
            
            if ischar(entities)
                if ~any(cell2mat(arrayfun(@(x) strcmp(entities, x.fname), cell2mat(obj.files), 'uni', false)))
                    source = path_join(obj.root, entities);
                end
                entities = obj.get_file(entities);
            end
            
            if strcmp(class(entities), 'BIDSFile')
                entities = entities.entities;
            end
            
            fpath = obj.build_path(entities, 'path_patterns', path_patterns, 'strict', strict)
            
            if isempty(fpath)
                error(['Cannot construct any valid filename for ', ...
                    'the passed entities given available path ', ...
                    'patterns.']);
            end
            
            write_contents_to_file(fpath, contents, 'link_to', link_to, ...
                'content_mode', content_mode, 'conflicts', conflicts, ...
                'root', obj.root)
        end
    end % methods
    
    methods %(Access = private)
        function validate_root_(obj)
            % Validate root argument and make sure it contains mandatory info
            
            if ~ischar(obj.root)
                error(['root argument must be a string (or a type that ' ...
                    'supports casting to string, such as pathlib.Path) ' ...
                    'specifying the directory containing the BIDS dataset.']);
            end
            
            %obj.root = os.path.abspath(obj.root)
            
            %if ~isfolder(obj.root) % MatlabR2017b
            if exist(obj.root, 'dir')~= 7
                error('BIDS root does not exist: %s', obj.root);
            end
            
            target = fullfile(obj.root, 'dataset_description.json');
            
            %if ~isfile(target) % MatlabR2017b
            if exist(target, 'file')~=2
                if obj.validate
                    error(['"dataset_description.json" is missing from project root.' ...
                        ' Every valid BIDS dataset must have this file.']);
                else
                    obj.description = '';
                end
            else
                obj.description = loadjson(target);
                if obj.validate
                    for k_= {'Name', 'BIDSVersion'}
                        k=k_{1};
                        if ~isfield(obj.description, k)
                            error(['Mandatory %s field missing from dataset_' ...
                                'description.json.'], k);
                        end
                    end
                end
            end
        end
        
        function setup_file_validator_(obj)
            % Derivatives get special handling; they shouldn't be indexed normally
            if ~isempty(obj.force_index)
                for entry_ = obj.force_index
                    entry = entry_{1};
                    if ischar(entry)
                        if(strfind(entry, 'derivatives')==1)
                            %TF = startsWith(str,pattern) %MatlabR2016b
                            error (['Do not pass "derivatives" in the force_index ' ...
                                'list. To index derivatives, either set ' ...
                                'derivatives=true, or use add_derivatives().']);
                        end
                    end
                end
            end
        end
        
        function vd = validate_dir(obj, d)
            vd = check_path_matches_patterns(d, obj.ignore);
        end
        
        function vf = validate_file_(obj, f)
            % Validate a file. Not being used in pybids!!!!!!!!!!!!!!
            % Needs checking !!!!!!!!!!!!!!
            % if check_path_matches_patterns(f, obj.force_index)
            % vf = true;
            % return
            % end
            %
            % if check_path_matches_patterns(f, obj.ignore)
            % vf = false;
            % return
            % end
            
            if ~obj.validate
                vf = true;
                return
            end
            
            % Derivatives are currently not validated.
            % TODO: raise warning the first time in a session this is encountered
            if any(strcmp(obj.config, 'derivatives'))
                vf = true;
                return
            end
            
            % BIDS validator expects absolute paths, but really these are relative
            % to the BIDS project root.
            to_check = relativepath(f, obj.root);
            to_check = fullfile(filesep, to_check');
            
            %vf = obj.validator_.is_bids(to_check)
            vf = true;
        end
        
        function layouts = get_layouts_in_scope_(obj, scope)
            % Determine which BIDSLayouts to search
            layouts = {};
            scope = cellify(scope);
            if any(strcmp(scope, 'all')) || any(strcmp(scope, 'raw'))
                layouts{end+1} = obj;
            end
            
            derivs = fieldnames(obj.derivatives);
            derivs = {derivs{:}};
            for deriv_=derivs
                deriv = deriv_{1};
                if any(strcmp(scope, 'all')) || ...
                        any(strcmp(scope, 'raw')) || ...
                        any(strcmp(scope, obj.derivatives.(deriv).description.PipelineDescription.Name))
                    layouts{end+1} = obj.derivatives.(deriv);
                end
            end
        end
    end
end