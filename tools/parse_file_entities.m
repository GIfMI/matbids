function ent_vals = parse_file_entities(filename, varargin)
% TODO: select all available configs, now hard coded bids and derivatives
% Check for duplicate configs
    % Parse the passed filename for entity/value pairs.
    
    %     Args:
    %         filename (str): The filename to parse for entity values
    %         entities (list): An optional list of Entity instances to use in
    %             extraction. If passed, the config argument is ignored.
    %         config (str, Config, list): One or more Config objects or names of
    %             configurations to use in matching. Each element must be a Config
    %             object, or a valid Config name (e.g., 'bids' or 'derivatives').
    %             If None, all available configs are used.
    %         include_unmatched (bool): If True, unmatched entities are included
    %             in the returned dict, with values set to None. If False
    %             (default), unmatched entities are ignored.
    %
    %     Returns: A dict, where keys are Entity names and values are the
    %         values extracted from the filename.
    %
    
    p = inputParser;
    addRequired(p, 'filename',@(x)validateattributes(x,{'char'},{'nonempty'}));
    addOptional(p, 'entities', {}, @(x)validateattributes(x,{'cell'},{}));
    addOptional(p, 'config', {}, @(x)validateattributes(x,{'cell', 'Config', 'char'},{''}));
    addOptional(p, 'include_unmatched', false, @(x)validateattributes(x,{'logical', 'double'},{''}));
    
    parse(p, filename, varargin{:});
    entities = cellify(p.Results.entities);
    configa = cellify(p.Results.config);
    include_unmatched = p.Results.include_unmatched;

    
    ent_vals = struct;
    if isempty(entities)
        if isempty(configa)
            configa = {'bids', 'derivatives'};
        end
        
        for i=1:numel(configa)
            if ischar(configa{i})
                configa{i} = Config.load(configa{i});
            end
        end        
            % Make all entities easily accessible in a single dict
            entities_={};
            for cfg=configa
                entities_ = update_struct(entities_, cfg{1}.entities);
            end
        entities = struct2cell(entities_);
    end
    % Extract matches
    bf = BIDSFile(filename);
    ent_vals = {};
    
    for e={entities{:}}
        e=e{1};
 
        m = e.match_file(bf);
        
        if ~isempty(m) || include_unmatched
           ent_vals.(e.name) = m; 
        end
    end
end