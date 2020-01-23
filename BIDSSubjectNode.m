classdef BIDSSubjectNode < BIDSNode
    properties (Constant)
        my_child_entity_ = 'session'
        my_child_class_ = 'BIDSSessionNode'
        my_entities_ = {'subject'}
    end
    
    properties (SetAccess = private)
        label
        sessions = {}
    end    
    
    methods %(Access = protected)
         function obj = BIDSSubjectNode(varargin)
            obj@BIDSNode(varargin{:});
         end
         
         function setup(obj)
            for i=1:numel(obj.children)
                if isa(obj.children{i}, 'BIDSSessionNode')
                    obj.sessions{end+1} = obj.children{i}.label;
                end
            end
            obj.label = obj.entities.subject;
        end
    end
end