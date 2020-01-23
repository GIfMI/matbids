classdef BIDSSessionNode < BIDSNode
    properties (Constant)
        my_entities_ = {'subject', 'session'};
    end

    properties (SetAccess = private)
        label
    end   
    
    methods %(Access = protected)
         function obj = BIDSSessionNode(varargin)
            obj@BIDSNode(varargin{:});
         end
         
         function setup(obj)
            obj.label = obj.entities.session;
        end
    end
end