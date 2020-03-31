function li = splitext(fpath)
    p = inputParser;
    addRequired(p, 'fpath',@(x)validateattributes(x,{'char'},{}));
    parse(p, fpath)
    fpath = p.Results.fpath;
    
    % Handle empty paths
    if isempty(fpath)
        li = [];
        return
    end
    
    % First split: get path, filename with other extensions, first
    % extension
    [path_without_extensions, filename, extensions] = fileparts(fpath);
    
    % Remove . from extension
    extensions = {extensions(2:end)};
    
    % Split secondary extensions
    file_with_secondary_extensions= strsplit(filename, '.');
    filename = file_with_secondary_extensions{1};
    
    % Merge extensions if existing
    if numel(file_with_secondary_extensions)>=2
        extensions = {file_with_secondary_extensions{2:end}, extensions{:}};
    end
    li = {fullfile(path_without_extensions, filename), extensions{:}};
end