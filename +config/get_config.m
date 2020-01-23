function cofg = get_config(varargin)
    p = inputParser;
    addOptional(p, 'refresh', false, @(x)validateattributes(x,{'logical', 'numeric'},{'nonempty'}));
    parse(p, varargin{:});
    refresh_cfg = logical(p.Results.refresh);
    
    persistent cfg
    if refresh_cfg || isempty(cfg)
        munlock('update_config');
    end
    cfg = update_config(refresh_cfg);
    cofg = cfg;
    
end

function outcfg = update_config(refresh_cfg)
    mlock
    persistent myoutcfg
%     if ~isempty(myoutcfg) && ~refresh_cfg
%         outcfg = myoutcfg;
%     else
      myoutcfg = config.bidsconfig.instance(refresh_cfg);
      outcfg = myoutcfg;
%     end
end