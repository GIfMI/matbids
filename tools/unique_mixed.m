function uniquelist = unique_mixed(valuelist, varargin)
% Performs partly the unique functionality
% valuelist: cell array of input data
% dtypes (optional): cell array of supported dtypes
%                    defaults to {'single', 'double', 'logical', 'char'}
% generates an error if a not-recognized data type is encountered

dtypes = {};

switch nargin
    case 0
        error('Not enough input parameters');
    case 1
    dtypes = {'single', 'double', 'logical', 'char'};        
    case 2
        dtypes = varargin{1};
        if ~iscellstr(dtypes)
            error('Data types must be a cell array');
        end
    otherwise
        error('Too many input parameters');
end

uniquelist = {};
if isempty(valuelist)
    return
end

idxs = logical(zeros(1, numel(valuelist)));
splitlist = struct;

% Split cell array in array of arrays with unique datatypes
for i = 1:length(dtypes)
    idx= cellfun(@(x) strcmp(dtypes{i}, class(x)), valuelist);
    idxs = any([idxs; idx]);
    splitlist(i).idx = idx;
    %splitlist(i).dtype = dtypes{i}; % not necessary
end

% Check if all values have a matching datatype
if ~all(idxs)
    error('Input cell array contains datatypes not supported');
end

% Select unique elements per data type
for i = 1:numel(splitlist)
    ismat = false;
    values = valuelist(splitlist(i).idx);
    
    %convert to mat if necessary
    if ~iscellstr(values)
        values = cell2mat(values);
        ismat = true;
    end
    
    values = unique(values);
    
    % convert back if necessary
    if ismat
        values = mat2cell(values, 1, ones(1,numel(values)));
    end
    splitlist(i).values = values;
end

% Compile unique list
uniquelist = {splitlist.values};
uniquelist=uniquelist(find(~cellfun('isempty', uniquelist)));
uniquelist = cat(2, uniquelist{:});
