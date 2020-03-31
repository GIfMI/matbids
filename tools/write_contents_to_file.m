function write_contents_to_file(fpath, contents, varargin)
    %     """
    %     Uses provided filename patterns to write contents to a new path, given
    %     a corresponding entity map.
    %
    %     Args:
    %         path (str): Destination path of the desired contents.
    %         contents (str): Raw text or binary encoded string of contents to write
    %             to the new path.
    %         link_to (str): Optional path with which to create a symbolic link to.
    %             Used as an alternative to and takes priority over the contents
    %             argument.UNSUPPORTED
    %         content_mode (str): Either 'text' or 'binary' to indicate the writing
    %             mode for the new file. Only relevant if contents is provided.
    %         root (str): Optional root directory that all patterns are relative
    %             to. Defaults to current working directory.
    %         conflicts (str): One of 'fail', 'skip', 'overwrite', or 'append'
    %             that defines the desired action when the output path already
    %             exists. 'fail' raises an exception; 'skip' does nothing;
    %             'overwrite' overwrites the existing file; 'append' adds  a suffix
    %             to each file copy, starting with 1. Default is 'fail'.
    %     """
    p = inputParser;
    content_mode_vals = {'text', 'binary'};
    conflict_vals = {'fail', 'skip', 'overwrite', 'append'};
    
    addRequired(p, 'fpath',@(x)validateattributes(x,{'char'},{'nonempty'}));
    addRequired(p, 'contents',@(x)validateattributes(x,{'char'},{}));
    addParameter(p, 'link_to', '', @(x)validateattributes(x,{'char'},{}));
    addParameter(p, 'content_mode', 'text', @(x) any(validatestring(x,content_mode_vals)));
    addParameter(p, 'root', '', @(x)validateattributes(x,{'char'},{}));
    addParameter(p, 'conflicts', 'fail', @(x) any(validatestring(x,conflict_vals)));
    
    parse(p, fpath, contents, varargin{:});
    
    contents = p.Results.contents;
    link_to = p.Results.link_to;
    content_mode = p.Results.content_mode;
    root = p.Results.root;
    conflicts = p.Results.conflicts;
    
    % disable symbolic link
    link_to = false;
    %%%
    
    if isempty(root) && ~isabs(fpath)
        root = pwd;
    end
    
    if ~isempty(root) && isabs(root) && isabs(fpath)
        % extra check compared to pybids
        error('cannot be absolute simultaneously')
    end
    
    if ~isempty(root)
        fpath = fullfile(root, fpath);
    end
    
    if exist(fpath)
        
        switch conflicts
            case 'fail'
                error('A file at path %s already exists', fpath);
            case 'skip'
                warning('A file at path %s already exists, skipping writing file', fpath);
                return
            case 'overwrite'
                if exist(fpath, 'dir')
                    warning('New path is a directory, not going to overwrite it, skipping instead.')
                    return
                end
                delete(fpath)
            case 'append'
                i = 1;
                while i < intmax
                    path_splits = splitext(fpath);
                    path_splits{1} = sprintf('%s_%d', path_splits{1}, i);
                    appended_filename=strjoin(path_splits, '.');
                    if ~exist(appended_filename, 'file')
                        fpath = appended_filename;
                        break;
                        
                    end
                    i = i+1;
                end
            otherwise
                error('Did not provide a valid conflicts parameter')
        end
    end
    
    if ~exist(fileparts(fpath), 'dir')
        try
            status = mkdir(fileparts(fpath));
            if ~status
                error('Path not created succesfully')
            end
        catch ME
            error(ME.message)
        end
    end
    
    if link_to
        % create symbolic link
    else
        try
            f = fopen(fpath, 'w');
            
            switch content_mode
                case 'text'
                    fprintf(f, '%s', contents);
                case  'binary'
                    fwrite(f, contents);
                otherwise
                    error('Could not write file');
            end
            fclose(f);
        catch ME
            error(ME.message);
        end
    end
end