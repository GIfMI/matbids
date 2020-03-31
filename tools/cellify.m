function obj_cell = cellify(obj)
    % Turns everything into a cell 
    % Cells stay cells, char arrays are just wrapped in a cell
    % Multidimensional arrays are turned in cell arrays with same number of
    % elements
    
    if iscell(obj)
        obj_cell = obj;
	elseif isempty(obj)
		obj_cell = {};
    elseif ischar(obj)
        obj_cell = {obj};
    elseif numel(obj)>1
%         t = num2cell([1:ndims(obj)]);
%         dims = cellfun(@(x) ones(1, size(obj, x)) , t, 'uni', false);
        
          % is faster
          for i=1:ndims(obj)
              dims{i}=ones(1, size(obj, i));
          end
        obj_cell = mat2cell(obj, dims{:});
        %         for i=1:numel(obj)
        %             obj_cell{i} = obj(i);
        %         end
    else
        obj_cell = {obj};
    end
end


%     if isa(obj, 'cell')
%         obj_cell = obj;
% 	elseif isempty(obj)
% 		obj_cell = {};
%     elseif ischar(obj)
%         obj_cell = {obj};
%     elseif numel(obj)>1
%         for i=1:ndims(obj)
%             dims{i}=ones(1, size(obj, i));
%         end
%         obj_cell = mat2cell(obj, dims{:});
%         %         for i=1:numel(obj)
%         %             obj_cell{i} = obj(i);
%         %         end
%     else
%         obj_cell = {obj};
%     end
% end