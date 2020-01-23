classdef Config < handle
    properties
        name = ''
        entities = struct
        default_path_patterns = {}
    end
    properties (Constant)
        config_field = {'name', 'entities', 'default_path_patterns'};
        %config_value = {'', {}, {} };
    end
    
    methods  %(Access=private)
        % Constructor
        function obj = Config(input_config)
            % input_config must be a struct with at least fieldname 'name'
            % and optionally 'entities' and 'default_path_patterns' as cell
            % arrays
            narginchk(1,1);
            p = inputParser;
            p.StructExpand = true;
            
            addParameter(p, 'name'                 , '', @(x)validateattributes(x,{'char'},{'nonempty'}));
            addParameter(p, 'entities'             , {}, @(x)validateattributes(x,{'cell', 'struct'},{}));
            addParameter(p, 'default_path_patterns', {}, @(x)validateattributes(x,{'cell'},{}));
            parse(p, input_config);
            
            if isempty(p.Results.name)
                error('Name must be provided');
            end
            
            obj.name = p.Results.name;
            obj.default_path_patterns = p.Results.default_path_patterns;
            entities = p.Results.entities;
            
            if ~isempty(entities)
                assert(iscell(entities), 'Entities must be a cell array');
                
                %                 for ent=entities
                %                     obj.entities.(ent{:}.name) = Entity(ent{:});
                %                 end
                for ent={entities{:}}
                    obj.entities.(ent{:}.name) = Entity(ent{:});
                end
            end
        end
        
        function disp(obj)
            fprintf('Class: Config | Name: %s | Entities : %d | Patterns: %d\n', obj.name, numel(fieldnames(obj.entities)), numel(obj.default_path_patterns));
        end
    end
    
    methods (Static)
        function obj = load(varargin)
            % input supported:
            % string: name of loaded config
            % struct with fieldnames
            % name must be a fieldname of the input struct
            narginchk(1, 1);
            
            input_config = varargin{1};
            if isa(input_config, 'char')
                input_config = varargin{1};
                config_paths = config.get_config().get_option('config_paths');
                
                if isfield(config_paths, input_config)
                    input_config = config_paths.(input_config);
                end
                
                if exist(input_config, 'file')~=2
                    error('Configuration file does not exist');
                else
                    % TODO: error checking
                    %input_config = loadjson(input_config);
                    input_config = jsonread(input_config);
                end
            end
            
            if isstruct(input_config)
                % Cellify input, output from json readers can differ
                % eg jsonread makes arrays by default if all elements of
                % the output structure have the same fieldnames, otherwise
                % a cell array will be generated
                % loadjson seems to import as a cell array by default
                % input_config.entities = mat2cell(input_config.entities, ones(1, numel(input_config.entities)));
                input_config.entities = cellify(input_config.entities);
            else
                eror('Input type not allowed');
                %this
            end
            obj = Config(input_config);
        end
    end
    
    %     methods
    %         function disp(obj)
    %             disp('I am a config object')
    %             properties(obj)
    %         end
    %     end
    
end