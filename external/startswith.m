function tf = startswith(str, prefix)
% Return true if the string starts with the specified prefix

% This file is from matlabtools.googlecode.com


if iscell(str)
    tf = cellfun(@(s)startswith(s, prefix) , str);
   return 
end


tf = strncmp(str, prefix, length(prefix));
end