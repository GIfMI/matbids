function fpath = path_join(varargin)
% similar as Python os.path.join
    
    fpath = '';
    
    if ~iscellstr(varargin)
        return;
    end
    
    for i=1:numel(varargin)
        
        token = strtrim(varargin{i});
        
        if isempty(token)
            fpath = fullfile(fpath, filesep);
        elseif isabs(token)%strcmp(filesep, token(1))
            % if absolute path, forget previous data
            fpath = token;
        else
            fpath = fullfile(fpath, token);
        end
    end
end