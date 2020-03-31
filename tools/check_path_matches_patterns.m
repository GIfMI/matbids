function matching = check_path_matches_patterns(this_path, patterns)
% Check if the path matches at least one of the provided patterns. '''
%this_path = GetFullPath(this_path);

patterns = cellify(patterns);
matching = false;
for i=1:numel(patterns)
    pattern = patterns{i};
    
    if isstring(pattern) || ischar(pattern)
        
        if isempty(regexp(pattern, '^\s*\^.*'))
            pattern = strcat('^', pattern);
        end
        
        if isempty(regexp(pattern, '.*\$\s*'))
            pattern = strcat(pattern, '$');
        end
        disp(pattern)
        if ~isempty(regexp(this_path, pattern))
            matching = true;
            break
        end
    else
        matching = false;
        break;
    end
end
end
%patterns = {'abcde', '^abcde', 'abcde$', '^abcde$'};