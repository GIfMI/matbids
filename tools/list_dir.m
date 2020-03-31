function [dirList, fileList] = list_dir(rootpath)
    
    dd = dir(rootpath);
    isub = [dd(:).isdir]; % returns logical vector
    dirList = {dd(isub).name}';
    dirList(ismember(dirList,{'.','..'})) = [];
    fileList = {dd(~isub).name}';
    
%    if isempty(dirList)
%        return
%    else
%        for i=1:numel(dirList)
%            walk_dir(fullfile(rootpath, dirList{i}));
%        end
%    end
end