function cofg = get_config2(testing, varargin)
    disp('a')
    mislocked
    if mislocked
        disp('b')
        mislocked
        munlock(mfilename);
        disp('c')
        mislocked
    end
    disp('d')
    mislocked
    clear (mfilename);
    disp('bbb')
%     p = inputParser;
%     addOptional(p, 'refresh', false, @(x)validateattributes(x,{'logical', 'numeric'},{'nonempty'}));
%     parse(p, varargin{:});
%     refresh_cfg = logical(p.Results.refresh);
    disp(testing)
    %
    % %     persistent cfg
    % %
    % %     if ~exist('cfg', 'var') || isempty(cfg)
    % %         cfg = config.bidsconfig.instance(true);
    % %     else
    % %         if refresh_cfg
    % %             cfg.reset_options();
    % %         end
    % %     end
    % %     cofg = cfg;
    %
    %
%     persistent cfg
%     if refresh_cfg
%         munlock(mfilename);
%         clear cfg
%     end
    % %     if ~exist('cfg', 'var') || isempty(cfg)
    % %         cfg = config.bidsconfig.instance(true);
    % %     else
    % %     end
%     if ~mislocked
%         mlock
%     end
    % %    cofg = cfg;
    
    cofg = 123;
    
end
