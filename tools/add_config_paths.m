function add_config_paths(configs)
    %     Add to the pool of available configuration files for BIDSLayout.
    %
    %     Args:
    %         kwargs: dictionary specifying where to find additional config files.
    %             Keys are names, values are paths to the corresponding .json file.
    %
    %     Example:
    %         > add_config_paths(my_config='/path/to/config')
    %         > layout = BIDSLayout('/path/to/bids', config=['bids', 'my_config'])
    %
    
                 p = inputParser;
                 p.StructExpand = false;
    
                 addRequired(p, 'configs');
                 parse(p, configs);
    
                 configs = p.Results.configs;
    
    fns = fieldnames(configs);
    
    for fn={fns{:}}
        fn = fn{1};
        %if ~isfile(configs.(fn)) %R2017b
        if ~(exist(configs.(fn), 'file') == 2)
            %error('Configuration file %s does not exist', configs.(fn));
        end
        cfg = config.get_config();
        cfg_paths = cfg.get_option('config_paths');
        if isfield(cfg_paths, fn)
            %error('Configuration %s already exists', fn);
        end
    end
    cfg.set_option('config_paths', update_struct(cfg_paths, configs));
end