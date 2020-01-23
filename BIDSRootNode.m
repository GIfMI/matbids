classdef BIDSRootNode < BIDSNode

    properties (Constant)
        my_child_entity_ = 'subject';
        my_child_class_ = 'BIDSSubjectNode';
       % my_entities_ = {'subject', 'session'};
        my_entities_ = {};
    end
    
    properties (SetAccess = private)
        subjects = {}
    end
    
    methods
        function obj = BIDSRootNode(fpath, config, layout, varargin)
            p = inputParser;
            addRequired(p, 'fpath',@(x)validateattributes(x,{'char'},{'nonempty'}));
            addRequired(p, 'config', @(x)validateattributes(x,{'cell', 'Config'},{'nonempty'}));
            addRequired(p, 'layout', @(x)validateattributes(x,{'cell', 'BIDSLayout'},{'nonempty'}));
            addOptional(p, 'force_index', false, @(x)validateattributes(x,{'logical', 'double'},{'nonempty'}));
            
            %--- disable parser temporarily to check functionality, keep it
            % to the parent class
            %parse(p, fpath, config, layout, varargin{:});
            force_index = true;
            %---
            obj@BIDSNode(fpath, config, layout, {}, {}, force_index);
        end
    end
    
    methods %(Access = protected)
        function setup(obj)
            for i=1:numel(obj.children)
                if isa(obj.children{i}, 'BIDSSubjectNode')
                    obj.subjects{end+1} = obj.children{i}.label;
                end
            end
        end
    end
end