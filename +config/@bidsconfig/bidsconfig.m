classdef bidsconfig < handle
    % Class which holds BIDS configurations.
    % Standard BIDS configurations are BIDS and DERIVATIVES.
    % The user can add extra configurations using in a file called
    % MATBIDS_CONFIG.JSON which is automatically added if detected in the 
    % paths.
    %
    % The class holds following properties
    % config_name: standard name of user-provided json config file
    %       json file must be located in the path
    % config_paths: cell array of folders containing config json files
    %       the defaults BIDS and DERIVATIVES json files must be located in
    %       a folder matbids/layout/config
    % default_settings: struct containing default configuration
    % settings: struct continaining default_settings + user-provided
    %       settings
    % bidsfield: cell array containing default json config file names
    %
    % The class uses the singelton design pattern which means that only one
    % object of the class can be instantiated. If an object already exists,
    % it will not create a new one but return the existing object.
    % To get the object, use bidsconfig.instance() instead of bidsconfig().
    
    properties (SetAccess = private)
        config_name = 'matbids_config.json'
        config_paths=''
        config_ext = '.json'
        default_settings = struct
        settings = struct
        bidsfields = {'bids', 'derivatives'};
    end
    
    methods (Access = private)
        % Constructor
        function obj = bidsconfig()
            
            obj.default_settings.config_paths = struct;
            
            % look for matbids folder in path
            package_path = regexp(fileparts(mfilename('fullpath')), '(?<word>.*)matbids', 'match');
            
            if isempty(package_path)
                error('Package matbids is not available');
            end
            package_path = package_path{1};
            
            obj.config_paths=fullfile(package_path, 'layout', 'config');
            
            if ~exist(obj.config_paths, 'dir')
                error('Configuration folder does not exist');
            end
            
            for field = obj.bidsfields
                obj.default_settings.config_paths.(field{1}) = fullfile(obj.config_paths, [field{1}, obj.config_ext]);
            end
            obj.reset_options(true);
        end
    end
    
    methods(Static)
        % Concrete implementation.  See Singleton superclass.
        function obj = instance(varargin)
            mlock
            refresh_instance = false;
            if nargin>=1
                refresh_instance = logical(varargin{1});
            end
            
            persistent uniqueInstance
            if isempty(uniqueInstance)% || refresh_instance
                obj = config.bidsconfig();
                uniqueInstance = obj;
            elseif refresh_instance
                obj = uniqueInstance;
                obj.reset_options('update_from_file', true);
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    
    methods
        % Set single option
        function obj = set_option(obj, key, value)
            p = inputParser;
            addRequired(p, 'obj');
            addRequired(p, 'key', @(x)validateattributes(x,{'char', 'string'},{'nonempty'}));
            addRequired(p, 'value');
            parse(p, obj, key, value);
            
            if ~isfield(obj.settings, key)
                error('Invalid matbids setting: %s', key);
            end
            obj.settings.(key) = value;
        end
        
        % Set multiple options
        function obj = set_options(obj, options)
            p = inputParser;
            addRequired(p, 'obj');
            addRequired(p, 'options', @(x)validateattributes(x,{'struct'}, {}));
            parse(p, obj, options);
            
            keys = fieldnames(options);
            for idx = 1:numel(keys)
                key = keys{idx};
                value = options.(key);
                obj = obj.set_option(key, value);
            end
        end
        
        % Get single option
        function opt = get_option(obj, key)
            narginchk(2,2);
            
            if ~isfield(obj.settings, key)
                error('Invalid matbids setting: %s', key);
            end
            opt =  obj.settings.(key);
        end
        
        % Get reset_options
        function reset_options(obj, varargin)
            p = inputParser;
            addRequired(p, 'obj')
            addOptional(p, 'update_from_file', false, @(x)validateattributes(x,{'logical', 'numeric'},{'nonempty'}));
            p.parse(obj, varargin{:});
            update_from_file = logical(p.Results.update_from_file);
            
            obj.settings = obj.default_settings;
            
            if update_from_file
                all_files = which(obj.config_name, '-all');
                obj.from_file(all_files, false);
            end
        end
    end
    
    methods (Access = private)
        % Get from file
        function from_file(obj, filenames, varargin)
            p = inputParser;
            addRequired(p, 'obj')
            addRequired(p, 'filenames');
            addOptional(p, 'error_on_missing', false, @(x)validateattributes(x,{'logical', 'numeric'},{'nonempty'}));
            p.parse(obj, filenames, varargin{:});
            error_on_missing = logical(p.Results.error_on_missing);
            
            if isstring(filenames) || ischar(filenames)
                filenames = cellify(filenames);
            else
                if ~iscell(filenames)
                    error('Invalid matbids input type');
                end
            end
            
            % Loop over files
            for i=1:numel(filenames)
                json_file = filenames{i};
                if exist(json_file, 'file')
                    settings_ = jsonread(json_file);
                    obj.settings = update_struct(settings_, obj.settings);
                elseif error_on_missing
                    error('File %s does not exist', json_file);
                end
            end
        end
    end
end

