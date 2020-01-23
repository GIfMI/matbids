classdef BIDSNodeProperties < handle
    properties
        child_entity = []
        child_class = []
        entities = {}
        label = []
    end
    
    methods
        function obj = BIDSNodeProperties(varargin)
            p = inputParser;
            addOptional(p, 'child_class', [], @(x)validateattributes(x,{'char'},{'nonempty'}));
            addOptional(p, 'child_entity', [], @(x)validateattributes(x,{'char'},{'nonempty'}));
            addOptional(p, 'entities', {}, @(x)validateattributes(x,{'cell'},{'nonempty'}));
            addOptional(p, 'label', [], @(x)validateattributes(x,{'char'},{'nonempty'}));
            
            parse(p, varargin{:});
            obj.child_class = p.Results.child_class;
            obj.child_entity = p.Results.child_entity;
            obj.label = p.Results.child_entity;
            obj.entities = cellify(p.Results.entities);
        end
        
    end
end