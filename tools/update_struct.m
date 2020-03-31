function struct1 = update_struct(struct1, struct2, varargin)
    % Merges 2 structures with or without recursion
    % Input:
    %   flags : usually user-provided structure
    %   def_flags : usually default flags
    %   varargin{1}: strict matching flag (true/1 or false/0), default: false
    %   varargin{2}: recursive flag or recur (true/1 or false/0), default: false
    % Output:
    %   flags : merged structure
    %
    %   strict = true:
    %       only fieldnames common to both inputs will be matched
    %
    %   strict = false:
    %       inputs will be fully merged, non-common fieldnames will be in the
    %       output
    %
    %   recur = true:
    %       output is a deep merge of both inputs (contains all fields) with
    %       common field values set to the values in the second input argument,
    %       independent of the depth
    %
    %   recur = false:
    %       output is a shallow merge of both inputs (output will only contain
    %       top-level fields, common fields will be set to the values in the
    %       first input argument
    
    recur = false;
    strict = false;
    
    if nargin>=3
        strict = logical(varargin{1});
    end
    
    if nargin==4
        recur = logical(varargin{2});
    end
    
    if isstruct(struct2)
        fnms = fieldnames(struct2);
    else
        fnms = {};
    end

    fnms = fieldnames(struct2);
    %     for i=1:length(fnms)
    %         fn = fnms{i};
    %         if ~isfield(struct1,fn) && ~strict
    %             struct1.(fn) = struct2.(fn);
    %        elseif recur && isstruct(struct1.(fn))
    %            struct1.(fn) = update_struct(struct1.(fn), struct2.(fn));
    %         end
    %     end
    % still faster despite lot of indexing
    for i=1:length(fnms)
        if ~isfield(struct1,fnms{i}) && ~strict
            struct1.(fnms{i}) = struct2.(fnms{i});
        elseif recur && isstruct(struct1.(fnms{i}))
            struct1.(fnms{i}) = update_struct(struct1.(fnms{i}), struct2.(fnms{i}));
        end
    end
    
end